# ARCHITECTURE.md — OPTCG Technical Architecture
**Version:** 1.0  
**Owner:** Logan H (VaultAutomation)  
**Last Updated:** April 2026

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GODOT 4 CLIENT                          │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ CardDatabase│  │  GameState   │  │   TurnManager    │  │
│  │  (autoload) │  │  (autoload)  │  │  (state machine) │  │
│  └──────┬──────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                │                    │            │
│  ┌──────▼──────────────────────────────────────▼─────────┐  │
│  │              BattleResolver + EffectQueue             │  │
│  └───────────────────────────────────────────────────────┘  │
│         │                │                    │            │
│  ┌──────▼──────┐  ┌───────▼──────┐  ┌────────▼─────────┐  │
│  │ Board UI    │  │ AI Opponent  │  │ GameServer (net)  │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
│                                              │             │
└──────────────────────────────────────────────┼─────────────┘
                                               │ Steam P2P
┌──────────────────────────────────────────────▼─────────────┐
│                    GCP BACKEND                              │
│                                                             │
│  ┌─────────────────┐       ┌──────────────────────────┐   │
│  │  Cloud Run API  │       │  Cloud SQL (PostgreSQL)  │   │
│  │  (OPTCG API)    │◄─────►│  - players               │   │
│  │  /api/auth      │       │  - decks                 │   │
│  │  /api/decks     │       │  - matches               │   │
│  │  /api/matches   │       │  - licenses              │   │
│  └────────┬────────┘       └──────────────────────────┘   │
│           │                                                 │
│  ┌────────▼────────┐       ┌──────────────────────────┐   │
│  │  Firebase Auth  │       │  Google Cloud Storage    │   │
│  │  (player login) │       │  (game installers)       │   │
│  └─────────────────┘       └──────────────────────────┘   │
│                                                             │
│  ┌─────────────────┐       ┌──────────────────────────┐   │
│  │  Cloudflare     │       │  Airtable + n8n          │   │
│  │  Workers (CDN)  │       │  (purchases + licenses)  │   │
│  └─────────────────┘       └──────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Data Architecture

### 2.1 Data Residency Rules

| Data | Where It Lives | Why |
|---|---|---|
| Card definitions | JSON bundled with client | Never changes mid-session. Instant load. Works offline. |
| Active match state | Godot memory (RAM) | Too fast-changing for DB. Never persisted mid-match. |
| Player accounts | Cloud SQL PostgreSQL | Server-side auth required for multiplayer. |
| Saved decks | Cloud SQL PostgreSQL | Must persist across devices/sessions. |
| Match history | Cloud SQL PostgreSQL | Analytics, replay (future), leaderboard (future). |
| Purchase records | Airtable (existing) | Already built into n8n Paystack pipeline. |
| License keys | Airtable (existing) | Tied to existing purchase workflow. |
| Local settings | Godot ConfigFile (local) | No server needed. Per-device preferences. |
| Offline deck cache | SQLite (local) | Deck builder works without internet. Synced on login. |
| Game installer | Google Cloud Storage | Signed URL delivery post-purchase. |

### 2.2 What NEVER Goes To The Database Mid-Match

- Player hand contents
- Live power values
- Current phase
- Attack declarations
- DON!! attachment states

All of the above live in `GameState` autoload in Godot memory. At match end, only the result (winner, loser, leaders used, turn count) is written to Cloud SQL.

---

## 3. Godot Client Architecture

### 3.1 Autoloads (Singletons)

#### GameState.gd
The single source of truth for all live game data during a match.

```
Responsibilities:
- All zone contents (leaders, characters, stages, hands, decks, life, trash, don)
- Active player index
- Turn number
- Phase tracking
- All move/card operations (move_card, send_to_trash, add_to_hand, etc.)
- Clone method for AI simulation

Does NOT:
- Make API calls
- Validate rules (that's TurnManager / BattleResolver's job)
- Render anything (that's BoardView's job)
```

#### CardDatabase.gd
Loaded once on startup. Immutable during gameplay.

```
Responsibilities:
- Parse all JSON files in data/cards/
- Store cards in Dictionary: card_id -> CardData
- Provide search/filter methods
- Provide get_card(card_id) -> CardData

Does NOT:
- Make API calls at runtime
- Change after startup
```

#### GameConfig.gd
Constants and player settings.

