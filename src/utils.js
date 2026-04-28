'use strict';

const pkg = require('../package.json');

/**
 * Removes characters that are commonly used in injection payloads.
 * Defense-in-depth helper; framework-level escaping must still be used.
 * @param {string} input
 * @returns {string}
 */
function sanitizeInput(input) {
  if (typeof input !== 'string') {
    return '';
  }
  return input.replace(/[<>"'`;]/g, '').slice(0, 256);
}

function getAppVersion() {
  return pkg.version;
}

module.exports = {
  sanitizeInput,
  getAppVersion,
};
