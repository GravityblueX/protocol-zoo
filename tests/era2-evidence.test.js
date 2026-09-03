const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const {
  DATASET_PATH,
  SIX_TO_FOUR_FIXTURE_PATH,
  SIT_CAPTURE_PATH,
  SIT_GENERATOR_PATH,
  parseDataset,
  validateEvidence,
  validateSixToFourFixture,
  validateSitCapture,
} = require('../scripts/validate-era2-evidence');

const checkedInDataset = fs.readFileSync(DATASET_PATH, 'utf8');
const checkedInFixture = fs.readFileSync(SIX_TO_FOUR_FIXTURE_PATH, 'utf8');
const checkedInCapture = fs.readFileSync(SIT_CAPTURE_PATH, 'utf8');
const checkedInGenerator = fs
  .readFileSync(SIT_GENERATOR_PATH, 'utf8')
  .replace(/\r\n?/g, '\n');

function replaceExactly(text, original, replacement) {
  const updated = text.replace(original, replacement);
  assert.notEqual(updated, text, `fixture marker was not found: ${original}`);
  return updated;
}

test('checked-in Era 2 data satisfies its structural and evidence contract', () => {
  const result = validateEvidence(
    checkedInDataset,
    checkedInFixture,
    checkedInCapture,
    checkedInGenerator,
  );
  assert.ok(result.rows.length > 0);
  assert.equal(result.rows.find(row => row[0] === '6to4')[5], 'fixture');
  assert.deepEqual(result.sixToFourFixture, {
    prefix: '2002:c612:5a01::/48',
    ipv4: '198.18.90.1',
  });
  assert.equal(result.sitCapture.protocol, 'sit-ipv6-in-ipv4');
});

test('private SIT evidence cannot upgrade the 6to4 record to real-capture', () => {
  const overstated = replaceExactly(
    checkedInDataset,
    '6to4,transition,RFC 3056,RFC 7526,historic,fixture,',
    '6to4,transition,RFC 3056,RFC 7526,historic,real-capture,',
  );

  assert.throws(
    () => validateEvidence(
      overstated,
      checkedInFixture,
      checkedInCapture,
      checkedInGenerator,
    ),
    /private SIT capture does not exercise 6to4 addressing or a relay/,
  );
});

test('private SIT real-capture metadata cannot claim the 6to4 protocol', () => {
  const mislabeledCapture = replaceExactly(
    checkedInCapture,
    '"protocol":"sit-ipv6-in-ipv4"',
    '"protocol":"6to4-private-sit"',
  );
  assert.throws(
    () => validateSitCapture(mislabeledCapture, checkedInGenerator),
    /private SIT capture must use protocol sit-ipv6-in-ipv4/,
  );

  const mislabeledGenerator = replaceExactly(
    checkedInGenerator,
    '"protocol":"sit-ipv6-in-ipv4"',
    '"protocol":"6to4-private-sit"',
  );
  assert.throws(
    () => validateSitCapture(checkedInCapture, mislabeledGenerator),
    /generator emits an incorrect protocol label/,
  );
});

test('SIT metadata rejects duplicate and nested protocol labels', () => {
  const duplicateProtocol = replaceExactly(
    checkedInCapture,
    '{"protocol":"sit-ipv6-in-ipv4",',
    '{"protocol":"6to4","protocol":"sit-ipv6-in-ipv4",',
  );
  assert.throws(
    () => validateSitCapture(duplicateProtocol, checkedInGenerator),
    /duplicate JSON key "protocol"/,
  );

  const nestedProtocol = replaceExactly(
    checkedInCapture,
    '"result":{"handshake":"pass",',
    '"result":{"protocol":"6to4","handshake":"pass",',
  );
  assert.throws(
    () => validateSitCapture(nestedProtocol, checkedInGenerator),
    /nested protocol labels: \$\.result\.protocol/,
  );
});

test('SIT metadata rejects contradictory 6to4 claims', () => {
  const contradictoryNote = replaceExactly(
    checkedInCapture,
    '"notes":["Private SIT-style',
    '"notes":["This is real 6to4 evidence.","Private SIT-style',
  );
  assert.throws(
    () => validateSitCapture(contradictoryNote, checkedInGenerator),
    /preserve the public-6to4 limitation/,
  );

  const nestedClaim = replaceExactly(
    checkedInCapture,
    '"result":{"handshake":"pass",',
    '"result":{"claim":"This is real 6to4 evidence.","handshake":"pass",',
  );
  assert.throws(
    () => validateSitCapture(nestedClaim, checkedInGenerator),
    /conflicting 6to4 claims.*\$\.result\.claim/,
  );
});

