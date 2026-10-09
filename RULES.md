# Archery — Official Rules

_The authoritative source of truth for this game's implementation. If the
implementation conflicts with this document, fix the implementation._

## 1. Objective
Score more total points than your opponent across a full match of 10 arrows
each. Every arrow is loosed at a classic target; rings score 1 (outer white)
through 10 (inner gold bullseye).

## 2. Setup
- 2 seats: Player 1 (human) and Player 2 (human pass-and-play or bot).
- Each seat shoots exactly 10 arrows.
- Seats alternate one arrow at a time (seat 0, seat 1, seat 0, …).
- Distance by arrow number: arrows 1–3 at 30m, 4–7 at 50m, 8–10 at 70m.
- A fresh random wind (-5..+5, negative pushes left) is rolled for every
  arrow.

## 3. Turn order
1. The engine grants the current seat the aim. The banner narrates whose
   turn it is.
2. A human drags the aim reticle anywhere (clamped to 1.15× target radius)
   and releases to loose the arrow.
3. A bot aims visibly: its reticle drifts from center to its final aim over
   ~1.1s with narration ("lining up…", "looses!") before the arrow flies.
4. The arrow flies (~0.62s) and the shot resolves.
5. After a short narration pause, the turn passes to the other seat.
6. The match ends when both seats have shot 10 arrows.

## 4. Legal moves
- Aim anywhere within the 1.15× target-radius clamp; release to loose.
- Aim INTO the wind to compensate: wind pushes the arrow sideways in flight.

## 5. Illegal moves
- Releasing while an arrow is already flying or the match is over (ignored).
- A bot's turn cannot be played by touch; touch input during a bot turn is
  ignored.
- Pausing mid-turn freezes the engine; no input is accepted while paused.

## 6. Captures
Not applicable — archery has no captures.

## 7. Special rules
- Wind drift: landing = aim + (wind × distance wind factor × drift
  constant) + small wobble. Stronger wind and longer distances drift more.
- Reticle clamp: aim cannot exceed 1.15× target radius.

## 8. Scoring
- Arrow lands outside the target face: 0 (miss).
- Arrow lands on the face: score = 10 − floor(distance from center in
  target-radius units × 10), clamped to 1–10.
- The inner gold (inner 10% radius) is the bullseye = 10 points.

## 9. Winning conditions
- After 10 arrows each, the higher total score wins.
- The winner is named on the victory screen with final scores.

## 10. Draw conditions
- Equal totals = a dead heat; no winner is declared, both scores shown.

## 11. AI strategy
The bot compensates for wind imperfectly, per difficulty:
- Easy: compensates 55% of wind drift, aim error up to ~0.42 radius units —
  playful, beatable.
- Medium: compensates 80%, error up to ~0.26 radius units.
- Hard: compensates 95%, error up to ~0.15 radius units — a genuine test.
Error grows slightly at longer distances for all difficulties.

## 12. Edge cases
- Pause during bot aim or flight: timers freeze; animations resume exactly
  where they stopped (startedAt shifted by paused duration).
- App backgrounded mid-turn: engine auto-pauses; the watchdog re-arms the
  current phase on resume — no stuck states.
- Restart mid-match: all state resets, a fresh wind is rolled, and the
  opening turn is granted.
- Tie: no win/lose sound; the dead-heat screen is shown.

## 13. Test cases
1. Full human-vs-bot match completes: 20 shots, scores tally, winner or
   dead heat declared.
2. Pass-and-play: both humans can aim and loose; bot turn is skipped.
3. Wind +5 at 70m with aim at center lands noticeably right of center.
4. Aiming into the wind compensates and can still hit gold.
5. Bot turn: reticle visibly drifts, narration plays, no silent auto-play.
6. Pause during flight, resume: arrow completes flight and resolves.
7. Release during flight is ignored (no double-loose).
8. Restart from the pause menu starts a fresh match.
9. Miss (0) does not break the turn order; next seat shoots.
10. Bullseye at 70m scores exactly 10.
