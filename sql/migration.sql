INSERT INTO users (username)
-- there is no need for SELECT DISTINCT due to the use of UNION
SELECT username FROM bad_posts
UNION SELECT REGEXP_SPLIT_TO_TABLE(upvotes, ',') FROM bad_posts
UNION SELECT REGEXP_SPLIT_TO_TABLE(downvotes, ',') FROM bad_posts
UNION SELECT username FROM bad_comments;

INSERT INTO topics (name)
-- standardize capitalization of topic names to title case
SELECT DISTINCT INITCAP(topic) FROM bad_posts;

-- Note 1: Leaving the timestamps as NULL for existing posts and comments
-- causes them to be sorted as earlier than all non-null timestamps
-- created later (after the migration), which is the correct behavior.

-- Note 2: The old INTEGER id values for posts and comments can be used as
-- the new BIGINT id values; there is no need to explicitly cast them.

INSERT INTO posts (id, user_id, topic_id, title, url, content)
-- keep only first 100 characters of title if it is longer than that
SELECT bp.id, u.id, t.id, LEFT(title, 100), url, text_content
FROM bad_posts bp
JOIN users u ON bp.username = u.username
JOIN topics t ON INITCAP(bp.topic) = t.name;

INSERT INTO comments (id, user_id, content, parent_post_id)
select bc.id, u.id, bc.text_content, bc.post_id
FROM bad_comments bc JOIN users u ON bc.username = u.username;

WITH temp_votes AS (
  SELECT
    REGEXP_SPLIT_TO_TABLE(upvotes, ',') AS username,
    id AS post_id,
    1 AS value
  FROM bad_posts
  UNION ALL SELECT
    REGEXP_SPLIT_TO_TABLE(downvotes, ',') AS username,
    id AS post_id,
    -1 AS value
  FROM bad_posts
)
INSERT INTO votes (user_id, post_id, value)
SELECT u.id, tv.post_id, tv.value
FROM temp_votes tv JOIN users u ON tv.username = u.username;
