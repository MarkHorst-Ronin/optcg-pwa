# AGENTS.md — Parallel Agent Build Plan
**Project:** One Piece TCG Digital (OPTCG)  
**Engine:** Godot 4 (GDScript)  
**Version:** 1.0  
**Last Updated:** April 2026

> Before starting ANY work, every agent MUST read CLAUDE.md in full.
> All rules, naming conventions, interface contracts, and restrictions live there.

---

## Build Wave Overview

Agents within the same wave run in parallel.
No agent in wave N may start until all agents in wave N-1 are complete and verified.

```
WAVE 1 — No dependencies (start immediately, all parallel)
├── Agent 1  — Card Database (JSON + CardData.gd + CardDatabase.gd)
├── Agent 2  — GameState Singleton
└── Agent 6  — Cloud Run API + PostgreSQL Schema

WAVE 2 — Depends on Wave 1 (all parallel)
├── Agent 3  — TurnManager           (needs Agent 2)
├── Agent 5  — Card Rendering        (needs Agent 1)
└── Agent 7  — Firebase Auth         (needs Agent 6)

WAVE 3 — Depends on Wave 2 (all parallel)
├── Agent 4  — BattleResolver + EffectQueue + DamageHandler  (needs Agents 2+3)
├── Agent 8  — Board UI + Zones                              (needs Agents 2+5)
└── Agent 9  — Deck Builder UI                               (needs Agents 1+5+7)

WAVE 4 — Depends on Wave 3 (all parallel)
├── Agent 10 — AI Opponent               (needs Agents 2+4)
├── Agent 11 — KeywordHandler + WinCheck (needs Agents 2+4)
└── Agent 12 — Online Multiplayer        (needs Agents 4+7)

WAVE 5 — Integration (depends on all prior waves)
└── Agent 13 — Full Game Loop, Tutorial, Polish
```

---

## Agent Specifications

---

### AGENT 1 — Card Database
**Wave:** 1 | **No dependencies**  
**Output:** ~1,500 lines JSON + ~150 lines GDScript

#### Responsibility
Complete OP01 Romance Dawn card set as JSON. CardData and EffectData resource classes. CardDatabase autoload singleton that parses and serves all card data.

#### Inputs
- CLAUDE.md — card JSON schema and CardData enums
- PRD.md — section 7 card data requirements
- Official OP01 card list (all 121 cards, publicly documented)

#### Deliverables
```
data/cards/OP01.json
scripts/data/CardData.gd
scripts/data/EffectData.gd
scripts/data/TargetFilter.gd
scripts/autoloads/CardDatabase.gd
```

#### CardData.gd required enums
```gdscript
enum CardType    { LEADER, CHARACTER, EVENT, STAGE, DON }
enum Color       { RED, GREEN, BLUE, PURPLE, BLACK, YELLOW }
enum Keyword     { RUSH, RUSH_CHARACTER, DOUBLE_ATTACK, BANISH,
                   BLOCKER, TRIGGER, COUNTER, DON_X, DON_MINUS }
enum Attribute   { SLASH, STRIKE, RANGED, SPECIAL, WISDOM, UNKNOWN }
enum EffectType  { DRAW, SEARCH, DISCARD, BOUNCE, TRASH, POWER_MOD,
                   COST_REDUCE, REST_TARGET, UNREST, ADD_LIFE, REMOVE_LIFE,
                   LOOK_LIFE, REORDER_LIFE, BANISH_TARGET, PLAY_FROM_TRASH,
                   GIVE_DON, CANNOT_ATTACK, CANNOT_BE_KOD }
enum EffectTiming { ON_PLAY, ON_KO, WHEN_ATTACKING, WHEN_ATTACKED,
                    MAIN, ACTIVATE, END_OF_TURN, END_OPP_TURN,
                    TRIGGER, COUNTER, DON_X, PERMANENT }
```

