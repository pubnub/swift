#!/usr/bin/env bash
#
# create-classes.sh — register the DataSync entity and relationship classes the
# healthcare integration test suites expect to find on the keyset.
#
# Usage:
#   SDK_DS_API_KEY=... SDK_DS_SUB_KEY=... ./create-classes.sh
#
# See README.md for the full environment and the class layout.
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/shared.sh"

require_environment

PATIENT="$(class_name patient)"
PRACTITIONER="$(class_name practitioner)"
CARE_FACILITY="$(class_name care-facility)"
ATTENDING_PHYSICIAN="$(class_name attending-physician)"
FACILITY_AFFILIATION="$(class_name facility-affiliation)"

say "entity-class: $PATIENT v1 (dateOfBirth + diagnosis restricted to 'clinical'; all fields also in 'admin')"
meta_post "$META/entity-classes/$PATIENT/versions/1" "$ENTITY_CLASS_MT" "$(cat <<JSON
{
  "data": {
    "description": "A patient in the hospital network",
    "config": { "ttlSec": 31536000 },
    "properties": [
      { "name": "mrn", "path": "/payload/mrn", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "fullName", "path": "/payload/fullName", "valueKind": "string", "filtering": "full", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "dateOfBirth", "path": "/payload/dateOfBirth", "valueKind": "date", "filtering": "simple", "projections": [{ "name": "clinical" }, { "name": "admin" }] },
      { "name": "diagnosis", "path": "/payload/diagnosis", "valueKind": "string", "filtering": "full", "projections": [{ "name": "clinical" }, { "name": "admin" }] }
    ]
  }
}
JSON
)"

say "entity-class: $PATIENT v2 (adds 'allergies' in clinical + admin)"
meta_post "$META/entity-classes/$PATIENT/versions/2" "$ENTITY_CLASS_MT" "$(cat <<JSON
{
  "data": {
    "description": "A patient in the hospital network",
    "config": { "ttlSec": 31536000 },
    "properties": [
      { "name": "mrn", "path": "/payload/mrn", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "fullName", "path": "/payload/fullName", "valueKind": "string", "filtering": "full", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "dateOfBirth", "path": "/payload/dateOfBirth", "valueKind": "date", "filtering": "simple", "projections": [{ "name": "clinical" }, { "name": "admin" }] },
      { "name": "diagnosis", "path": "/payload/diagnosis", "valueKind": "string", "filtering": "full", "projections": [{ "name": "clinical" }, { "name": "admin" }] },
      { "name": "allergies", "path": "/payload/allergies", "valueKind": "string", "filtering": "full", "projections": [{ "name": "clinical" }, { "name": "admin" }] }
    ]
  }
}
JSON
)"

say "entity-class: $PRACTITIONER v1 (email + phone admin-only)"
meta_post "$META/entity-classes/$PRACTITIONER/versions/1" "$ENTITY_CLASS_MT" "$(cat <<JSON
{
  "data": {
    "description": "A clinician (physician, nurse, etc.)",
    "config": { "ttlSec": 31536000 },
    "properties": [
      { "name": "npi", "path": "/payload/npi", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "fullName", "path": "/payload/fullName", "valueKind": "string", "filtering": "full", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "specialty", "path": "/payload/specialty", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "email", "path": "/payload/email", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "admin" }] },
      { "name": "phone", "path": "/payload/phone", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "admin" }] }
    ]
  }
}
JSON
)"

say "entity-class: $CARE_FACILITY v1 (every field in __default__ and admin)"
meta_post "$META/entity-classes/$CARE_FACILITY/versions/1" "$ENTITY_CLASS_MT" "$(cat <<JSON
{
  "data": {
    "description": "A hospital or clinic in the network",
    "config": { "ttlSec": 31536000 },
    "properties": [
      { "name": "code", "path": "/payload/code", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "name", "path": "/payload/name", "valueKind": "string", "filtering": "full", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "city", "path": "/payload/city", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "postalCode", "path": "/payload/postalCode", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] }
    ]
  }
}
JSON
)"

say "relationship-class: $ATTENDING_PHYSICIAN v1 ($PRACTITIONER -> $PATIENT, one-to-many)"
meta_post "$META/relationship-classes/$ATTENDING_PHYSICIAN/versions/1" "$RELATIONSHIP_CLASS_MT" "$(cat <<JSON
{
  "data": {
    "description": "The physician currently responsible for a patients care",
    "directed": true,
    "cardinality": "one-to-many",
    "entityAClass": "$PRACTITIONER",
    "entityBClass": "$PATIENT",
    "properties": [
      { "name": "role", "path": "/payload/role", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] },
      { "name": "since", "path": "/payload/since", "valueKind": "date", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] }
    ]
  }
}
JSON
)"

say "relationship-class: $FACILITY_AFFILIATION v1 ($CARE_FACILITY -> $PRACTITIONER, many-to-many)"
meta_post "$META/relationship-classes/$FACILITY_AFFILIATION/versions/1" "$RELATIONSHIP_CLASS_MT" "$(cat <<JSON
{
  "data": {
    "description": "A practitioner may practise at several facilities, and vice versa",
    "directed": true,
    "cardinality": "many-to-many",
    "entityAClass": "$CARE_FACILITY",
    "entityBClass": "$PRACTITIONER",
    "properties": [
      { "name": "department", "path": "/payload/department", "valueKind": "string", "filtering": "simple", "projections": [{ "name": "__default__" }, { "name": "admin" }] }
    ]
  }
}
JSON
)"

finish
