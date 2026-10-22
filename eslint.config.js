const { FlatCompat } = require("@eslint/eslintrc");
const legacyConfig = require("./.eslintrc.js");

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

module.exports = compat.config(legacyConfig);
