-- Migration 001: Bible content tables
-- WAL mode is enabled at connection open before running migrations

CREATE TABLE IF NOT EXISTS translations (
    id                  TEXT PRIMARY KEY,
    abbreviation        TEXT NOT NULL,
    name                TEXT NOT NULL,
    language_code       TEXT NOT NULL,
    language_name       TEXT NOT NULL,
    is_downloaded       INTEGER NOT NULL DEFAULT 0,
    download_size_bytes INTEGER,
    downloaded_at       INTEGER,
    api_source          TEXT NOT NULL DEFAULT 'api_bible',
    copyright           TEXT,
    created_at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_translations_language ON translations(language_code);

CREATE TABLE IF NOT EXISTS books (
    id                  INTEGER PRIMARY KEY,
    translation_id      TEXT NOT NULL REFERENCES translations(id) ON DELETE CASCADE,
    book_code           TEXT NOT NULL,
    book_number         INTEGER NOT NULL,
    name                TEXT NOT NULL,
    short_name          TEXT NOT NULL,
    chapter_count       INTEGER NOT NULL,
    UNIQUE(translation_id, book_code)
);
CREATE INDEX IF NOT EXISTS idx_books_translation ON books(translation_id);

CREATE TABLE IF NOT EXISTS chapters (
    id                  INTEGER PRIMARY KEY,
    book_id             INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    chapter_number      INTEGER NOT NULL,
    verse_count         INTEGER NOT NULL DEFAULT 0,
    UNIQUE(book_id, chapter_number)
);
CREATE INDEX IF NOT EXISTS idx_chapters_book ON chapters(book_id);

CREATE TABLE IF NOT EXISTS verses (
    id                  INTEGER PRIMARY KEY,
    chapter_id          INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
    verse_number        INTEGER NOT NULL,
    text                TEXT NOT NULL,
    text_plain          TEXT NOT NULL,
    has_footnote        INTEGER NOT NULL DEFAULT 0,
    footnote_text       TEXT,
    UNIQUE(chapter_id, verse_number)
);
CREATE INDEX IF NOT EXISTS idx_verses_chapter ON verses(chapter_id);

-- User annotation tables

CREATE TABLE IF NOT EXISTS highlights (
    id                  INTEGER PRIMARY KEY,
    verse_id            INTEGER NOT NULL REFERENCES verses(id),
    color               TEXT NOT NULL DEFAULT '#FCD34D',
    created_at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_highlights_verse ON highlights(verse_id);

CREATE TABLE IF NOT EXISTS bookmarks (
    id                  INTEGER PRIMARY KEY,
    verse_id            INTEGER NOT NULL REFERENCES verses(id) UNIQUE,
    label               TEXT,
    created_at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE TABLE IF NOT EXISTS notes (
    id                  INTEGER PRIMARY KEY,
    verse_id            INTEGER NOT NULL REFERENCES verses(id),
    body                TEXT NOT NULL,
    created_at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_notes_verse ON notes(verse_id);

-- Audio downloads tracking

CREATE TABLE IF NOT EXISTS audio_downloads (
    id                  INTEGER PRIMARY KEY,
    translation_id      TEXT NOT NULL,
    book_code           TEXT NOT NULL,
    chapter_number      INTEGER NOT NULL,
    file_path           TEXT NOT NULL,
    file_size_bytes     INTEGER,
    bitrate             TEXT,
    downloaded_at       INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    UNIQUE(translation_id, book_code, chapter_number)
);
CREATE INDEX IF NOT EXISTS idx_audio_dl_translation ON audio_downloads(translation_id);

-- Reading sessions for milestone/streak tracking (no server sync)

CREATE TABLE IF NOT EXISTS reading_sessions (
    id                  INTEGER PRIMARY KEY,
    date                TEXT NOT NULL UNIQUE,
    chapters_read       INTEGER NOT NULL DEFAULT 0,
    minutes_spent       INTEGER NOT NULL DEFAULT 0
);

-- Donation milestone tracking (no PII, no payment data)

CREATE TABLE IF NOT EXISTS donation_milestones (
    id                  INTEGER PRIMARY KEY,
    milestone_type      TEXT NOT NULL,
    milestone_value     INTEGER NOT NULL,
    triggered_at        INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    prompt_shown        INTEGER NOT NULL DEFAULT 0,
    prompt_dismissed    INTEGER NOT NULL DEFAULT 0,
    donated             INTEGER NOT NULL DEFAULT 0
);

-- Schema version tracking

CREATE TABLE IF NOT EXISTS schema_migrations (
    version     INTEGER PRIMARY KEY,
    applied_at  INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
INSERT OR IGNORE INTO schema_migrations(version) VALUES (1);
