-- Migration 004: Cross-reference network (Treasury of Scripture Knowledge dataset)

CREATE TABLE IF NOT EXISTS cross_references (
    id                      INTEGER PRIMARY KEY,
    source_verse_book       TEXT NOT NULL,
    source_verse_chapter    INTEGER NOT NULL,
    source_verse_number     INTEGER NOT NULL,
    target_verse_book       TEXT NOT NULL,
    target_verse_chapter    INTEGER NOT NULL,
    target_verse_number     INTEGER NOT NULL,
    ref_type                TEXT NOT NULL DEFAULT 'parallel',
    strength                INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_xref_source ON cross_references(
    source_verse_book, source_verse_chapter, source_verse_number
);
CREATE INDEX IF NOT EXISTS idx_xref_target ON cross_references(
    target_verse_book, target_verse_chapter, target_verse_number
);

INSERT OR IGNORE INTO schema_migrations(version) VALUES (4);
