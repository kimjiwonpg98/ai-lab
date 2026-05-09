# Popcat AI Notifier

Codex, Claude Code, Gemini CLI 같은 AI 작업 도구가 승인 요청을 보내거나 작업을 끝냈을 때 macOS에서 고양이 GIF와 소리로 알려주는 메뉴바 앱입니다.

## 파일

- `PopcatAI.dmg`: 설치용 macOS DMG 파일

## 설치

1. `PopcatAI.dmg`를 엽니다.
2. `PopcatAI` 앱을 `Applications` 폴더로 드래그합니다.
3. `Applications`에서 `PopcatAI`를 실행합니다.
4. 메뉴바 오른쪽 위의 고양이 아이콘을 확인합니다.

## 지원 방식

- Codex CLI: `notify` 설정과 hook 이벤트를 사용합니다.
- Claude Code: hook 이벤트를 사용합니다.
- Gemini CLI: hook 또는 로컬 패치 기반으로 이벤트를 전달합니다.
- Codex/Claude/ChatGPT 데스크톱 앱: macOS 알림센터에 알림을 남기는 경우에만 fallback으로 감지합니다.

ChatGPT 앱처럼 macOS 알림센터에 완료 알림을 남기지 않는 앱은 공식 hook이 없으면 안정적으로 감지하기 어렵습니다.

## 권한

데스크톱 앱 알림 감시 기능을 쓰려면 macOS 전체 디스크 접근 권한이 필요할 수 있습니다.

1. 메뉴바 고양이 아이콘을 클릭합니다.
2. `전체 디스크 접근 설정 열기`를 누릅니다.
3. `PopcatAI`를 허용합니다.

Codex CLI는 sandbox 안에서 로컬 HTTP 연결이 막혀도 `/private/tmp/popcat-ai-notifier/inbox` 파일 큐 fallback으로 이벤트를 전달합니다.

## 체크섬

```text
SHA-256: a46cbce00a35597326cd3bd65caa4b1612fedf35e8ab45d05f06dd016927b66a
```