```
Constants:
- MAX_CHARACTERS_ON_FIELD = 5
- DON_PER_TURN = 2
- DON_FIRST_PLAYER_TURN1 = 1
- STARTING_HAND_SIZE = 5
- MAX_COPIES_PER_DECK = 4
- DECK_SIZE = 50
- DON_DECK_SIZE = 10

Settings (loaded from ConfigFile):
- animation_speed
- card_text_size
- colorblind_mode
- turn_timer_seconds
```

### 3.2 Core Scripts

#### TurnManager.gd
State machine managing the 5-phase turn structure.

```
States: REFRESH → DRAW → DON → MAIN → END
Signals: phase_changed(Phase), turn_ended(int), game_over(int)
Key rules enforced:
- First player skips draw on turn 1
- First player gets 1 DON!! on turn 1 (not 2)
- Neither player can attack on turn 1
- Characters cannot attack turn they are played (unless Rush)

REFRESH PHASE — exact order per official Rule Manual v1.11:
  1. Set ALL rested cards as active (Leader, Characters, Stages, cost DON!!)
  2. Return all attached DON!! cards to cost area AS ACTIVE (not rested)
  ⚠️ CRITICAL: DON!! that return from attached cards come back ACTIVE.
  They are immediately available on the next turn.
  Exception: DON!! removed mid-turn from a KO/bounced card return RESTED.

END PHASE — exact 4-step order per Rule Manual v1.11:
  1. Turn player's [End of Your Turn] effects activate and resolve
  2. Non-turn player's [End of Your Turn] effects activate and resolve
  3. Turn player's "during this turn" effects are cancelled
  4. Non-turn player's "during this turn" effects are cancelled
  5. Turn ends, opponent's turn begins
```

#### BattleResolver.gd
The 4-step combat sequence.

```
Steps: ATTACK_DECLARATION → BLOCK_STEP → COUNTER_STEP → DAMAGE_STEP
Key rules enforced:
- Attacker rests on declaration (cannot add DON!! after)
- Only rested Characters can be targeted
- Ties go to attacker
- Block Step: only 1 Blocker per battle
- Counter Step: from hand only, any number
- Power comparison is: attacker >= defender (tie = attacker wins)
Async: awaits player input at Block Step and Counter Step
```

#### EffectQueue.gd
FIFO async effect resolver. Critical for correct Trigger sequencing.

```
- All effects pushed to queue and resolved in order
- Each effect awaits player input if needed
- Source card leaving the field cancels its queued effects
  (unless effect.independent = true)
- Double Attack: hit 1 Trigger resolves → queue drains → hit 2 applied
```

#### DamageHandler.gd
Life card reveal and Trigger processing.

```
Per Comprehensive Rules 4-6-2 and 1-2-1-1-1:

- Handles 1 damage (standard) and 2 damage (Double Attack)
- If damage value is 0, nothing happens (rule 4-6-2-2)
- Banish path: trash Life card, Trigger NOT activated, card NOT added to hand
- Standard path: move top Life card to hand; if [Trigger] present, player may
  activate it INSTEAD of adding to hand (rule 2-11-1)
- Double Attack: sequential — hit 1 fully resolves including Trigger before hit 2
- WIN CONDITION CHECK: loss is triggered by taking damage WITH 0 Life cards
  remaining (rule 1-2-1-1-1). Check inside damage loop, not as a separate state.
  Exact check: if life_count == 0 BEFORE popping Life card → player loses.
  ⚠️ Do NOT check life_count == 0 as a passive state outside damage processing.
```

#### KeywordHandler.gd
Centralized keyword logic.

```
can_attack_this_turn(card) -> bool       # Rush / turns_on_field check
process_blocker(card, attack) -> void    # Redirect + rest blocker
check_don_threshold(card) -> void        # DON!! ×N permanent check
process_trigger(card, player) -> bool   # Reveal + optional activate
get_total_power(card) -> int             # MAY return negative value — do not clamp to 0
                                         # Per rule 1-3-6-1: power can be negative
                                         # Card stays on field unless effect says otherwise
```

#### WinConditionChecker.gd
Called inside DamageHandler during each damage step, and on Draw Phase.

```
Per Comprehensive Rules 1-2-1-1:

Win condition 1 — KO (checked INSIDE DamageHandler during damage loop):
  → Player loses when their Leader takes damage AND life_count == 0 at that moment
  → NOT triggered by life reaching 0 passively — only triggered by the damage event
  → Nami exception: if Nami leader (OP01-016) deck-out occurs, Nami WINS

Win condition 2 — Deck-Out (checked at start of Draw Phase):
  → Player loses if deck_size == 0 when required to draw
  → Nami (OP01-016): wins when HER OWN deck empties
  → All other leaders: deck-out = loss

Both conditions: when met, loss is registered at the next rule processing point
(rule 1-2-2). Do not interrupt mid-effect — let current effect finish first.

Returns: winner_player_idx (int) or null
```

