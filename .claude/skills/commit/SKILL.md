---
name: commit
description: Git staged 변경사항을 분석하여 Conventional Commits 형식의 한국어 커밋 메시지를 자동 생성하고 커밋합니다. 중요한 작업 완료 시점에 사용하세요.
argument-hint: [추가 컨텍스트]
disable-model-invocation: true
allowed-tools: Bash(git *), Read
---

# /commit — 자동 커밋 스킬

## 동작 순서

### 1단계: 현재 상태 파악

현재 브랜치와 변경사항을 확인합니다:

```
!`git status --short`
```

```
!`git diff --staged`
```

staged 변경사항이 없으면 먼저 `git add`를 안내하세요:
- 특정 파일: `git add <파일명>`
- 전체: `git add -A` (단, `.env`, 시크릿 파일 제외 확인 후)

### 2단계: 커밋 메시지 생성

`git diff --staged` 결과를 분석하여 아래 규칙에 맞는 **한국어 커밋 메시지**를 생성합니다.

#### Conventional Commits 규칙

형식: `type(scope): 한국어 설명`

| type | 사용 시점 |
|------|-----------|
| `feat` | 새로운 기능 추가 |
| `fix` | 버그 수정 |
| `docs` | 문서 변경 |
| `style` | 코드 포맷팅 (기능 변경 없음) |
| `refactor` | 리팩토링 (버그 수정/기능 추가 없음) |
| `perf` | 성능 개선 |
| `test` | 테스트 추가/수정 |
| `chore` | 빌드, 설정 파일 변경 |
| `ci` | CI/CD 설정 변경 |
| `build` | 빌드 시스템, 의존성 변경 |

#### 좋은 커밋 메시지 원칙
- 직관적이고 간결하게 **핵심**만 작성
- 무엇을 했는지가 아니라 **왜**, **무엇이 변경됐는지** 명확하게
- description은 2자 이상, 명령형으로 작성
- scope는 영향받는 모듈/기능명 (선택사항)

#### 예시
```
feat(auth): 소셜 로그인 기능 추가
fix(api): 토큰 만료 시 자동 갱신 오류 수정
refactor: 유저 서비스 의존성 분리
docs: API 엔드포인트 문서 보강
chore: ESLint 규칙 설정 업데이트
```

### 3단계: 커밋 실행

생성한 메시지로 커밋합니다. Co-Author는 Hook이 자동 삽입합니다:

```bash
git commit -m "type(scope): 한국어 설명"
```

멀티라인 커밋 메시지가 필요한 경우:
```bash
git commit -m "$(cat <<'EOF'
type(scope): 한국어 요약

- 세부 변경사항 1
- 세부 변경사항 2
EOF
)"
```

### 4단계: 확인

커밋 완료 후 결과를 보여줍니다:
```
!`git log --oneline -3`
```

## 주의사항
- `.env`, 비밀키, 패스워드가 포함된 파일은 절대 커밋하지 않습니다
- 커밋 전 테스트 Hook이 자동 실행되며, 실패 시 커밋이 차단됩니다
- 보호 브랜치(main, dev, develop)에서는 직접 커밋 대신 PR을 사용하세요
