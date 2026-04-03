#!/bin/bash
# auto-commit.sh
# Stop Hook: Claude 응답 완료 후 변경사항 감지 시 자동 커밋 제안

PROTECTED_BRANCHES="main master dev develop release staging"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# git 저장소가 아니면 종료
if [ -z "$CURRENT_BRANCH" ]; then
  exit 0
fi

# 보호 브랜치에서는 자동 커밋 안 함
for branch in $PROTECTED_BRANCHES; do
  if [ "$CURRENT_BRANCH" = "$branch" ] || echo "$CURRENT_BRANCH" | grep -qE "^release/"; then
    exit 0
  fi
done

# 변경사항 확인
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
STAGED=$(git -C "$ROOT" diff --cached --name-only 2>/dev/null)
UNSTAGED=$(git -C "$ROOT" diff --name-only 2>/dev/null)
UNTRACKED=$(git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null)

if [ -z "$STAGED" ] && [ -z "$UNSTAGED" ] && [ -z "$UNTRACKED" ]; then
  exit 0
fi

# 변경 파일 수 계산
TOTAL_FILES=$(echo -e "$STAGED\n$UNSTAGED\n$UNTRACKED" | grep -c '\S' || true)

# 변경사항이 있을 때 Claude에게 컨텍스트 제공
cat <<EOF
[자동 커밋 감지] 브랜치 '$CURRENT_BRANCH'에 커밋되지 않은 변경사항이 있습니다 (${TOTAL_FILES}개 파일).

Staged:
$(echo "$STAGED" | head -5)
$([ "$(echo "$STAGED" | wc -l)" -gt 5 ] && echo "  ... 외 더 있음")

Unstaged/Untracked:
$(echo -e "$UNSTAGED\n$UNTRACKED" | head -5)

중요한 작업 단계가 완료되었다면 /commit 스킬로 커밋하는 것을 권장합니다.
EOF

exit 0
