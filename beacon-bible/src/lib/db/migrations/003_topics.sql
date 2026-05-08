-- Migration 003: Topic taxonomy + reading plans + entity index

CREATE TABLE IF NOT EXISTS topic_categories (
    id                  INTEGER PRIMARY KEY,
    slug                TEXT NOT NULL UNIQUE,
    display_name        TEXT NOT NULL,
    icon_name           TEXT,
    sort_order          INTEGER NOT NULL DEFAULT 0,
    parent_id           INTEGER REFERENCES topic_categories(id)
);

CREATE TABLE IF NOT EXISTS topic_verses (
    topic_id            INTEGER NOT NULL REFERENCES topic_categories(id),
    verse_id            INTEGER NOT NULL REFERENCES verses(id),
    relevance_score     REAL NOT NULL DEFAULT 1.0,
    PRIMARY KEY(topic_id, verse_id)
);
CREATE INDEX IF NOT EXISTS idx_topic_verses_topic ON topic_verses(topic_id);
CREATE INDEX IF NOT EXISTS idx_topic_verses_verse ON topic_verses(verse_id);

CREATE TABLE IF NOT EXISTS intent_mappings (
    id                  INTEGER PRIMARY KEY,
    trigger_phrase      TEXT NOT NULL,
    topic_slug          TEXT NOT NULL REFERENCES topic_categories(slug),
    confidence          REAL NOT NULL DEFAULT 1.0
);
CREATE INDEX IF NOT EXISTS idx_intent_trigger ON intent_mappings(trigger_phrase);

CREATE TABLE IF NOT EXISTS misquotes (
    id                  INTEGER PRIMARY KEY,
    misquoted_text      TEXT NOT NULL,
    misquoted_text_normalized TEXT NOT NULL,
    actual_verse_id     INTEGER REFERENCES verses(id),
    actual_text         TEXT NOT NULL,
    explanation         TEXT
);

-- Reading plans

CREATE TABLE IF NOT EXISTS reading_plans (
    id                  INTEGER PRIMARY KEY,
    external_id         TEXT UNIQUE,
    title               TEXT NOT NULL,
    description         TEXT,
    duration_days       INTEGER NOT NULL,
    author              TEXT,
    is_curated          INTEGER NOT NULL DEFAULT 0,
    is_user_created     INTEGER NOT NULL DEFAULT 0,
    tags                TEXT DEFAULT '[]',
    created_at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE TABLE IF NOT EXISTS plan_days (
    id                  INTEGER PRIMARY KEY,
    plan_id             INTEGER NOT NULL REFERENCES reading_plans(id) ON DELETE CASCADE,
    day_number          INTEGER NOT NULL,
    title               TEXT,
    readings            TEXT NOT NULL DEFAULT '[]',
    reflection_prompt   TEXT,
    UNIQUE(plan_id, day_number)
);
CREATE INDEX IF NOT EXISTS idx_plan_days_plan ON plan_days(plan_id);

CREATE TABLE IF NOT EXISTS user_plan_progress (
    id                  INTEGER PRIMARY KEY,
    plan_id             INTEGER NOT NULL REFERENCES reading_plans(id) ON DELETE CASCADE,
    day_number          INTEGER NOT NULL,
    completed_at        INTEGER,
    UNIQUE(plan_id, day_number)
);
CREATE INDEX IF NOT EXISTS idx_progress_plan ON user_plan_progress(plan_id);

-- Named entity index (persons, places, events)

CREATE TABLE IF NOT EXISTS entities (
    id                  INTEGER PRIMARY KEY,
    name                TEXT NOT NULL,
    entity_type         TEXT NOT NULL,
    description         TEXT,
    first_mention_book  TEXT,
    UNIQUE(name, entity_type)
);
CREATE INDEX IF NOT EXISTS idx_entities_type ON entities(entity_type);
CREATE INDEX IF NOT EXISTS idx_entities_name ON entities(name);

CREATE TABLE IF NOT EXISTS entity_verses (
    entity_id           INTEGER NOT NULL REFERENCES entities(id),
    verse_id            INTEGER NOT NULL REFERENCES verses(id),
    PRIMARY KEY(entity_id, verse_id)
);
CREATE INDEX IF NOT EXISTS idx_entity_verses_entity ON entity_verses(entity_id);

INSERT OR IGNORE INTO schema_migrations(version) VALUES (3);
