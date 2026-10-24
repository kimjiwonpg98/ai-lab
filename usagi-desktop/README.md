# 먼작귀 칭구들

Windows와 Mac에서 사용할 수 있는 데스크톱 캐릭터 앱입니다.
캐릭터 7종, 마우스 따라가기, 클릭 정지·재생, 드래그 이동, 크기·속도 조절을 지원합니다.

## 다운로드 및 설치 · v0.4.2

| 운영체제 | 다운로드 | 지원 환경 |
| --- | --- | --- |
| Windows | [EXE 다운로드](https://github.com/kimjiwonpg98/ai-lab/releases/download/friends-v0.4.2/Meonjakgwi-Friends.exe) | Windows 10/11 · x64 |
| Mac | [DMG 다운로드](https://github.com/kimjiwonpg98/ai-lab/releases/download/friends-v0.4.2/Meonjakgwi-Friends-0.4.2-universal.dmg) | macOS 13 이상 · Apple Silicon / Intel |

### Windows

1. `Meonjakgwi-Friends.exe`를 다운로드합니다.
2. 원하는 폴더에 두고 실행합니다. 별도 설치나 Python 설치는 필요 없습니다.
3. 캐릭터를 우클릭하거나 작업 표시줄 알림 영역의 앱 아이콘을 우클릭하면 메뉴가 열립니다.
   아이콘이 보이지 않으면 알림 영역의 숨겨진 아이콘 목록을 확인하세요.

아이콘을 더블클릭하면 캐릭터를 숨기거나 다시 표시합니다. 종료는 메뉴의 **종료**를 선택하세요.
업데이트할 때는 실행 중인 앱을 종료한 뒤 새 EXE로 교체합니다. 설정은 Windows 사용자별로 저장됩니다.
Windows 코드 서명이 없는 개인 배포 파일이므로 실행 시 보안 안내가 표시될 수 있습니다.

### Mac

1. DMG를 열고 `먼작귀 칭구들.app`을 `Applications` 폴더로 드래그합니다.
2. 응용 프로그램에서 앱을 실행합니다. 메뉴 막대에 🐰가 표시됩니다.
3. 캐릭터 우클릭 또는 메뉴 막대 🐰에서 설정을 변경합니다.

업데이트할 때는 기존 앱을 종료한 뒤 새 앱으로 교체하세요.
이전 이름의 `Usagi Desktop.app`이 남아 있다면 수동으로 삭제할 수 있습니다.
Apple 개발자 인증서 서명·공증이 없는 개인 프로젝트이므로 실행이 차단될 수 있습니다.
출처를 확인한 뒤 시스템 설정 → 개인정보 보호 및 보안 → 확인 없이 열기로 승인할 수 있습니다.

### 검증 범위

Windows에서는 자동 빌드, 캐릭터 이미지 로딩 및 패키징된 EXE 시작 검사를 통과했습니다.
Windows 실제 데스크톱에서의 수동 조작은 아직 검증하지 않았습니다.
Mac에서는 개발 머신의 렌더링과 DMG 무결성을 확인했습니다.
Intel 실기기와 macOS 13에서의 실행은 별도로 검증하지 않았습니다.

## 사용법

| 동작 | Windows | Mac |
| --- | --- | --- |
| 정지 / 재생 | 캐릭터 클릭 | 캐릭터 클릭 |
| 이동 | 캐릭터 드래그 | 캐릭터 드래그 |
| 설정 메뉴 | 캐릭터 또는 알림 영역 아이콘 우클릭 | 캐릭터 우클릭 / Control-클릭 또는 메뉴 막대 🐰 |
| 숨기기 / 다시 표시 | 알림 영역 메뉴 또는 아이콘 더블클릭 | 메뉴 막대 🐰 |
| 종료 | 우클릭 메뉴 → 종료 | 메뉴 막대 🐰 → 종료 |

메뉴에서 **캐릭터 선택**, **마우스 따라가기**, **크기**, **속도**를 변경할 수 있습니다.
마우스 따라가기는 기본으로 꺼져 있으며, 켜면 커서 옆으로 부드럽게 이동합니다.
캐릭터 위에 마우스를 올리거나 마우스 버튼을 누르는 동안, 메뉴를 열거나 숨긴 동안에는 따라가기를 멈춥니다.
**화면 구석으로 데려오기**를 선택하면 위치를 초기화하고 따라가기를 끕니다.
캐릭터 선택·위치·따라가기 설정은 같은 운영체제에서 재실행 후에도 유지됩니다.

선택할 수 있는 캐릭터는 **우사기춤 / 치어리더 우사기 / 모찌 먹는 랏코 / 울먹이는 치이카와 /
간식 먹는 치이카와 / 클로버 치이카와 / 춤추는 치이카와**입니다.
치어리더는 PNG 이미지에 움직임을 적용한 버전이며, 정지하면 대기 이미지로 바뀝니다.

기본 무음이며 실행 중 다운로드, 마이크, 화면 녹화, 접근성 권한을 사용하지 않습니다.
전체 화면 앱 위 표시 여부는 운영체제와 해당 앱의 창 동작에 따라 달라집니다.
로그인 시 자동 실행과 음악 연동은 아직 구현하지 않았습니다.
이미지 출처는 [Assets/SOURCES.md](Assets/SOURCES.md)에 기록했습니다.

## 소스 실행 및 빌드

저장소의 `usagi-desktop` 폴더에서 실행합니다.

### Windows · PowerShell

Python이 설치된 Windows에서 다음 명령으로 소스를 실행합니다.

```powershell
python -m pip install -r windows/requirements.txt
python windows/main.py
```

EXE 생성:

```powershell
./windows/build.ps1
```

결과는 `dist/Meonjakgwi-Friends.exe`입니다.
GitHub Actions의 `Friends Windows` 워크플로에서도 빌드 및 자동 실행 검사를 수행합니다.

### Mac · 터미널

Xcode Command Line Tools가 필요합니다.

```sh
bash scripts/build.sh
open "dist/먼작귀 칭구들.app"
```

설치용 DMG 생성: `bash scripts/package-dmg.sh`
아이콘 재생성: `bash scripts/make-icon.sh`
Apple Silicon·Intel 통합 빌드이며 로컬 임시 서명을 사용합니다.

## 변경 이력 및 영상 안내

v0.4.2: Windows EXE 지원 및 **춤추는 치이카와** 추가. 1080p 영상의 30~32초에서 추출한 60프레임입니다. 원본의 컷 전환과 크기 변화도 포함합니다.

v0.4.1: **클로버 치이카와** 추가. 지정한 6~9초 중 원경 이후 6.60~9.00초 구간을 사용하며, 1080p 원본에서 640×640 투명 프레임 72장으로 추출했습니다.

v0.4.0: 앱 이름을 **먼작귀 칭구들**로 변경하고, 지정한 나무위키 페이지의 대표 이미지를 앱 아이콘으로 적용했습니다.
**울먹이는 치이카와**, **간식 먹는 치이카와** 두 캐릭터를 1080p 영상에서 추출해 추가했습니다.
첫 장면은 컷 전환 이후 전신이 나오는 45.60~49.00초(102프레임), 두 번째는 55.00~57.00초(60프레임)입니다.
두 캐릭터 모두 512×512 투명 프레임이며 클릭 정지·재개, 크기·속도 조절, 마우스 따라가기를 지원합니다.
기존 앱은 종료한 뒤 새 이름의 앱을 설치하세요. 이전 `Usagi Desktop.app`은 수동으로 삭제할 수 있습니다.
캐릭터 선택·위치·마우스 따라가기 설정은 기존과 같은 저장 공간을 사용해 유지됩니다.

v0.3.1: **우사기춤** 이름 변경 및 1080p 원본 기반 고화질 프레임 적용.

v0.3.0: **모찌 먹는 랏코**를 캐릭터 선택에 추가했습니다.
사용자 지정 영상의 56.70~58.30초 구간에서 추출한 48프레임을 30fps로 반복합니다.
테이블에 가려진 하체는 복원하지 않고 상반신과 앞의 디저트를 함께 남겼습니다.
배경 제거 경계와 반복 구간 전환이 일부 보일 수 있습니다.
기존 마우스 따라가기, 크기·재생 속도 조절, 클릭 일시 정지를 동일하게 지원합니다.

Windows와 Mac 화면 위에서 움직이는 데스크톱 캐릭터 앱입니다.
사용자가 지정한 유튜브 영상의 13.00~13.80초 구간에서 우사기를 분리한
24장의 투명 PNG를 30fps로 반복 재생합니다. 실제 영상의 팔·몸·고개 움직임을 사용합니다.
클릭하면 현재 프레임에서 일시 정지하고, 다시 클릭하면 이어서 재생합니다.
음악은 포함하지 않으며 실행 중 다운로드는 없습니다.

우사기춤은 1544×1080 원본에서 495×540 투명 프레임으로 추출합니다.
기존 360p 추출본의 단순 확대가 아니라 1080p 원본 픽셀을 사용합니다.
크게 확대하면 경계가 거칠고, 일부 프레임에 작은 배경색 잔여물이 보일 수 있습니다.
우사기춤은 가림과 컷 전환이 없는 짧은 구간을 반복합니다. 춤추는 치이카와에는 원본 컷 전환과 일부 바닥 그림자가 남아 있습니다.

## 영상에서 다시 추출

`scripts/extract_dance.py`는 이 영상의 위치와 색상에 맞춘 전용 추출기입니다.
numpy, opencv-python-headless, pillow를 설치한 Python 환경에서 실행합니다.

```sh
python scripts/extract_dance.py /path/to/source.mp4
bash scripts/build.sh
```

`dance-contact.png`는 전체 프레임 검수용 이미지이며, `dance-preview.gif`는 동작 미리보기입니다.
랏코 추출: `python scripts/extract_rakko.py /path/to/rakko-video.mp4`
치이카와 추출: `python scripts/extract_chiikawa.py cry /path/to/first-video.mp4` 또는 `snack /path/to/second-video.mp4`.

## 미리보기 생성

```sh
"dist/먼작귀 칭구들.app/Contents/MacOS/UsagiDesktop" --preview /tmp/usagi-preview.png
```

클로버 장면 추출: `python scripts/extract_chiikawa.py clover /path/to/video.mp4`

춤추는 치이카와 추출: `python scripts/extract_chiikawa.py dance /path/to/video.mp4`
