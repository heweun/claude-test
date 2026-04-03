---
name: merge-pr
description: PR 머지 전 체크리스트를 확인하고 merge commit 방식으로 머지한 뒤, 브랜치 정리 등 후처리를 자동으로 수행합니다.
argument-hint: [PR번호]
disable-model-invocation: true
allowed-tools: Bash(git *, gh *), Read
---

# /merge-pr — PR 머지 스킬

## 동작 순서

### 1단계: 머지할 PR 확인

PR 번호를 인자로 받거나, 현재 브랜치의 PR을 자동 감지합니다:

```
!`gh pr list --state open --json number,title,headRefName,baseRefName | head -20`
```

인자가 있으면: `$ARGUMENTS[0]` 번 PR을 머지합니다.
없으면: 현재 브랜치(`!`git rev-parse --abbrev-ref HEAD``)의 PR을 찾습니다.

PR 정보에서 `headRefName`(소스 브랜치)과 `baseRefName`(대상 브랜치)를 확인합니다.

### 2단계: 최신 베이스 브랜치 동기화 (핵심)

머지 전 반드시 베이스 브랜치(main 등)의 최신 상태를 받아옵니다:

```bash
git fetch origin
```

**소스 브랜치로 이동 후 베이스 브랜치를 merge해 충돌 여부를 직접 확인합니다:**

```bash
git checkout $SOURCE_BRANCH
git merge origin/$BASE_BRANCH --no-commit --no-ff
```

- 충돌 없음 → `git merge --abort` 후 다음 단계 진행
- 충돌 있음 → **즉시 중단하고 사용자에게 보고**:

```
⚠️ 충돌 감지: origin/main과 $SOURCE_BRANCH 사이에 충돌이 있습니다.

충돌 파일:
  - [충돌 파일 목록: git diff --name-only --diff-filter=U]

머지 전에 충돌을 해결해주세요:
  1. git merge origin/main
  2. 충돌 파일 직접 수정
  3. git add <파일>
  4. git commit -m "fix: main 최신화 충돌 해결"
  5. 다시 /merge-pr 실행
```

충돌이 있으면 여기서 중단합니다.

### 3단계: PR 상태 확인

```
!`gh pr view $PR_NUMBER --json title,state,isDraft`
```

- `state`가 `OPEN`인지 확인
- `isDraft`가 `false`인지 확인 (Draft PR은 머지 불가)

#### 체크리스트 출력

```
✅ origin/main 최신화 완료
✅ 충돌 없음 (로컬 merge 테스트 통과)
✅ PR 상태: OPEN (Draft 아님)
```

### 4단계: Merge Commit으로 머지

```bash
gh pr merge $PR_NUMBER --merge --delete-branch
```

- `--merge`: merge commit 방식 (squash/rebase 아님)
- `--delete-branch`: 머지 후 소스 브랜치 원격 삭제

### 5단계: 머지 후 정리

```bash
git checkout $BASE_BRANCH
git pull
git branch -d $SOURCE_BRANCH 2>/dev/null || true
git fetch --prune
```

### 6단계: 완료 보고

```
!`git log --oneline -5`
```

```
✅ PR #$PR_NUMBER 머지 완료
📦 브랜치 '$SOURCE_BRANCH' 삭제됨
🌿 현재 브랜치: $BASE_BRANCH (최신 상태)
```

## 주의사항
- 충돌이 있으면 사용자가 직접 해결 후 재실행해야 합니다
- CI가 있는 경우 통과 여부도 함께 확인하세요 (`gh pr checks $PR_NUMBER`)
- 보호 브랜치(main/dev/develop) 자체를 소스로 하는 PR은 머지하지 마세요
