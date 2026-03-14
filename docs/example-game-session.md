# Example Game Session: "The Baker Street Murder"

A complete walkthrough of one game session with 10 players, demonstrating all game mechanics, API calls, time tracking, scoring, and player interactions.

---

## Scenario Setup

**Crime:** The owner of "Golden Wheat Bakery", Viktor Morozov (age 52), is found dead in the bakery kitchen at 6:15 AM by the morning delivery driver. The bakery is located on Baker Street in the town center.

**In-game start time:** Day 1, 7:00 AM (detective receives the call).

---

## Players & Role Cards (10 Players)

| # | Player | Role | Card Details |
|---|--------|------|-------------|
| 1 | Alex | **Detective** | Starts at Police Department. Must solve the murder. Holds 1 card. |
| 2 | Maria | **Partner Detective** | Assists Alex. Holds 1 card. |
| 3 | Ivan | **Policeman** | Guards crime scene. Found the body after delivery driver reported it. Truthful. |
| 4 | Olena | **Coroner** | Performed autopsy. Truthful. |
| 5 | Dmitro | **Witness** (delivery driver) | Arrived at 6:15 AM, found the back door unlocked, saw the body. Truthful. |
| 6 | Katya | **Witness** (neighbor) | Lives above the bakery. Heard loud argument around 11 PM the night before. Truthful. |
| 7 | Sergiy | **Killer** (business partner) | Co-owns the bakery. Had a life insurance policy on Viktor. Was at the bakery at 10:30 PM "to discuss finances". Will lie about departure time. |
| 8 | Lina | **Accomplice** (Sergiy's wife) | Provides a false alibi — claims Sergiy was home by 10:00 PM. Cannot manipulate evidence. |
| 9 | Bohdan | **Resident** (shopkeeper next door) | Owns the hardware store. Saw Sergiy's car parked at the bakery at 11:15 PM. Neutral — will share if asked directly. Also holds a 2nd card: **Resident** (Viktor's ex-wife, Nadia) — bitter about divorce, claims Viktor had many enemies, misleading but not the killer. |
| 10 | Taras | **Resident** (bakery employee) | Works morning shifts. Had a dispute with Viktor over unpaid wages last week. Innocent but looks suspicious. Also holds a 2nd card: **Resident** (local barkeeper) — Viktor was a regular, was drinking alone the evening before the murder until ~9:30 PM. |

> **Note:** Players 9 and 10 each hold 2 role cards since we have 10 players but 12 roles to fill.

---

## Town Map & Locations

| Location | Type | Travel Time from PD |
|----------|------|-------------------|
| Police Department (PD) | POLICE_DEPARTMENT | 0 min |
| Golden Wheat Bakery | CRIME_SCENE | 10 min |
| Town Hospital / Morgue | HOSPITAL | 8 min |
| Sergiy's House | RESIDENCE | 15 min |
| Bohdan's Hardware Store | WORKPLACE | 12 min |
| Katya's Apartment (above bakery) | RESIDENCE | 10 min |
| Taras's Apartment | RESIDENCE | 20 min |
| Nadia's House (Viktor's ex-wife) | RESIDENCE | 18 min |
| The Old Barrel (bar) | SHOP | 7 min |
| Viktor's House | RESIDENCE | 14 min |

**Peak hour reminder:** +15 min to all travel during 7-9 AM, 1-2 PM, 6-7 PM.

---

## Full Game Walkthrough

### Step 1: Arrive at the Crime Scene

**In-game time: 7:00 AM (Day 1)** — Detective Alex receives the call at the Police Department.

**Travel:** PD → Golden Wheat Bakery = 10 min base + 15 min peak (7-9 AM) = **25 min**

```
POST /time/start
{
  "gameSessionId": "session-001",
  "playerId": "alex-001",
  "actionType": "TRAVEL",
  "details": { "from": "loc-pd", "to": "loc-bakery" }
}
→ Response: { "eventId": "te-001", "durationMinutes": 25, "arrivalTime": "07:25" }

POST /locations/player-location
{ "playerId": "alex-001", "locationId": "loc-bakery", "gameSessionId": "session-001" }
```

