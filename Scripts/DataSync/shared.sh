#!/usr/bin/env bash
#
# shared.sh — shared helpers for the DataSync class provisioning scripts.
#
# Sourced by create-classes.sh and delete-classes.sh; not runnable on its own.
#
# Required environment:
#   SDK_DS_API_KEY   metadata-plane API key authorizing class writes
#   SDK_DS_SUB_KEY   subscribe key the classes are registered under

META_BASE="https://admin-api.private.portal.pdx1.aws.int.ps.pn"
CLASS_PREFIX="Swift-"
PN_VERSION="2026-09-03"

ENTITY_CLASS_MT="application/vnd.pubnub.objects.entity-class+json;version=1"
RELATIONSHIP_CLASS_MT="application/vnd.pubnub.objects.relationship-class+json;version=1"

FAILURES=0

# Requires the credentials, and sets META: the metadata base scoped to the subkey.
require_environment() {
  local missing=()
  [ -n "${SDK_DS_API_KEY:-}" ] || missing+=("SDK_DS_API_KEY")
  [ -n "${SDK_DS_SUB_KEY:-}" ] || missing+=("SDK_DS_SUB_KEY")

  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'Set %s to run this script\n' "${missing[*]}" >&2
    exit 1
  fi

  META="$META_BASE/v2/datasync/subkeys/$SDK_DS_SUB_KEY"
}

# The name a class is registered under: "patient" -> "Swift-patient".
class_name() { printf '%s%s' "$CLASS_PREFIX" "$1"; }

# Prints a section heading.
say() { printf '\n=== %s ===\n' "$1"; }

# Pretty-prints JSON, or prints it as-is when it is not valid JSON.
pp_json() { local s="$1"; [ -z "$s" ] && return 0; printf '%s\n' "$s" | jq . 2>/dev/null || printf '%s\n' "$s"; }

# Runs one request and prints the response, counting a failure on any status not
# listed in the first argument. Never aborts, so one bad request hides no others.
send() { # accepted-codes curl-args...
  local accepted="$1"; shift
  local out body hc
  out="$(curl -sS -w $'\n%{http_code}' "$@")" || true
  hc="${out##*$'\n'}"
  body="${out%$'\n'*}"

  printf -- '--- response ---\n'
  pp_json "$body"

  if [ -n "$hc" ] && [[ " $accepted " == *" $hc "* ]]; then
    printf -- '-> HTTP %s\n' "$hc"
  else
    printf -- '-> HTTP %s (unexpected)\n' "${hc:-no response}" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

# Registers one class version. A 409 means it already exists — delete it first.
meta_post() { # url media-type body
  local url="$1" mt="$2" body="$3"
  printf -- '--- request ---\nPOST %s\nContent-Type: %s\n' "$url" "$mt"
  pp_json "$body"
  send 201 -X POST "$url" \
    -H "Content-Type: $mt" \
    -H "Accept: $mt" \
    -H "Authorization: $SDK_DS_API_KEY" \
    -H "Pubnub-Version: $PN_VERSION" \
    -H "Idempotency-Key: $(uuidgen)" \
    -d "$body"
}

# Removes one class version. Answers 404 when it was never registered.
meta_delete() { # url
  local url="$1"
  printf -- '--- request ---\nDELETE %s\n' "$url"
  send "200 204 404" -X DELETE "$url" \
    -H "Accept: application/json" \
    -H "Authorization: $SDK_DS_API_KEY" \
    -H "Pubnub-Version: $PN_VERSION"
}

# Exits non-zero if any request failed.
finish() {
  if [ "$FAILURES" -gt 0 ]; then
    printf '\n=== %d request(s) failed ===\n' "$FAILURES" >&2
    exit 1
  fi

  say "done"
}
