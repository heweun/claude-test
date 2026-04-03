#!/bin/bash
# auto-commit.sh
# Stop Hook: 작업 완료 후 커밋되지 않은 변경사항이 있으면 /commit 자동 실행 유도

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

# 무한 루프 방지: 60초 내 동일 브랜치에서 이미 트리거했으면 스킵
LOCK_FILE="/tmp/claude_autocommit_$(echo "$CURRENT_BRANCH" | tr '/' '_')"
NOW=$(date +%s)
if [ -f "$LOCK_FILE" ]; then
  LAST=$(cat "$LOCK_FILE" 2>/dev/null || echo 0)
  if [ $((NOW - LAST)) -lt 60 ]; then
    exit 0
  fi
fi
echo "$NOW" > "$LOCK_FILE"

# 변경 파일 수 계산
TOTAL_FILES=$(printf '%s\n' "$STAGED" "$UNSTAGED" "$UNTRACKED" | grep -c '\S' || true)

cat <<EOF
[자동 커밋] 브랜치 '$CURRENT_BRANCH'에 커밋되지 않은 변경사항이 있습니다 (${TOTAL_FILES}개 파일).

Staged: $(printf '%s\n' "$STAGED" | grep -c '\S' || echo 0)개
Unstaged/Untracked: $(printf '%s\n' "$UNSTAGED" "$UNTRACKED" | grep -c '\S' || echo 0)개

지금 바로 /commit 스킬을 실행해서 변경사항을 커밋하세요.
EOF

exit 2
