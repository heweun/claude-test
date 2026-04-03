# Git Workflow with Claude Code

Claude Code의 Skill · Agent · Hook으로 자동화된 Git 커밋 & PR 워크플로우.

---

## 빠른 시작

```bash
# 기능 브랜치 생성 후 작업
git checkout -b feat/기능명

# 작업 완료 → AI가 커밋 메시지 작성
/commit

# PR 생성 → 코드 리뷰 자동 실행
/create-pr

# 체크리스트 확인 후 머지
/merge-pr
```

---

## 스킬 (Skill)

### `/commit`
staged 변경사항을 분석해 Conventional Commits 형식의 **한국어 커밋 메시지**를 자동 생성합니다.

```
feat(auth): 소셜 로그인 기능 추가
fix(api): 토큰 만료 시 자동 갱신 오류 수정
```

허용 type: `feat` `fix` `docs` `style` `refactor` `perf` `test` `chore` `ci` `build`

### `/create-pr`
브랜치를 원격에 push하고, 커밋 히스토리와 diff를 분석해 PR 템플릿을 작성한 뒤 `gh pr create`로 PR을 생성합니다.
PR 생성 후 `code-reviewer` 에이전트가 자동 실행되어 리뷰 결과를 PR 코멘트로 게시합니다.

| 변경 유형 | 자동 추가 섹션 |
|-----------|--------------|
| 프론트엔드 (`.tsx` `.vue` `components/` 등) | Screenshots |
| 백엔드 (`api/` `service/` `controller/` 등) | Architecture / Sequence |

### `/merge-pr`
머지 전 체크리스트를 확인하고 **merge commit** 방식으로 머지합니다.

체크 항목:
- PR 상태 (Open, Draft 아님)
- 충돌 없음
- CI 통과 — CI 없으면 로컬 테스트로 자동 대체

머지 완료 후 소스 브랜치 삭제 · 로컬 브랜치 정리 · main 동기화를 자동으로 수행합니다.

---

## 자동 동작 (Hook)

| 시점 | 동작 |
|------|------|
| 세션 시작 | `main` `dev` `develop` 등 보호 브랜치 감지 → 경고 |
| `git commit` 실행 | Conventional Commits 형식 검증 → 실패 시 차단 |
| `git commit` 실행 | 테스트 자동 실행 → 실패 시 차단 |
| `git commit` 실행 | `Co-Authored-By: Claude` 자동 삽입 |
| `git push --force` 실행 | 보호 브랜치 강제 push 차단 |
| Claude 응답 완료 | 미커밋 변경사항 감지 → `/commit` 유도 |

---

## 테스트 명령어 설정

`.claude/hooks/test-config.json`에서 프로젝트별 테스트 명령어를 지정합니다.
설정하지 않으면 `package.json` · `pyproject.toml` · `Makefile` 등을 자동 감지합니다.

```json
{
  "testCommand": "npm test",
  "timeout": 120
}
```

---

## 파일 구조

```
.claude/
├── settings.json              # Hook 등록
├── hooks/
│   ├── test-config.json       # 테스트 설정
│   ├── branch-guard.sh        # 보호 브랜치 차단
│   ├── co-author-inject.sh    # Co-Author 자동 삽입
│   ├── validate-commit.sh     # 커밋 메시지 검증
│   ├── pre-commit-test.sh     # 커밋 전 테스트
│   ├── validate-push.sh       # 강제 push 차단
│   └── auto-commit.sh         # 작업 완료 알림
├── skills/
│   ├── commit/SKILL.md
│   ├── create-pr/SKILL.md
│   └── merge-pr/SKILL.md
└── agents/
    └── code-reviewer.md
```

---

## 요구사항

- [Claude Code](https://claude.ai/code)
- [GitHub CLI (`gh`)](https://cli.github.com) — PR 기능 사용 시
- Git Bash — Windows 환경에서 Hook 실행 시
