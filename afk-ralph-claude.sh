#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env if present.
if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  source "$ROOT_DIR/.env"
  set +a
fi

# Defaults from settings.json
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"
CLAUDE_MODEL="sonnet"
CLAUDE_EFFORT="high"
if [ -f "$CLAUDE_SETTINGS" ]; then
  _model="$(jq -r '.model // empty' "$CLAUDE_SETTINGS")"
  _effort="$(jq -r '.effortLevel // empty' "$CLAUDE_SETTINGS")"
  [ -n "$_model" ] && CLAUDE_MODEL="$_model"
  [ -n "$_effort" ] && CLAUDE_EFFORT="$_effort"
fi

# Parse arguments
ITERATIONS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      CLAUDE_MODEL="$2"
      shift 2
      ;;
    --effort)
      CLAUDE_EFFORT="$2"
      shift 2
      ;;
    *)
      if [ -z "$ITERATIONS" ]; then
        ITERATIONS="$1"
      else
        echo "Unknown argument: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$ITERATIONS" ]; then
  echo "Usage: $0 <iterations> [--model <model>] [--effort <effort>]"
  exit 1
fi

LOG_DIR="$ROOT_DIR/logs"
STATE_DIR="$ROOT_DIR/state"
SCRIPTS_DIR="$ROOT_DIR/scripts"
LOCK_FILE="$STATE_DIR/ralph.lock"
AGENT_STATUS_FILE="$STATE_DIR/agent-status.json"

mkdir -p "$LOG_DIR" "$STATE_DIR"

if [ -f "$LOCK_FILE" ]; then
  echo "Ralph loop already running: $LOCK_FILE exists"
  exit 1
fi

cleanup() {
  rm -f "$LOCK_FILE" "$AGENT_STATUS_FILE"
}
trap cleanup EXIT

echo "$$" > "$LOCK_FILE"

require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Missing required file: $file"
    exit 1
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    exit 1
  fi
}

require_file "$ROOT_DIR/AGENT.md"
require_file "$ROOT_DIR/PROMPT.md"
require_file "$SCRIPTS_DIR/fetch_linear_task.py"
require_file "$SCRIPTS_DIR/update_linear_issue.py"

require_cmd claude
require_cmd python3
require_cmd jq

if [ -z "${LINEAR_API_KEY:-}" ]; then
  echo "Missing LINEAR_API_KEY"
  exit 1
fi

if [ -z "${LINEAR_PROJECT_NAME:-}" ]; then
  echo "Missing LINEAR_PROJECT_NAME"
  echo "Example: export LINEAR_PROJECT_NAME='Build Order Backend'"
  exit 1
fi

for ((i=1; i<=ITERATIONS; i++)); do
  echo
  echo "===================================================="
  echo "Ralph iteration $i / $ITERATIONS | model: $CLAUDE_MODEL | effort: $CLAUDE_EFFORT"
  echo "===================================================="

  timestamp="$(date +"%Y-%m-%dT%H-%M-%S")"
  run_log="$LOG_DIR/ralph-$timestamp.log"

  echo "[1/5] Fetching next task from Linear..."

  fetch_output="$(python3 "$SCRIPTS_DIR/fetch_linear_task.py")"
  echo "$fetch_output" | tee -a "$run_log"

  if [[ "$fetch_output" == *"NO_TASK_FOUND"* ]]; then
    echo "No eligible task found. Exiting."
    exit 0
  fi

  require_file "$STATE_DIR/current-task.md"

  issue_id="$(grep -E '^Issue:' "$STATE_DIR/current-task.md" | head -n1 | sed 's/^Issue:[[:space:]]*//')"
  issue_title="$(grep -E '^Title:' "$STATE_DIR/current-task.md" | head -n1 | sed 's/^Title:[[:space:]]*//')"

  if [ -z "$issue_id" ]; then
    echo "Could not parse Issue from state/current-task.md"
    exit 1
  fi

  echo "[2/5] Marking issue as In Progress in Linear..."
  python3 "$SCRIPTS_DIR/update_linear_issue.py" start "$issue_id" \
    | tee -a "$run_log"

  echo "[3/5] Running coding agent for $issue_id ($issue_title)..."

  agent_prompt="$(cat <<'AGENT_EOF'
