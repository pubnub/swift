#!/usr/bin/env bash
#
# delete-classes.sh — remove the DataSync entity and relationship classes that
# create-classes.sh registers. 404s are expected on a keyset the classes were never registered on.
#
# Deleting a class does not delete the entities and relationships registered
# under it. Remove those first if the keyset still holds any.
#
# Usage:
#   SDK_DS_API_KEY=... SDK_DS_SUB_KEY=... ./delete-classes.sh

set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/shared.sh"

require_environment

CLASS_PATHS=(
  "relationship-classes/$(class_name facility-affiliation)/versions/1"
  "relationship-classes/$(class_name attending-physician)/versions/1"
  "entity-classes/$(class_name care-facility)/versions/1"
  "entity-classes/$(class_name practitioner)/versions/1"
  "entity-classes/$(class_name patient)/versions/2"
  "entity-classes/$(class_name patient)/versions/1"
)

say "deleting ${#CLASS_PATHS[@]} class versions"

for path in "${CLASS_PATHS[@]}"; do
  meta_delete "$META/$path"
done

finish