test('SIT generator validation ignores decoys outside the emitted metadata', () => {
  const variableProtocol = replaceExactly(
    replaceExactly(
      checkedInGenerator,
      '{"protocol":"sit-ipv6-in-ipv4",',
      '{"protocol":$PROTOCOL_JSON,',
    ),
    'frames=$(tshark -r "$OUT_DIR/sit-ipv6-in-ipv4.pcapng"',
    '# decoy: "protocol":"sit-ipv6-in-ipv4"\n' +
      'PROTOCOL_JSON=\'"6to4"\'\n' +
      'frames=$(tshark -r "$OUT_DIR/sit-ipv6-in-ipv4.pcapng"',
  );
  assert.throws(
    () => validateSitCapture(checkedInCapture, variableProtocol),
    /generator emits an incorrect protocol label/,
  );
});

test('SIT generator template rejects escaped keys and nested claims', () => {
  const escapedDuplicate = replaceExactly(
    checkedInGenerator,
    '{"protocol":"sit-ipv6-in-ipv4",',
    '{"protocol":"sit-ipv6-in-ipv4","pro\\u0074ocol":"6to4",',
  );
  assert.throws(
    () => validateSitCapture(checkedInCapture, escapedDuplicate),
    /duplicate JSON key "protocol"/,
  );

  const nestedClaim = replaceExactly(
    checkedInGenerator,
    '"result":{"handshake":"pass",',
    '"result":{"claims":["real 6to4 evidence"],"handshake":"pass",',
  );
  assert.throws(
    () => validateSitCapture(checkedInCapture, nestedClaim),
    /conflicting 6to4 claims.*\$\.result\.claims\[0\]/,
  );
});

test('a later variable-path heredoc cannot overwrite SIT metadata', () => {
  const overwritten = replaceExactly(
    checkedInGenerator,
    '\njsonschema -i ',
    '\ncat >"$M15_METADATA" <<\\SECOND_EOF\n' +
      '{"protocol":"6to4"}\n' +
      'SECOND_EOF\n' +
      'jsonschema -i ',
  );
  assert.throws(
    () => validateSitCapture(checkedInCapture, overwritten),
    /exactly one metadata heredoc/,
  );
});

test('post-heredoc commands cannot overwrite or mutate SIT metadata', () => {
  const rewrites = [
    String.raw`printf '%s\n' '{"protocol":"6to4"}' >"$ROOT/$OUT/sit-ipv6-in-ipv4.json"`,
    String.raw`printf '%s\n' "{\"protocol\":\"6to\\u0034\"}" >"$ROOT/$OUT/sit-ipv6-in-ipv4.json"`,
    String.raw`printf '%s\n' "{\"protocol\":\"6to\\u0034\"}" | tee "$ROOT/$OUT/sit-ipv6-in-ipv4.json" >/dev/null`,
    String.raw`sed -i 's/sit-ipv6-in-ipv4/6to\\\u0034/' "$ROOT/$OUT/sit-ipv6-in-ipv4.json"`,
  ];

  for (const rewrite of rewrites) {
    const overwritten = replaceExactly(
      checkedInGenerator,
      '\njsonschema -i ',
      `\n${rewrite}\njsonschema -i `,
    );
    assert.throws(
      () => validateSitCapture(checkedInCapture, overwritten),
      /canonical post-metadata validation tail/,
      rewrite,
    );
  }
});

test('cleanup cannot run after the canonical metadata writer', () => {
  const withoutPrewriteCleanup = replaceExactly(
    checkedInGenerator,
    '\ncleanup\ncat >',
    '\ncat >',
  );
  const cleanupAfterWrite = replaceExactly(
    withoutPrewriteCleanup,
    '\ntrap - EXIT INT TERM',
    '\ncleanup\ntrap - EXIT INT TERM',
  );

  assert.throws(
    () => validateSitCapture(checkedInCapture, cleanupAfterWrite),
    /verify frames, then clean up immediately before writing metadata/,
  );

  const cleanupTooEarly = replaceExactly(
    withoutPrewriteCleanup,
    'trap cleanup EXIT INT TERM',
    'trap cleanup EXIT INT TERM\ncleanup',
  );
  assert.throws(
    () => validateSitCapture(checkedInCapture, cleanupTooEarly),
    /verify frames, then clean up immediately before writing metadata/,
  );
});

test('cleanup function cannot be replaced or redefined', () => {
  const definition = checkedInGenerator
    .split(/\r?\n/)
    .find(line => line.startsWith('cleanup(){'));
  assert.ok(definition);

  for (const replacement of [
    'cleanup(){ :; }',
    definition.replace(
      'sudo rm -rf "$TMP"; }',
      'sudo rm -rf "$TMP"; rm -f "$ROOT/$OUT/sit-ipv6-in-ipv4.json"; }',
    ),
  ]) {
    const changed = replaceExactly(checkedInGenerator, definition, replacement);
    assert.throws(
      () => validateSitCapture(checkedInCapture, changed),
      /canonical cleanup function/,
    );
  }

  const redefined = replaceExactly(
    checkedInGenerator,
    '\ncleanup\ncat >',
    '\ncleanup(){ :; }\ncleanup\ncat >',
  );
  assert.throws(
    () => validateSitCapture(checkedInCapture, redefined),
    /canonical cleanup function/,
  );
});