#### CardDatabase.gd required public methods
```gdscript
func get_card(card_id: String) -> CardData
func get_set(set_id: String) -> Array[CardData]
func get_all_cards() -> Array[CardData]
func search(filter: CardFilter) -> Array[CardData]
```

#### Card JSON schema (exact)
```json
{
  "card_id": "OP01-001",
  "card_name": "Monkey D. Luffy",
  "card_type": "LEADER",
  "colors": ["RED"],
  "cost": 0, "power": 5000, "life": 5, "counter": 0,
  "attributes": ["STRIKE"],
  "types": ["Supernovas", "Straw Hat Crew"],
  "keywords": [],
  "effects": [{
    "timing": "ACTIVATE", "don_cost": 1,
    "effect_type": "GIVE_DON", "value": 1,
    "target": "SELF_OR_CHARACTER",
    "optional": false,
    "description": "Give up to 1 rested DON!! card."
  }],
  "trigger_effect": null,
  "art": "op01_001.webp",
  "rarity": "L", "set": "OP01"
}
```

#### Definition of Done
- [ ] All 121 OP01 cards present with correct data
- [ ] All card types (Leader, Character, Event, Stage) represented
- [ ] All keywords appear on at least one card
- [ ] CardDatabase loads without errors in Godot debugger
- [ ] `get_card("OP01-001")` returns correct Luffy data
- [ ] All functions have type hints

---

### AGENT 2 — GameState Singleton
**Wave:** 1 | **No dependencies**  
**Output:** ~300 lines GDScript

#### Responsibility
The single source of truth for all live game data during a match. Pure data container and mutation layer only. No rules validation, no rendering.

#### Inputs
- CLAUDE.md — GameState data structure
- ARCHITECTURE.md — section 3.1

#### Deliverables
```
scripts/autoloads/GameState.gd
scripts/data/CardInstance.gd
```

#### Required fields
```gdscript
# Indexed by player_idx (0 = player 1, 1 = player 2)
var leaders:        Array[CardInstance]   # size 2
var characters:     Array[Array]          # [[p1 chars], [p2 chars]] max 5 each
var stages:         Array[CardInstance]   # size 2, null if no Stage active
var hands:          Array[Array]
var decks:          Array[Array]
var don_cost_areas: Array[Array]          # active DON!! in cost area
var don_decks:      Array[Array]          # DON!! deck (10 cards at start)
var life_areas:     Array[Array]          # face-down Life cards
var trash_piles:    Array[Array]
var active_player:  int                   # 0 or 1
var turn_number:    int
```

#### Required public methods
```gdscript
# Movement
func move_card(card: CardInstance, from_zone: Zone, to_zone: Zone, player_idx: int) -> void
func send_to_trash(card: CardInstance, player_idx: int) -> void
func add_to_hand(player_idx: int, card: CardInstance) -> void
func pop_top_life(player_idx: int) -> CardInstance
func pop_top_deck(player_idx: int) -> CardInstance

# Queries
func get_leader(player_idx: int) -> CardInstance
func get_characters(player_idx: int) -> Array[CardInstance]
func get_life_count(player_idx: int) -> int
func get_deck_size(player_idx: int) -> int
func get_hand_size(player_idx: int) -> int
func get_don_count(player_idx: int) -> int
func get_hand(player_idx: int) -> Array[CardInstance]

# DON!! management
func add_don_to_cost(player_idx: int, count: int) -> void
func attach_don_to_card(card: CardInstance, player_idx: int) -> void
func return_attached_don(card: CardInstance, as_active: bool) -> void

# Validation (pure — no side effects)
func can_play_card(player_idx: int, card_id: String) -> bool
func can_attack(player_idx: int, card_id: String) -> bool
func get_valid_attack_targets(player_idx: int) -> Array[CardInstance]

# AI simulation
func clone() -> GameState
func apply_play(card: CardInstance, player_idx: int) -> void
func get_playable_cards(player_idx: int, budget: int) -> Array[CardInstance]
func get_attackable(player_idx: int) -> Array[CardInstance]
```

