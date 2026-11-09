#!/usr/bin/env python3

"""Posts Codex review findings (findings.json) to a pull request as one review.

Every finding must be anchored to an added, modified or deleted line. Standard
library only.

Usage: post_review.py <findings.json>
Env:   GITHUB_TOKEN, GITHUB_REPOSITORY, PR_NUMBER, HEAD_SHA
"""
import json
import os
import re
import sys
import urllib.request

API = "https://api.github.com"
SEVERITIES = {
    "critical": "🔴 Critical",
    "high": "🟠 High",
    "major": "🟡 Major",
    "minor": "🔵 Minor",
    "nitpick": "⚪ Nitpick",
}
CATEGORIES = {
    "correctness": "Correctness",
    "concurrency": "Concurrency",
    "public-api": "Public API",
    "compatibility": "Compatibility",
    "performance": "Performance",
    "security": "Security",
    "tests": "Tests",
    "docs": "Docs",
    "build": "Build",
    "release": "Release",
    "other": "Other",
}
HUNK = re.compile(r"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@")
MAX_TITLE_LENGTH = 80
MAX_BODY_LENGTH = 10_000
MAX_SUGGESTION_LENGTH = 5_000
MAX_SUGGESTION_LINES = 5
MAX_LINE_NUMBER = 10_000_000
MAX_RANGE_LENGTH = 1_000
FINDING_FIELDS = {
    "file",
    "line",
    "side",
    "end_line",
    "severity",
    "category",
    "title",
    "body",
    "suggestion",
}


def request(method, path, body=None):
    http_request = urllib.request.Request(
        f"{API}{path}",
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={
            "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    with urllib.request.urlopen(http_request) as response:
        return json.load(response)


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
    if set(parsed) != {"findings"}:
        sys.exit('::error::Codex output must contain only the "findings" array.')
    findings = parsed.get("findings")
    if not isinstance(findings, list):
        # A broken run must fail, not pass as a clean review.
        sys.exit('::error::Codex output has no "findings" array.')
    valid = valid_findings(findings)
    return valid, len(findings) - len(valid)


def valid_findings(findings):
    valid = []
    for finding in findings:
        if not isinstance(finding, dict):
            print(f"::warning::Dropping malformed finding: {finding}")
            continue
        # The prompt says to omit these; a model that writes null means omitted.
        for optional in ("side", "end_line", "suggestion"):
            if finding.get(optional) is None:
                finding.pop(optional, None)
        file = finding.get("file")
        line = finding.get("line")
        end_line = finding.get("end_line", line)
        title = finding.get("title")
        body = finding.get("body")
        suggestion = finding.get("suggestion")
        side = finding.get("side")
        suggestion_lines = suggestion.count("\n") + 1 if isinstance(suggestion, str) else 0
        if (
            set(finding) <= FINDING_FIELDS
            and valid_path(file)
            and type(line) is int
            and 0 < line <= MAX_LINE_NUMBER
            and type(end_line) is int
            and line <= end_line <= MAX_LINE_NUMBER
            and end_line - line < MAX_RANGE_LENGTH
            # Type checks come first: membership tests hash their operand and
            # raise TypeError on lists and dicts.
            and (side is None or side == "left")
            and isinstance(finding.get("severity"), str)
            and finding["severity"] in SEVERITIES
            and isinstance(finding.get("category"), str)
            and finding["category"] in CATEGORIES
            and valid_text(title, MAX_TITLE_LENGTH, single_line=True)
            and title.endswith(".")
            and valid_text(body, MAX_BODY_LENGTH)
            and (
                suggestion is None
                or (
                    side is None
                    and end_line - line < MAX_SUGGESTION_LINES
                    and valid_text(suggestion, MAX_SUGGESTION_LENGTH)
                    and suggestion_lines <= MAX_SUGGESTION_LINES
                )
            )
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


def changed_lines(repo, pr_number):
    """Maps each changed file to its added/modified and deleted line numbers."""
    result, page = {}, 1
    while True:
        files = request("GET", f"/repos/{repo}/pulls/{pr_number}/files?per_page=100&page={page}")
        for entry in files:
            lines = {"right": set(), "left": set()}
            old_line, new_line = None, None
            for row in entry.get("patch", "").splitlines():
                hunk = HUNK.match(row)
                if hunk:
                    old_line, new_line = int(hunk.group(1)), int(hunk.group(2))
                elif old_line is None or row.startswith("\\"):
                    continue
                elif row.startswith("+"):
                    lines["right"].add(new_line)
                    new_line += 1
                elif row.startswith("-"):
                    lines["left"].add(old_line)
                    old_line += 1
                else:
                    old_line += 1
                    new_line += 1
            result[entry["filename"]] = lines
        if len(files) < 100:
            return result
        page += 1


def valid_anchors(findings, diff_lines):
    """Drops findings that are not anchored entirely to changed diff lines."""
    valid = []
    for finding in findings:
        side = finding.get("side", "right")
        start, end = finding["line"], finding.get("end_line", finding["line"])
        lines = diff_lines.get(finding["file"], {}).get(side, set())
        if all(line in lines for line in range(start, end + 1)):
            valid.append(finding)
        else:
            print(f"::warning::Dropping finding outside changed lines: {finding}")
    return valid


def render(finding, with_suggestion=False):
    header = f"{SEVERITIES[finding['severity']]} | {CATEGORIES[finding['category']]}"
    text = f"{header}\n\n**{finding['title']}**\n\n{finding['body']}"
    if with_suggestion and "suggestion" in finding:
        # GitHub renders this fence as a diff with a "Commit suggestion" button.
        text += f"\n\n```suggestion\n{finding['suggestion']}\n```"
    return text


def summarize(findings, rejected=0):
    if not findings and not rejected:
        text = "**Automated review complete.** No findings from this review."
    elif not findings:
        text = "**Review incomplete.**"
    else:
        counts = {severity: sum(f["severity"] == severity for f in findings) for severity in SEVERITIES}
        text = "**Codex review:** " + ", ".join(
            f"{count} {severity}" for severity, count in counts.items() if count
        ) + "."
    if rejected:
        text += f"\n\n⚠️ {rejected} finding(s) had an invalid format and were not posted, so this review may be incomplete."
    return text


def main():
    repo = os.environ["GITHUB_REPOSITORY"]
    pr_number = os.environ["PR_NUMBER"]
    findings, rejected = load_output(sys.argv[1])
    diff_lines = changed_lines(repo, pr_number)
    anchored = valid_anchors(findings, diff_lines)
    rejected += len(findings) - len(anchored)
    findings = anchored

    comments = []
    for finding in findings:
        start, end = finding["line"], finding.get("end_line", finding["line"])
        side = "LEFT" if finding.get("side") == "left" else "RIGHT"
        comment = {
            "path": finding["file"],
            "line": end,
            "side": side,
            "body": render(finding, side == "RIGHT"),
        }
        if end > start:
            comment.update({"start_line": start, "start_side": side})
        comments.append(comment)

    request(
        "POST",
        f"/repos/{repo}/pulls/{pr_number}/reviews",
        {
            "commit_id": os.environ["HEAD_SHA"],
            "event": "COMMENT",
            "body": summarize(findings, rejected),
            "comments": comments,
        },
    )
    print(f"Posted review with {len(comments)} inline comment(s).")


if __name__ == "__main__":
    main()
