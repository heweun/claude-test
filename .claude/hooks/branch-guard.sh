#!/bin/bash
# branch-guard.sh
# SessionStart Hook: 보호 브랜치에서 작업 시작 시 경고

PROTECTED_BRANCHES="main master dev develop release staging"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -z "$CURRENT_BRANCH" ] || [ "$CURRENT_BRANCH" = "HEAD" ]; then
  exit 0
fi

for branch in $PROTECTED_BRANCHES; do
  if [ "$CURRENT_BRANCH" = "$branch" ] || echo "$CURRENT_BRANCH" | grep -qE "^release/"; then
    cat <<EOF >&2
⚠️  [브랜치 가드] 현재 보호 브랜치 '$CURRENT_BRANCH'에 있습니다.

보호 브랜치에서 직접 작업하는 것은 위험합니다.
작업용 브랜치를 생성하여 진행하세요:

  git checkout -b feat/기능명
  git checkout -b fix/버그명

작업 내용이 없다면 계속 진행해도 안전합니다.
EOF
    exit 2
  fi
done

exit 0
