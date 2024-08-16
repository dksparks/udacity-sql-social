CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(25) UNIQUE NOT NULL,
  CONSTRAINT username_nonempty CHECK (LENGTH(TRIM(username)) > 0)
);

CREATE TABLE topics (
  -- a 4-byte integer should suffice for id here
  id SERIAL PRIMARY KEY,
  name VARCHAR(30) UNIQUE NOT NULL,
  description VARCHAR(500),
  CONSTRAINT topic_name_nonempty CHECK (LENGTH(TRIM(name)) > 0)
);

CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users (id) ON DELETE SET NULL,
  topic_id INTEGER REFERENCES topics (id) ON DELETE CASCADE,
  title VARCHAR(100) NOT NULL,
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
  -- exactly one of url and content must be present
  CONSTRAINT post_url_xor_content CHECK (
    (url IS NULL AND content IS NOT NULL) OR
    (url IS NOT NULL AND content IS NULL)
  )
);

CREATE TABLE comments (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users (id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  -- top-level comments have a parent_post_id
  parent_post_id BIGINT REFERENCES posts (id) ON DELETE CASCADE,
  -- other comments have a parent_comment_id
  parent_comment_id BIGINT REFERENCES comments (id) ON DELETE CASCADE,
  -- comments must have a parent_post_id or a parent_comment_id, but not both
  CONSTRAINT comment_exactly_one_parent CHECK (
    (parent_post_id IS NULL AND parent_comment_id IS NOT NULL) OR
    (parent_post_id IS NOT NULL AND parent_comment_id IS NULL)
  ),
  CONSTRAINT comment_content_nonempty CHECK (LENGTH(TRIM(content)) > 0)
);

CREATE TABLE votes (
  user_id BIGINT REFERENCES users (id) ON DELETE SET NULL,
  post_id BIGINT REFERENCES posts (id) ON DELETE CASCADE,
  -- a boolean would be more efficient here, but the template suggests 1 and -1
  value SMALLINT NOT NULL,
  CONSTRAINT vote_up_or_down CHECK (value IN (1, -1)),
  PRIMARY KEY (post_id, user_id)
);
