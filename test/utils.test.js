'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { sanitizeInput, getAppVersion } = require('../src/utils');

test('sanitizeInput removes injection-prone characters', () => {
  assert.strictEqual(sanitizeInput('<script>alert(1)</script>'), 'scriptalert(1)/script');
});

test('sanitizeInput truncates long inputs', () => {
  const long = 'a'.repeat(1000);
  assert.strictEqual(sanitizeInput(long).length, 256);
});

test('sanitizeInput handles non-string values', () => {
  assert.strictEqual(sanitizeInput(undefined), '');
  assert.strictEqual(sanitizeInput(42), '');
});

test('getAppVersion returns a semver string', () => {
  assert.match(getAppVersion(), /^\d+\.\d+\.\d+/);
});
