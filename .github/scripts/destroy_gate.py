#!/usr/bin/env python3
"""Destroy gate (AGENTS.md / SKILL.md).

Fails if a Terraform JSON plan deletes a resource without recreating it
(i.e. a pure "delete", not a "replace"), unless the resource address is listed
in the project's testing/.checkov-allowlist.json "allowed_deletions".

Usage: destroy_gate.py <tfplan.json> <allowlist.json>
"""
import json
import sys


def main() -> int:
    plan_path, allowlist_path = sys.argv[1], sys.argv[2]
    with open(plan_path) as f:
        plan = json.load(f)
    try:
        with open(allowlist_path) as f:
            allowed = set(json.load(f).get("allowed_deletions", []))
    except FileNotFoundError:
        allowed = set()

    blocked, approved, replaced = [], [], []
    for rc in plan.get("resource_changes", []):
        actions = rc["change"]["actions"]
        if "delete" not in actions:
            continue
        if "create" in actions:
            replaced.append(rc["address"])
        elif rc["address"] in allowed:
            approved.append(rc["address"])
        else:
            blocked.append(rc["address"])

    for addr in replaced:
        print(f"replace (allowed): {addr}")
    for addr in approved:
        print(f"delete (allow-listed): {addr}")
    for addr in blocked:
        print(f"::error title=Destroy gate::Unapproved deletion of {addr}")

    if blocked:
        print(f"{len(blocked)} unapproved deletion(s). Add them to {allowlist_path} if intended.")
        return 1
    print("Destroy gate passed: no unapproved deletions.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
