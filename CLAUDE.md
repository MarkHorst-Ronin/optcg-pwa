# CLAUDE.md — OPTCG Project Context
> Read this file first before doing anything on this project.
> Every Claude agent working on any part of OPTCG must read this entire file before writing a single line of code.

---

## What This Project Is

A fully rules-accurate digital implementation of the **One Piece Card Game (OPTCG)** by Bandai, built in **Godot 4 using GDScript**. The game ships on Steam and via self-hosted direct download. It supports single-player vs AI, local PvP (hot seat), and online PvP via Steam P2P lobbies.

**Owner:** Logan H (VaultAutomation Pty Ltd)  
**Engine:** Godot 4 — GDScript only (no C#, no GDNative)  
**PRD:** See PRD.md  
**Architecture:** See ARCHITECTURE.md  
**Agent Plan:** See AGENTS.md  

---

## Repository Structure

```
optcg-pwa/
├── CLAUDE.md                    ← You are here
├── PRD.md                       ← Full product requirements
├── ARCHITECTURE.md              ← Technical stack and data flows
├── AGENTS.md                    ← Parallel agent build plan (13 agents, 5 waves)
├── README.md                    ← macOS setup guide and dev workflow
│
├── project.godot                ← Godot 4.3 project config (GL Compatibility, 1920×1080)
├── index.html                   ← Web export entry point
│
├── data/
│   └── cards/
│       ├── OP01.json            ← Romance Dawn card set (121 cards — Agent 1 fills)
│       └── ...                  ← Future sets added here
│
├── scenes/
│   ├── game/
│   │   ├── GameBoard.tscn
│   │   ├── TurnManager.tscn
│   │   └── BattleResolver.tscn
│   ├── zones/
│   │   ├── LeaderZone.tscn
│   │   ├── CharacterZone.tscn
│   │   ├── StageZone.tscn
│   │   ├── DonZone.tscn
│   │   ├── LifeZone.tscn
│   │   ├── HandZone.tscn
│   │   └── TrashZone.tscn
│   ├── cards/
│   │   ├── CardBase.tscn
│   │   ├── LeaderCard.tscn
│   │   ├── CharacterCard.tscn
│   │   ├── EventCard.tscn
│   │   ├── StageCard.tscn
│   │   └── DonCard.tscn
│   └── ui/
│       ├── MainMenu.tscn        ← Run/Main scene
│       ├── LoginScreen.tscn
│       ├── DeckBuilder.tscn
│       ├── WinLoseScreen.tscn
│       ├── PhaseIndicator.tscn
│       ├── PowerCompare.tscn
│       ├── TriggerPrompt.tscn
│       ├── BlockerPrompt.tscn
│       ├── CounterPhaseUI.tscn
│       └── SelectionPrompt.tscn
│
├── scripts/
│   ├── autoloads/
│   │   ├── GameState.gd         ← Singleton: all live game state [STUB]
│   │   ├── CardDatabase.gd      ← Singleton: card data loaded from JSON [STUB]
│   │   └── GameConfig.gd        ← Singleton: settings and constants [COMPLETE]
│   ├── core/
│   │   ├── TurnManager.gd       ← 5-phase state machine [STUB]
│   │   ├── BattleResolver.gd    ← 4-step combat flow [STUB]
│   │   ├── DamageHandler.gd     ← Life/trigger processing [STUB]
│   │   ├── EffectQueue.gd       ← FIFO async effect resolver [STUB]
│   │   ├── KeywordHandler.gd    ← Keyword logic (Rush, Blocker, etc.) [STUB]
│   │   └── WinConditionChecker.gd ← Win/loss detection [STUB]
│   ├── data/
│   │   ├── CardData.gd          ← CardData resource + all enums [COMPLETE]
│   │   ├── CardInstance.gd      ← Runtime card with live state [COMPLETE]
│   │   ├── EffectData.gd        ← Effect metadata resource [COMPLETE]
│   │   ├── DeckData.gd          ← Deck container resource [COMPLETE]
│   │   ├── DeckValidator.gd     ← Deck rule validation [COMPLETE]
│   │   └── CardFilter.gd        ← Search/filter for card database [COMPLETE]
│   ├── ai/
│   │   └── AIOpponent.gd        ← 3-tier AI (Easy/Medium/Hard) [STUB]
│   ├── net/
│   │   ├── GameServer.gd        ← Host-authoritative RPC handlers [STUB]
│   │   ├── SteamLobby.gd        ← GodotSteam lobby management [STUB]
│   │   └── AuthManager.gd       ← Firebase Auth client [STUB]
│   └── ui/
│       ├── BoardView.gd         ← Board visualization [STUB]
│       ├── CardView.gd          ← Card rendering + 8 visual states [STUB]
│       └── DeckBuilderView.gd   ← Deck builder UI logic [STUB]
│
└── api/                         ← Node.js Cloud Run backend
    ├── index.js                 ← Express server entry point [STUB]
    ├── package.json             ← express, pg, firebase-admin, uuid
    ├── Dockerfile
    ├── .env.example
    ├── db/
    │   └── schema.sql           ← PostgreSQL schema [COMPLETE]
    └── routes/
        ├── auth.js              ← Login/register [STUB]
        ├── decks.js             ← GET/POST/DELETE decks [STUB]
        ├── matches.js           ← Match history [STUB]
        └── license.js           ← License key validation [STUB]
```

---

## Implementation Status

| File | Status | Owner Agent |
|---|---|---|
| `scripts/autoloads/GameConfig.gd` | COMPLETE | — |
| `scripts/data/CardData.gd` | COMPLETE (enums + fields) | Agent 1 |
| `scripts/data/CardInstance.gd` | COMPLETE | Agent 2 |
| `scripts/data/EffectData.gd` | COMPLETE | Agent 1 |
| `scripts/data/DeckData.gd` | COMPLETE | Agent 9 |
| `scripts/data/DeckValidator.gd` | COMPLETE | Agent 9 |
| `scripts/data/CardFilter.gd` | COMPLETE | Agent 9 |
| `api/db/schema.sql` | COMPLETE | Agent 6 |
| `data/cards/OP01.json` | EMPTY — needs 121 cards | Agent 1 |
| `scripts/autoloads/GameState.gd` | STUB | Agent 2 |
| `scripts/autoloads/CardDatabase.gd` | STUB | Agent 1 |
| `scripts/core/TurnManager.gd` | STUB | Agent 3 |
| `scripts/core/BattleResolver.gd` | STUB | Agent 4 |
| `scripts/core/DamageHandler.gd` | STUB | Agent 4 |
| `scripts/core/EffectQueue.gd` | STUB | Agent 4 |
| `scripts/core/KeywordHandler.gd` | STUB | Agent 11 |
| `scripts/core/WinConditionChecker.gd` | STUB | Agent 11 |
| `scripts/ai/AIOpponent.gd` | STUB | Agent 10 |
| `scripts/net/GameServer.gd` | STUB | Agent 12 |
| `scripts/net/SteamLobby.gd` | STUB | Agent 12 |
| `scripts/net/AuthManager.gd` | STUB | Agent 7 |
| `scripts/ui/BoardView.gd` | STUB | Agent 8 |
| `scripts/ui/CardView.gd` | STUB | Agent 5 |
| `scripts/ui/DeckBuilderView.gd` | STUB | Agent 9 |
| All `api/routes/*.js` | STUB | Agents 6, 7 |

---

## Language and Engine Rules

- **GDScript only.** No C#. No GDExtension unless specifically for GodotSteam (which requires it).
- **Godot 4.x** — use Godot 4 APIs. Do not use Godot 3 patterns.
- **Type hints everywhere.** All function signatures must include type hints.
- **class_name on every script** that is referenced by other scripts.
- **Signals over direct calls** for cross-node communication.
- **await for async** — all player input steps (trigger prompts, block/counter, target selection) use await.
- **No globals except autoloads.** The three autoloads (GameState, CardDatabase, GameConfig) are the only singletons.

---

## Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Files | snake_case | `turn_manager.gd`, `card_data.gd` |
| Classes | PascalCase | `TurnManager`, `CardData` |
| Variables | snake_case | `attached_don`, `is_rested` |
| Constants | UPPER_SNAKE | `MAX_CHARACTERS`, `DON_PER_TURN` |
| Signals | past_tense snake_case | `phase_changed`, `battle_complete` |
| Enums | PascalCase name, UPPER members | `Phase.MAIN`, `Keyword.RUSH` |
| Scene nodes | PascalCase | `LeaderZone`, `P1_HandZone` |

---

## Core Data Structures

### CardData (resource — loaded from JSON, read-only at runtime)
```gdscript
card_id: String          # "OP01-001"
card_name: String        # "Monkey D. Luffy"
card_type: CardType      # LEADER / CHARACTER / EVENT / STAGE / DON
colors: Array[Color]     # ["RED"]
cost: int                # DON!! to play
power: int               # Base power
life: int                # Leader only
counter: int             # 0 / 1000 / 2000
attributes: Array[Attribute]  # [STRIKE, SLASH, ...]
types: Array[String]     # ["Supernovas", "Straw Hat Crew"]
keywords: Array[Keyword] # [RUSH, BLOCKER, ...]
effects: Array[EffectData]
trigger_effect: EffectData  # null if none
art: String              # path to texture
rarity: String           # C / U / R / SR / L
set_id: String           # "OP01"
```

### CardData Enums (all defined in CardData.gd)
```gdscript
enum CardType  { LEADER, CHARACTER, EVENT, STAGE, DON }
enum Color     { RED, GREEN, BLUE, PURPLE, BLACK, YELLOW }
enum Keyword   { RUSH, RUSH_CHARACTER, DOUBLE_ATTACK, BANISH, BLOCKER, TRIGGER, COUNTER, DON_X, DON_MINUS }
enum Attribute { SLASH, STRIKE, RANGED, SPECIAL, WISDOM, UNKNOWN }
enum EffectType { DRAW, SEARCH, DISCARD, BOUNCE, TRASH, POWER_MOD, COST_REDUCE, REST_TARGET,
                  UNREST, ADD_LIFE, REMOVE_LIFE, LOOK_LIFE, REORDER_LIFE, BANISH_TARGET,
                  PLAY_FROM_TRASH, GIVE_DON, CANNOT_ATTACK, CANNOT_BE_KOD }
enum EffectTiming { ON_PLAY, ON_KO, WHEN_ATTACKING, WHEN_ATTACKED, MAIN, ACTIVATE,
                    END_OF_TURN, END_OPP_TURN, TRIGGER, COUNTER, DON_X, PERMANENT }
```

### CardInstance (runtime — mutable during game)
```gdscript
card_data: CardData      # reference to static data
is_rested: bool
attached_don: int
temp_power_mods: Array   # cleared after each battle
perm_power_mods: Array   # cleared at end of turn or as specified
owner_id: int            # 0 or 1
turns_on_field: int      # 0 = played this turn (blocked from attacking unless Rush)
```
Key method: `get_total_power() -> int` — NEVER clamps to 0; returns actual negative value per rule 4.

### GameState (autoload singleton)
```gdscript
# Per-player state (index 0 = player 1, index 1 = player 2)
leaders: Array[CardInstance]        # [p1_leader, p2_leader]
characters: Array[Array]            # [[p1 chars], [p2 chars]]
stages: Array[CardInstance]         # [p1_stage, p2_stage]
hands: Array[Array]                 # [[p1 hand], [p2 hand]]
decks: Array[Array]                 # [[p1 deck], [p2 deck]]
don_cost_areas: Array[Array]        # [[p1 don], [p2 don]]
don_decks: Array[Array]             # [[p1 don deck], [p2 don deck]]
life_areas: Array[Array]            # [[p1 life], [p2 life]]
trash_piles: Array[Array]           # [[p1 trash], [p2 trash]]
active_player: int                  # 0 or 1
turn_number: int
```
Signals: `card_moved`, `don_attached`, `don_returned`, `state_reset`

### CardFilter (search helper)
```gdscript
colors: Array        # OR logic across colors
card_type: CardType  # exact match; -1 = any
min_cost: int
max_cost: int
keywords: Array      # AND logic
set_ids: Array       # OR logic
text: String         # matches card_name or description
```

---

## Rules You Must Never Get Wrong

These are the most commonly misimplemented rules. Every agent must internalize them.
Source: Official Bandai OPTCG Comprehensive Rules v1.2.0 (January 16, 2026).

1. **Ties go to the ATTACKER.** To survive, defender must have STRICTLY GREATER power.

2. **Win condition is triggered by damage, not by Life reaching 0.** Per rule 1-2-1-1-1:
   a player loses when their Leader TAKES DAMAGE while they have 0 Life cards remaining.
   Having 0 Life does not itself trigger a loss — the next damaging hit does.
   In the engine: check for loss INSIDE damage processing, not as a separate state check.

3. **First player cannot attack on turn 1.** Not even with Rush characters. (Rule Manual)

4. **Power CAN go below 0.** Per rule 1-3-6-1: power can become a negative value.
   Per rule 1-3-6-1-1: a card with negative power stays on the field unless an effect
   specifically moves it. Do NOT clamp power to 0 in get_total_power(). Return the
   actual negative value. Only clamp COST to 0 (rule 1-3-6-2).

5. **DON!! returns to cost area ACTIVE during Refresh Phase.** Per the official Rule Manual:
   "Set all rested cards as active, AND return all DON!! cards attached to cards to your
   cost area IN AN ACTIVE STATE." This means returned DON!! are immediately available
   to use again on the very next turn. Do NOT return them rested.
   EXCEPTION: When a Character leaves the field mid-turn (KO, bounce, etc.), its
   attached DON!! return rested (Rule Manual: "returned to the cost area and rested").

6. **Bounce ≠ K.O.** Returning a card to hand does NOT trigger [On K.O.].
   Per rule 3-1-6: card is treated as a new card in a new area; all effects are removed.

7. **5-card limit trash: NO effects can be applied at all.** Per rule 3-7-6-1-1:
   "Trashing a Character according to 3-7-6-1 is treated as processing a rule, and
   no effect can be applied." This means not just [On K.O.] — literally no effect fires.
   Implement as a direct rule-level trash bypassing the entire effect pipeline.

8. **Double Attack Trigger sequencing:** Trigger from hit 1 fully resolves (including all
   effects and player choices) BEFORE hit 2 is applied. Per rule 4-6-2-2, damage of X
   repeats the "damage taken is 1" process X times sequentially.

9. **Banish skips Trigger AND sends Life card to trash** (not hand). The card is gone.
   Per keyword definition: "the Life card is trashed without its [Trigger] being activated."

10. **Counter only from hand.** You cannot use a Character on the field as a Counter.

11. **End Phase has 4 ordered steps** (not just 1):
    a. YOUR end-of-turn effects activate and resolve
    b. OPPONENT'S end-of-turn effects activate and resolve
    c. YOUR "during this turn" duration effects are cancelled
    d. OPPONENT'S "during this turn" duration effects are cancelled
    e. Turn ends, opponent's turn begins

12. **Nami (OP01-016) wins by emptying her OWN deck.** All other players lose on deck-out.

13. **Card text overrides Comprehensive Rules** (rule 1-3-1). If a card's text contradicts
    a rule, the card text takes precedence. Always check card text first.

14. **If an impossible action is required, skip it** (rule 1-3-2). Don't error — just
    skip the impossible part and continue resolving any remaining parts of the effect.

15. **DON!! deck is an OPEN area** (rule 3-3-2). Both players can view its contents.
    The main deck is a SECRET area. The hand is secret (only owner can view).
    The Life area is secret (neither player can view face-down contents unless specified).

---

## What Each Agent Is Responsible For

See AGENTS.md for full specifications with deliverables and DoD checklists.

| Agent | Module | Primary Files |
|---|---|---|
| Agent 1 | Card Database — JSON + parsing | `data/cards/OP01.json`, `CardDatabase.gd`, `CardData.gd` (enums already defined) |
| Agent 2 | GameState — state container | `scripts/autoloads/GameState.gd` |
| Agent 3 | TurnManager — 5-phase state machine | `scripts/core/TurnManager.gd` |
| Agent 4 | BattleResolver + EffectQueue + DamageHandler | `scripts/core/BattleResolver.gd`, `EffectQueue.gd`, `DamageHandler.gd` |
| Agent 5 | Card Rendering + CardView | `scripts/ui/CardView.gd`, `scenes/cards/*.tscn` |
| Agent 6 | Cloud Run API + PostgreSQL | `api/` (Node.js backend) |
| Agent 7 | Firebase Auth — login/register | `api/routes/auth.js`, `scripts/net/AuthManager.gd` |
| Agent 8 | Board UI + Zones | `scripts/ui/BoardView.gd`, `scenes/game/GameBoard.tscn`, `scenes/zones/*.tscn` |
| Agent 9 | Deck Builder UI | `scripts/ui/DeckBuilderView.gd`, `scenes/ui/DeckBuilder.tscn` |
| Agent 10 | AI Opponent (Easy/Medium/Hard) | `scripts/ai/AIOpponent.gd` |
| Agent 11 | KeywordHandler + WinConditionChecker | `scripts/core/KeywordHandler.gd`, `WinConditionChecker.gd` |
| Agent 12 | Online Multiplayer + GameServer | `scripts/net/GameServer.gd`, `SteamLobby.gd` |
| Agent 13 | Integration + Full Game Loop + Polish | All scenes, UI flow, export presets |

---

## Interfaces Between Agents

These are the contracts that agents must agree on before building.

### Agent 1 → Everyone: Card JSON Schema
```json
{
  "card_id": "OP01-001",
  "card_name": "Monkey D. Luffy",
  "card_type": "LEADER",
  "colors": ["RED"],
  "cost": 0,
  "power": 5000,
  "life": 5,
  "counter": 0,
  "attributes": ["STRIKE"],
  "types": ["Supernovas", "Straw Hat Crew"],
  "keywords": [],
  "effects": [
    {
      "timing": "ACTIVATE",
      "don_cost": 1,
      "effect_type": "GIVE_DON",
      "value": 1,
      "target": "SELF_OR_CHARACTER",
      "optional": false,
      "description": "Give up to 1 rested DON!! card."
    }
  ],
  "trigger_effect": null,
  "art": "op01_001.webp",
  "rarity": "L",
  "set": "OP01"
}
```

### Agent 2 → Agent 4: GameState interface (BattleResolver calls these)
```gdscript
GameState.get_leader(player_idx: int) -> CardInstance
GameState.get_characters(player_idx: int) -> Array[CardInstance]
GameState.get_life_count(player_idx: int) -> int
GameState.pop_top_life(player_idx: int) -> CardInstance
GameState.add_to_hand(player_idx: int, card: CardInstance) -> void
GameState.send_to_trash(card: CardInstance, player_idx: int) -> void
GameState.get_don_count(player_idx: int) -> int
GameState.can_attack(player_idx: int, card_id: String) -> bool
GameState.get_valid_attack_targets(player_idx: int) -> Array
GameState.move_card(card, from_zone, to_zone, player_idx: int) -> void
GameState.return_attached_don(card: CardInstance, as_active: bool) -> void
```

### Agent 2 → Agent 10: GameState clone interface (AI simulation)
```gdscript
GameState.clone() -> GameState
GameState.get_playable_cards(player_idx: int, budget: int) -> Array[CardInstance]
GameState.get_attackable(player_idx: int) -> Array[CardInstance]
GameState.apply_play(card: CardInstance, player_idx: int) -> void
```

### Agent 6/7 → Agent 2: API endpoints expected by the Godot client
```
POST /api/auth/login           → { uid, token }
POST /api/auth/register        → { uid, token }
GET  /api/decks/{uid}          → Array[DeckData]
POST /api/decks/{uid}          → save deck
DELETE /api/decks/{uid}/{id}   → delete deck
POST /api/matches/result       → save match result
GET  /api/license/validate-key → { valid: bool }
```

### Agent 7 → Godot: AuthManager signals
```gdscript
signal login_complete(uid: String, display_name: String)
signal login_failed(error: String)
signal logout_complete()
```

---

## Backend API (api/)

The `api/` directory is a **Node.js + Express** backend deployed to Google Cloud Run.

- **Runtime:** Node 20 LTS
- **Database:** PostgreSQL 14+ (shared Cloud SQL instance `houseof-m-apps`)
- **Auth:** Firebase Admin SDK — validates Firebase ID tokens
- **Schema:** `api/db/schema.sql` — tables: `players`, `decks`, `matches`, `licenses`
- **Entry point:** `api/index.js` — mounts routes under `/api/`
- **Local dev:** `cd api && cp .env.example .env && npm install && npm run dev`

The Godot client talks to this API only at game startup (auth + deck fetch). Never mid-match.

---

## What NOT To Do

- Do not call Airtable from inside the Godot client. Airtable is backend only.
- Do not store game state in a database mid-match. Memory only.
- Do not call any API during active gameplay except the initial startup card load check.
- Do not use C# or any non-GDScript language in the Godot project.
- Do not implement any rule from memory without cross-referencing the Rules section above.
- Do not use polling for multiplayer state — use Godot RPC signals.
- Do not send opponent hand card IDs over the network. Ever.
- Do not add any monetisation logic inside gameplay code — keep it in the API layer.
- Do not create `DamageHandler.tscn` — DamageHandler is a script-only node, not a scene.
- Do not add `HandView.gd` — hand display is handled by `BoardView.gd` and zone scenes.

---

## GCP Infrastructure (Existing — Do Not Recreate)

| Resource | Value |
|---|---|
| GCP Project | houseof-m-apps |
| Cloud Run instance (n8n) | https://n8n-116267842979.us-central1.run.app |
| Cloud SQL | PostgreSQL, existing N8N_ENCRYPTION_KEY |
| Airtable base | appxj1oWnsbZsrNfR (Lead Gen base) |
| Cloudflare | Workers as API gateway |

New resources needed for OPTCG:
- GCS bucket for game installer storage
- New Cloud Run service for OPTCG game API (separate from n8n instance)
- New PostgreSQL database/schema for OPTCG player data (can share Cloud SQL instance)

---

## Definition of Done

A module is complete when:
1. All functions have type hints
2. All public signals are documented with a comment
3. Edge cases from the Rules section above are handled
4. A minimal test scenario runs without errors in the Godot debugger
5. The module's interface contract (see above) is met exactly

---

*End of CLAUDE.md*
