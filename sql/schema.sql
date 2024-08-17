CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  -- uniqueness of username enforced by unique index
  username VARCHAR(25) NOT NULL,
  -- allow last_login to be null since a user could create an account
  -- (or have one created for them) without ever logging in
  last_login TIMESTAMP WITH TIME ZONE,
  CONSTRAINT username_nonempty CHECK (LENGTH(TRIM(username)) > 0)
);
CREATE UNIQUE INDEX user_by_username ON users (username);

CREATE TABLE topics (
  -- an ordinary 4-byte integer should suffice for id here
  id SERIAL PRIMARY KEY,
  -- uniqueness of name enforced by unique index
  name VARCHAR(30) NOT NULL,
  description VARCHAR(500),
  CONSTRAINT topic_name_nonempty CHECK (LENGTH(TRIM(name)) > 0)
);
CREATE UNIQUE INDEX topic_by_name ON topics (name);

CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users (id) ON DELETE SET NULL,
  topic_id INTEGER REFERENCES topics (id) ON DELETE CASCADE,
  title VARCHAR(100) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE,
  -- choose a reasonable limit for url length
  url VARCHAR(2000),
  content TEXT,
  CONSTRAINT title_nonempty CHECK (LENGTH(TRIM(title)) > 0),
  CONSTRAINT post_url_absent_or_nonempty CHECK (
    url IS NULL OR LENGTH(TRIM(url)) > 0
  ),
  CONSTRAINT post_content_absent_or_nonempty CHECK (
    content IS NULL OR LENGTH(TRIM(content)) > 0
  ),
  CONSTRAINT post_url_xor_content CHECK (
    -- exactly one of url or content must be present
    (url IS NULL AND content IS NOT NULL) OR
    (url IS NOT NULL AND content IS NULL)
  )
);
-- including created_at in these indexes makes it easier to retrieve
-- the last 20 posts by the specified user or for the specified topic
CREATE INDEX posts_by_user ON posts (user_id, created_at);
CREATE INDEX posts_by_topic ON posts (topic_id, created_at);
CREATE INDEX posts_by_url ON posts (url);

CREATE TABLE comments (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users (id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE,
  content TEXT NOT NULL,
  -- top-level comments have a parent_post_id; others have a parent_comment_id
  parent_post_id BIGINT REFERENCES posts (id) ON DELETE CASCADE,
  parent_comment_id BIGINT REFERENCES comments (id) ON DELETE CASCADE,
  CONSTRAINT comment_exactly_one_parent CHECK (
    -- exactly one of parent_post_id or parent_comment_id must be present
    (parent_post_id IS NULL AND parent_comment_id IS NOT NULL) OR
    (parent_post_id IS NOT NULL AND parent_comment_id IS NULL)
  ),
  CONSTRAINT comment_content_nonempty CHECK (LENGTH(TRIM(content)) > 0)
);
-- including created_at in this index makes it easier to retrieve
-- the last 20 comments by the specified user
CREATE INDEX comments_by_user ON comments (user_id, created_at);
CREATE INDEX comments_by_parent_post ON comments (parent_post_id);
CREATE INDEX comments_by_parent_comment ON comments (parent_comment_id);

CREATE TABLE votes (
  user_id BIGINT REFERENCES users (id) ON DELETE SET NULL,
  post_id BIGINT REFERENCES posts (id) ON DELETE CASCADE,
  -- a boolean would use less space for storing the value (one byte vs. two),
  -- but using a smallint with 1 and -1 allows finding a post's score by
  -- simply computing a sum
  value SMALLINT NOT NULL,
  CONSTRAINT vote_up_or_down CHECK (value IN (1, -1)),
  -- specifying the primary key in this order (with post_id first) allows for
  -- quick lookup of all votes for a particular post, which is required when
  -- computing the post's score (upvotes minus downvotes)
  PRIMARY KEY (post_id, user_id)
);

-- Note: the following queries seem unlikely to be executed frequently enough
-- to justify creating indexes or denormalizing the data to accommodate them:
-- a. List all users who haven’t logged in in the last year.
-- b. List all users who haven’t created any posts.
-- d. List all topics that don’t have any posts.