### 3.3 Scene Tree

```
GameBoard (Node2D)
├── BackgroundLayer (CanvasLayer layer=-1)
│
├── Player2Side (Control, top half)
│   ├── P2_LeaderZone
│   ├── P2_CharacterZone (5 slots)
│   ├── P2_StageZone
│   ├── P2_LifeZone
│   ├── P2_HandZone
│   └── P2_DonZone (cost area + deck)
│
├── BattleArena (Control, center)
│   ├── PowerDisplay
│   ├── PhaseIndicator
│   └── ActionLog
│
├── Player1Side (Control, bottom half)
│   └── [mirror of P2]
│
├── TrashZones (left/right edges)
│
└── UILayer (CanvasLayer layer=10)
    ├── TriggerPrompt
    ├── BlockerPrompt
    ├── CounterPhaseUI
    ├── SelectionPrompt
    ├── HandExpand
    └── EndTurnButton
```

---

## 4. Multiplayer Architecture

### 4.1 Network Model
- **Transport:** Steam P2P via GodotSteam SteamMultiplayerPeer
- **Authority:** Host is server. All game logic runs on host. Client sends intentions.
- **Client trust:** Zero. Every client action is validated server-side before applying.

### 4.2 RPC Flow

```
Client action → GameServer.request_*(card_id, ...) RPC
             → Host validates (phase, ownership, DON!! cost, etc.)
             → Host applies to GameState
             → Host broadcasts _broadcast_*() RPC to all peers
             → All clients update BoardView
```

### 4.3 Information Hiding

| Data | Sent to opponent? |
|---|---|
| Your hand card IDs | NEVER |
| Your hand count | YES (count only) |
| Card played to field | YES (card_id at moment of play) |
| Life card contents | ONLY at moment of damage reveal |
| DON!! count | YES |
| Power values | YES (calculated server-side) |

### 4.4 Sync Events

All state changes broadcast as typed sync events:
```
CARD_PLAYED, CARD_RESTED, CARD_UNRESTED, DON_ATTACHED,
DON_RETURNED, LIFE_REVEALED, CARD_TRASHED, CARD_BOUNCED,
POWER_MOD_APPLIED, HAND_COUNT_CHANGED, TURN_CHANGED,
PHASE_CHANGED, GAME_OVER
```

---

## 5. Backend API Architecture

### 5.1 Cloud Run Service: OPTCG API

Separate Cloud Run service from the existing n8n instance.  
Base URL: `https://optcg-api-[hash].us-central1.run.app`  
Proxied via Cloudflare Workers at: `https://api.optcg.yourdomain.com`

### 5.2 Endpoints

```
POST   /api/auth/login              → { uid, token, display_name }
POST   /api/auth/register           → { uid, token }

GET    /api/decks/{uid}             → Array[DeckDTO]
POST   /api/decks/{uid}             → { deck_id } (save/update deck)
DELETE /api/decks/{uid}/{deck_id}   → 204

POST   /api/matches/result          → { match_id } (save match result)
GET    /api/matches/{uid}/history   → Array[MatchDTO] (last 50)

POST   /api/license/validate        → { valid: bool, uid: String }
GET    /api/license/activate        → { success: bool }
```

### 5.3 PostgreSQL Schema

```sql
-- Players
CREATE TABLE players (
  uid           VARCHAR(128) PRIMARY KEY,  -- Firebase UID
  display_name  VARCHAR(64)  NOT NULL,
  email         VARCHAR(256) NOT NULL,
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  last_login    TIMESTAMPTZ
);

-- Decks
CREATE TABLE decks (
  deck_id       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  uid           VARCHAR(128) REFERENCES players(uid),
  deck_name     VARCHAR(64)  NOT NULL,
  leader_id     VARCHAR(16)  NOT NULL,
  card_list     JSONB        NOT NULL,    -- Array of {card_id, count}
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  DEFAULT NOW()
);

-- Matches
CREATE TABLE matches (
  match_id      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  winner_uid    VARCHAR(128) REFERENCES players(uid),
  loser_uid     VARCHAR(128) REFERENCES players(uid),
  winner_leader VARCHAR(16)  NOT NULL,
  loser_leader  VARCHAR(16)  NOT NULL,
  turn_count    INT          NOT NULL,
  win_condition VARCHAR(32)  NOT NULL,   -- 'KO', 'DECK_OUT', 'NAMI'
  played_at     TIMESTAMPTZ  DEFAULT NOW()
);

-- Licenses
CREATE TABLE licenses (
  license_id    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  license_key   VARCHAR(64)  UNIQUE NOT NULL,
  uid           VARCHAR(128) REFERENCES players(uid),
  order_id      VARCHAR(128) NOT NULL,   -- Paystack order reference
  activated_at  TIMESTAMPTZ,
  hardware_id   VARCHAR(256),
  created_at    TIMESTAMPTZ  DEFAULT NOW()
);
```

