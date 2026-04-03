# Git Commit & PR Merge 워크플로우 — 최종 합의 문서

> 상태: **합의 완료** ✓  
> 적용 범위: 이 프로젝트만 (`.claude/` 디렉토리)  
> 기술 스택: 여러 언어 혼용

---

## 최종 확정 사항 요약

| # | 항목 | 결정 |
|---|------|------|
| Q1 | 커밋 메시지 언어 | **한국어** (직관적·간결하게 핵심 작성) |
| Q2 | Co-Author 추가 | **항상 추가** (모든 git commit에 Hook으로 자동 삽입) |
| Q3 | 테스트 명령어 | **설정 파일 관리** (`.claude/hooks/test-config.json`) |
| Q4 | Conventional Commits 규칙 | **기본만** (type: 한국어 description) |
| Q5 | PR 템플릿 섹션 | **기본 4섹션 + 컨텍스트 섹션** (프론트: Screenshot, 백엔드: Sequence/Architecture) |
| Q6 | 코드 리뷰 출력 위치 | **PR 코멘트** (`gh pr comment`) |
| Q7 | 머지 조건 | **셀프 머지** (리뷰어 없음, CI 없으면 로컬 테스트로 대체) |
| Q8 | 머지 방식 | **merge commit** |

### 추가 확정 사항 (인라인 코멘트 반영)

| 항목 | 결정 |
|------|------|
| 자동 커밋 시점 | **중요 지점마다 자동 커밋** — Stop Hook으로 작업 완료 시 자동 감지 후 커밋 |
| 브랜치 가드 | **작업 시작 시 브랜치 확인** — `main`, `dev`, `develop` 등 보호 브랜치에서 직접 작업 차단 |

---

## 1. Git 커밋 워크플로우

### 1-1. Hook: 브랜치 가드 (`SessionStart` / `PreToolUse`)

> 작업 시작 시 현재 브랜치가 보호 브랜치(`main`, `dev`, `develop`, `master`, `release/*`)인지 확인하고, 맞으면 작업용 브랜치 생성을 유도

- **트리거**: `SessionStart` 또는 파일 편집 전 `PreToolUse(Write/Edit)`
- **동작**: 보호 브랜치 감지 → 경고 + 새 브랜치 생성 제안
- **스크립트**: `.claude/hooks/branch-guard.sh`

### 1-2. Hook: Co-Author 자동 삽입 (`PreToolUse`)

> 모든 `git commit` 명령에 Co-Author 태그 자동 삽입

- **트리거**: `PreToolUse` + `Bash` matcher + `git commit *` 패턴
- **동작**: 명령어에 `--trailer` 옵션 추가 또는 `-m` 메시지에 Co-Author 라인 삽입
- **삽입 태그**:
  ```
  Co-Authored-By: Claude
  ```
- **스크립트**: `.claude/hooks/co-author-inject.sh`

### 1-3. Hook: Conventional Commits 검증 (`PreToolUse`)

> `git commit` 시 메시지 형식 검증 후 미통과 시 차단

- **형식**: `type(scope): 한국어 설명`
- **허용 type**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`
- **검증 규칙**: type 필수, description 한국어, 직관적·간결하게 핵심 작성
- **스크립트**: `.claude/hooks/validate-commit.sh`

### 1-4. Hook: 커밋 전 테스트 실행 (`PreToolUse`)

> `git commit` 전 자동으로 테스트 실행, 실패 시 커밋 차단

- **설정 파일**: `.claude/hooks/test-config.json`
  ```json
  {
    "testCommand": "npm test",
    "timeout": 120,
    "skipOnBranches": []
  }
  ```
- **프로젝트 자동 감지**: `package.json` → `npm test`, `pyproject.toml` → `pytest`, `Makefile` → `make test`
- **스크립트**: `.claude/hooks/pre-commit-test.sh`

### 1-5. Skill: `/commit`

> 수동 커밋 스킬 — staged 변경사항을 분석하여 Conventional Commits 형식의 한국어 커밋 메시지를 AI가 자동 생성 후 커밋

| 항목 | 내용 |
|------|------|
| **파일 위치** | `.claude/skills/commit/SKILL.md` |
| **호출 방식** | 수동 (`/commit`) — `disable-model-invocation: true` |
| **동작 흐름** | 1) `git diff --staged` 분석 → 2) 한국어 메시지 자동 생성 → 3) 형식 검증 → 4) 커밋 |

### 1-6. Hook: 자동 커밋 (`Stop`)

> 중요 작업 완료 시점(파일 저장, 기능 구현 완료 등)에 자동으로 커밋

- **트리거**: `Stop` Hook — Claude가 응답 완료 시 변경사항 감지
- **동작**: `git status` 확인 → staged/unstaged 변경사항 존재 시 자동 커밋 제안 또는 실행
- **조건**: 보호 브랜치가 아닌 경우에만 동작
- **스크립트**: `.claude/hooks/auto-commit.sh`

---

## 2. PR 머지 워크플로우

### 2-1. Skill: `/create-pr`

> PR 생성 스킬 — 커밋 히스토리와 diff를 분석하여 PR 템플릿 자동 작성 후 `gh pr create` 실행

| 항목 | 내용 |
|------|------|
| **파일 위치** | `.claude/skills/create-pr/SKILL.md` |
| **호출 방식** | 수동 (`/create-pr`) |
| **동작 흐름** | 1) 커밋 히스토리/diff 분석 → 2) PR 템플릿 생성 → 3) 코드 리뷰 에이전트 실행 → 4) `gh pr create` → 5) 리뷰 결과 PR 코멘트 |

#### PR 템플릿 구조

```markdown
## Summary
- 변경사항 요약 bullet points

