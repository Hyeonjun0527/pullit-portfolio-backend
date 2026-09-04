SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE common_folder (
  sort_order INT NOT NULL,
  created_at DATETIME(6) NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  owner_id BIGINT NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  name VARCHAR(255) NOT NULL,
  scope ENUM('ALL', 'CUSTOM') NOT NULL,
  type ENUM('QUESTION_SET', 'WRONG_ANSWER') NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE learn_stats (
  consecutive_learning_days INT NOT NULL,
  last_learning_date DATE DEFAULT NULL,
  total_solved_question_set_count INT NOT NULL,
  weekly_solved_question_count INT NOT NULL,
  created_at DATETIME(6) NOT NULL,
  member_id BIGINT NOT NULL,
  total_correct_question_count BIGINT NOT NULL,
  total_question_count BIGINT NOT NULL,
  total_solved_question_count BIGINT NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  PRIMARY KEY (member_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE learn_stats_daily (
  activity_date DATE NOT NULL,
  solved_question_count INT NOT NULL,
  solved_question_set_count INT NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_id BIGINT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY learn_stats_daily_unique_idx (member_id, activity_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE member (
  created_at DATETIME(6) NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  kakao_id BIGINT DEFAULT NULL,
  updated_at DATETIME(6) NOT NULL,
  email VARCHAR(255) NOT NULL,
  name VARCHAR(255) DEFAULT NULL,
  role ENUM('ADMIN', 'MEMBER') NOT NULL,
  status ENUM('ACTIVE', 'BANNED', 'INACTIVE') DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY UKmbmcqelty0fbrvxp1q58dn57t (email),
  UNIQUE KEY UKtqi1nx9ul3nx7guxpqycuvgue (kakao_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE migration_history (
  created_at DATETIME(6) NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  updated_at DATETIME(6) NOT NULL,
  migration_name VARCHAR(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY UKmvh5rqlacqimatqgv28j2wiml (migration_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE outbox_event (
  attempts INT DEFAULT NULL,
  created_at DATETIME(6) NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  updated_at DATETIME(6) NOT NULL,
  event_id VARCHAR(36) NOT NULL,
  event_type VARCHAR(100) NOT NULL,
  worker_id VARCHAR(255) DEFAULT NULL,
  payload LONGTEXT NOT NULL,
  status ENUM('DONE', 'FAILED', 'PENDING', 'SENDING') NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event_event_id (event_id),
  KEY ix_outbox_event_status_created (status, created_at),
  KEY ix_outbox_event_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE processed_event (
  created_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  event_id VARCHAR(36) NOT NULL,
  PRIMARY KEY (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE question (
  created_at DATETIME(6) NOT NULL,
  deleted_at DATETIME(6) DEFAULT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  question_set_id BIGINT DEFAULT NULL,
  updated_at DATETIME(6) NOT NULL,
  dtype VARCHAR(31) NOT NULL,
  explanation TEXT DEFAULT NULL,
  question_text TEXT DEFAULT NULL,
  PRIMARY KEY (id),
  KEY FKd2w5k3smcsfn7dcjiq5kxseq2 (question_set_id),
  CONSTRAINT FKd2w5k3smcsfn7dcjiq5kxseq2 FOREIGN KEY (question_set_id) REFERENCES question_set (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE question_multiple_choice (
  id BIGINT NOT NULL,
  answer VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT FK7y2qqxvjta4akuk8v7y7xyvgc FOREIGN KEY (id) REFERENCES question (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE question_options (
  question_id BIGINT NOT NULL,
  option_text VARCHAR(255) DEFAULT NULL,
  KEY FKaewurtlqda0y6wcg9jeylyg6a (question_id),
  CONSTRAINT FKaewurtlqda0y6wcg9jeylyg6a FOREIGN KEY (question_id) REFERENCES question_multiple_choice (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE question_set (
  question_length INT DEFAULT NULL,
  retry_count INT NOT NULL,
  common_folder_id BIGINT DEFAULT NULL,
  created_at DATETIME(6) NOT NULL,
  deleted_at DATETIME(6) DEFAULT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  owner_id BIGINT NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  version BIGINT NOT NULL,
  title VARCHAR(150) DEFAULT NULL,
  difficulty ENUM('EASY', 'HARD') DEFAULT NULL,
  learning_status ENUM('COMPLETED', 'IN_PROGRESS', 'NOT_STARTED') DEFAULT NULL,
  status ENUM('COMPLETE', 'FAILED', 'PENDING', 'UNPROCESSABLE') DEFAULT NULL,
  type ENUM('MULTIPLE_CHOICE', 'SHORT_ANSWER', 'SUBJECTIVE', 'TRUE_FALSE') DEFAULT NULL,
  PRIMARY KEY (id),
  KEY FKklqs1htxnwjhgi6vn16u1kd82 (common_folder_id),
  CONSTRAINT FKklqs1htxnwjhgi6vn16u1kd82 FOREIGN KEY (common_folder_id) REFERENCES common_folder (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE question_set_source (
  question_set_id BIGINT NOT NULL,
  source_id BIGINT NOT NULL,
  PRIMARY KEY (question_set_id, source_id),
  KEY FKk8jramh7amnwnvhftj6p9a1kw (source_id),
  CONSTRAINT FKk8jramh7amnwnvhftj6p9a1kw FOREIGN KEY (source_id) REFERENCES source (id),
  CONSTRAINT FKsgwhvpdkwp6641ui7vp51j8dm FOREIGN KEY (question_set_id) REFERENCES question_set (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE question_short_answer (
  id BIGINT NOT NULL,
  answer VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT FKssoff9cf0px1usmsn0d1v4dr9 FOREIGN KEY (id) REFERENCES question (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE question_true_false (
  answer BIT(1) NOT NULL,
  id BIGINT NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT FK9gjexpb42svh57saot0k9y0ht FOREIGN KEY (id) REFERENCES question (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE source (
  page_count INT DEFAULT NULL,
  created_at DATETIME(6) NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_id BIGINT NOT NULL,
  source_folder_id BIGINT DEFAULT NULL,
  updated_at DATETIME(6) NOT NULL,
  content_type VARCHAR(255) NOT NULL,
  file_path VARCHAR(255) NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  status ENUM('DELETED', 'FAILED', 'NOT_EXIST', 'PROCESSING', 'READY', 'UPLOADED') NOT NULL,
  PRIMARY KEY (id),
  KEY FKmcc76l1b8ujhbvdjjc31o492t (source_folder_id),
  CONSTRAINT FKmcc76l1b8ujhbvdjjc31o492t FOREIGN KEY (source_folder_id) REFERENCES source_folder (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE source_folder (
  created_at DATETIME(6) NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_id BIGINT NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  color VARCHAR(255) DEFAULT NULL,
  description VARCHAR(255) DEFAULT NULL,
  name VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE marking_result (
  is_correct BIT(1) NOT NULL,
  created_at DATETIME(6) NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_id BIGINT NOT NULL,
  question_id BIGINT NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  PRIMARY KEY (id),
  KEY FKjm5epe8dpfyi2wavf0pkts2r9 (question_id),
  CONSTRAINT FKjm5epe8dpfyi2wavf0pkts2r9 FOREIGN KEY (question_id) REFERENCES question (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE wrong_answer (
  is_reviewed BIT(1) DEFAULT NULL,
  created_at DATETIME(6) NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_id BIGINT DEFAULT NULL,
  question_id BIGINT DEFAULT NULL,
  updated_at DATETIME(6) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY UKk52s1oc2m2dbrrui4w2e749jt (member_id, question_id),
  UNIQUE KEY UKti433dnayhh5p3qhbwqu1cv27 (question_id),
  CONSTRAINT FKovvauh9ri5jp9f22tkbkcqyvs FOREIGN KEY (question_id) REFERENCES question (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