Maria (partner) travels with Alex — same time cost, single trip.

**Arrives: 7:25 AM**

---

### Step 2: Gather Initial Information (Question Policeman Ivan)

**In-game time: 7:25 AM**

Alex questions Ivan (Policeman) at the crime scene. Ivan is truthful.

**Ivan's testimony:**
> "I arrived at 6:30 AM after the delivery driver called it in. The victim is Viktor Morozov, 52, owner of this bakery. Body is in the kitchen near the ovens. Back door was unlocked — no signs of forced entry. The cash register was untouched. This doesn't look like a robbery."

```
POST /cases/case-001/testimonies
{
  "witnessPlayerId": "ivan-003",
  "content": "Arrived 6:30 AM. Victim Viktor Morozov found in kitchen. Back door unlocked, no forced entry. Cash register untouched — not a robbery.",
  "isTruthful": true
}
```

**Time cost:** 10 minutes (questioning)
**Current time: 7:35 AM**

---

### Step 3: Consult the Coroner

Alex calls Olena (Coroner) to request autopsy results. Olena is at the hospital.

**Option A:** Travel to hospital. But Alex decides to **call** instead (verification tool — free action, costs 5 min of in-game time).

**Olena's report:**
> "Cause of death: blunt force trauma to the back of the head. Consistent with a heavy cylindrical object. Time of death: approximately 10:30 PM – 11:30 PM last night. No defensive wounds — the victim was struck from behind. Blood alcohol level: 0.04% — he had been drinking, but was not heavily intoxicated."

```
POST /police/reports
{
  "caseId": "case-001",
  "victimName": "Viktor Morozov",
  "causeOfDeath": "Blunt force trauma to the back of the head",
  "timeOfDeath": "22:30-23:30 (previous day)",
  "injuries": "Single impact wound to occipital region, no defensive wounds",
  "toxicology": "BAC 0.04%",
  "additionalNotes": "Weapon consistent with heavy cylindrical object"
}
```

**Time cost:** 5 minutes
**Current time: 7:40 AM**

---

### Step 4: Search for Evidence

Alex and Maria search the bakery crime scene.

**Evidence found:**

