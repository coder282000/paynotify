// src/utils/password.js
const bcrypt = require('bcryptjs');

const SALT_ROUNDS = 12; // Higher than 10 for better security on financial app

/**
 * Hash a plain-text password before storing in DB.
 * Never store plain-text passwords.
 */
const hashPassword = async (plainPassword) => {
    return await bcrypt.hash(plainPassword, SALT_ROUNDS);
};

/**
 * Compare a plain-text password against a stored hash.
 * Returns true if they match, false otherwise.
 */
const verifyPassword = async (plainPassword, hashedPassword) => {
    return await bcrypt.compare(plainPassword, hashedPassword);
};

module.exports = { hashPassword, verifyPassword };
