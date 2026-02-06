-- Replace PASSWORD_HASH with a bcrypt hash of FARM123@# (minimum 10 rounds).
-- Example command (Node.js):
--   node -e "const bcrypt=require('bcrypt'); console.log(bcrypt.hashSync('FARM123@#', 12));"

INSERT INTO users (username, password_hash, email)
VALUES ('TRLM_FarmLH', 'PASSWORD_HASH', NULL);
