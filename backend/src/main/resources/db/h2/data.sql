-- Seed roles
INSERT INTO role (id, type) VALUES (1, 'ROLE_USER');
INSERT INTO role (id, type) VALUES (2, 'ROLE_ADMIN');

-- Seed users (password = password123 for all)
-- BCrypt hash generated via: new BCryptPasswordEncoder().encode("password123")
INSERT INTO "user" (id, first_name, last_name, username, email, password) VALUES
  (1, 'John', 'Doe', 'johndoe', 'john@doe.com', '$2a$10$S0l0FHNJUQOCEjBs7lnHCOS370dmslSflIHLb6MGltAcdR.vWSfji'),
  (2, 'Linda', 'Calvin', 'lindacalvin', 'linda@calvin.com', '$2a$10$S0l0FHNJUQOCEjBs7lnHCOS370dmslSflIHLb6MGltAcdR.vWSfji'),
  (3, 'Jeffrey', 'Taylor', 'jeffreytaylor', 'jeffrey@taylor.com', '$2a$10$S0l0FHNJUQOCEjBs7lnHCOS370dmslSflIHLb6MGltAcdR.vWSfji');

-- Seed user-role mapping
INSERT INTO user_role (user_id, role_id) VALUES (1,1);
INSERT INTO user_role (user_id, role_id) VALUES (1,2);
INSERT INTO user_role (user_id, role_id) VALUES (2,1);
INSERT INTO user_role (user_id, role_id) VALUES (2,2);
INSERT INTO user_role (user_id, role_id) VALUES (3,1);

-- Seed types
INSERT INTO type (id, name, description) VALUES (1, 'Transfer', 'Transfer type');
INSERT INTO type (id, name, description) VALUES (2, 'Payment', 'Payment type');
INSERT INTO type (id, name, description) VALUES (3, 'Shopping', 'Shopping type');

-- Simple wallets for users
INSERT INTO wallet (id, iban, name, balance, user_id) VALUES
  (1, 'DE00123456789000000001', 'Main Wallet John', 1000, 1),
  (2, 'DE00123456789000000002', 'Main Wallet Linda', 1000, 2),
  (3, 'DE00123456789000000003', 'Main Wallet Jeff', 1000, 3);
