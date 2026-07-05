# BROTATO (working title)

브로타토 스타일 로그라이크 탑다운 서바이벌 슈터. Godot 4.x로 제작하고
GitHub Actions가 HTML5로 빌드해 **GitHub Pages**에 자동 배포합니다.

플레이 URL(배포 후): `https://<GitHub계정>.github.io/BROTATO/`

## 현재 구현 범위

- **캐릭터 선택 화면**(JAE AGAIN): 3인 중 선택 — 사진 + 능력 설명 + START
  - **다니엘**: 체력 +200%, 몸통 박치기(몹 접촉 시 넉백+데미지)
  - **쑤마왕**: 보스 데미지 +200%, 받는 데미지 50% 감소
  - **솔추**: 체력 +40%, 근접 시 창으로 자동 반격
- 플레이어 이동(WASD·방향키) + **자동 조준/자동 발사** (사진 스프라이트)
- 무기 2종: **카메라**(샷건, 다중 펠릿) · **시운이의 커터칼**(근접 광역)
- 적: 기본 몹(50%) · 탱커(25%) · 원거리 몹(25%, 2초마다 투사체) + 화면 가장자리 스폰
- 황금 고블린(3%): 이동 5배·데미지 없음·맵 배회, 7초 내 처치 못하면 도망, 골드 잭팟
- 웨이브 타이머 + 웨이브별 체력/스폰 스케일링, 웨이브 클리어 보너스 골드
- 브로타토 스타일 UI: 질감 바닥+비네트, 빨간 HP바, 코인 골드 표시, 중앙 WAVE/타이머
- 골드 드랍: 적이 코인을 떨구고 플레이어가 근접하면 자석처럼 흡수, 데미지 숫자 표시
- 게임오버 → R 재시작

> 아직 미구현(다음 단계): 상점·재굴림, 능력치 업그레이드, 나머지 무기, 보스(서영교·차현승), 투척무기, 사운드.

## 조작

| 키 | 동작 |
|---|---|
| WASD / 방향키 | 이동 |
| (자동) | 조준·발사 |
| R | 게임오버 후 재시작 |

## 로컬에서 실행하려면

1. [Godot 4.3](https://godotengine.org/download) 다운로드
2. Godot에서 이 폴더의 `project.godot` 열기
3. F5(실행)

## 배포 (GitHub Pages)

`main` 브랜치에 push하면 `.github/workflows/deploy.yml`이 자동으로:
1. `barichello/godot-ci` 컨테이너에서 HTML5 export
2. 결과물을 GitHub Pages에 배포

**최초 1회 설정:** GitHub 저장소 → Settings → Pages → *Build and deployment*
→ Source를 **GitHub Actions**로 지정해야 합니다.

## 프로젝트 구조

```
project.godot          # 엔진 설정 + GameState 오토로드 + 창 크기
export_presets.cfg     # Web(HTML5) export 프리셋 (CI가 사용)
scenes/
  character_select.tscn # 시작 화면 (메인 씬)
  game.tscn             # 게임플레이 씬 (main.gd)
assets/                 # 캐릭터·몹 사진 (PNG)
scripts/
  character_select.gd  # 캐릭터 선택 화면
  characters.gd        # 캐릭터 정의(능력/스탯) 단일 출처
  main.gd              # 게임 루프·웨이브·스폰·HUD
  game_state.gd        # 골드/경험치/웨이브/선택캐릭터 전역 상태 (오토로드)
  player.gd            # 이동 + 무기 장착 + 캐릭터 능력
  weapon.gd            # 자동조준 무기 베이스
  camera_weapon.gd     # 카메라(샷건)
  cutter_weapon.gd     # 시운이의 커터칼(근접)
  bullet.gd            # 투사체
  enemy.gd             # 적 (기본/탱커 공용)
.github/workflows/deploy.yml
```
