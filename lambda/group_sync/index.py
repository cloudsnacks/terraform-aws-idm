"""Cognito pre-token-generation trigger: Okta groups -> cognito:groups.

The Okta `groups` claim is mapped onto the user pool attribute
`custom:okta_groups` by the identity provider attribute mapping. Cognito does
not place federated users into Cognito groups from that attribute, so this
function copies the parsed group list into the ID token's `cognito:groups`
claim at token-generation time (option 1: verbatim passthrough).

Cognito may store the mapped claim in a few shapes depending on the IdP:
  - a JSON array string:      '["admins", "users"]'
  - a bracketed list string:  '[admins, users]'
  - a comma-separated string: 'admins, users'
All three are handled.
"""

import json


def _parse_groups(raw):
    if not raw:
        return []

    raw = raw.strip()

    # Preferred: a JSON-encoded array.
    try:
        value = json.loads(raw)
        if isinstance(value, list):
            return [str(g).strip() for g in value if str(g).strip()]
        if isinstance(value, str):
            raw = value
    except (ValueError, TypeError):
        pass

    # Fallback: strip surrounding brackets/quotes and split on commas.
    raw = raw.strip("[]")
    return [
        g.strip().strip('"').strip("'")
        for g in raw.split(",")
        if g.strip().strip('"').strip("'")
    ]


def handler(event, context):
    attributes = (event.get("request") or {}).get("userAttributes") or {}
    groups = _parse_groups(attributes.get("custom:okta_groups", ""))

    if groups:
        event["response"] = {
            "claimsOverrideDetails": {
                "groupOverrideDetails": {
                    "groupsToOverride": groups,
                }
            }
        }

    return event