#### Definition of Done
- [ ] All fields typed and initialised
- [ ] All public methods implemented with type hints
- [ ] `clone()` returns a true deep copy with no shared references
- [ ] `can_attack()` returns false for cards played this turn (unless Rush)
- [ ] `return_attached_don(as_active: true)` and `(as_active: false)` both work correctly
- [ ] No rules logic anywhere — data operations only

---

### AGENT 3 — TurnManager
**Wave:** 2 | **Depends on:** Agent 2  
**Output:** ~250 lines GDScript

#### Responsibility
5-phase turn state machine. All phase transition rules. Signals at each change. No rendering.

#### Inputs
- CLAUDE.md — rules section (End Phase 4-step order, Refresh DON!! return)
- ARCHITECTURE.md — TurnManager.gd spec
- Agent 2 — GameState public methods

#### Deliverables
```
scripts/core/TurnManager.gd
scenes/game/TurnManager.tscn
```

#### Signals required
```gdscript
signal phase_changed(new_phase: Phase)
signal turn_ended(player_idx: int)
signal game_over(winner_idx: int)
signal draw_required(player_idx: int)
```

#### REFRESH PHASE — exact order (Rule Manual v1.11)
1. Set ALL rested cards active: Leader, all Characters, Stage, cost area DON!!
2. Return all DON!! attached to Leader/Characters → cost area **AS ACTIVE**
   ⚠️ CRITICAL: `GameState.return_attached_don(card, as_active: true)`

#### END PHASE — exact 4-step order (Rule Manual v1.11)
1. Turn player's [End of Your Turn] effects resolve
2. Non-turn player's [End of Your Turn] effects resolve
3. Turn player's "during this turn" effects cancelled
4. Non-turn player's "during this turn" effects cancelled
5. Swap active_player, increment turn_number

#### DON!! Phase
- Standard: add 2 from don_deck to cost area as active
- First player turn 1: add only 1
- If don_deck has 1 remaining: add that 1 only
- If don_deck empty: add nothing

#### Definition of Done
- [ ] All 5 phases transition in correct sequence
- [ ] Refresh sets DON!! ACTIVE (confirmed with test: don should be active after refresh)
- [ ] End Phase fires in correct 4-step order
- [ ] First-player turn 1: no draw, only 1 DON!!
- [ ] game_over signal emitted when deck empty on draw
- [ ] 3-turn round trip runs without errors in debugger

---

### AGENT 4 — BattleResolver + EffectQueue + DamageHandler
**Wave:** 3 | **Depends on:** Agents 2 + 3  
**Output:** ~600 lines GDScript

#### Responsibility
The 4-step combat system. FIFO async effect queue. Damage and life processing. Most complex module — every edge case from CLAUDE.md applies here.

#### Inputs
- CLAUDE.md — entire rules section (all 15 rules)
- ARCHITECTURE.md — BattleResolver, EffectQueue, DamageHandler specs
- Agent 2 — GameState methods
- Agent 3 — TurnManager signals

#### Deliverables
```
scripts/core/BattleResolver.gd
scripts/core/EffectQueue.gd
scripts/core/DamageHandler.gd
scenes/game/BattleResolver.tscn
```

#### BattleResolver — 4 steps
```
Step 1 ATTACK DECLARATION:
- Rest attacker
- Validate target: only rested Characters or Leader
- Fire [When Attacking] effects → EffectQueue
- Await EffectQueue.all_resolved

Step 2 BLOCK STEP:
- Request block decision from defender (30s timeout → auto no-block)
- Max 1 Blocker per battle
- If blocker: rest it, change attack.target

Step 3 COUNTER STEP:
- Defender may discard Character cards (Counter value adds to defender power)
- Defender may play Event [Counter] cards (pay cost with active DON!!)
- HAND ONLY — never from field
- Repeat until defender passes

Step 4 DAMAGE STEP:
- attacker_power = attacker.get_total_power()  ← may be negative
- defender_power = defender.get_total_power()  ← may be negative
- if attacker_power >= defender_power: attacker wins
- vs Leader → DamageHandler.deal_damage()
- vs Character → GameState.send_to_trash(defender)
- if attacker loses → nothing happens
```

