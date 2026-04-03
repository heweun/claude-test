---
name: commit
description: 변경사항을 작업 단위로 분석해 staged 파일을 그룹화하고, 각 그룹에 맞는 Conventional Commits 메시지로 커밋합니다.
argument-hint: [추가 컨텍스트]
disable-model-invocation: true
allowed-tools: Bash(git *), Read
---

# /commit — 작업 단위 커밋 스킬

## 동작 순서

### 1단계: 전체 변경사항 파악

```
!`git status --short`
```

staged / unstaged / untracked 파일을 모두 확인합니다.

### 2단계: 작업 단위 분석 및 스테이징 제안

변경된 파일 목록을 보고 **의미 있는 작업 단위**로 그룹을 나눕니다.

예시:
```
[그룹 1] feat(auth): 로그인 기능
  - src/auth/login.js
  - src/auth/token.js

[그룹 2] style(css): 버튼 스타일 정리
  - src/styles/button.css
```

그룹이 1개면 그냥 진행합니다.
그룹이 2개 이상이면 **첫 번째 그룹부터 순서대로** 커밋합니다.

staged 파일이 없으면 첫 번째 그룹의 파일을 add합니다:
```bash
git add <파일1> <파일2> ...
```

> `.env`, 비밀키, 패스워드가 포함된 파일은 절대 add하지 않습니다.

### 3단계: staged 변경사항 분석

```
!`git diff --staged`
```

diff를 분석하여 아래 규칙에 맞는 **한국어 커밋 메시지**를 생성합니다.

#### Conventional Commits 형식

`type(scope): 한국어 설명`

| type | 사용 시점 |
|------|-----------|
| `feat` | 새로운 기능 추가 |
| `fix` | 버그 수정 |
| `docs` | 문서 변경 |
| `style` | 코드 포맷팅 (기능 변경 없음) |
| `refactor` | 리팩토링 |
| `perf` | 성능 개선 |
| `test` | 테스트 추가/수정 |
| `chore` | 빌드, 설정 파일 변경 |
| `ci` | CI/CD 설정 변경 |
| `build` | 빌드 시스템, 의존성 변경 |

#### 좋은 커밋 메시지 원칙
- **무엇**을 했는지가 아니라 **왜**, **무엇이 변경됐는지** 명확하게
- description은 2자 이상, 명령형으로 작성
- scope는 영향받는 모듈/기능명 (선택사항)

#### 예시
```
feat(auth): 소셜 로그인 기능 추가
fix(api): 토큰 만료 시 자동 갱신 오류 수정
refactor: 유저 서비스 의존성 분리
```

### 4단계: 커밋 실행

```bash
git commit -m "type(scope): 한국어 설명"
```

멀티라인이 필요한 경우:
```bash
git commit -m "$(cat <<'EOF'
type(scope): 한국어 요약

- 세부 변경사항 1
- 세부 변경사항 2
EOF
)"
```

### 5단계: 남은 변경사항 안내

커밋 후 `git status --short`를 다시 확인합니다.

- 남은 변경사항이 있으면: 다음 그룹을 안내하고 `/commit`을 다시 실행하도록 유도합니다
- 모두 커밋됐으면: 전체 커밋 목록을 보여주고 종료합니다

```
!`git log --oneline -5`
```

## 주의사항
- 한 번에 모든 파일을 커밋하지 않습니다. 의미 있는 단위로 나눠서 커밋합니다
- 보호 브랜치(main, dev, develop)에서는 커밋 자체가 훅에 의해 차단됩니다
- Co-Author는 git 훅이 자동 삽입합니다 (prepare-commit-msg)