Read AGENT.md, PROMPT.md, and state/current-task.md before doing anything.
Implement exactly the issue described in state/current-task.md.
Do not work on any other issue.
Follow AGENT.md and PROMPT.md strictly.
Return the final result in the required structured format at the end.
AGENT_EOF
  )"

  jq -n \
    --argjson running true \
    --arg agentType "claude" \
    --arg model "$CLAUDE_MODEL" \
    --arg reasoningEffort "$CLAUDE_EFFORT" \
    --argjson pid $$ \
    --arg issueId "$issue_id" \
    --arg issueTitle "$issue_title" \
    --arg startedAt "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg command "claude --dangerously-skip-permissions --model $CLAUDE_MODEL --effort $CLAUDE_EFFORT -p <prompt>" \
    '{running:$running,agentType:$agentType,model:$model,reasoningEffort:$reasoningEffort,pid:$pid,issueId:$issueId,issueTitle:$issueTitle,startedAt:$startedAt,command:$command}' \
    > "$AGENT_STATUS_FILE"

  result="$(
    claude --dangerously-skip-permissions \
      --model "$CLAUDE_MODEL" \
      --effort "$CLAUDE_EFFORT" \
      -p "$agent_prompt" \
      2>&1
  )"

  jq '.running = false' "$AGENT_STATUS_FILE" > "${AGENT_STATUS_FILE}.tmp" \
    && mv "${AGENT_STATUS_FILE}.tmp" "$AGENT_STATUS_FILE"

  echo "$result" | tee -a "$run_log"

  # Ensure the agent didn't break infrastructure scripts
  for script in "$SCRIPTS_DIR/fetch_linear_task.py" "$SCRIPTS_DIR/update_linear_issue.py"; do
    if ! python3 -m py_compile "$script" 2>/dev/null; then
      echo "WARNING: $script has syntax errors after agent run, restoring from git"
      git checkout -- "$script"
    fi
  done

  echo "[4/5] Parsing agent result..."

  if [[ "$result" == *"STATUS: DONE"* ]]; then
    echo "Task completed."

    linear_comment="$(printf "%s\n" "$result" | awk '
      BEGIN {capture=0}
      /^LINEAR_COMMENT:/ {capture=1; sub(/^LINEAR_COMMENT:[[:space:]]*/, ""); print; next}
      capture==1 {print}
    ')"

    if [ -z "$linear_comment" ]; then
      linear_comment="Agent completed the task and validation passed."
    fi

    echo "[5/5] Updating Linear as In Review..."
    python3 "$SCRIPTS_DIR/update_linear_issue.py" done "$issue_id" "$linear_comment" \
      | tee -a "$run_log"

  elif [[ "$result" == *"STATUS: BLOCKED"* ]]; then
    echo "Task is blocked."

    linear_comment="$(printf "%s\n" "$result" | awk '
      BEGIN {capture=0}
      /^LINEAR_COMMENT:/ {capture=1; sub(/^LINEAR_COMMENT:[[:space:]]*/, ""); print; next}
      capture==1 {print}
    ')"

    if [ -z "$linear_comment" ]; then
      linear_comment="Agent marked the issue as blocked."
    fi

    python3 "$SCRIPTS_DIR/update_linear_issue.py" blocked "$issue_id" "$linear_comment" \
      | tee -a "$run_log"

  elif [[ "$result" == *"STATUS: NEEDS_SPLIT"* ]]; then
    echo "Task needs split."

    linear_comment="$(printf "%s\n" "$result" | awk '
      BEGIN {capture=0}
      /^LINEAR_COMMENT:/ {capture=1; sub(/^LINEAR_COMMENT:[[:space:]]*/, ""); print; next}
      capture==1 {print}
    ')"

    if [ -z "$linear_comment" ]; then
      linear_comment="Agent marked the issue as too large and needing split."
    fi

    python3 "$SCRIPTS_DIR/update_linear_issue.py" needs_split "$issue_id" "$linear_comment" \
      | tee -a "$run_log"

  elif [[ "$result" == *"STATUS: FAILED"* ]]; then
    echo "Task failed."

    linear_comment="$(printf "%s\n" "$result" | awk '
      BEGIN {capture=0}
      /^LINEAR_COMMENT:/ {capture=1; sub(/^LINEAR_COMMENT:[[:space:]]*/, ""); print; next}
      capture==1 {print}
    ')"

    if [ -z "$linear_comment" ]; then
      linear_comment="Agent failed while implementing the issue."
    fi

    python3 "$SCRIPTS_DIR/update_linear_issue.py" failed "$issue_id" "$linear_comment" \
      | tee -a "$run_log"

  else
    echo "Unknown agent result format. Raw output saved to: $run_log"
  fi
done

echo
echo "Ralph loop finished after $ITERATIONS iterations."