1. **Rolling pin with blood** — found behind the flour sacks, partially wiped.
2. **Financial documents** — spread across the office desk, showing bakery was in serious debt. A life insurance document names Sergiy as beneficiary.
3. **Two coffee cups** — on the kitchen table. Viktor had a guest.
4. **Muddy boot prints** — near the back door, size 44 (men's).

```
POST /cases/case-001/evidence
{ "type": "PHYSICAL", "description": "Wooden rolling pin with blood residue, found behind flour sacks, partially wiped clean", "locationFound": "loc-bakery", "foundByPlayerId": "alex-001" }

POST /cases/case-001/evidence
{ "type": "DOCUMENT", "description": "Financial documents showing bakery debt of 850,000 UAH. Life insurance policy: 2,000,000 UAH, beneficiary: Sergiy Koval", "locationFound": "loc-bakery", "foundByPlayerId": "alex-001" }

POST /cases/case-001/evidence
{ "type": "PHYSICAL", "description": "Two used coffee cups on kitchen table — victim had a visitor", "locationFound": "loc-bakery", "foundByPlayerId": "maria-002" }

POST /cases/case-001/evidence
{ "type": "PHYSICAL", "description": "Muddy boot prints near back door, size 44 men's", "locationFound": "loc-bakery", "foundByPlayerId": "maria-002" }
```

**Time cost:** 30 minutes (thorough search)
**Current time: 8:10 AM**

---

### Step 5: Interview Witnesses

#### Witness 1: Dmitro (delivery driver) — at crime scene

**Dmitro's testimony (truthful):**
> "I arrive every morning at 6:15 to deliver flour. The back door is usually locked — Viktor opens it for me. Today it was already open. I walked in and found him on the floor. I didn't touch anything. I called the police right away."

```
POST /cases/case-001/testimonies
{
  "witnessPlayerId": "dmitro-005",
  "content": "Arrived 6:15 AM for flour delivery. Back door was unusually unlocked. Found victim on kitchen floor. Did not touch anything. Called police immediately.",
  "isTruthful": true
}
```

**Time cost:** 10 minutes
**Current time: 8:20 AM** (still peak hour)

#### Witness 2: Katya (neighbor above bakery) — at her apartment

Katya's apartment is above the bakery — same location, no travel needed.

**Katya's testimony (truthful):**
> "I heard a loud argument downstairs around 11 PM. Two male voices. I couldn't make out words but one was definitely Viktor — I know his voice. The other voice was deeper. Then I heard a loud thud and it went quiet. I thought they just knocked something over. I didn't call anyone."

```
POST /cases/case-001/testimonies
{
  "witnessPlayerId": "katya-006",
  "content": "Heard loud argument downstairs ~11 PM. Two male voices — one was Viktor. Heard a loud thud, then silence. Did not report it.",
  "isTruthful": true
}
```

**Time cost:** 10 minutes
**Current time: 8:30 AM**

---

**Detective's notes at this point:**

```
POST /cases/case-001/notes
{
  "detectivePlayerId": "alex-001",
  "content": "Victim killed between 10:30-11:30 PM, blunt force from behind. Had a visitor (2 cups). Argument heard at 11 PM. Bakery in debt. Life insurance beneficiary: Sergiy Koval (business partner) — PRIME SUSPECT. Also need to check: boot prints size 44, rolling pin as weapon, who was Viktor meeting?"
}
```

---

### Step 6: Identify Suspects

Based on evidence gathered, Alex identifies suspects:

1. **Sergiy Koval** — business partner, life insurance beneficiary, financial motive
2. **Taras** — bakery employee, recent wage dispute (could be anger motive)
3. **Nadia** — Viktor's ex-wife (bitter divorce — possible motive)

Alex queries the police database:

```
GET /police/criminal-records?query=Sergiy Koval
→ Response: { "results": [{ "suspectName": "Sergiy Koval", "records": [] }] }  // clean record

GET /police/criminal-records?query=Taras Bondar
→ Response: { "results": [{ "suspectName": "Taras Bondar", "records": [{ "offense": "Disorderly conduct", "date": "2024-03-15", "outcome": "Fine paid" }] }] }
```

**Time cost:** 15 minutes
**Current time: 8:45 AM**

---

### Step 7: Interrogate Suspects

Alex now needs to question all three suspects. Here's where **officer deployment** and **strategic planning** matter.

#### Deploy Officer 1 to fetch Sergiy

```
POST /players/alex-001/action
{
  "actionType": "DEPLOY_OFFICER",
  "description": "Send Officer 1 to bring Sergiy Koval from his house to PD",
  "targetPlayerId": "sergiy-007"
}
```

Travel: PD → Sergiy's house (15 min) + return with suspect (15 min) = **30 min**.
But it's 8:45 AM — still peak hour until 9:00 AM.
First leg: 15 + 15 peak = 30 min (departs crime scene, but officer goes from PD).
Actually officer is dispatched from detective's current location (bakery).
Bakery → Sergiy's house = ~12 min + peak 15 = 27 min, then return 27 min = **54 min total**.

Let's simplify: Officer dispatched. **Sergiy arrives at PD at approximately 9:40 AM.**

**Officer 1 status: DEPLOYED (unavailable until ~9:40 AM)**

#### Deploy Officer 2 to fetch Taras

```
POST /players/alex-001/action
{
  "actionType": "DEPLOY_OFFICER",
  "description": "Send Officer 2 to bring Taras Bondar from his apartment to PD",
  "targetPlayerId": "taras-010"
}
```

Bakery → Taras's apartment (20 min base, peak applies until 9:00) → complicated. **Taras arrives at PD at approximately 10:05 AM.**

**Officer 2 status: DEPLOYED**

#### Meanwhile: Alex travels to PD to wait, or investigates further

Alex decides to visit Bohdan's hardware store on the way back to PD to gather more info while officers are working.

**Travel:** Bakery → Bohdan's Hardware Store = 5 min (adjacent, 8:50 AM, peak still active → 5 + 15 = 20 min).

**Arrives at hardware store: 9:05 AM** (peak hour ended at 9:00)

#### Interview Bohdan (shopkeeper — neutral resident)

**Bohdan's testimony:**
> "I close the shop at 9 PM. But I came back around 11 PM because I forgot my phone. I saw Sergiy's car — the blue Volkswagen — still parked outside the bakery. The lights were on inside. I thought it was strange since the bakery closes at 8 PM."

```
POST /cases/case-001/testimonies
{
  "witnessPlayerId": "bohdan-009",
  "content": "Returned to shop at ~11 PM. Saw Sergiy Koval's blue Volkswagen parked outside bakery. Bakery lights were on. Unusual since bakery closes at 8 PM.",
  "isTruthful": true
}
```

**Time cost:** 10 minutes
**Current time: 9:15 AM**

This is critical — places Sergiy at the bakery at 11 PM, within the time-of-death window.

---

#### Alex draws a Hint Card

```
POST /cases/case-001/hints
{ "detectivePlayerId": "alex-001" }
→ Response: {
    "hintId": "hint-001",
    "content": "Anonymous tip: 'Check the size of Sergiy Koval's boots.'",
    "isTruthful": true   // hidden from detective
  }
```

Interesting — connects to the size 44 boot prints at the scene.

---

#### Travel to Police Department for interrogations

**Travel:** Hardware Store → PD = 12 min base (no peak, it's 9:15 AM) = **12 min**

**Arrives at PD: 9:27 AM**

---

#### Interrogation 1: Sergiy Koval (KILLER — will lie)

Sergiy arrives at PD around 9:40 AM. Alex interrogates him.

**Sergiy's statements (lies marked):**
> "Viktor and I are business partners. Yes, I was at the bakery last night — I stopped by around 10:30 PM to drop off some paperwork. Viktor was alive and well when I left. **I left at 10:45 PM.** _(LIE — he stayed until after 11 PM)_ We had coffee and talked about the business. Everything was fine between us."

When asked about the life insurance:
> "That's standard business practice. We both had policies on each other. It means nothing."

When asked about boot size:
> "I wear size 43." _(LIE — he wears size 44)_

When asked about the argument:
> "There was no argument. We talked calmly. **Your witness must have heard the TV.** _(LIE)_"

```
POST /cases/case-001/testimonies
{
  "witnessPlayerId": "sergiy-007",
  "content": "Was at bakery 10:30-10:45 PM to drop off paperwork. Had coffee with Viktor. Left at 10:45 PM. Relationship was fine. Boot size 43. No argument — witness may have heard TV.",
  "isTruthful": false
}
```

**Time cost:** 20 minutes
**Current time: 10:00 AM**

---

#### Interrogation 2: Taras Bondar (innocent employee)

Taras arrives ~10:05 AM.

**Taras's statements (truthful — he's a Resident, not opposing):**
> "Yes, I had an argument with Viktor last week about my wages. He owed me for two weeks. But we sorted it out on Friday — he paid me. I was home all evening last night. I live alone so no one can confirm. I went to bed around 10 PM."

When asked about boot size:
> "I wear size 42."

```
POST /cases/case-001/testimonies
{
  "witnessPlayerId": "taras-010",
  "content": "Had wage dispute with Viktor, resolved last Friday. Was home alone all evening. Went to bed ~10 PM. Boot size 42.",
  "isTruthful": true
}
```

**Time cost:** 15 minutes
**Current time: 10:15 AM**

---

### Step 8: Verify Testimonies

Now Alex needs to verify the conflicting accounts.

#### Verify 1: Check security footage at Bohdan's Hardware Store

The hardware store has a security camera facing the street (and the bakery entrance).

```
GET /police/security-footage?locationId=loc-hardware-store&timeStart=22:00&timeEnd=23:59
→ Response: {
    "footage": [{
      "footageId": "ft-001",
      "locationId": "loc-hardware-store",
      "timestampStart": "22:00",
      "timestampEnd": "23:59",
      "personsVisible": ["Sergiy Koval"],
      "relevantEvents": [
        "22:28 — Sergiy Koval's blue VW arrives, parks in front of bakery",
        "22:30 — Sergiy enters bakery through front door",
        "23:12 — Bakery lights turn off",
        "23:14 — Sergiy exits through front door, walks to car",
        "23:15 — Sergiy drives away"
      ]
    }]
  }
```

**This is devastating for Sergiy.** He claimed he left at 10:45 PM. The footage shows him leaving at **11:14 PM** — right in the middle of the time-of-death window, and matches the argument heard at 11 PM.

```
POST /cases/case-001/evidence
{
  "type": "DIGITAL",
  "description": "Security footage from hardware store: Sergiy arrived at bakery 10:28 PM, entered at 10:30 PM, left at 11:14 PM. Contradicts his claim of leaving at 10:45 PM.",
  "locationFound": "loc-hardware-store",
  "foundByPlayerId": "alex-001"
}
```

**Time cost:** 10 minutes (phone call to retrieve footage)
**Current time: 10:25 AM**

#### Verify 2: Check Sergiy's alibi with his wife Lina (ACCOMPLICE)

Alex calls Lina.

**Lina's statement (lie — she's the accomplice):**
> "Sergiy came home at 10:50 PM. I remember because I was watching the news. He was with me the rest of the night."

