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

### 2단계: 머지 전 체크리스트 확인

아래 항목을 순서대로 확인합니다:

#### ① PR 상태 확인
```
!`gh pr view $PR_NUMBER --json title,state,baseRefName,headRefName,mergeable,isDraft`
```

- `state`가 `OPEN`인지 확인
- `isDraft`가 `false`인지 확인 (Draft PR은 머지 불가)
- `mergeable`이 `MERGEABLE`인지 확인 (충돌 없음)

#### ② CI 확인
```
!`gh pr checks $PR_NUMBER 2>/dev/null`
```

CI가 없거나 설정되지 않은 경우 → 로컬 테스트로 대체:
```
!`cat .claude/hooks/test-config.json 2>/dev/null`
```
테스트 명령어를 찾아 실행하고 통과 여부를 확인합니다.

#### ③ 충돌 확인
```
!`gh pr view $PR_NUMBER --json mergeable -q .mergeable`
```

`CONFLICTING`이면 충돌을 먼저 해결해야 합니다.

#### 체크리스트 결과 출력

```
✅ PR 상태: OPEN (Draft 아님)
✅ 충돌 없음
✅ CI 통과 / 로컬 테스트 통과
📋 리뷰어: 셀프 머지 (리뷰어 없음)
```

모든 항목 통과 시 머지를 진행합니다. 실패 항목이 있으면 사용자에게 보고하고 중단합니다.

### 3단계: Merge Commit으로 머지

```bash
gh pr merge $PR_NUMBER --merge --delete-branch
```

- `--merge`: merge commit 방식 (squash/rebase 아님)
- `--delete-branch`: 머지 후 소스 브랜치 자동 삭제

### 4단계: 머지 후 정리 작업

#### 로컬 브랜치 정리
```bash
git fetch --prune
git checkout main 2>/dev/null || git checkout dev 2>/dev/null || git checkout develop
git pull
```

#### 로컬에 남아있는 소스 브랜치 삭제
```bash
git branch -d $SOURCE_BRANCH 2>/dev/null || echo "로컬 브랜치가 이미 없거나 머지되지 않았습니다"
```

### 5단계: 완료 보고

```
!`git log --oneline -5`
```

머지 완료 요약을 출력합니다:
```
✅ PR #$PR_NUMBER 머지 완료
📦 브랜치 '$SOURCE_BRANCH' 삭제됨
🌿 현재 브랜치: main (최신 상태)
```

## 주의사항
- 이 스킬은 셀프 머지를 허용합니다 (리뷰어 승인 불필요)
- CI가 실패한 경우 로컬 테스트로 대체하지만, 가능하면 CI를 통과시킨 후 머지하세요
- 보호 브랜치(main/dev/develop) 자체를 소스로 하는 PR은 머지하지 마세요
