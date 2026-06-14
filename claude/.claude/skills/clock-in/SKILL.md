---
name: clock-in
description: Start the workday. Pull the journal, load yesterday's handoff context, surface open work, and create today's daily note. Use when the user says "clock-in", "출근", "오늘 시작", "어디까지 했지", or begins their first session of the day.
---

# clock-in

저널 경로: `~/vaults/journals`

목표: 아침에 "오늘 뭐 하지 / 어디까지 했지"를 기억에 의존하지 않고 즉시 복원한다.

## 절차

1. **오늘 날짜 확정** — `date +%F`를 Bash로 얻어라 (추측 금지). 변수 `TODAY`.
2. **동기화** — `cd ~/vaults/journals && git pull --rebase`. 충돌이 나면 멈추고 사용자에게 알린다.
3. **어제 인수인계 읽기** — `daily/` 에서 `TODAY` 이전 가장 최근 데일리노트를 찾아 **"Next Session Context"** 섹션을 읽는다. 이게 오늘의 착수점이다.
4. **미결 작업 훑기** — `notes/` 에서 frontmatter `status: open` 인 노트 제목을 모은다.
5. **오늘 데일리노트 생성** — `daily/<TODAY>.md` 가 없으면 `templates/daily.md` 를 복사해 `{{DATE}}` 를 `TODAY` 로 치환하고, "On deck" 에 3·4번에서 모은 항목을 채운다. 이미 있으면 건드리지 않는다.
6. **브리핑** — 사용자에게 3줄로: ① 어제 어디까지 했나 ② 오늘 할 일 후보 ③ 미결/주의. 그리고 "어디부터 시작할까?" 로 끝낸다.

커밋은 하지 않는다 (clock-out이 한다).
