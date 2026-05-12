# PRD — One Piece TCG Digital (OPTCG)
**Version:** 1.0  
**Owner:** Logan H (VaultAutomation)  
**Engine:** Godot 4 (GDScript)  
**Status:** Pre-production  
**Last Updated:** April 2026

---

## 1. Product Overview

A faithful digital implementation of the official One Piece Card Game (OPTCG) by Bandai, built in Godot 4 and distributed initially via Steam. The game replicates the physical TCG rules exactly — including the DON!! resource system, all keyword effects, and the 4-step combat sequence — while adding digital-native features such as an AI opponent, online multiplayer via Steam P2P, and an automated deck builder.

The game is self-published. Card data ships bundled with the client as JSON files. Player accounts, saved decks, and match history are persisted via a Cloud Run API backed by Cloud SQL PostgreSQL on GCP. Purchases and license keys are handled via Paystack + n8n (existing VaultAutomation infrastructure).

---

## 2. Goals

### Primary Goals
- Deliver a fully playable, rules-accurate digital OPTCG experience on PC (Steam)
- Support single-player vs AI and online PvP (2 players)
- Allow players to build, save, and manage decks
- Ship with OP01 Romance Dawn card set as the starter set

### Secondary Goals
- Port to Nintendo eShop (Switch) post-launch
- Mobile port (iOS + Android) as a future phase
- Self-hosted direct sales channel via own website (GCS + Cloud Run)
- Booster pack monetisation as optional DLC on Steam

### Out of Scope (v1.0)
- Ranked ladder / competitive matchmaking
- Spectator mode
- Trading between players
- Blockchain / NFT integration
- Physical card code redemption

---

## 3. Target Audience

| Segment | Description |
|---|---|
| Primary | One Piece manga/anime fans aged 16–35 who play or want to learn the physical TCG |
| Secondary | Digital TCG players (Hearthstone, MTG Arena, Marvel Snap) looking for a new game |
| Tertiary | Competitive OPTCG players who want to test decks digitally before physical tournaments |

---

## 4. Platform & Distribution

| Platform | Priority | Notes |
|---|---|---|
| Steam (PC/Windows/Linux/macOS) | P0 — Launch | Primary. $100 listing fee. 70% revenue share to developer. |
| Self-hosted (own website) | P0 — Launch | GCS installer + Paystack. 0% platform cut. DRM via online auth. |
| Nintendo eShop (Switch 2) | P1 — Post-launch | Requires dev kit. Godot porting via W4 Games or GDExtension. |
| iOS App Store | P2 — Future | Mobile port required. 30% cut (15% under $1M/yr). |
| Google Play | P2 — Future | Mobile port required. 30% cut (15% under $1M/yr). |
| Epic Games Store | P2 — Future | 12% cut. Secondary PC listing. |

---

## 5. Game Modes

### 5.1 vs AI (CPU)
- Three difficulty levels: Easy (Greedy), Medium (Heuristic scoring), Hard (MCTS-lite)
- Required for tutorial and offline play
- AI uses full rules including Blockers, Counters, and Trigger decisions

### 5.2 Local PvP (Hot Seat)
- Two players on one machine
- Hand-hiding transitions between turns
- No network required

### 5.3 Online PvP (Steam P2P)
- Steam lobbies via GodotSteam plugin
- Host-authoritative game state
- Turn timer: 90 seconds per turn
- Block/Counter step timer: 30 seconds each
- Trigger prompt timer: 20 seconds (auto-skip on timeout)
- Reconnect grace period: 60 seconds

### 5.4 Tutorial
- Scripted game with guided prompts
- Teaches: DON!! system, turn phases, attack declaration, Block/Counter, Trigger resolution
- Cannot be lost — tutorial opponent plays predefined actions

### 5.5 Deck Builder
- Filter cards by color, type, cost, keyword, set
- Real-time construction rule validation (50 cards, max 4 copies, color restriction)
- Save/load up to 20 decks per account
- Import/export deck lists as text codes

---

## 6. Core Rules Implementation

All rules follow the official Bandai OPTCG Comprehensive Rules v1.2.0 (January 2026).

### 6.1 Turn Structure
1. Refresh Phase — set ALL rested cards active; return attached DON!! to cost area ACTIVE (not rested)
2. Draw Phase — draw 1 card (first player skips on turn 1)
3. DON!! Phase — take 2 DON!! from deck (first player gets 1 on turn 1)
4. Main Phase — play cards, attach DON!!, declare attacks, activate effects
5. End Phase — (1) your end-of-turn effects, (2) opponent's end-of-turn effects, (3) your "this turn" effects cancelled, (4) opponent's "this turn" effects cancelled, (5) turn passes

### 6.2 Keywords (all must be implemented)
- **Rush** — attack the turn the card is played
- **Rush: Character** — attack only Characters (not Leader) on entry turn
- **Blocker** — redirect opponent's attack to this card
- **Double Attack** — deal 2 Life damage instead of 1
- **Banish** — Life card goes to trash, Trigger does not activate
- **Trigger** — free effect when Life card is revealed from damage
- **Counter** — power boost from hand during Counter Step
- **DON!! ×N** — threshold power effect, permanent condition
- **DON!! −N** — return DON!! to activate effect

