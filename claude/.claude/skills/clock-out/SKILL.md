---
name: clock-out
description: End the workday. Write a session retro, finalize today's daily note with a summary and next-session handoff, then sync the journal (pull-commit-push). Use when the user says "clock-out", "퇴근", "오늘 마무리", "정리하자", or is wrapping up for the day.
---

# clock-out

저널 경로: `~/vaults/journals`

목표: 실수를 흘려보내지 않고 글로 남기고, 내일의 나에게 인수인계서를 남긴다.

## 절차

1. **오늘 날짜 확정** — `date +%F` (Bash). 변수 `TODAY`.
2. **오늘 한 일 파악** — 이번 세션 대화 맥락 + 만진 repo의 변경사항에서 오늘 한 일을 정리한다.
3. **회고 작성** — 회고가 필요한 작업마다 `retro/<TODAY>-<topic>.md` 를 `templates/retro.md` 로 생성한다. **반복 실수는 사람 실수 / AI 실수로 나눠서** 적는다. (이미 같은 주제 회고가 있으면 append.)
4. **데일리노트 마감** — `daily/<TODAY>.md` 의:
   - **Day Summary** — 오늘 실제로 한 일 요약.
   - **Next Session Context** — 내일 아침 이 블록만 읽으면 복원되도록: 착수 명령 / 필수 참조 파일 / 맥락·주의.
5. **검증 (선택)** — 코드·산출물 품질 확인이 필요하면 **자기검증하지 말고** OMC `code-reviewer` 또는 `verifier` 에이전트에 위임한다. (생성자 ≠ 평가자)
6. **도메인 지식 승격 (선택)** — 오늘 노트에서 오래 갈 도메인 사실이 보이면 `projects/<system>.md` 에 반영한다.
7. **동기화 (pull → commit → push)** — 다른 머신 변경을 먼저 합치고 사내 journals(origin)에 반영해 모든 머신을 일치시킨다. (멀티머신 동기화의 핵심)
   - `cd ~/vaults/journals && git pull --rebase` — 충돌 나면 멈추고 사용자에게 알린다.
   - `git add -A && git commit -m "journal: <TODAY>"` — 커밋할 변경이 없으면 생략.
   - `git push` — 실패하면 사용자에게 알린다 (remote가 origin에 push 권한·credential 있어야 함).
8. **요약 보고** — 무엇을 회고/마감/커밋했는지 사용자에게 3줄로.
