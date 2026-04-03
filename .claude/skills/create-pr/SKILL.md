---
name: create-pr
description: 현재 브랜치의 커밋 히스토리와 diff를 분석하여 PR 템플릿을 자동 생성하고, 코드 리뷰 에이전트를 실행한 뒤 gh pr create로 PR을 생성합니다.
argument-hint: [base-branch]
disable-model-invocation: true
allowed-tools: Bash(git *, gh *), Read, Glob, Grep, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__javascript_tool
---

# /create-pr — PR 자동 생성 스킬

## 사전 조건 확인

```
!`git status --short`
```
```
!`git rev-parse --abbrev-ref HEAD`
```

- 커밋되지 않은 변경사항이 있으면 먼저 `/commit`으로 커밋하세요
- 보호 브랜치(main/dev/develop)에서는 실행하지 마세요

## 동작 순서

### 1단계: 원격 브랜치로 Push

로컬 브랜치를 원격에 올립니다:

```bash
git push -u origin HEAD
```

- 이미 push된 경우 최신 커밋만 추가 push됩니다
- push 실패(충돌 등) 시 중단하고 원인을 안내합니다

### 2단계: 변경사항 분석

base 브랜치를 결정합니다 (기본: `main`, 인자로 지정 가능):

```
!`git log --oneline main..HEAD 2>/dev/null || git log --oneline -10`
```
```
!`git diff main...HEAD --stat 2>/dev/null || git diff HEAD~1 --stat`
```
```
!`git diff main...HEAD -- . 2>/dev/null || git diff HEAD~1`
```

### 3단계: 변경 컨텍스트 감지

변경된 파일 경로를 분석하여 프론트엔드/백엔드를 자동 감지합니다:

**프론트엔드 감지 조건** (아래 중 하나 해당 시):
- `.tsx`, `.jsx`, `.vue`, `.svelte` 파일 포함
- `components/`, `pages/`, `views/`, `src/app/` 경로 포함
- `styles/`, `.css`, `.scss` 파일 포함

**백엔드 감지 조건** (아래 중 하나 해당 시):
- `api/`, `service/`, `controller/`, `repository/`, `handler/` 경로 포함
- `.java`, `.kt`, `.go`, `.py`, `.rb` 파일 포함 (단, 프론트엔드 파일 없을 때)

### 4단계: PR 템플릿 작성

분석 결과를 바탕으로 PR 본문을 작성합니다:

```markdown
## Summary
- [변경사항 핵심 요약, 1~3개 bullet]

## Changes
- [주요 변경 파일/기능 목록]

## Test Plan
- [ ] [테스트 항목 1]
- [ ] [테스트 항목 2]

## Notes
[리뷰어 참고사항, 특이한 구현 결정, 향후 개선 계획 등]

<!-- 백엔드 변경 감지 시 추가 -->
## Architecture / Sequence
<!-- 시퀀스 다이어그램 또는 아키텍처 변경사항 설명 -->
```

### 4.5단계: 프론트엔드 스크린샷 캡처 (프론트엔드 감지 시에만)

프론트엔드 파일이 변경된 경우, 브라우저 자동화로 실제 스크린샷을 캡처합니다:

1. `mcp__claude-in-chrome__tabs_context_mcp`로 현재 탭 확인
2. `mcp__claude-in-chrome__tabs_create_mcp`로 새 탭 생성
3. 변경된 HTML 파일 경로를 `file://` URL로 변환하여 `mcp__claude-in-chrome__navigate`로 열기
   - 예: `file:///C:/Users/804/Desktop/claude-test/dashboard.html`
4. `mcp__claude-in-chrome__computer`로 스크린샷 캡처
5. PR 본문 Screenshots 섹션에 아래 형식으로 삽입:

```markdown
## Screenshots
![After](캡처된_이미지_설명)
```

> 로컬 서버가 필요한 경우(React/Vue 등): `localhost` URL 사용. 서버가 없으면 `file://` 경로로 시도.
> 캡처 실패 시: Screenshots 섹션을 생략하고 PR 생성을 계속합니다.

### 5단계: 코드 리뷰 에이전트 실행

PR 생성 전 코드 리뷰 에이전트를 실행합니다 (결과는 PR 생성 후 코멘트로 자동 추가됨):

PR 번호를 먼저 생성한 뒤 리뷰 에이전트를 실행해야 하므로, 다음 순서로 진행합니다.

### 6단계: PR 생성

```bash
gh pr create \
  --title "type: 한국어 PR 제목" \
  --body "$(cat <<'EOF'
[위에서 작성한 PR 템플릿 내용]
EOF
)" \
  --base main
```

### 7단계: 코드 리뷰 코멘트 추가

PR이 생성되면 코드 리뷰 에이전트(`code-reviewer`)를 호출하여 리뷰 결과를 PR 코멘트로 작성합니다:

에이전트에게 다음을 전달하세요:
- PR 번호: `gh pr view --json number -q .number`
- 리뷰 후 `gh pr comment <PR번호> --body "..."` 로 결과 게시

### 8단계: 완료 확인

```
!`gh pr view --web 2>/dev/null || gh pr view`
```

## PR 제목 규칙
- Conventional Commits 형식: `type: 한국어 설명`
- 70자 이하로 간결하게
- 예: `feat: 소셜 로그인 기능 추가`, `fix: 결제 오류 수정`