#### DamageHandler — exact per rules
```
if damage == 0: return immediately (rule 4-6-2-2)
for each hit:
  if GameState.get_life_count(player) == 0:
    → player loses — emit TurnManager.game_over
    return
  life_card = GameState.pop_top_life(player)
  if Banish:
    GameState.send_to_trash(life_card)     ← NO Trigger, NO hand add
  else:
    if life_card has Trigger:
      await UI.trigger_prompt()            ← player chooses activate or skip
      if activated:
        EffectQueue.enqueue(trigger_effect)
        await EffectQueue.all_resolved
        ← card still goes to hand after
    GameState.add_to_hand(player, life_card)
  if Double Attack and this was hit 1:
    await get_tree().process_frame         ← let hit 1 fully resolve before hit 2
```

#### EffectQueue — FIFO async
```
- All effects pushed to queue, resolved in order
- Each effect: await player input if required
- If source card left field: skip effect (unless effect.independent = true)
- emit all_resolved when queue empty
```

#### Definition of Done
- [ ] Full 4-step battle runs end to end without errors
- [ ] Tie → attacker wins (test: 5000 vs 5000 → attacker wins)
- [ ] Double Attack deals 2 Life damage with Trigger between hits
- [ ] Banish: life card trashed, no Trigger, no hand add
- [ ] Blocker redirects target correctly
- [ ] Counter from hand adds power for that battle only
- [ ] Win condition fires when Leader hit at 0 Life
- [ ] Power of 0 or negative resolves correctly in battle
- [ ] damage == 0 does nothing

---

### AGENT 5 — Card Rendering + CardView
**Wave:** 2 | **Depends on:** Agent 1  
**Output:** ~200 lines GDScript + scenes

#### Responsibility
Visual card representation. CardBase scene rendering any card from CardData. All 8 visual states. No game logic.

#### Inputs
- ARCHITECTURE.md — card states list
- Agent 1 — CardData.gd

#### Deliverables
```
scenes/cards/CardBase.tscn
scenes/cards/LeaderCard.tscn
scenes/cards/CharacterCard.tscn
scenes/cards/EventCard.tscn
scenes/cards/StageCard.tscn
scenes/cards/DonCard.tscn
scripts/ui/CardView.gd
```

#### Visual states
```gdscript
enum CardState {
  ACTIVE,      # upright, full opacity
  RESTED,      # 90° rotation, 0.2s tween
  TARGETED,    # glow shader outline
  HOVERABLE,   # scale 1.1, z-index raised, detail panel
  PLAYABLE,    # subtle pulse animation
  UNPLAYABLE,  # desaturated, 0.5 alpha
  FACE_DOWN,   # card back, all text hidden
  ATTACKING    # slight forward push
}

func set_state(state: CardState) -> void
func flip_to_face_up(animate: bool) -> void
func attach_don_visual(count: int) -> void
func load_card(data: CardData) -> void
```

#### Definition of Done
- [ ] All 8 states render correctly
- [ ] Resting tweens smoothly (0.2s)
- [ ] Face-down shows card back only, zero text
- [ ] DON!! badge shows correct count
- [ ] Hover shows full detail panel
- [ ] Works for all 5 card types

---

### AGENT 6 — Cloud Run API + PostgreSQL Schema
**Wave:** 1 | **No dependencies**  
**Output:** ~400 lines Node.js + SQL

#### Responsibility
OPTCG backend API on Cloud Run. PostgreSQL schema. All endpoints the game client needs.

#### Inputs
- ARCHITECTURE.md — sections 5.2 and 5.3
- Existing GCP project: houseof-m-apps, Cloud SQL instance

#### Deliverables
```
api/
├── index.js
├── routes/auth.js
├── routes/decks.js
├── routes/matches.js
├── routes/license.js
├── middleware/auth.js          ← Firebase JWT validation
├── db/schema.sql
├── db/client.js
└── Dockerfile
```