_(This contradicts the security footage which shows Sergiy leaving the bakery at 11:14 PM. He couldn't have been home at 10:50 PM.)_

```
POST /cases/case-001/testimonies
{
  "witnessPlayerId": "lina-008",
  "content": "Sergiy arrived home at 10:50 PM. Was watching news when he came in. He stayed home the rest of the night.",
  "isTruthful": false
}
```

**Time cost:** 5 minutes
**Current time: 10:30 AM**

#### Verify 3: Check The Old Barrel (bar) for Viktor's evening

Alex calls the barkeeper (Taras's 2nd card).

**Barkeeper's statement (truthful):**
> "Viktor was here last night. He arrived around 8 PM, had two beers. He seemed worried — kept checking his phone. He left around 9:30 PM. He mentioned he had a 'meeting' but didn't say with whom."

```
POST /cases/case-001/testimonies
{
  "witnessPlayerId": "taras-010-card2",
  "content": "Viktor was at The Old Barrel 8:00-9:30 PM. Had two beers. Seemed worried, checking phone. Left saying he had a 'meeting'.",
  "isTruthful": true
}
```

**Time cost:** 5 minutes
**Current time: 10:35 AM**

#### Verify 4: Interview Nadia, Viktor's ex-wife

Alex dispatches Officer 1 (now free) to bring Nadia to PD.

Travel time: PD → Nadia's house (18 min) + return (18 min) = **36 min**. Nadia arrives ~11:11 AM.

**Nadia's statement (misleading but not lying about the murder):**
> "Viktor was a terrible man. He had enemies everywhere — owed money to people, cheated on me. I wouldn't be surprised if half the town wanted him dead. Have you looked at that employee of his? The one who was always angry?"

_(Nadia tries to point blame at Taras — she's a misleading resident, not involved in the murder.)_

```
POST /cases/case-001/testimonies
{
  "witnessPlayerId": "bohdan-009-card2",
  "content": "Viktor had many enemies. Owed money. Suggests investigating bakery employee Taras. Bitter about divorce.",
  "isTruthful": true  // technically truthful but misleading in implication
}
```

**Time cost:** 15 minutes
**Current time: 11:26 AM**

#### Verify 5: Confirm Sergiy's boot size

Alex sends Officer 2 to Sergiy's house with a search authorization to check boots.

Travel time: PD → Sergiy's house (15 min) + search + return (15 min) = **~40 min**.

Officer 2 reports back: **Found boots size 44 in the hallway. Mud on the soles matches the type near the bakery's back alley.**

```
POST /cases/case-001/evidence
{
  "type": "PHYSICAL",
  "description": "Sergiy Koval's boots found at his home: size 44 (he claimed 43). Mud on soles consistent with bakery back alley.",
  "locationFound": "loc-sergiy-house",
  "foundByPlayerId": "alex-001"
}
```

**Current time: ~12:06 PM**

---

### Step 9: Reconstruct the Timeline

```
POST /cases/case-001/notes
{
  "detectivePlayerId": "alex-001",
  "content": "RECONSTRUCTED TIMELINE:\n- 8:00 PM: Viktor at The Old Barrel, drinking, seems worried\n- 9:30 PM: Viktor leaves bar, mentions a 'meeting'\n- ~10:00 PM: Viktor arrives at bakery (home? or went directly?)\n- 10:28 PM: Sergiy's car arrives at bakery (security footage)\n- 10:30 PM: Sergiy enters bakery. They have coffee (2 cups found)\n- ~10:30-11:00 PM: Discussion about finances/debt escalates\n- ~11:00 PM: Loud argument heard by neighbor Katya\n- ~11:00-11:05 PM: Sergiy strikes Viktor from behind with rolling pin\n- 11:12 PM: Bakery lights turned off (footage)\n- 11:14 PM: Sergiy exits, drives away (footage)\n- Sergiy lied about leaving at 10:45 PM\n- Sergiy lied about boot size (44, not 43)\n- Wife Lina lied about him being home at 10:50 PM (he was still at bakery)\n- MOTIVE: Life insurance policy of 2,000,000 UAH + bakery debt of 850,000 UAH"
}
```

---

### Step 10: Final Review

Alex reviews all findings with partner Maria.

**Evidence summary:**
1. Rolling pin (weapon) — blunt force matches coroner report
2. Financial documents — bakery in debt, life insurance on Viktor with Sergiy as beneficiary
3. Two coffee cups — Viktor had a visitor
4. Boot prints size 44 — match Sergiy's actual boot size (he lied about size 43)
5. Security footage — Sergiy present 10:28 PM – 11:14 PM (he lied about 10:45 PM departure)
6. Mud on Sergiy's boots — matches crime scene back alley
7. Lina's alibi for Sergiy disproven by security footage timestamps

**Witness corroboration:**
- Katya heard argument at 11 PM (2 male voices) — matches timeline
- Bohdan saw Sergiy's car at 11 PM — matches footage
- Barkeeper confirms Viktor had a "meeting" — with Sergiy

**Time cost:** 15 minutes
**Current time: ~12:21 PM**

---

### Step 11: Make a Verdict

```
POST /cases/case-001/verdict
{
  "detectivePlayerId": "alex-001",
  "accusedPlayerId": "sergiy-007",
  "reasoning": "Sergiy Koval killed Viktor Morozov at approximately 11 PM using a rolling pin. Motive: 2M UAH life insurance + bakery debt. Sergiy lied about departure time, boot size, and the argument. Security footage and physical evidence confirm presence at time of death. Wife Lina provided false alibi."
}
→ Response: {
    "isCorrect": true,
    "message": "Correct! Sergiy Koval is the killer.",
    "caseStatus": "SOLVED"
  }
```

---

## Scoring Breakdown

```
GET /points/alex-001?sessionId=session-001
→ Response: {
    "playerId": "alex-001",
    "totalPoints": 850,
    "breakdown": {
      "correctAccusation": 500,
      "timeBonus": 200,
      "dayBonus": 150,
      "falseleadPenalty": 0,
      "wrongAccusationPenalty": 0
    },
    "details": {
      "solvedInDays": 1,
      "totalInGameTime": "5 hours 21 minutes",
      "wrongAccusations": 0,
      "falseLeadsFollowed": 0
    }
  }
```

| Scoring Category | Points | Notes |
|-----------------|--------|-------|
| Correct accusation | +500 | Identified the killer correctly |
| Time bonus | +200 | Solved in ~5.5 hours of in-game time (fast) |
| 3-day bonus | +150 | Solved on Day 1 (well within the 3-day limit) |
| False leads | 0 | Did not pursue Taras despite Nadia's misdirection |
| Wrong accusations | 0 | No incorrect verdicts submitted |
| **Total** | **850** | |

---

## Win/Loss Results

| Player | Role | Result | Reason |
|--------|------|--------|--------|
| Alex | Detective | **WIN** | Correctly identified the killer |
| Maria | Partner Detective | **WIN** | Case solved correctly |
| Ivan | Policeman | **WIN** | Case solved correctly (supporting role) |
| Olena | Coroner | **WIN** | Case solved correctly (supporting role) |
| Dmitro | Witness | **WIN** | Case solved correctly (supporting role) |
| Katya | Witness | **WIN** | Case solved correctly (supporting role) |
| Sergiy | **Killer** | **LOSS** | Detective identified him correctly |
| Lina | **Accomplice** | **LOSS** | Failed to mislead the detective (false alibi was disproven) |
| Bohdan | Resident (×2) | **WIN** | Case solved correctly |
| Taras | Resident (×2) | **WIN** | Case solved correctly |

**Final score: Detective 850 / 1000 possible points.**

---

## Time Log Summary

| Time | Action | Duration | Peak? |
|------|--------|----------|-------|
| 7:00 AM | Travel: PD → Bakery | 25 min | Yes (+15) |
| 7:25 AM | Question Policeman Ivan | 10 min | — |
| 7:35 AM | Call Coroner Olena | 5 min | — |
| 7:40 AM | Search crime scene | 30 min | — |
| 8:10 AM | Interview Dmitro (at scene) | 10 min | — |
| 8:20 AM | Interview Katya (above bakery) | 10 min | — |
| 8:30 AM | Deploy Officers 1 & 2 | 0 min | — |
| 8:30 AM | Write detective notes | 5 min | — |
| 8:35 AM | Query police database | 15 min | — |
| 8:50 AM | Travel: Bakery → Hardware Store | 20 min | Yes (+15) |
| 9:05 AM | Interview Bohdan | 10 min | — |
| 9:15 AM | Draw hint card | 0 min | — |
| 9:15 AM | Travel: Hardware Store → PD | 12 min | No |
| 9:40 AM | Interrogate Sergiy | 20 min | — |
| 10:05 AM | Interrogate Taras | 15 min | — |
| 10:20 AM | Verify: security footage | 10 min | — |
| 10:30 AM | Verify: call Lina | 5 min | — |
| 10:35 AM | Verify: call barkeeper | 5 min | — |
| 10:40 AM | Dispatch Officer to fetch Nadia | 0 min | — |
| 11:11 AM | Interrogate Nadia | 15 min | — |
| 11:26 AM | Dispatch Officer for boot search | 0 min | — |
| 12:06 PM | Receive boot evidence | 0 min | — |
| 12:06 PM | Reconstruct timeline | 15 min | — |
| 12:21 PM | Final review with Maria | 15 min | — |
| 12:36 PM | Submit verdict | — | — |
| | **Total in-game time** | **~5h 36m** | |

---

## API Calls Summary (by service)

| Service | Calls | Examples |
|---------|-------|---------|
| Case Service | 15 | Create evidence (5), add testimonies (8), add notes (2) |
| Player Service | 4 | Deploy officers (2), log actions (2) |
| Time & Points Service | 8 | Start/end travel (6), get status (1), get score (1) |
| Map Service | 5 | Update player location (3), get travel time (2) |
| Police DB Service | 5 | Query criminal records (2), get security footage (1), submit coroner report (1), search (1) |
| **Total** | **37** | |