## Changes
- 주요 변경 파일/기능 목록

## Test Plan
- [ ] 테스트 계획 체크리스트

## Notes
리뷰어 참고사항

## Screenshots (프론트엔드 변경 감지 시 자동 추가)
<!-- 스크린샷 또는 GIF 첨부 -->

## Architecture / Sequence (백엔드 변경 감지 시 자동 추가)
<!-- 시퀀스 다이어그램 또는 아키텍처 설명 -->
```

> **프론트/백엔드 감지 기준**: 파일 확장자 및 경로 (`.tsx`, `.vue`, `components/` → 프론트, `api/`, `service/`, `repository/` → 백엔드)

### 2-2. Agent: `code-reviewer`

> PR 생성 시 자동으로 코드 리뷰를 수행하고 `gh pr comment`로 결과를 PR에 코멘트

| 항목 | 내용 |
|------|------|
| **파일 위치** | `.claude/agents/code-reviewer.md` |
| **모델** | `sonnet` |
| **도구** | `Read`, `Glob`, `Grep`, `Bash(git diff *, gh *)` |
| **출력** | `gh pr comment` 로 PR 코멘트 자동 작성 |

#### 리뷰 체크 항목
- 보안 취약점 (OWASP Top 10, 하드코딩 시크릿)
- 코드 품질/가독성
- 성능 이슈
- 에러 핸들링 누락
- 테스트 커버리지 여부

### 2-3. Skill: `/merge-pr`

> PR 머지 스킬 — 체크리스트 확인 후 merge commit으로 머지, 후처리 자동화

| 항목 | 내용 |
|------|------|
| **파일 위치** | `.claude/skills/merge-pr/SKILL.md` |
| **호출 방식** | 수동 (`/merge-pr`) |
| **머지 방식** | `--merge` (merge commit) |
| **동작 흐름** | 1) 체크리스트 확인 → 2) merge commit → 3) 후처리 |

#### 머지 전 체크리스트
- [ ] 보호 브랜치(main/dev/develop)로 머지 확인
- [ ] CI 통과 여부 (`gh pr checks`) — CI 없으면 로컬 테스트로 대체
- [ ] 충돌 없음 확인
- [ ] 자기 자신 PR 확인 (셀프 머지 허용)

#### 머지 후 자동 정리
- 소스 브랜치 삭제 (`git branch -d`, `gh pr close --delete-branch`)
- 로컬 브랜치 정리 (`git fetch --prune`)
- main/dev 브랜치로 전환 및 pull

---

## 3. 최종 파일 구조

```
.claude/
├── settings.json                    # Hook 등록 (PreToolUse, Stop, SessionStart)
├── skills/
│   ├── commit/
│   │   └── SKILL.md                 # /commit — AI 커밋 메시지 생성
│   ├── create-pr/
│   │   └── SKILL.md                 # /create-pr — PR 자동 생성
│   └── merge-pr/
│       └── SKILL.md                 # /merge-pr — PR 머지 + 후처리
├── agents/
│   └── code-reviewer.md             # 코드 리뷰 에이전트
└── hooks/
    ├── test-config.json             # 테스트 명령어 설정
    ├── branch-guard.sh              # 보호 브랜치 작업 차단
    ├── co-author-inject.sh          # Co-Author 자동 삽입
    ├── validate-commit.sh           # Conventional Commits 검증
    ├── pre-commit-test.sh           # 커밋 전 테스트 실행
    └── auto-commit.sh               # 중요 시점 자동 커밋
```

---

## 4. 기술 제약사항 (Claude Code Docs 기반)

| 항목 | 내용 |
|------|------|
| Git Hook 이벤트 | 네이티브 없음 → `PreToolUse(Bash)` + command pattern으로 구현 |
| 커밋 차단 | exit code `2` + stderr 메시지 |
| 명령어 수정 | `updatedInput`으로 git 명령어 변형 가능 |
| Skill 수동 호출 | `disable-model-invocation: true` 설정 필수 |
| 동적 컨텍스트 | `!` + backtick으로 실행 결과 주입 (PR diff 등) |
