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
optcg/
├── CLAUDE.md                    ← You are here
├── PRD.md                       ← Full product requirements
├── ARCHITECTURE.md              ← Technical stack and data flows
├── AGENTS.md                    ← Parallel agent build plan
│
├── project.godot
├── export_presets.cfg
│
├── data/
│   └── cards/
│       ├── OP01.json            ← Romance Dawn card set
│       └── ...                  ← Future sets added here
│
├── scenes/
│   ├── game/
│   │   ├── GameBoard.tscn
│   │   ├── TurnManager.tscn
│   │   ├── BattleResolver.tscn
│   │   └── DamageHandler.tscn
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
│       ├── PhaseIndicator.tscn
│       ├── PowerCompare.tscn
│       ├── TriggerPrompt.tscn
│       ├── BlockerPrompt.tscn
│       ├── CounterPhaseUI.tscn
│       └── SelectionPrompt.tscn
│
├── scripts/
│   ├── autoloads/
│   │   ├── GameState.gd         ← Singleton: all live game state
│   │   ├── CardDatabase.gd      ← Singleton: all card data loaded from JSON
│   │   └── GameConfig.gd        ← Singleton: settings and constants
│   ├── core/
│   │   ├── TurnManager.gd
│   │   ├── BattleResolver.gd
│   │   ├── DamageHandler.gd
│   │   ├── EffectQueue.gd
│   │   ├── KeywordHandler.gd
│   │   └── WinConditionChecker.gd
│   ├── data/
│   │   ├── CardData.gd          ← CardData resource class
│   │   ├── DeckData.gd          ← DeckData resource class
│   │   ├── EffectData.gd        ← EffectData resource class
│   │   ├── CardInstance.gd      ← Runtime card with live state
│   │   └── DeckValidator.gd
│   ├── ai/
│   │   └── AIOpponent.gd
│   ├── net/
│   │   ├── GameServer.gd        ← Host-authoritative RPC
│   │   └── SteamLobby.gd
│   └── ui/
│       ├── BoardView.gd
│       ├── CardView.gd
│       └── HandView.gd
│
└── resources/
    └── card_database/           ← Optional .tres resources if needed
```

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
keywords: Array[Keyword] # [RUSH, BLOCKER, ...]
effects: Array[EffectData]
trigger_effect: EffectData  # null if none
art: String              # path to texture
rarity: String           # C / U / R / SR / L
set_id: String           # "OP01"
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

See AGENTS.md for full agent specifications. Summary:

| Agent | Module | Entry Point |
|---|---|---|
| Agent 1 | Card Database (JSON + CardData.gd) | data/cards/OP01.json |
| Agent 2 | GameState + TurnManager | scripts/autoloads/GameState.gd |
| Agent 3 | BattleResolver + EffectQueue | scripts/core/BattleResolver.gd |
| Agent 4 | AI Opponent | scripts/ai/AIOpponent.gd |
| Agent 5 | Board UI + Card Rendering | scenes/game/GameBoard.tscn |
| Agent 6 | Cloud Run API + PostgreSQL Schema | api/ (separate repo) |
| Agent 7 | Auth + Player Accounts | api/auth/ |
| Agent 8 | Deck Builder UI | scenes/ui/DeckBuilder.tscn |

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

### Agent 2 → Agent 3: GameState interface
Agent 3 (BattleResolver) calls these GameState methods:
```gdscript
GameState.get_leader(player_idx: int) -> CardInstance
GameState.get_characters(player_idx: int) -> Array[CardInstance]
GameState.get_life_count(player_idx: int) -> int
GameState.pop_top_life(player_idx: int) -> CardInstance
GameState.add_to_hand(player_idx: int, card: CardInstance) -> void
GameState.send_to_trash(card: CardInstance, player_idx: int) -> void
GameState.get_don_count(player_idx: int) -> int
GameState.can_attack(player_idx: int, card_id: String) -> bool
```

### Agent 2 → Agent 4: GameState clone interface
AI clones game state before simulating actions:
```gdscript
GameState.clone() -> GameState
GameState.get_playable_cards(player_idx: int, budget: int) -> Array[CardInstance]
GameState.get_attackable(player_idx: int) -> Array[CardInstance]
GameState.apply_play(card: CardInstance, player_idx: int) -> void
```

### Agent 6 → Agent 2: API endpoints expected by game
```
POST /api/auth/login           → { uid, token }
GET  /api/decks/{uid}          → Array[DeckData]
POST /api/decks/{uid}          → save deck
POST /api/matches/result       → save match result
GET  /api/cards/validate-key   → { valid: bool }
```

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

---

## GCP Infrastructure (Existing — Do Not Recreate)

| Resource | Value |
|---|---|
| GCP Project | houseof-m-apps |
| Cloud Run instance | https://n8n-116267842979.us-central1.run.app |
| Cloud SQL | PostgreSQL, existing N8N_ENCRYPTION_KEY |
| Airtable base | appxj1oWnsbZsrNfR (Lead Gen base) |
| Cloudflare | Workers as API gateway |

New resources needed:
- GCS bucket for game installer storage
- New Cloud Run service for OPTCG game API (separate from n8n instance)
- New PostgreSQL database/schema for OPTCG player data (can share instance)

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
