#!/bin/bash
# pre-commit-test.sh
# PreToolUse Hook: git commit 전 테스트 자동 실행

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# git commit 명령이 아니면 통과
if ! echo "$COMMAND" | grep -qE '^\s*git commit'; then
  exit 0
fi

# --amend, --allow-empty 등 특수 커밋은 통과
if echo "$COMMAND" | grep -qE -- '--allow-empty'; then
  exit 0
fi

CONFIG_FILE="$(git rev-parse --show-toplevel 2>/dev/null)/.claude/hooks/test-config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  exit 0
fi

TIMEOUT=$(jq -r '.timeout // 120' "$CONFIG_FILE")
AUTO_DETECT=$(jq -r '.autoDetect // true' "$CONFIG_FILE")
CUSTOM_CMD=$(jq -r '.testCommand // empty' "$CONFIG_FILE")

# 현재 브랜치가 스킵 브랜치에 해당하면 통과
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
SKIP_BRANCHES=$(jq -r '.skipOnBranches[]? // empty' "$CONFIG_FILE")
for skip_branch in $SKIP_BRANCHES; do
  if [ "$CURRENT_BRANCH" = "$skip_branch" ]; then
    exit 0
  fi
done

# 테스트 명령어 결정
TEST_CMD=""
if [ -n "$CUSTOM_CMD" ] && [ "$CUSTOM_CMD" != "null" ]; then
  TEST_CMD="$CUSTOM_CMD"
elif [ "$AUTO_DETECT" = "true" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  DETECTION_LENGTH=$(jq '.detectionOrder | length' "$CONFIG_FILE")
  for i in $(seq 0 $((DETECTION_LENGTH - 1))); do
    FILE=$(jq -r ".detectionOrder[$i].file" "$CONFIG_FILE")
    CMD=$(jq -r ".detectionOrder[$i].command" "$CONFIG_FILE")
    if [ -f "$ROOT/$FILE" ]; then
      TEST_CMD="$CMD"
      break
    fi
  done
fi

if [ -z "$TEST_CMD" ]; then
  exit 0
fi

# auto:python — uv 있으면 uv run pytest, 없으면 python -m pytest
if [ "$TEST_CMD" = "auto:python" ]; then
  if command -v uv &>/dev/null; then
    TEST_CMD="uv run pytest"
  else
    TEST_CMD="python -m pytest"
  fi
fi

echo "🧪 [테스트 실행] $TEST_CMD" >&2

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
cd "$ROOT" && timeout "$TIMEOUT" bash -c "$TEST_CMD" >&2
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  cat <<EOF >&2

❌ [커밋 차단] 테스트가 실패했습니다 (종료 코드: $EXIT_CODE)
테스트를 통과한 후 다시 커밋하세요.

  $TEST_CMD
EOF
  exit 2
fi

echo "✅ [테스트 통과] 커밋을 진행합니다." >&2
exit 0
