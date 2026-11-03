BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "backup" (
    "id" bigserial PRIMARY KEY,
    "hubId" bigint NOT NULL,
    "objectKey" text NOT NULL,
    "sizeBytes" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "status" text NOT NULL,
    "error" text
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "document" (
    "id" bigserial PRIMARY KEY,
    "hubId" bigint NOT NULL,
    "path" text NOT NULL,
    "title" text NOT NULL,
    "area" text NOT NULL,
    "type" text,
    "status" text,
    "frontmatter" text NOT NULL,
    "tags" json NOT NULL,
    "blobSha" text NOT NULL,
    "lastCommitSha" text,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "document_hub_path_idx" ON "document" USING btree ("hubId", "path");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "document_link" (
    "id" bigserial PRIMARY KEY,
    "fromDocId" bigint NOT NULL,
    "hubId" bigint NOT NULL,
    "toPath" text NOT NULL,
    "toDocId" bigint
);

-- Indexes
CREATE INDEX "document_link_from_idx" ON "document_link" USING btree ("fromDocId");
CREATE INDEX "document_link_to_idx" ON "document_link" USING btree ("toDocId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "hub" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "slug" text NOT NULL,
    "githubRepo" text,
    "remoteUrl" text NOT NULL,
    "installationId" bigint,
    "defaultBranch" text NOT NULL DEFAULT 'main'::text,
    "headSha" text,
    "lastIndexedAt" timestamp without time zone,
    "ownerId" uuid NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "hub_slug_idx" ON "hub" USING btree ("slug");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "hub_member" (
    "id" bigserial PRIMARY KEY,
    "hubId" bigint NOT NULL,
    "userId" uuid NOT NULL,
    "role" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "hub_member_unique_idx" ON "hub_member" USING btree ("hubId", "userId");


--
-- MIGRATION VERSION FOR whisker
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('whisker', '20261103161402936', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261103161402936', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20261015164015382', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261015164015382', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
