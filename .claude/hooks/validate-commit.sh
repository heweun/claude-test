#!/bin/bash
# validate-commit.sh
# PreToolUse Hook: Conventional Commits 형식 검증

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# git commit 명령이 아니면 통과
if ! echo "$COMMAND" | grep -qE '^\s*git commit'; then
  exit 0
fi

# --amend, --no-edit, -C 등 메시지 없는 커밋은 통과
if echo "$COMMAND" | grep -qE -- '--no-edit|-C\s'; then
  exit 0
fi

# 커밋 메시지 추출
MSG=""
if echo "$COMMAND" | grep -qE -- '-m\s+"[^"]*"'; then
  MSG=$(echo "$COMMAND" | grep -oE -- '-m\s+"[^"]*"' | sed -E 's/-m\s+"([^"]*)"/\1/')
elif echo "$COMMAND" | grep -qE -- "-m\s+'[^']*'"; then
  MSG=$(echo "$COMMAND" | grep -oE -- "-m\s+'[^']*'" | sed -E "s/-m\\s+'([^']*)'/\\1/")
fi

# 메시지를 추출하지 못했으면 통과 (에디터 사용 등)
if [ -z "$MSG" ]; then
  exit 0
fi

# 첫 줄만 검증 (멀티라인 커밋 메시지 지원)
FIRST_LINE=$(echo "$MSG" | head -1)

VALID_TYPES="feat|fix|docs|style|refactor|perf|test|chore|ci|build"
PATTERN="^($VALID_TYPES)(\(.+\))?: .{2,}"

if ! echo "$FIRST_LINE" | grep -qP "$PATTERN"; then
  cat <<EOF >&2
❌ [커밋 검증 실패] Conventional Commits 형식에 맞지 않습니다.

올바른 형식: type(scope): 한국어 설명 (2자 이상)
허용 type: feat, fix, docs, style, refactor, perf, test, chore, ci, build

입력한 메시지: "$FIRST_LINE"

예시:
  feat: 로그인 기능 추가
  fix(auth): 토큰 만료 오류 수정
  docs: README 설치 가이드 업데이트
EOF
  exit 2
fi

exit 0