### 6.3 Effect Timing Keywords
- [On Play] — when card enters the field
- [On K.O.] — when eliminated by battle or effect (NOT triggered by limit-trash or bounce)
- [When Attacking] — at attack declaration
- [Main] / [①] — player-activated during Main Phase
- [End of Turn] — after Main Phase
- [End of Opponent's Turn] — reactive
- [Trigger] — from Life pile on damage
- [Counter] — during Counter Step

### 6.4 Win Conditions
- Knockout: a player loses when their Leader takes damage while they have 0 Life cards remaining (rule 1-2-1-1-1). The loss is triggered by the damage event, not by Life reaching 0 passively.
- Deck-Out: a player loses if they have 0 cards in their deck (rule 1-2-1-1-2)
- Nami special: Nami Leader (OP01-016) wins when HER OWN deck empties

### 6.5 Field Limits
- Max 5 Characters on field simultaneously
- 6th Character played forces trash of one existing — treated as a rule, NO effects can be applied at all (rule 3-7-6-1-1). Not just no [On K.O.] — zero effects fire.
- Max 1 Stage card active (new Stage: reveal then trash existing then place new)

### 6.6 Critical Edge Cases (must implement correctly per official rules v1.2.0)
- Ties go to the ATTACKER. Power >= defender wins. Defender must be STRICTLY greater to survive.
- Loss from KO is triggered INSIDE damage processing when life_count == 0 at moment of damage (rule 1-2-1-1-1). Not a passive state check.
- If damage value is 0, nothing happens — no Life card revealed (rule 4-6-2-2)
- Power CAN go below 0 (rule 1-3-6-1). Card stays on field. Never clamp power to 0 in code.
- Cost treated as 0 when it goes negative outside calculations (rule 1-3-6-2)
- DON!! returns to cost area ACTIVE at Refresh Phase (Rule Manual v1.11). Not rested.
- DON!! removed from KO'd or bounced card mid-turn returns RESTED
- Bounce strips attached DON!! and all applied effects (rule 3-1-6). Does NOT trigger [On K.O.]
- Bottom-deck removal: card is gone for the game
- Double Attack: Trigger from hit 1 fully resolves BEFORE hit 2 (rule 4-6-2-2)
- [Trigger] activates INSTEAD of adding card to hand — player chooses. Card goes to hand if Trigger not used (rule 2-11-1)
- Card text overrides Comprehensive Rules (rule 1-3-1)
- Impossible actions are skipped, not errored (rule 1-3-2)
- If rest and set-active required simultaneously, rest takes precedence (rule 1-3-8)

---

## 7. Card Data

### 7.1 Storage
- Card definitions ship as JSON files bundled with the game client
- Loaded on startup into CardDatabase autoload singleton in memory
- Never fetched from server at runtime
- New card sets delivered via game updates (new JSON file per set)

### 7.2 Launch Card Set
- **OP01 — Romance Dawn** (121 cards)
- Covers all 6 colors, all card types (Leader, Character, Event, Stage), all keywords

### 7.3 Card JSON Fields
```
card_id, card_name, card_type, colors[], cost, power, life,
counter, attributes[], types[], keywords[], effects[], 
trigger_effect, art, rarity, set
```

---

## 8. Backend Architecture

### 8.1 Stack
| Component | Technology | Status |
|---|---|---|
| Card database | JSON files (bundled with client) | Build now |
| Game engine | Godot 4 (GDScript) | Build now |
| Player auth | Firebase Auth (GCP: houseof-m-apps) | Exists |
| Player data / saved decks | Cloud SQL PostgreSQL | Exists |
| Match history | Cloud SQL PostgreSQL | Exists |
| Backend API | Cloud Run | Exists |
| Purchase / license keys | Airtable + n8n + Paystack | Already built |
| Game installer storage | Google Cloud Storage | Setup required |
| CDN / API gateway | Cloudflare Workers | Exists |

### 8.2 Data Separation Rules
- Card definitions → JSON bundled with client (never from server at runtime)
- Active match state → Godot memory only (never hits database mid-match)
- Match results → written to Cloud SQL only AFTER match ends
- Player hand cards → never sent to opponent client
- Life cards → face-down, only revealed to both clients at moment of damage

---

## 9. Monetisation

### 9.1 v1.0 — Premium (Pay Once)
- Price: **$14.99 USD**
- Includes full OP01 card set and all game modes
- No pay-to-win, no loot boxes in v1.0
- License key system: generated on purchase, validated on first launch
- Key tied to hardware fingerprint (Godot OS.get_unique_id())

### 9.2 Post-Launch (TBD)
- DLC card sets: $4.99 per set
- Cosmetic card backs / board themes: $1.99–$4.99
- No gameplay advantage sold — cosmetics only

---

## 10. Steam Requirements

- Steam Direct fee: $100 one-time
- Required assets: store page, capsule art, screenshots (min 5), trailer
- Age rating via IARC (free for digital-only titles)
- Steam Deck compatibility review required
- GodotSteam plugin: overlay, achievements, cloud saves, P2P lobbies
- 10 achievements at launch (see Section 13.1 in full doc)

---

## 11. Performance Targets

| Metric | Target |
|---|---|
| Startup to main menu | < 5 seconds |
| Card database load (121 cards) | < 1 second |
| Match start vs AI | < 2 seconds |
| Online match start | < 10 seconds |
| Frame rate | 60 fps (GTX 1060 equivalent) |
| Installer size | < 500 MB |

---

## 12. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Bandai IP / copyright claim | Medium | High | Fan/unofficial implementation. Monitor Bandai policy on digital fan games. |
| Piracy | Medium | Low | Online auth required for multiplayer. |
| Godot console porting | High | Medium | Nintendo port is P1 not P0. Use W4 Games. |
| Low Steam discoverability | High | High | Wishlist campaign, r/OnePieceTCG, YouTube devlogs, TikTok. |
| Rules edge case bugs | High | Medium | Test suite against all official Q&A rulings. |

---

## 13. Out of Scope — v1.0

- Spectator mode, replay system
- Card trading / marketplace
- Physical card code redemption
- Ranked ladder / ELO
- Voice chat
- Console and mobile ports
- Cards beyond OP01

---

*End of PRD v1.0*
