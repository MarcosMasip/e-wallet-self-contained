-- H2 schema for self-contained in-memory mode (mirrors PostgreSQL objects)
CREATE SEQUENCE IF NOT EXISTS role_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS transaction_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS type_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS wallet_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS user_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE role (
  id BIGINT PRIMARY KEY,
  type VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE "user" (
  id BIGINT PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  username VARCHAR(20) NOT NULL UNIQUE,
  email VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL
);

CREATE TABLE wallet (
  id BIGINT PRIMARY KEY,
  iban VARCHAR(34) NOT NULL UNIQUE,
  name VARCHAR(50) NOT NULL,
  balance DECIMAL NOT NULL,
  user_id BIGINT NOT NULL,
  CONSTRAINT fk_wallet_user FOREIGN KEY (user_id) REFERENCES "user"(id)
);

CREATE TABLE type (
  id BIGINT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(50)
);

CREATE TABLE transaction (
  id BIGINT PRIMARY KEY,
  amount DECIMAL NOT NULL,
  description VARCHAR(50),
  created_at TIMESTAMP NOT NULL,
  reference_number VARCHAR(50) NOT NULL UNIQUE,
  status VARCHAR(20) NOT NULL,
  from_wallet_id BIGINT NOT NULL,
  to_wallet_id BIGINT NOT NULL,
  type_id BIGINT NOT NULL,
  CONSTRAINT fk_tx_from_wallet FOREIGN KEY (from_wallet_id) REFERENCES wallet(id),
  CONSTRAINT fk_tx_to_wallet FOREIGN KEY (to_wallet_id) REFERENCES wallet(id),
  CONSTRAINT fk_tx_type FOREIGN KEY (type_id) REFERENCES type(id)
);

CREATE TABLE user_role (
  role_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  PRIMARY KEY (role_id, user_id),
  CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES role(id),
  CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES "user"(id)
);
