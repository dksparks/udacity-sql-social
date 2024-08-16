CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(25) UNIQUE NOT NULL CHECK (
    LENGTH(TRIM(username) > 0)
  )
);
CREATE TABLE topics (
  -- a 4-byte integer should suffice for id here
  id SERIAL PRIMARY KEY,
  name VARCHAR(30) UNIQUE NOT NULL CHECK (
    LENGTH(TRIM(name) > 0)
  ),
  description VARCHAR(500)
);
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users (id)
    ON DELETE SET NULL,
  topic_id INTEGER REFERENCES topics (id)
    ON DELETE CASCADE,
  title VARCHAR(100) NOT NULL CHECK (
    LENGTH(TRIM(title) > 0)
  ),
  -- choose a reasonable limit for url length
  url VARCHAR(2000) CHECK (
    -- if url is present, it cannot be empty
    url IS NULL OR LENGTH(TRIM(url) > 0)
  ),
  content TEXT CHECK (
    -- if content is present, it cannot be empty
    text IS NULL OR LENGTH(TRIM(content) > 0)
  ),
  -- exactly one of url and content must be present
  CHECK (
    (url IS NULL AND content IS NOT NULL) OR
    (url IS NOT NULL AND content IS NULL)
  )
);
CREATE TABLE comments (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users (id)
    ON DELETE SET NULL,
  content TEXT NOT NULL CHECK (
    LENGTH(TRIM(content) > 0)
  ),
  -- top-level comments have a parent_post_id
  parent_post_id BIGINT REFERENCES posts (id)
    ON DELETE CASCADE,
  -- other comments have a parent_comment_id
  parent_comment_id BIGINT REFERENCES comments (id)
    ON DELETE CASCADE,
  -- exactly one type of parent must be present
  CHECK (
    (
      parent_post_id IS NULL
      AND parent_comment_id IS NOT NULL
    ) OR (
      parent_post_id IS NOT NULL
      AND parent_comment_id IS NULL
    )
  )
);
create table votes (
  user_id BIGINT REFERENCES users (id)
    ON DELETE SET NULL,
  post_id BIGINT REFERENCES posts (id)
    ON DELETE CASCADE,
  -- it would be more efficient to use a boolean here,
  -- but the project template suggests 1 and -1
  value SMALLINT NOT NULL CHECK (
    value IN (1, -1)
  ),
  PRIMARY KEY (post_id, user_id)
);
