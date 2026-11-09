#!/usr/bin/env python3

"""Posts Codex review findings (findings.json) to a pull request as one review.

Findings on lines visible in the PR diff become inline comments. The rest go
into the review summary. Each finding gets an ID (R1, R2, ...) and the review
summary carries a hidden ledger of every finding so far. The next run reads it
back, so a finding is posted once, and the model can report it as fixed or
discarded. Standard library only.

Usage: post_review.py <findings.json>
Env:   GITHUB_TOKEN, GITHUB_REPOSITORY, PR_NUMBER, HEAD_SHA
"""
import json
import os
import re
import sys
import urllib.error
from functools import lru_cache

# -I leaves the script directory off sys.path; the sibling module is needed.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from review_thread import STATUSES, GraphQLError, fetch_state, graphql, human_signals, request  # noqa: E402

SEVERITIES = {
    "critical": "🔴 Critical",
    "high": "🟠 High",
    "major": "🟡 Major",
    "minor": "🔵 Minor",
    "nitpick": "⚪ Nitpick",
}
CATEGORIES = {"correctness", "concurrency", "public-api", "performance", "security", "tests", "docs", "other"}
FINDING_ID = re.compile(r"R[1-9]\d*")
HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@")
RESOLVE = "mutation($id: ID!) { resolveReviewThread(input: {threadId: $id}) { thread { id } } }"
MAX_TITLE_LENGTH = 80
MAX_BODY_LENGTH = 10_000
MAX_SUGGESTION_LENGTH = 50_000
MAX_LINE_NUMBER = 10_000_000
MAX_RANGE_LENGTH = 1_000


def load_output(path):
    """Parses the model output, tolerating a Markdown fence around the JSON."""
    with open(path, encoding="utf-8") as handle:
        text = handle.read().strip()
    text = re.sub(r"^```(?:json)?\s*|\s*```$", "", text)
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError as error:
        sys.exit(f"::error::Codex output is not valid JSON: {error}")
    if not isinstance(parsed, dict):
        sys.exit("::error::Codex output must be a JSON object.")
    findings = parsed.get("findings")
    if not isinstance(findings, list):
        # A broken run must fail, not pass as a clean review.
        sys.exit('::error::Codex output has no "findings" array.')
    updates = parsed.get("updates", [])
    if not isinstance(updates, list):
        sys.exit('::error::Codex output has a malformed "updates" array.')
    return valid_findings(findings), valid_updates(updates)


def valid_findings(findings):
    valid = []
    for finding in findings:
        if not isinstance(finding, dict):
            print(f"::warning::Dropping malformed finding: {finding}")
            continue
        file = finding.get("file")
        line = finding.get("line")
        end_line = finding.get("end_line", line)
        title = finding.get("title")
        body = finding.get("body")
        suggestion = finding.get("suggestion")
        if (
            valid_path(file)
            and type(line) is int
            and 0 < line <= MAX_LINE_NUMBER
            and type(end_line) is int
            and line <= end_line <= MAX_LINE_NUMBER
            and end_line - line < MAX_RANGE_LENGTH
            and finding.get("severity") in SEVERITIES
            and finding.get("category") in CATEGORIES
            and valid_text(title, MAX_TITLE_LENGTH, single_line=True)
            and title.endswith(".")
            and valid_text(body, MAX_BODY_LENGTH)
            and ("suggestion" not in finding or isinstance(suggestion, str))
            and (suggestion is None or len(suggestion) <= MAX_SUGGESTION_LENGTH)
        ):
            valid.append(finding)
        else:
            print(f"::warning::Dropping malformed finding: {finding}")
    return valid


def valid_path(path):
    """Returns whether a path is a non-empty, repository-relative POSIX path."""
    return (
        isinstance(path, str)
        and path
        and not path.startswith("/")
        and "\0" not in path
        and "\n" not in path
        and "\r" not in path
        and all(part not in {"", ".", ".."} for part in path.split("/"))
    )


def valid_text(text, limit, single_line=False):
    """Returns whether text is non-empty, bounded and optionally one line."""
    return (
        isinstance(text, str)
        and bool(text.strip())
        and len(text) <= limit
        and "\0" not in text
        and (not single_line or ("\n" not in text and "\r" not in text))
    )


def valid_updates(updates):
    valid = []
    for update in updates:
        if (
            isinstance(update, dict)
            and isinstance(update.get("id"), str)
            and FINDING_ID.fullmatch(update["id"])
            and update.get("status") in STATUSES
        ):
            valid.append(update)
        else:
            print(f"::warning::Dropping malformed update: {update}")
    return valid


@lru_cache(maxsize=None)
def can_write(repo, login):
    try:
        permission = request("GET", f"/repos/{repo}/collaborators/{login}/permission")["permission"]
    except urllib.error.HTTPError:
        return False
    return permission in {"admin", "maintain", "write"}


def apply_updates(repo, ledger, threads, updates):
    """Applies the model's status updates to open findings; returns threads to resolve.

    Only open findings change. A discard also needs a human with write access
    to have replied to, 👎'd or resolved the finding's thread, because the model
    reads that thread as untrusted data and could be talked into hiding a finding.
    """
    to_resolve = []
    for update in updates:
        entry = ledger.get(update["id"])
        if entry is None or entry["status"] != "open" or update["status"] == "open":
            continue
        thread = threads.get(update["id"])
        if update["status"] == "fixed":
            entry["status"] = "fixed"
            if thread and not thread["isResolved"]:
                to_resolve.append(thread["id"])
            continue
        decline = next((s for s in human_signals(thread) if can_write(repo, s[0])), None) if thread else None
        if decline is None:
            print(f"::warning::{update['id']} discarded without a human decline; keeping it open.")
            continue
        entry.update(status="discarded", by=f"@{decline[0]}", via=decline[1], url=decline[2])
    return to_resolve


