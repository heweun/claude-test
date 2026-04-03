#!/bin/bash
# validate-push.sh
# PreToolUse Hook: git push 시 보호 브랜치 강제 push 차단

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# git push 명령이 아니면 통과
if ! echo "$COMMAND" | grep -qE '^\s*git push'; then
  exit 0
fi

# --force, -f, --force-with-lease 감지
if echo "$COMMAND" | grep -qE -- '--force|-f\b|--force-with-lease'; then
  PROTECTED_BRANCHES="main master dev develop"
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  for branch in $PROTECTED_BRANCHES; do
    # 명령어에 보호 브랜치 이름이 있거나 현재 브랜치가 보호 브랜치이면 차단
    if echo "$COMMAND" | grep -qE "\b$branch\b" || [ "$CURRENT_BRANCH" = "$branch" ]; then
      cat <<EOF >&2
🚫 [Push 차단] 보호 브랜치 '$branch'에 강제 push는 허용되지 않습니다.

  git push --force  →  허용 안 됨
  git push          →  허용됨 (일반 push)

강제 push가 꼭 필요하다면 직접 터미널에서 실행하세요.
EOF
      exit 2
    fi
  done
fi

exit 0
