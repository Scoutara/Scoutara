-- ── SCOUTARA Trial Keys Table ──────────────────────────────────────────────
-- Run this in your Supabase SQL Editor BEFORE going live
-- Project: https://rfnxevgbxxtazyjsyvpv.supabase.co

-- Drop old table if it exists from a previous version
DROP TABLE IF EXISTS demo_trials;

-- Create the trial tracking table
CREATE TABLE demo_trials (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email       text UNIQUE NOT NULL,
  trial_key   text NOT NULL,
  first_login timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Allow public read/write (trial auth happens in app, not via Supabase RLS)
ALTER TABLE demo_trials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read trial records"
  ON demo_trials FOR SELECT USING (true);

CREATE POLICY "Public insert trial records"
  ON demo_trials FOR INSERT WITH CHECK (true);

-- Indexes for fast lookups
CREATE INDEX demo_trials_email_idx ON demo_trials (email);
CREATE INDEX demo_trials_key_idx   ON demo_trials (trial_key);

-- DONE
-- Each trial key can only be used ONCE (enforced in app).
-- first_login is set the moment a club activates their key.
-- Trial expires exactly 14 days after first_login.
-- All player data persists — clubs keep everything when they subscribe.
