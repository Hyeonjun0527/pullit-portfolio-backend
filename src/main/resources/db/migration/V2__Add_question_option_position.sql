ALTER TABLE question_options
  ADD COLUMN migration_row_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST,
  ADD COLUMN option_position INT NULL;

CREATE TEMPORARY TABLE question_option_positions AS
SELECT
  migration_row_id,
  ROW_NUMBER() OVER (PARTITION BY question_id ORDER BY migration_row_id) - 1 AS option_position
FROM question_options;

UPDATE question_options qo
JOIN question_option_positions qop ON qop.migration_row_id = qo.migration_row_id
SET qo.option_position = qop.option_position;

DROP TEMPORARY TABLE question_option_positions;

ALTER TABLE question_options
  DROP PRIMARY KEY,
  DROP COLUMN migration_row_id,
  MODIFY option_position INT NOT NULL,
  ADD KEY idx_question_options_position (question_id, option_position);
