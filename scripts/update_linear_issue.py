#!/usr/bin/env python3
"""Update a Linear issue's state and/or add a comment.

Usage:
    python scripts/update_linear_issue.py start       <issue-identifier>
    python scripts/update_linear_issue.py done        <issue-identifier> [comment]
    python scripts/update_linear_issue.py blocked     <issue-identifier> [comment]
    python scripts/update_linear_issue.py failed      <issue-identifier> [comment]
    python scripts/update_linear_issue.py needs_split <issue-identifier> [comment]
    python scripts/update_linear_issue.py comment     <issue-identifier> <comment>

State transitions:
    start       -> moves to "In Progress"
    done        -> moves to "In Review" (or "Done" if no review state exists)
    blocked     -> adds comment with blocker details, keeps current state
    failed      -> adds comment with failure details, keeps current state
    needs_split -> adds comment with split suggestion, keeps current state
    comment     -> adds a comment without changing state
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from common_linear import graphql

# Maps action -> target workflow state name candidates (tried in order).
STATE_TARGETS = {
    "start": ["In Progress"],
    "done": ["In Review", "Done", "Closed"],
    "blocked": ["Todo", "Backlog"],
    "failed": ["Todo", "Backlog"],
}


def find_issue_by_identifier(identifier: str) -> dict | None:
    """Look up an issue by its human-readable identifier (e.g. BO-42)."""
    data = graphql(
        """
        query($id: String!) {
            issue(id: $id) {
                id
                identifier
                title
                team { id }
                state { id name type }
            }
        }
        """,
        variables={"id": identifier},
    )
    return data.get("issue")


def get_team_states(team_id: str) -> list[dict]:
    """Get all workflow states for a team."""
    data = graphql(
        """
        query($teamId: ID!) {
            workflowStates(filter: { team: { id: { eq: $teamId } } }) {
                nodes { id name type }
            }
        }
        """,
        variables={"teamId": team_id},
    )
    return data.get("workflowStates", {}).get("nodes", [])


def transition_issue(issue_id: str, state_id: str) -> None:
    """Move an issue to a new workflow state."""
    graphql(
        """
        mutation($id: String!, $stateId: String!) {
            issueUpdate(id: $id, input: { stateId: $stateId }) {
                success
            }
        }
        """,
        variables={"id": issue_id, "stateId": state_id},
    )


def add_comment(issue_id: str, body: str) -> None:
    """Add a comment to an issue."""
    graphql(
        """
        mutation($issueId: String!, $body: String!) {
            commentCreate(input: { issueId: $issueId, body: $body }) {
                success
            }
        }
        """,
        variables={"issueId": issue_id, "body": body},
    )


def resolve_target_state(team_id: str, action: str) -> dict | None:
    """Find the best matching workflow state for the given action."""
    candidates = STATE_TARGETS.get(action)
    if not candidates:
        return None

    states = get_team_states(team_id)
    for candidate_name in candidates:
        for state in states:
            if state["name"].lower() == candidate_name.lower():
                return state
    return None


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    action = sys.argv[1]
    identifier = sys.argv[2]
    comment_text = sys.argv[3] if len(sys.argv) > 3 else ""

    valid_actions = {"start", "done", "blocked", "failed", "needs_split", "comment"}
    if action not in valid_actions:
        print(f"ERROR: unknown action '{action}'. Valid: {', '.join(sorted(valid_actions))}")
        sys.exit(1)

    issue = find_issue_by_identifier(identifier)
    if not issue:
        print(f"ERROR: issue '{identifier}' not found in Linear.")
        sys.exit(1)

    issue_id = issue["id"]
    team_id = issue["team"]["id"]

    # State transition for start/done.
    if action in STATE_TARGETS:
        target = resolve_target_state(team_id, action)
        if target:
            transition_issue(issue_id, target["id"])
            print(f"OK: {identifier} -> {target['name']}")
        else:
            print(f"WARN: no matching state for action '{action}', skipping transition.")

    # Comment for all actions except bare start.
    if action == "start":
        add_comment(issue_id, "Ralph agent picked up this issue and started working on it.")
        print(f"OK: comment added to {identifier}")
    elif action == "comment":
        if not comment_text:
            print("ERROR: 'comment' action requires a comment body.")
            sys.exit(1)
        add_comment(issue_id, comment_text)
        print(f"OK: comment added to {identifier}")
    elif comment_text:
        prefix = {
            "done": "Agent completed this task.",
            "blocked": "Agent marked this task as BLOCKED.",
            "failed": "Agent FAILED on this task.",
            "needs_split": "Agent marked this task as NEEDS_SPLIT.",
        }.get(action, "")
        full_comment = f"{prefix}\n\n{comment_text}" if prefix else comment_text
        add_comment(issue_id, full_comment)
        print(f"OK: comment added to {identifier}")


if __name__ == "__main__":
    main()