#### Endpoints (exact paths)
```
POST   /api/auth/login              → { uid, token, display_name }
POST   /api/auth/register           → { uid, token }
GET    /api/decks/:uid              → Array[DeckDTO]
POST   /api/decks/:uid              → { deck_id }
DELETE /api/decks/:uid/:deck_id     → 204
POST   /api/matches/result          → { match_id }
GET    /api/matches/:uid/history    → Array[MatchDTO]
POST   /api/license/validate        → { valid: bool }
POST   /api/license/activate        → { success: bool }
```

#### PostgreSQL schema
```sql
CREATE TABLE players (
  uid           VARCHAR(128) PRIMARY KEY,
  display_name  VARCHAR(64)  NOT NULL,
  email         VARCHAR(256) NOT NULL,
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  last_login    TIMESTAMPTZ
);

CREATE TABLE decks (
  deck_id    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  uid        VARCHAR(128) REFERENCES players(uid),
  deck_name  VARCHAR(64)  NOT NULL,
  leader_id  VARCHAR(16)  NOT NULL,
  card_list  JSONB        NOT NULL,
  created_at TIMESTAMPTZ  DEFAULT NOW(),
  updated_at TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE matches (
  match_id      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  winner_uid    VARCHAR(128) REFERENCES players(uid),
  loser_uid     VARCHAR(128) REFERENCES players(uid),
  winner_leader VARCHAR(16)  NOT NULL,
  loser_leader  VARCHAR(16)  NOT NULL,
  turn_count    INT          NOT NULL,
  win_condition VARCHAR(32)  NOT NULL,
  played_at     TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE licenses (
  license_id  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  license_key VARCHAR(64)  UNIQUE NOT NULL,
  uid         VARCHAR(128) REFERENCES players(uid),
  order_id    VARCHAR(128) NOT NULL,
  activated_at TIMESTAMPTZ,
  hardware_id VARCHAR(256),
  created_at  TIMESTAMPTZ  DEFAULT NOW()
);
```

#### Definition of Done
- [ ] All 9 endpoints respond correctly
- [ ] Firebase JWT middleware rejects unauthenticated requests
- [ ] schema.sql applies cleanly to Cloud SQL instance
- [ ] Dockerfile builds and runs locally
- [ ] Deployed to Cloud Run, health check passes

---

### AGENT 7 — Firebase Auth + Player Accounts
**Wave:** 2 | **Depends on:** Agent 6  
**Output:** ~150 lines GDScript

#### Responsibility
Firebase Auth integration in the Godot client. Login, register, persistent session, auth token for API calls.

#### Inputs
- ARCHITECTURE.md — section 8.1
- Agent 6 — API endpoint contracts

#### Deliverables
```
scripts/net/AuthManager.gd
scenes/ui/LoginScreen.tscn
```

#### Required interface
```gdscript
signal login_complete(uid: String, display_name: String)
signal login_failed(error: String)
signal logout_complete()

func login(email: String, password: String) -> void
func register(email: String, password: String, display_name: String) -> void
func logout() -> void
func get_current_uid() -> String
func is_logged_in() -> bool
func get_auth_token() -> String
```

#### Definition of Done
- [ ] Login/register works end to end with Firebase project
- [ ] Auth token persisted in ConfigFile for auto-login on next launch
- [ ] Failed login shows user-visible error
- [ ] get_auth_token() returns JWT accepted by Agent 6 API

---

### AGENT 8 — Board UI Layout + Zones
**Wave:** 3 | **Depends on:** Agents 2 + 5  
**Output:** ~400 lines GDScript + scenes

#### Responsibility
Full game board scene tree. All zones rendered and functional. Phase indicator, power compare display, action log. Visual only — no game logic.

#### Inputs
- ARCHITECTURE.md — section 3.3 scene tree
- Agent 5 — CardView interface
- Agent 2 — GameState signals

