-- Initial PostgreSQL schema for NotesDB.
-- File bytes belong in private object storage; note_files stores their keys.

CREATE TABLE users (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            text NOT NULL,
    email           text NOT NULL UNIQUE,
    role            text NOT NULL CHECK (role IN ('student', 'professor', 'admin')),
    accessibility_preferences jsonb NOT NULL DEFAULT '{}'::jsonb,
    training_completed_at timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE courses (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code                text NOT NULL,
    title               text NOT NULL,
    term                text NOT NULL,
    owner_professor_id  bigint NOT NULL REFERENCES users(id),
    created_at          timestamptz NOT NULL DEFAULT now(),
    UNIQUE (code, term)
);

CREATE TABLE enrollments (
    user_id     bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    course_id   bigint NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, course_id)
);

CREATE TABLE topics (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id           bigint NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    name                text NOT NULL,
    parent_topic_id     bigint REFERENCES topics(id) ON DELETE SET NULL,
    created_at          timestamptz NOT NULL DEFAULT now(),
    UNIQUE (course_id, name)
);

CREATE TABLE notes (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_id       bigint NOT NULL REFERENCES users(id),
    course_id       bigint NOT NULL REFERENCES courses(id),
    title           text NOT NULL,
    lecture_date    date,
    source_type     text NOT NULL CHECK (source_type IN ('typeset', 'image_pipeline')),
    status          text NOT NULL DEFAULT 'processing'
                    CHECK (status IN ('processing', 'needs_review', 'published', 'failed')),
    visibility      text NOT NULL DEFAULT 'private'
                    CHECK (visibility IN ('private', 'course', 'public')),
    extracted_text  text NOT NULL DEFAULT '',
    search_vector   tsvector,
    accessibility_report jsonb,
    accessibility_score numeric(5, 4)
                    CHECK (accessibility_score BETWEEN 0 AND 1),
    accessibility_checked_at timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE note_topics (
    note_id         bigint NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    topic_id        bigint NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    assigned_by     text NOT NULL CHECK (assigned_by IN ('author', 'pipeline')),
    confidence      numeric(5, 4) CHECK (confidence BETWEEN 0 AND 1),
    created_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (note_id, topic_id)
);

CREATE TABLE tags (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL UNIQUE,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE note_tags (
    note_id     bigint NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    tag_id      bigint NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (note_id, tag_id)
);

CREATE TABLE note_files (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    note_id         bigint NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    kind            text NOT NULL CHECK (kind IN (
                        'original_image', 'tex_source', 'compiled_pdf',
                        'accessible_html'
                    )),
    bucket          text NOT NULL,
    object_key      text NOT NULL,
    sha256          char(64) NOT NULL,
    mime_type       text NOT NULL,
    size_bytes      bigint NOT NULL CHECK (size_bytes >= 0),
    alt_text        text,
    alt_text_status text CHECK (alt_text_status IN (
                        'missing', 'auto_draft', 'author_verified'
                    )),
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (bucket, object_key)
);

CREATE TABLE processing_jobs (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    note_id         bigint NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    stage           text NOT NULL CHECK (stage IN (
                        'ocr', 'latex', 'topic_tagging', 'compile', 'accessibility_check'
                    )),
    status          text NOT NULL DEFAULT 'queued'
                    CHECK (status IN ('queued', 'running', 'succeeded', 'failed')),
    error           text,
    started_at      timestamptz,
    finished_at     timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX courses_owner_professor_idx ON courses(owner_professor_id);
CREATE INDEX enrollments_course_idx ON enrollments(course_id);
CREATE INDEX topics_parent_idx ON topics(parent_topic_id);
CREATE INDEX notes_course_visibility_idx ON notes(course_id, visibility);
CREATE INDEX notes_author_idx ON notes(author_id);
CREATE INDEX notes_search_vector_idx ON notes USING GIN(search_vector);
CREATE INDEX note_topics_topic_idx ON note_topics(topic_id);
CREATE INDEX note_files_note_kind_idx ON note_files(note_id, kind);
CREATE INDEX processing_jobs_status_created_idx ON processing_jobs(status, created_at);
