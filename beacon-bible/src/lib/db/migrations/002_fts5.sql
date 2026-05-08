-- Migration 002: FTS5 search index + concordance

CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts USING fts5(
    text_plain,
    content='verses',
    content_rowid='id',
    tokenize='porter unicode61 remove_diacritics 1'
);

CREATE TRIGGER IF NOT EXISTS verses_ai AFTER INSERT ON verses BEGIN
    INSERT INTO verses_fts(rowid, text_plain) VALUES (new.id, new.text_plain);
END;

CREATE TRIGGER IF NOT EXISTS verses_ad AFTER DELETE ON verses BEGIN
    INSERT INTO verses_fts(verses_fts, rowid, text_plain)
    VALUES ('delete', old.id, old.text_plain);
END;

CREATE TRIGGER IF NOT EXISTS verses_au AFTER UPDATE ON verses BEGIN
    INSERT INTO verses_fts(verses_fts, rowid, text_plain)
    VALUES ('delete', old.id, old.text_plain);
    INSERT INTO verses_fts(rowid, text_plain) VALUES (new.id, new.text_plain);
END;

-- Concordance: unique words per translation with Strong's numbers where available

CREATE TABLE IF NOT EXISTS concordance (
    id                  INTEGER PRIMARY KEY,
    translation_id      TEXT NOT NULL REFERENCES translations(id) ON DELETE CASCADE,
    word                TEXT NOT NULL,
    word_normalized     TEXT NOT NULL,
    occurrence_count    INTEGER NOT NULL DEFAULT 0,
    strongs_number      TEXT,
    UNIQUE(translation_id, word_normalized)
);
CREATE INDEX IF NOT EXISTS idx_concordance_word ON concordance(word_normalized);
CREATE INDEX IF NOT EXISTS idx_concordance_strongs ON concordance(strongs_number);

CREATE TABLE IF NOT EXISTS word_occurrences (
    id                  INTEGER PRIMARY KEY,
    concordance_id      INTEGER NOT NULL REFERENCES concordance(id),
    verse_id            INTEGER NOT NULL REFERENCES verses(id),
    position            INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_word_occ_concordance ON word_occurrences(concordance_id);
CREATE INDEX IF NOT EXISTS idx_word_occ_verse ON word_occurrences(verse_id);

INSERT OR IGNORE INTO schema_migrations(version) VALUES (2);