#### Deliverables
```
scenes/game/GameBoard.tscn
scenes/zones/LeaderZone.tscn
scenes/zones/CharacterZone.tscn
scenes/zones/StageZone.tscn
scenes/zones/DonZone.tscn
scenes/zones/LifeZone.tscn
scenes/zones/HandZone.tscn
scenes/zones/TrashZone.tscn
scenes/ui/PhaseIndicator.tscn
scenes/ui/PowerCompare.tscn
scripts/ui/BoardView.gd
```

#### BoardView signals
```gdscript
signal card_clicked(card: CardInstance, zone: Zone)
signal end_turn_pressed()
signal zone_clicked(zone: Zone, player_idx: int)
```

#### Definition of Done
- [ ] Full board renders for both players
- [ ] Cards display in zones using CardView
- [ ] Phase indicator updates on TurnManager.phase_changed
- [ ] Power compare bar shows during battle
- [ ] Action log shows last 5 actions
- [ ] Hand cards visible to owning player only

---

### AGENT 9 — Deck Builder UI
**Wave:** 3 | **Depends on:** Agents 1 + 5 + 7  
**Output:** ~350 lines GDScript + scenes

#### Responsibility
Full deck builder. Browse/filter cards, add/remove, real-time rule validation, save/load via API.

#### Inputs
- Agent 1 — CardDatabase.gd
- Agent 5 — CardView
- Agent 7 — AuthManager (for API calls)
- PRD.md — section 5.5

#### Deliverables
```
scenes/ui/DeckBuilder.tscn
scripts/data/DeckData.gd
scripts/data/DeckValidator.gd
scripts/ui/DeckBuilderView.gd
```

#### DeckValidator rules
```gdscript
func validate(deck: DeckData) -> ValidationResult:
  # Rule 1: exactly 50 cards
  # Rule 2: exactly 1 Leader
  # Rule 3: max 4 copies per card_id
  # Rule 4: card colors must match Leader colors
  # Rule 5: no banned cards (BanList)
```

#### Definition of Done
- [ ] All 121 OP01 cards browsable
- [ ] Filter by color, type, cost, keyword works
- [ ] 5th copy of a card prevented with error
- [ ] Wrong color card prevented with error
- [ ] Live count shows e.g. "47/50"
- [ ] Save calls API, success confirmed
- [ ] Load retrieves saved decks from API

---

### AGENT 10 — AI Opponent
**Wave:** 4 | **Depends on:** Agents 2 + 4  
**Output:** ~400 lines GDScript

#### Responsibility
Three-tier AI (Easy/Medium/Hard). Full phase decision logic — plays, attacks, blocks, counters, Trigger activation.

#### Inputs
- ARCHITECTURE.md — AIOpponent.gd spec
- Agent 2 — GameState clone interface
- Agent 4 — BattleResolver signals

#### Deliverables
```
scripts/ai/AIOpponent.gd
```

#### Difficulty tiers
```
EASY (Greedy):
  Play: highest-cost affordable card
  Attack: always target Leader
  Block: never
  Counter: never
  Trigger: always activate

MEDIUM (Heuristic scoring):
  Play: score by (power * 0.001 + cost * 2.0 + keyword bonuses)
        Rush +6, Blocker +12, Double Attack +10
        -8 if field already at 5 chars
  Attack priority: kill rested chars > hit Leader at life <= 2 > hit Leader
  Block: block if life <= 2 OR Double Attack incoming at life <= 3
         OR Banish incoming at life <= 3
  Counter: use minimum needed to flip outcome; skip if cannot win
  Reserve 2 DON!! if has Counter Event and opponent has 6000+ attacker

HARD (MCTS-lite):
  Simulate top 20 action sequences
  Score: life_diff * 15 + board_power * 0.001 + hand_size * 8
  Pick highest score
  Re-evaluate each phase independently
```

