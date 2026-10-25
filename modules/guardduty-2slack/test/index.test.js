'use strict';

const { test } = require('node:test');
const assert = require('node:assert');

const { buildMessage, severityLabel } = require('../lambda/index');
const ec2Finding = require('../events/ec2-ssh-bruteforce.json');

test('severityLabel maps GuardDuty severities', () => {
  assert.strictEqual(severityLabel(8), 'HIGH');
  assert.strictEqual(severityLabel(5), 'MEDIUM');
  assert.strictEqual(severityLabel(2), 'LOW');
});

test('buildMessage includes the finding title and instance', () => {
  const message = buildMessage(ec2Finding.detail);

  assert.match(message.text, /SSH brute force/);
  assert.match(message.blocks[1].elements[0].text, /i-0a1b2c3d4e5f60789/);
});
