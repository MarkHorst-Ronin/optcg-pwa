-- schema.sql — OPTCG PostgreSQL schema
-- Agent 6 owns this file.
-- Apply to Cloud SQL instance: houseof-m-apps, us-central1
-- Run: psql -h <host> -U postgres -d optcg -f schema.sql

CREATE DATABASE optcg;
\c optcg;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Players ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS players (
  uid           VARCHAR(128) PRIMARY KEY,
  display_name  VARCHAR(64)  NOT NULL,
  email         VARCHAR(256) NOT NULL UNIQUE,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  last_login    TIMESTAMPTZ
);

-- ── Decks ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS decks (
  deck_id    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  uid        VARCHAR(128) NOT NULL REFERENCES players(uid) ON DELETE CASCADE,
  deck_name  VARCHAR(64)  NOT NULL,
  leader_id  VARCHAR(16)  NOT NULL,
  card_list  JSONB        NOT NULL,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_decks_uid ON decks(uid);

-- ── Matches ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matches (
  match_id      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  winner_uid    VARCHAR(128) REFERENCES players(uid),
  loser_uid     VARCHAR(128) REFERENCES players(uid),
  winner_leader VARCHAR(16)  NOT NULL,
  loser_leader  VARCHAR(16)  NOT NULL,
  turn_count    INT          NOT NULL CHECK (turn_count > 0),
  win_condition VARCHAR(32)  NOT NULL CHECK (win_condition IN ('KO','DECK_OUT','NAMI','CONCEDE')),
  played_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_matches_winner ON matches(winner_uid);
CREATE INDEX IF NOT EXISTS idx_matches_loser  ON matches(loser_uid);

-- ── Licenses ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS licenses (
  license_id   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  license_key  VARCHAR(64)  NOT NULL UNIQUE,
  uid          VARCHAR(128) REFERENCES players(uid),
  order_id     VARCHAR(128) NOT NULL,
  activated_at TIMESTAMPTZ,
  hardware_id  VARCHAR(256),
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_licenses_key ON licenses(license_key);
CREATE INDEX IF NOT EXISTS idx_licenses_uid ON licenses(uid);