#### Definition of Done
- [ ] Easy AI completes a full game without errors
- [ ] Medium AI makes logical attack target decisions
- [ ] Medium AI uses Blockers appropriately
- [ ] Hard AI never makes an illegal move
- [ ] All WEIGHTS exported as variables for tuning
- [ ] AI responds within 1 second (non-blocking — use CallDeferred or await)

---

### AGENT 11 — KeywordHandler + WinConditionChecker
**Wave:** 4 | **Depends on:** Agents 2 + 4  
**Output:** ~250 lines GDScript

#### Responsibility
Centralise all keyword processing. Implement every keyword per official rules. WinConditionChecker with exact loss trigger conditions per Comprehensive Rules v1.2.0.

#### Inputs
- CLAUDE.md — all 15 rules, especially rules 2, 4, 5, 7, 9, 12
- ARCHITECTURE.md — KeywordHandler and WinConditionChecker specs
- Agent 2 — GameState
- Agent 4 — BattleResolver

#### Deliverables
```
scripts/core/KeywordHandler.gd
scripts/core/WinConditionChecker.gd
```

#### KeywordHandler — critical implementations
```gdscript
func can_attack_this_turn(card: CardInstance) -> bool:
  # RUSH: return true regardless of turns_on_field
  # RUSH_CHARACTER: return true but only vs Characters (not Leader)
  # Standard: return turns_on_field > 0

func get_total_power(card: CardInstance) -> int:
  # = base_power + (attached_don * 1000) + perm_mods + temp_mods
  # ⚠️ NEVER clamp to 0 — per rule 1-3-6-1 power CAN be negative
  # Card stays on field even at negative power (rule 1-3-6-1-1)
  return base + don_bonus + perm_total + temp_total  # may be negative

func evaluate_trigger(card: CardInstance, player_idx: int) -> bool:
  # Per rule 2-11-1: Trigger activates INSTEAD of adding to hand
  # If player activates: enqueue trigger, card STILL goes to hand after
  # If player skips: card goes to hand, no Trigger
  # Returns true if activated

func process_blocker(card: CardInstance, attack: AttackEvent) -> bool:
  # Must be ACTIVE to block (check is_rested == false)
  # Rest the blocker
  # Redirect attack.target to blocker
  # Return false if card is rested (cannot block)
```

#### WinConditionChecker — exact per Comprehensive Rules v1.2.0
```gdscript
func check_damage_loss(player_idx: int) -> bool:
  # Called INSIDE DamageHandler BEFORE popping Life card
  # Per rule 1-2-1-1-1: loss triggered when Leader takes damage at 0 Life
  # Returns true if life_count == 0 at moment of damage
  # Nami (OP01-016): if this would be a loss, check if Nami condition instead

func check_deckout_loss(player_idx: int) -> bool:
  # Per rule 1-2-1-1-2: called at start of Draw Phase
  # Returns true if deck_size == 0
  # Nami (OP01-016) wins on own deck-out — return false for Nami, emit win

func get_winner_from_loser(loser_idx: int) -> int:
  return 1 - loser_idx  # opponent of the losing player wins
```

#### Definition of Done
- [ ] Rush card attacks on play turn; standard card cannot
- [ ] get_total_power() returns correct negative values
- [ ] Blocker fails silently if card is rested
- [ ] Trigger goes to hand after activation per rule 2-11-1
- [ ] Nami deck-out win condition fires correctly
- [ ] Standard deck-out loss fires correctly
- [ ] Damage loss fires inside damage processing not as passive check
- [ ] All 15 CLAUDE.md rules verified by manual test cases

---

### AGENT 12 — Online Multiplayer + GameServer
**Wave:** 4 | **Depends on:** Agents 4 + 7  
**Output:** ~350 lines GDScript

#### Responsibility
Steam P2P multiplayer via GodotSteam. Host-authoritative RPC handlers. State sync. Lobby creation and joining. Disconnect handling.

#### Inputs
- ARCHITECTURE.md — section 4 (full multiplayer spec)
- Agent 2 — GameState
- Agent 4 — BattleResolver signals
- Agent 7 — AuthManager.get_auth_token()