---

## 6. Card Data Architecture

### 6.1 File Structure

```
data/cards/
├── OP01.json    (121 cards — Romance Dawn)
├── OP02.json    (future)
└── ...
```

### 6.2 JSON Schema

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

### 6.3 Effect Types Supported

```
DRAW, SEARCH, DISCARD, BOUNCE, TRASH,
POWER_MOD, COST_REDUCE, REST_TARGET, UNREST,
ADD_LIFE, REMOVE_LIFE, LOOK_LIFE, REORDER_LIFE,
BANISH_TARGET, PLAY_FROM_TRASH, GIVE_DON,
CANNOT_ATTACK, CANNOT_BE_KOD
```

### 6.4 Effect Timing Values

```
ON_PLAY, ON_KO, WHEN_ATTACKING, WHEN_ATTACKED,
MAIN, ACTIVATE, END_OF_TURN, END_OPP_TURN,
TRIGGER, COUNTER, DON_X, PERMANENT
```

---

## 7. Anti-Piracy Architecture

### 7.1 License Key Flow
```
1. Player purchases on Steam or website (Paystack)
2. n8n webhook generates UUID license key
3. Key stored in Airtable + Cloud SQL licenses table
4. Key emailed to player
5. On first game launch: player enters key
6. Client calls POST /api/license/activate with key + hardware_id
7. API validates key, stores hardware_id, marks activated
8. Client stores activation token locally (ConfigFile)
9. On subsequent launches: token checked locally (offline play works)
10. Online multiplayer: token re-validated against API on match start
```

### 7.2 DRM Strength
- Single-player: soft DRM (local token). Bypassable but not worth the effort for a $14.99 game.
- Multiplayer: hard requirement. Cannot play online without valid server-side auth.
- Hardware binding: optional enforcement (can allow 2 activations per key for device replacement)

---

## 8. Performance Architecture

### 8.1 Startup Sequence
```
1. Godot launches
2. GameConfig.gd loads settings from ConfigFile
3. CardDatabase.gd loads all JSON files → Dictionary in memory (< 1 second)
4. Main menu displayed
5. Player logs in (Firebase Auth call) — async, non-blocking
6. Decks loaded from API — async, non-blocking
```

### 8.2 Memory Budget
- 121 cards × ~2KB per CardData resource ≈ 250KB for full card database
- Active match: ~50 CardInstance objects in memory ≈ negligible
- UI textures: largest cost. Keep card art as compressed WebP, max 512×512 per card.

### 8.3 Target Hardware
- Minimum: GTX 1060 / 8GB RAM / SSD
- Recommended: GTX 1660 / 16GB RAM / SSD
- Steam Deck: must pass Steam Deck Verified review

---

## 9. Deployment Pipeline

### 9.1 Game Client
```
Godot 4 Export → Windows .exe / Linux / macOS
             → Upload to GCS (game-installers bucket)
             → Signed URL generated on purchase
             → Also submitted to Steam via Steamworks SDK
```

### 9.2 Backend API
```
Cloud Run service: optcg-api
Region: us-central1 (same as existing n8n instance)
Min instances: 1 (always warm — critical for multiplayer auth)
Max instances: 10
Memory: 512MB
Trigger: HTTP
Auth: Firebase Auth JWT validation on all protected endpoints
```

---

## 10. Technology Versions

| Technology | Version |
|---|---|
| Godot | 4.x (latest stable) |
| GDScript | Godot 4 syntax |
| GodotSteam | Latest stable extension |
| PostgreSQL | 14+ (existing Cloud SQL instance) |
| Cloud Run | gen2 |
| Firebase Auth | v9+ SDK |
| Node.js (API) | 20 LTS |
| Cloudflare Workers | Current |

---

*End of ARCHITECTURE.md*
