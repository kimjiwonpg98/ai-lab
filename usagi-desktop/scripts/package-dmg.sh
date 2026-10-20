#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/Usagi Desktop.app"
DMG="$PROJECT_DIR/dist/Usagi-Desktop-0.3.1-universal.dmg"
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/usagi-dmg.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
bash "$PROJECT_DIR/scripts/build.sh"
ditto "$APP_DIR" "$STAGING/Usagi Desktop.app"
ln -s /Applications "$STAGING/Applications"
cat > "$STAGING/설치 안내.txt" <<'TEXT'
Usagi Desktop 0.3.1

설치: Usagi Desktop.app을 Applications 폴더로 드래그하세요.
실행: Applications에서 Usagi Desktop을 실행하세요.
종료: 메뉴 막대의 토끼 아이콘 → 종료.

macOS 13 이상 / Apple Silicon 및 Intel Mac 지원.
우클릭 또는 메뉴 막대에서 캐릭터 선택, 마우스 따라가기, 크기, 춤 속도를 변경할 수 있습니다.

이 앱은 Apple 개발자 인증서로 서명하거나 공증하지 않은 개인 프로젝트입니다.
macOS가 실행을 차단하면 다운로드 출처를 확인한 뒤
시스템 설정 → 개인정보 보호 및 보안에서 '확인 없이 열기'를 선택할 수 있습니다.
보안 기능을 전역으로 끄지 마세요.

캐릭터와 영상의 권리는 각 권리자에게 있습니다.
소스 및 출처: https://github.com/kimjiwonpg98/ai-lab/tree/master/usagi-desktop
TEXT
hdiutil create -volname "Usagi Desktop" -srcfolder "$STAGING" \
  -format UDZO -ov "$DMG"
hdiutil verify "$DMG"
(cd "$PROJECT_DIR/dist" && shasum -a 256 "$(basename "$DMG")") > "$DMG.sha256"
printf 'DMG: %s\n' "$DMG"
