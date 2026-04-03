#!/bin/bash
# co-author-inject.sh
# PreToolUse Hook: git commit 명령에 Co-Author 태그 자동 삽입

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# git commit 명령이 아니면 통과
if ! echo "$COMMAND" | grep -qE '^\s*git commit'; then
  exit 0
fi

CO_AUTHOR="Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

# 이미 Co-Author가 삽입되어 있으면 통과
if echo "$COMMAND" | grep -q "Co-Authored-By"; then
  exit 0
fi

# -m "메시지" 패턴 처리
if echo "$COMMAND" | grep -qE -- '-m\s+"[^"]*"'; then
  NEW_COMMAND=$(echo "$COMMAND" | sed -E "s/-m \"([^\"]*)\"/--trailer 'Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>' -m \"\1\"/")
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":$(echo "$NEW_COMMAND" | jq -Rs .)}}}"
  exit 0
fi

# -m '메시지' 패턴 처리
if echo "$COMMAND" | grep -qE -- "-m\s+'[^']*'"; then
  NEW_COMMAND=$(echo "$COMMAND" | sed -E "s/-m '([^']*)'/--trailer 'Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>' -m '\1'/")
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":$(echo "$NEW_COMMAND" | jq -Rs .)}}}"
  exit 0
fi

# heredoc(EOF) 패턴 또는 기타 — --trailer 옵션 추가
NEW_COMMAND="$COMMAND --trailer '$CO_AUTHOR'"
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":$(echo "$NEW_COMMAND" | jq -Rs .)}}}"
exit 0