test('6to4 fixture prefix must encode its declared IPv4 address', () => {
  const mismatched = replaceExactly(
    checkedInFixture,
    '2002:c612:5a01::/48',
    '2002:c612:0101::/48',
  );

  assert.throws(
    () => validateSixToFourFixture(mismatched),
    /prefix embeds 198\.18\.1\.1 but fixture declares 198\.18\.90\.1/,
  );
});

test('non-canonical 6to4 records cannot evade uniqueness checks', () => {
  for (const duplicate of [
    '  6to4 prefix=2002:c612:5a01::/48 embedded_ipv4=198.18.90.1',
    '6TO4 prefix=2002:c612:5a01::/48 embedded_ipv4=198.18.90.1',
    '\t6to4\tprefix=2002:c612:5a01::/48 embedded_ipv4=198.18.90.1',
    '\u00856to4 prefix=2002:c612:5a01::/48 embedded_ipv4=198.18.90.1',
  ]) {
    assert.throws(
      () => validateSixToFourFixture(`${checkedInFixture}${duplicate}\n`),
      /exactly one 6to4 record/,
    );
  }

  const withoutFinalNewline = checkedInFixture.replace(/\r?\n$/, '');
  for (const separator of ['\u0085', '\u2028', '\u2029']) {
    assert.throws(
      () => validateSixToFourFixture(
        withoutFinalNewline +
          separator +
          '6to4 prefix=2002:c612:5a01::/48 embedded_ipv4=198.18.90.1',
      ),
      /exactly one 6to4 record/,
    );
  }
});

test('the closed M15 dataset cannot silently drop its 6to4 record', () => {
  const withoutSixToFour = checkedInDataset
    .split(/\r?\n/)
    .filter(line => !line.startsWith('6to4,'))
    .join('\n');

  assert.throws(
    () => validateEvidence(
      withoutSixToFour,
      checkedInFixture,
      checkedInCapture,
      checkedInGenerator,
    ),
    /missing the 6to4 record/,
  );
});

test('protocol name aliases cannot duplicate evidence records', () => {
  const rows = checkedInDataset.split(/\r?\n/);
  const sixToFourRow = rows.find(line => line.startsWith('6to4,'));
  const rarpRow = rows.find(line => line.startsWith('RARP,'));
  assert.ok(sixToFourRow);
  assert.ok(rarpRow);
  const base = checkedInDataset.replace(/\r?\n$/, '');

  for (const alias of ['6TO4', ' 6to4', '6to4\u00a0']) {
    const overstated = sixToFourRow
      .replace('6to4,', `${alias},`)
      .replace(',fixture,', ',real-capture,');
    assert.throws(
      () => parseDataset(`${base}\n${overstated}\n`),
      /canonical spelling|leading or trailing whitespace|duplicate protocol name/,
      alias,
    );
  }

  const uppercaseOnly = replaceExactly(checkedInDataset, '6to4,', '6TO4,');
  assert.throws(() => parseDataset(uppercaseOnly), /canonical spelling/);

  const lowercaseRarp = rarpRow.replace('RARP,', 'rarp,');
  assert.throws(
    () => parseDataset(`${base}\n${lowercaseRarp}\n`),
    /duplicate protocol name/,
  );
});

test('malformed rows and unknown evidence levels fail closed', () => {
  const invalidLevel = replaceExactly(
    checkedInDataset,
    'RARP,link/network,RFC 903,RFC 903,historic,fixture,',
    'RARP,link/network,RFC 903,RFC 903,historic,observed,',
  );
  assert.throws(() => parseDataset(invalidLevel), /invalid evidence_level/);

  const missingColumn = replaceExactly(
    checkedInDataset,
    ',non-routable discovery,DHCP/ARP',
    ',non-routable discovery',
  );
  assert.throws(() => parseDataset(missingColumn), /column mismatch/);

  const unicodeWhitespace = replaceExactly(
    checkedInDataset,
    'boot without IP',
    '\u0085',
  );
  assert.throws(() => parseDataset(unicodeWhitespace), /record separator/);
});

test('CSV quoting accepts embedded commas and escaped quotes', () => {
  const quoted = replaceExactly(
    checkedInDataset,
    'boot without IP',
    '"boot, without ""configured"" IP"',
  );

  assert.equal(parseDataset(quoted)[0][6], 'boot, without "configured" IP');
});

test('malformed CSV quoting fails closed', () => {
  const unterminated = replaceExactly(
    checkedInDataset,
    'boot without IP',
    '"boot without IP',
  );
  assert.throws(() => parseDataset(unterminated), /unterminated quoted field/);

  const trailingText = replaceExactly(
    checkedInDataset,
    'boot without IP',
    '"boot without IP"unexpected',
  );
  assert.throws(() => parseDataset(trailingText), /after closing quote/);
});
