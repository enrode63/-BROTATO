# BROTATO (working title)

브로타토 스타일 로그라이크 탑다운 서바이벌 슈터. Godot 4.x로 제작하고
GitHub Actions가 HTML5로 빌드해 **GitHub Pages**에 자동 배포합니다.

플레이 URL(배포 후): `https://<GitHub계정>.github.io/BROTATO/`

## 현재 구현 범위 (코어 루프 / MVP 1~4)

- 플레이어 이동(WASD·방향키) + **자동 조준/자동 발사**
- 무기 2종: **카메라**(샷건, 다중 펠릿) · **시운이의 커터칼**(근접 광역)
- 적 2종: 기본 몹 · 탱커 + 화면 가장자리 스폰
- 웨이브 타이머 + 웨이브별 체력/스폰 스케일링, 웨이브 클리어 보너스 골드
- HP/웨이브/타이머/골드 HUD, 게임오버 → R 재시작

> 아직 미구현(다음 단계): 상점·재굴림, 능력치 업그레이드, 나머지 무기·캐릭터·보스, 투척무기, 사운드.

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
scenes/main.tscn       # 메인 씬 (main.gd)
scripts/
  main.gd              # 게임 루프·웨이브·스폰·HUD
  game_state.gd        # 골드/경험치/웨이브 전역 상태 (오토로드)
  player.gd            # 이동 + 무기 장착
  weapon.gd            # 자동조준 무기 베이스
  camera_weapon.gd     # 카메라(샷건)
  cutter_weapon.gd     # 시운이의 커터칼(근접)
  bullet.gd            # 투사체
  enemy.gd             # 적 (기본/탱커 공용)
.github/workflows/deploy.yml
```