def drop_repeats(findings, ledger):
    """Drops findings that restate an open or discarded one; a fixed one may come back."""
    known = {(e.get("file"), e.get("title", "").lower()) for e in ledger.values() if e["status"] != "fixed"}
    fresh = []
    for finding in findings:
        if (finding["file"], finding["title"][:80].lower()) in known:
            print(f"::notice::Dropping a repeat of an earlier finding: {finding['title']}")
        else:
            fresh.append(finding)
    return fresh


def commentable_lines(repo, pr_number):
    """Maps each changed file to the set of new-side lines the diff shows."""
    result, page = {}, 1
    while True:
        files = request("GET", f"/repos/{repo}/pulls/{pr_number}/files?per_page=100&page={page}")
        for entry in files:
            lines, current = set(), None
            for row in entry.get("patch", "").splitlines():
                hunk = HUNK.match(row)
                if hunk:
                    current = int(hunk.group(1))
                elif current is not None and not row.startswith("-"):
                    lines.add(current)
                    current += 1
            result[entry["filename"]] = lines
        if len(files) < 100:
            return result
        page += 1


def render(finding, with_suggestion=False):
    text = f"{SEVERITIES[finding['severity']]} · {finding['id']}\n\n<b>{finding['title']}</b>\n\n{finding['body']}"
    if with_suggestion and "suggestion" in finding:
        # GitHub renders this fence as a diff with a "Commit suggestion" button.
        text += f"\n\n```suggestion\n{finding['suggestion']}\n```"
    # Keep the trusted marker last so model-controlled text cannot impersonate it.
    return text + f"\n\n<!-- id:{finding['id']} -->"


def render_ledger(ledger):
    # < and > are escaped so no title can close the HTML comment.
    payload = json.dumps(ledger, ensure_ascii=False).replace("<", "\\u003c").replace(">", "\\u003e")
    return f"<!-- review-ledger:v1 {payload} -->"


def summarize(new, before, ledger):
    """Headlines the review: what is new, what is still open and what changed."""
    changed = {s: sum(ledger[k]["status"] == s and before[k] == "open" for k in before) for s in ("fixed", "discarded")}
    still_open = sum(e["status"] == "open" for k, e in ledger.items() if k in before)
    if not new and not still_open:
        text = "**Ready to merge.** No open findings."
    else:
        counts = {s: sum(f["severity"] == s for f in new) for s in SEVERITIES}
        parts = []
        if new:
            parts.append(", ".join(f"{n} {s}" for s, n in counts.items() if n) + " new")
        if still_open:
            parts.append(f"{still_open} earlier still open")
        text = "**Codex review:** " + "; ".join(parts) + "."
    closed = [f"{n} {s}" for s, n in changed.items() if n]
    return text + (f" Since the last review: {', '.join(closed)}." if closed else "")


def main():
    repo = os.environ["GITHUB_REPOSITORY"]
    pr_number = os.environ["PR_NUMBER"]
    findings, updates = load_output(sys.argv[1])
    ledger, threads = fetch_state(repo, pr_number)
    before = {key: entry["status"] for key, entry in ledger.items()}

    to_resolve = apply_updates(repo, ledger, threads, updates)
    new = drop_repeats(findings, ledger)
    next_id = max((int(key[1:]) for key in ledger), default=0) + 1
    for offset, finding in enumerate(new):
        finding["id"] = f"R{next_id + offset}"
        ledger[finding["id"]] = {"status": "open", "title": finding["title"][:80], "file": finding["file"]}

    comments, leftover = [], []
    if new:
        visible = commentable_lines(repo, pr_number)
        for finding in new:
            start, end = finding["line"], finding.get("end_line", finding["line"])
            visible_lines = visible.get(finding["file"], set())
            if all(line in visible_lines for line in range(start, end + 1)):
                comment = {"path": finding["file"], "line": end, "side": "RIGHT", "body": render(finding, True)}
                if end > start:
                    comment.update({"start_line": start, "start_side": "RIGHT"})
                comments.append(comment)
            else:
                leftover.append(finding)

    summary = summarize(new, before, ledger)
    if leftover:
        summary += "\n\nFindings outside the diff:\n\n" + "\n\n".join(
            f"- `{f['file']}:{f['line']}`\n\n{render(f)}" for f in leftover
        )
    summary += f"\n\n{render_ledger(ledger)}"

    request(
        "POST",
        f"/repos/{repo}/pulls/{pr_number}/reviews",
        {"commit_id": os.environ["HEAD_SHA"], "event": "COMMENT", "body": summary, "comments": comments},
    )
    print(f"Posted review with {len(comments)} inline comment(s).")

    # After posting, so a failed post leaves the threads open for the next run.
    for thread_id in to_resolve:
        try:
            graphql(RESOLVE, {"id": thread_id})
        except (GraphQLError, urllib.error.URLError) as error:
            print(f"::warning::Could not resolve thread {thread_id}: {error}")


if __name__ == "__main__":
    main()