#### Deliverables
```
scripts/net/GameServer.gd
scripts/net/SteamLobby.gd
```

#### Information hiding — MANDATORY
```
NEVER send opponent hand card IDs to enemy client
NEVER trust client power calculations — always server-computed
Life cards: reveal to both only at moment of damage
Hand count: broadcast count only, never IDs
```

#### RPC methods required
```gdscript
# Client → Host (any_peer, reliable)
request_play_card(card_id: String, zone_index: int)
request_attack(attacker_id: String, target_id: String)
respond_block(blocker_id: String)      # empty = no block
respond_counter(card_ids: Array, event_id: String)
respond_trigger(activate: bool)
request_end_turn()

# Host → All (authority, reliable)
broadcast_play_card(player_idx: int, card_id: String, zone_index: int)
broadcast_attack(attacker_id: String, target_id: String)
broadcast_damage(player_idx: int, card_id: String, banished: bool)
broadcast_phase_change(new_phase: int)
broadcast_game_over(winner_idx: int)
```

#### Definition of Done
- [ ] Two clients create and join Steam lobby successfully
- [ ] Full game plays to completion without desync
- [ ] Host disconnect triggers client reconnect flow
- [ ] Client disconnect: 60s forfeit timer on host
- [ ] Opponent hand size correct, card IDs never exposed
- [ ] Turn timer broadcasts countdown to both clients

---

### AGENT 13 — Integration + Full Game Loop + Polish
**Wave:** 5 | **Depends on:** All prior agents  
**Output:** ~300 lines GDScript + scene wiring

#### Responsibility
Wire all modules together. Full game loop from main menu to match completion. Tutorial. Win/lose screen. Performance pass.

#### Inputs
- All prior deliverables
- PRD.md — sections 5, 11, 13

#### Deliverables
```
scenes/game/GameManager.tscn
scenes/ui/MainMenu.tscn
scenes/ui/WinLoseScreen.tscn
scenes/ui/TutorialOverlay.tscn
scripts/core/GameManager.gd
```

#### Integration checklist
- [ ] Main menu → deck select → game start → full match → result → menu
- [ ] vs AI (all 3 difficulties) — no errors
- [ ] Local PvP hot-seat — no errors
- [ ] Online PvP — full match completion
- [ ] Tutorial — all 5 teaching steps complete
- [ ] All 10 Steam achievements trigger correctly
- [ ] Startup time < 5 seconds (PRD target)
- [ ] 60 fps on GTX 1060 equivalent hardware
- [ ] Zero GDScript errors on full playthrough in debugger

---

## Interface Contracts (must be honoured exactly)

| Provider | Consumers | Contract |
|---|---|---|
| Agent 1 | All | CardData enums, JSON schema, CardDatabase public methods |
| Agent 2 | 3,4,8,10,11,12 | GameState fields + all public method signatures |
| Agent 3 | 4,8,13 | Signals: phase_changed, turn_ended, game_over, draw_required |
| Agent 4 | 10,11,12,13 | Signals: battle_complete; EffectQueue.all_resolved |
| Agent 5 | 8,9 | CardView.set_state(), load_card(), scene node names |
| Agent 6 | 7,9 | REST endpoint paths + response shapes |
| Agent 7 | 9,12,13 | get_auth_token(), is_logged_in() |
| Agent 11 | 4,10,13 | get_total_power(), check_damage_loss(), evaluate_trigger() |

---

## Open Questions (must be answered before Wave 1 starts)

1. **Art assets:** Placeholder coloured rectangles for the build phase, or real OP01 art?
2. **Godot version:** Exact 4.x minor version to lock — recommend latest stable
3. **GodotSteam:** Which release — check godotsteam.com for Godot 4 compatible build
4. **Firebase project:** New project or use existing houseof-m-apps?
5. **Cloud Run region:** us-central1 to match existing n8n instance?

---

*End of AGENTS.md*
