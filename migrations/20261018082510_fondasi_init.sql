-- Fondasi (Plan 02): schema awal user, sesi web, Personal Access Token, dan Project (vault).
-- Dijalankan saat startup oleh `whisker` (sqlx::migrate!, advisory lock) — ADR-007.
-- `uuidv7()` bawaan PostgreSQL 18.

CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE users (
    id                   uuid        PRIMARY KEY DEFAULT uuidv7(),
    email                citext      NOT NULL UNIQUE,
    password_hash        text        NOT NULL,
    role                 text        NOT NULL CHECK (role IN ('admin', 'member')),
    must_change_password boolean     NOT NULL DEFAULT false,
    display_name         text        NOT NULL,
    avatar_key           text        NOT NULL,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),
    disabled_at          timestamptz NULL
);

CREATE TABLE sessions (
    id_hash      bytea       PRIMARY KEY,
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at   timestamptz NOT NULL DEFAULT now(),
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    expires_at   timestamptz NOT NULL
);

CREATE INDEX sessions_user_id_idx ON sessions (user_id);

CREATE TABLE access_tokens (
    id             uuid        PRIMARY KEY DEFAULT uuidv7(),
    user_id        uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name           text        NOT NULL,
    display_prefix text        NOT NULL,
    token_hash     bytea       NOT NULL UNIQUE,
    created_at     timestamptz NOT NULL DEFAULT now(),
    last_used_at   timestamptz NULL,
    revoked_at     timestamptz NULL
);

CREATE INDEX access_tokens_user_id_idx ON access_tokens (user_id);

CREATE TABLE vaults (
    id         uuid        PRIMARY KEY DEFAULT uuidv7(),
    owner_id   uuid        NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    slug       text        NOT NULL CHECK (slug ~ '^[a-z0-9][a-z0-9-]{0,62}$'),
    name       text        NOT NULL,
    icon       text        NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (owner_id, slug)
);
