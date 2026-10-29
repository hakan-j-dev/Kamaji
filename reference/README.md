# reference

Kamaji 설계에 참고하는 외부 원본. 수정하지 않고 읽기 전용으로 둔다.

사본 폴더는 저장소에 올리지 않는다(`.gitignore`). 아래 출처와 커밋으로 같은 버전을 다시 받는다.

## pstack

- 출처: https://github.com/cursor/plugins/tree/main/pstack
- 커밋: `1ba91fc25c0977741dd0e267849e6234b037ed0a` (2026-10-28)
- 작성자: Lauren Tan (@poteto)
- 라이선스: MIT (`pstack/LICENSE`)

## open-pstack

pstack을 Claude Code와 Codex용으로 옮긴 커뮤니티 포팅판. 다중 모델 실행기, 모델 목록 한 곳 관리, 공통 스킬 폴더를 추가했다.

- 출처: https://github.com/ericlitman/open-pstack
- 커밋: `b4c5e3d63318308b7e11f26b2bc156e7793d834a` (2026-10-22)
- 기준 원본: pstack 0.15.29 (Cursor 커밋 `88d47514`)
- 라이선스: MIT (`open-pstack/LICENSE`, 포함된 외부 작업은 `LICENSE-*`)

## pstack-claude

pstack을 Claude Code, Codex, Copilot, Pi, OpenCode, Muse, Gemini 등으로 옮긴 포팅판. open-pstack의 기반이 된 프로젝트다.

- 출처: https://github.com/michael-denyer/pstack-claude
- 커밋: `190fc9a009491cbcfc04e25ef5b3c2d1fcf5ca8a` (2026-10-28), 버전 0.9.111
- 라이선스: MIT (`pstack-claude/LICENSE`, 포함된 외부 작업은 `LICENSE-*`)
