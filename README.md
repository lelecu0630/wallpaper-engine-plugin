# Wallpaper Engine Local MCP

Windows용 Wallpaper Engine 전용 로컬 MCP 플러그인. Node.js 20 이상과 ChatGPT 데스크톱 Work/Codex가 필요합니다.

## 한 번에 설치

전체 ZIP을 압축 해제하고 `INSTALL.cmd`를 실행하세요. Wallpaper Engine을 먼저 실행하면 설치 경로를 자동 탐색합니다. ChatGPT를 완전히 종료하고 새 Work 대화에서 플러그인을 선택하세요.

다른 경로는 `install.ps1 -WallpaperEnginePath <path> -WorkshopPath <path>`로 지정합니다. npm 의존성과 API 키는 없습니다.

## 포함 기능

- 다운로드된 배경 검색, project.json 읽기
- 배경 적용, 재생/정지/음소거, 기존 사용자 설정 변경
- 전용 창 캡처, UI Automation, 실험적 클릭/드래그/문자 입력
- NaN/Infinity 접근성 좌표 처리, Bitmap 정수 생성자 수정
- 작은 보조 창을 제외하는 진단기
- 요청한 편집 범위에서 반복 대화 확인을 줄이는 기본 지침

ChatGPT 자체 도구 승인 팝업은 별도입니다. 구독/업로드 도구는 제공하지 않습니다. 좌표 조작을 통한 모든 동작을 보안적으로 차단하는 샌드박스는 아닙니다.

## 확인된 범위와 제한

사용자 PC에서 532개 배경 조회, 선택 창 캡처, 설정 변경 및 복원 결과가 보고됐습니다. 편집기 일부 GPU 영역은 검게 캡처될 수 있습니다. 효과 추가/저장 전체 과정은 검증되지 않았습니다. 원본 대신 복사본을 사용하세요. submitted=true는 실제 반영 확인이 아닙니다.

로컬 stdio 전용이며 웹 ChatGPT에 넣는 원격 URL은 없습니다. 임의 셸 실행/전역 SendInput 도구는 없습니다. UI 도구는 대상 실행 파일 경로를 검사합니다. 사용자 배경/이미지/로그는 배포물에 포함하지 않습니다.

## 개발

`node --test test.mjs` / `node diagnose.mjs`

## 제거

ChatGPT 플러그인 화면에서 제거하거나 `codex plugin remove wallpaper-engine-local@wallpaper-local`을 사용하세요.

## 공식 문서

https://help.wallpaperengine.io/en/functionality/cli.html

https://developers.openai.com/plugins/build/plugins
