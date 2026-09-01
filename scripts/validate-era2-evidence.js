#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');

const DATASET_PATH = path.resolve(__dirname, '..', 'datasets', 'era2.csv');
const SIX_TO_FOUR_FIXTURE_PATH = path.resolve(
  __dirname,
  '..',
  'captures',
  'fixtures',
  'era2',
  'ipv6-transition.txt',
);
const SIT_CAPTURE_PATH = path.resolve(
  __dirname,
  '..',
  'captures',
  'era2-ipv6',
  'sit-ipv6-in-ipv4.json',
);
const SIT_GENERATOR_PATH = path.resolve(__dirname, 'era2-ipv6-capture.sh');
const EXPECTED_HEADER = [
  'name',
  'layer',
  'original_spec',
  'current_spec',
  'status',
  'evidence_level',
  'birth_context',
  'wire_assumption',
  'topology_assumption',
  'addressing_model',
  'discovery_model',
  'trust_model',
  'state_model',
  'failure_model',
  'bandwidth_assumption',
  'middlebox_assumption',
  'death_pressure',
  'surviving_descendants',
];
const ALLOWED_EVIDENCE_LEVELS = new Set([
  'real-capture',
  'fixture',
  'static',
  'document-reconstruction',
  'not-run',
]);
const ONLY_UNICODE_WHITESPACE = /^(?:\p{White_Space}|\uFEFF)*$/u;
const EDGE_UNICODE_WHITESPACE =
  /^(?:\p{White_Space}|\uFEFF)+|(?:\p{White_Space}|\uFEFF)+$/gu;
const SIT_LIMITATION_NOTE =
  'Private SIT-style IPv6-in-IPv4 only; no public 6to4 anycast, Teredo ' +
  'relay, ISATAP broker, or NAT64 service was contacted.';

function parseDataset(text) {
  if (!text.trim()) throw new Error('era2.csv is empty');

  const records = parseCsv(text);
  const header = records[0].fields;
  if (
    header.length !== EXPECTED_HEADER.length ||
    header.some((name, index) => name !== EXPECTED_HEADER[index])
  ) {
    throw new Error('era2.csv header does not match the documented contract');
  }

  const names = new Set();
  for (const { fields: row, lineNumber } of records.slice(1)) {
    if (row.length !== header.length) {
      throw new Error(`era2.csv column mismatch at row ${lineNumber}`);
    }
    if (row.some(value => ONLY_UNICODE_WHITESPACE.test(value))) {
      throw new Error(`era2.csv contains an empty field at row ${lineNumber}`);
    }
    if (!ALLOWED_EVIDENCE_LEVELS.has(row[5])) {
      throw new Error(`invalid evidence_level at row ${lineNumber}: ${row[5]}`);
    }
    const protocolName = row[0].replace(EDGE_UNICODE_WHITESPACE, '');
    if (protocolName !== row[0]) {
      throw new Error(
        `protocol name has leading or trailing whitespace at row ${lineNumber}: ${row[0]}`,
      );
    }
    const canonicalName = protocolName.toLowerCase();
    if (canonicalName === '6to4' && protocolName !== '6to4') {
      throw new Error(`6to4 protocol name must use canonical spelling at row ${lineNumber}`);
    }
    if (names.has(canonicalName)) {
      throw new Error(`duplicate protocol name at row ${lineNumber}: ${row[0]}`);
    }
    names.add(canonicalName);
  }

  return records.slice(1).map(record => record.fields);
}

function parseCsv(text) {
  const records = [];
  let fields = [];
  let field = '';
  let state = 'start';
  let lineNumber = 1;
  let recordLineNumber = 1;
  let recordStarted = false;

  function finishField() {
    fields.push(field);
    field = '';
    state = 'start';
  }

  function finishRecord() {
    finishField();
    records.push({ fields, lineNumber: recordLineNumber });
    fields = [];
    recordStarted = false;
  }

  for (let index = 0; index < text.length; index += 1) {
    const character = text[index];
    if (/[\u0085\u2028\u2029]/.test(character)) {
      throw new Error(`non-standard CSV record separator at line ${lineNumber}`);
    }

    if (state === 'quoted') {
      if (character === '"') {
        if (text[index + 1] === '"') {
          field += '"';
          index += 1;
        } else {
          state = 'after-quote';
        }
      } else {
        field += character;
        if (character === '\n') lineNumber += 1;
      }
      continue;
    }

    if (state === 'after-quote') {
      if (character === ',') {
        finishField();
        recordStarted = true;
        continue;
      }
      if (character !== '\r' && character !== '\n') {
        throw new Error(
          `unexpected character after closing quote at line ${lineNumber}`,
        );
      }
    } else if (character === '"') {
      if (state !== 'start') {
        throw new Error(`unexpected quote in unquoted field at line ${lineNumber}`);
      }
      state = 'quoted';
      recordStarted = true;
      continue;
    } else if (character === ',') {
      finishField();
      recordStarted = true;
      continue;
    } else if (character !== '\r' && character !== '\n') {
      field += character;
      state = 'unquoted';
      recordStarted = true;
      continue;
    }

    if (character === '\r') {
      if (text[index + 1] !== '\n') {
        throw new Error(`bare carriage return in CSV at line ${lineNumber}`);
      }
      index += 1;
    }
    finishRecord();
    lineNumber += 1;
    recordLineNumber = lineNumber;
  }

  if (state === 'quoted') {
    throw new Error(`unterminated quoted field starting at line ${recordLineNumber}`);
  }
  if (recordStarted || fields.length > 0 || field.length > 0) finishRecord();
  return records;
}

function validateSixToFourFixture(text) {
  const lines = text
    .split(/\r\n|[\n\r\u0085\u2028\u2029]/)
    .filter(line => /^(?:\p{White_Space}|\uFEFF)*6to4\b/iu.test(line));
  if (lines.length !== 1) {
    throw new Error('IPv6 transition fixture must contain exactly one 6to4 record');
  }

  const match = lines[0].match(
    /^6to4 prefix=2002:([0-9a-f]{4}):([0-9a-f]{4})::\/48 embedded_ipv4=([0-9]{1,3}(?:\.[0-9]{1,3}){3})$/i,
  );
  if (!match) throw new Error('invalid 6to4 fixture syntax');

  const octets = match[3].split('.').map(Number);
  if (octets.length !== 4 || octets.some(value => value < 0 || value > 255)) {
    throw new Error(`invalid embedded IPv4 address in 6to4 fixture: ${match[3]}`);
  }

  const embeddedHex = (match[1] + match[2]).toLowerCase();
  const expectedHex = octets
    .map(value => value.toString(16).padStart(2, '0'))
    .join('');
  if (embeddedHex !== expectedHex) {
    const embeddedAddress = embeddedHex
      .match(/.{2}/g)
      .map(value => Number.parseInt(value, 16))
      .join('.');
    throw new Error(
      `6to4 prefix embeds ${embeddedAddress} but fixture declares ${match[3]}`,
    );
  }

  return { prefix: `2002:${match[1]}:${match[2]}::/48`, ipv4: match[3] };
}

function rejectDuplicateJsonKeys(text) {
  function skipWhitespace(index) {
    while (/\s/.test(text[index] || '')) index += 1;
    return index;
  }

  function scanString(index) {
    const start = index;
    index += 1;
    while (index < text.length) {
      if (text[index] === '\\') {
        index += 2;
      } else if (text[index] === '"') {
        const end = index + 1;
        return { value: JSON.parse(text.slice(start, end)), end };
      } else {
        index += 1;
      }
    }
    throw new Error('unterminated JSON string');
  }

  function scanValue(index, path) {
    index = skipWhitespace(index);
    if (text[index] === '"') return scanString(index).end;
    if (text[index] === '{') return scanObject(index, path);
    if (text[index] === '[') return scanArray(index, path);
    while (index < text.length && !/[\s,\]}]/.test(text[index])) index += 1;
    return index;
  }

  function scanObject(index, path) {
    const keys = new Set();
    index = skipWhitespace(index + 1);
    if (text[index] === '}') return index + 1;
    while (index < text.length) {
      const key = scanString(index);
      if (keys.has(key.value)) {
        throw new Error(`duplicate JSON key ${JSON.stringify(key.value)} at ${path}`);
      }
      keys.add(key.value);
      index = skipWhitespace(key.end);
      index = skipWhitespace(index + 1);
      index = scanValue(index, `${path}.${key.value}`);
      index = skipWhitespace(index);
      if (text[index] === '}') return index + 1;
      index = skipWhitespace(index + 1);
    }
    throw new Error('unterminated JSON object');
  }

  function scanArray(index, path) {
    index = skipWhitespace(index + 1);
    if (text[index] === ']') return index + 1;
    let item = 0;
    while (index < text.length) {
      index = scanValue(index, `${path}[${item}]`);
      index = skipWhitespace(index);
      if (text[index] === ']') return index + 1;
      index = skipWhitespace(index + 1);
      item += 1;
    }
    throw new Error('unterminated JSON array');
  }

  scanValue(0, '$');
}

function nestedProtocolPaths(value, path = '$') {
  if (value === null || typeof value !== 'object') return [];
  const paths = [];
  for (const [key, child] of Object.entries(value)) {
    const childPath = Array.isArray(value) ? `${path}[${key}]` : `${path}.${key}`;
    if (key === 'protocol' && path !== '$') paths.push(childPath);
    paths.push(...nestedProtocolPaths(child, childPath));
  }
  return paths;
}

function sixToFourMentions(value, path = '$') {
  if (typeof value === 'string') {
    return /6to4/i.test(value) ? [path] : [];
  }
  if (value === null || typeof value !== 'object') return [];
  const paths = [];
  for (const [key, child] of Object.entries(value)) {
    const childPath = Array.isArray(value) ? `${path}[${key}]` : `${path}.${key}`;
    if (/6to4/i.test(key)) paths.push(`${childPath} (key)`);
    paths.push(...sixToFourMentions(child, childPath));
  }
  return paths;
}

function validateSitMetadata(capture) {
  if (capture === null || Array.isArray(capture) || typeof capture !== 'object') {
    throw new Error('SIT capture metadata must be a JSON object');
  }
  if (capture.protocol !== 'sit-ipv6-in-ipv4') {
    throw new Error(
      `private SIT capture must use protocol sit-ipv6-in-ipv4, got ${JSON.stringify(capture.protocol)}`,
    );
  }
  if (capture.evidence_level !== 'real-capture') {
    throw new Error('the packet-backed SIT record must remain real-capture evidence');
  }
  if (capture.experiment !== 'm15-private-ipv6-in-ipv4-netns') {
    throw new Error('unexpected M15 SIT experiment identifier');
  }
  const nestedProtocols = nestedProtocolPaths(capture);
  if (nestedProtocols.length > 0) {
    throw new Error(
      `SIT capture metadata contains nested protocol labels: ${nestedProtocols.join(', ')}`,
    );
  }
  if (
    !Array.isArray(capture.notes) ||
    capture.notes.length !== 1 ||
    capture.notes[0] !== SIT_LIMITATION_NOTE
  ) {
    throw new Error('SIT capture metadata must preserve the public-6to4 limitation');
  }
  const mentions = sixToFourMentions(capture);
  if (mentions.length !== 1 || mentions[0] !== '$.notes[0]') {
    throw new Error(`conflicting 6to4 claims in SIT metadata: ${mentions.join(', ')}`);
  }
}

function validateSitGenerator(generatorText) {
  const lines = generatorText.split(/\r?\n/);
  const canonicalCleanupDefinitions = new Set([
    'cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo ip netns del "$A" 2>/dev/null || true; sudo ip netns del "$B" 2>/dev/null || true; sudo rm -rf "$TMP"; }',
    'cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo ip netns del "$A" 2>/dev/null || true; sudo ip netns del "$B" 2>/dev/null || true; [ -z "$TMP" ] || sudo rm -rf "$TMP"; }',
  ]);
  const cleanupDefinitions = lines
    .map((line, index) => ({ index, line }))
    .filter(({ line }) => /^cleanup\s*\(\)/.test(line));
  const cleanupMentions = generatorText.match(/\bcleanup\b/g) || [];
  if (
    cleanupDefinitions.length !== 1 ||
    !canonicalCleanupDefinitions.has(cleanupDefinitions[0].line) ||
    cleanupMentions.length !== 4
  ) {
    throw new Error('SIT capture generator must preserve its canonical cleanup function');
  }
  const cleanupRebinding = lines
    .slice(cleanupDefinitions[0].index + 1)
    .some(line => {
      const code = line.trimStart();
      return (
        !code.startsWith('#') &&
        /^(?:\.|alias\b|eval\b|function\b|source\b|unalias\b|unset\b)/.test(code)
      );
    });
  if (cleanupRebinding) {
    throw new Error('SIT capture generator cannot rebind cleanup after its definition');
  }
  const heredocOperators = lines.flatMap(line => {
    const code = line.trimStart();
    return code.startsWith('#') ? [] : code.match(/<</g) || [];
  });
  if (heredocOperators.length !== 1) {
    throw new Error('SIT capture generator must contain exactly one metadata heredoc');
  }
  const heredocs = [];
  for (let index = 0; index < lines.length; index += 1) {
    const opener = lines[index].match(
      /^cat >"(\$(?:ROOT\/\$OUT|OUT_DIR)\/sit-ipv6-in-ipv4\.json)" <<([A-Za-z_][A-Za-z0-9_]*)[ \t]*$/,
    );
    if (!opener) continue;
    const end = lines.indexOf(opener[2], index + 1);
    if (end === -1) throw new Error('SIT capture generator has an unclosed metadata heredoc');
    heredocs.push({
      body: lines.slice(index + 1, end),
      end,
      metadataPath: opener[1],
      start: index,
    });
    index = end;
  }
  if (heredocs.length !== 1 || heredocs[0].body.length !== 1) {
    throw new Error('SIT capture generator must emit one canonical metadata JSON line');
  }
  const [{ body, end, metadataPath, start }] = heredocs;
  const captureDirectory = metadataPath.slice(0, -'/sit-ipv6-in-ipv4.json'.length);
  const expectedFramesLine =
    `frames=$(tshark -r "${captureDirectory}/sit-ipv6-in-ipv4.pcapng" ` +
    '-T fields -e frame.number | wc -l); [ "$frames" -gt 0 ]';
  if (lines[start - 2] !== expectedFramesLine || lines[start - 1] !== 'cleanup') {
    throw new Error(
      'SIT capture generator must verify frames, then clean up immediately before writing metadata',
    );
  }
  const metadataLine = body[0];
  const metadataProtocolKeys = Array.from(metadataLine.matchAll(/"protocol"\s*:/g));
  if (
    metadataProtocolKeys.length !== 1 ||
    !metadataLine.startsWith('{"protocol":"sit-ipv6-in-ipv4",')
  ) {
    throw new Error('SIT capture generator emits an incorrect protocol label');
  }
  const notesSuffix = `"notes":[${JSON.stringify(SIT_LIMITATION_NOTE)}]}`;
  if (!metadataLine.endsWith(notesSuffix)) {
    throw new Error('SIT capture generator emits an incorrect 6to4 limitation');
  }
  let generatedCapture;
  try {
    rejectDuplicateJsonKeys(metadataLine);
    const rendered = metadataLine.replace('"frames":$frames', '"frames":1');
    if (rendered === metadataLine) {
      throw new Error('metadata template is missing the frames placeholder');
    }
    generatedCapture = JSON.parse(rendered);
  } catch (error) {
    throw new Error(`invalid SIT generator metadata template: ${error.message}`);
  }
  validateSitMetadata(generatedCapture);

  const expectedTail = [
    `jsonschema -i "${metadataPath}" "$ROOT/schemas/experiment.schema.json"`,
    'trap - EXIT INT TERM',
    `printf 'M15 private IPv6 transition: pass (%s frames)\\n' "$frames"`,
  ];
  const tail = lines.slice(end + 1);
  if (tail.at(-1) === '') tail.pop();
  if (
    tail.length !== expectedTail.length ||
    tail.some((line, index) => line !== expectedTail[index])
  ) {
    throw new Error(
      'SIT capture generator must preserve its canonical post-metadata validation tail',
    );
  }

  const allProtocolKeys = Array.from(
    generatorText.matchAll(/"((?:\\.|[^"\\])*)"\s*:/g),
    match => {
      try {
        return JSON.parse(`"${match[1]}"`);
      } catch {
        return null;
      }
    },
  ).filter(key => key === 'protocol');
  if (allProtocolKeys.length !== 1) {
    throw new Error('SIT capture generator must contain exactly one protocol key');
  }
  const sixToFourLabels = generatorText.match(/6to4/gi) || [];
  if (sixToFourLabels.length !== 1) {
    throw new Error('SIT capture generator must contain exactly one 6to4 limitation');
  }
}

function validateSitCapture(captureText, generatorText) {
  let capture;
  try {
    capture = JSON.parse(captureText);
    rejectDuplicateJsonKeys(captureText);
  } catch (error) {
    throw new Error(`invalid SIT capture metadata JSON: ${error.message}`);
  }
  validateSitMetadata(capture);
  validateSitGenerator(generatorText);
  return capture;
}

function validateEvidence(datasetText, fixtureText, captureText, generatorText) {
  const rows = parseDataset(datasetText);
  const sixToFour = rows.find(row => row[0] === '6to4');
  if (!sixToFour) throw new Error('era2.csv is missing the 6to4 record');
  if (sixToFour[5] !== 'fixture') {
    throw new Error(
      '6to4 must remain fixture evidence: the private SIT capture does not ' +
        'exercise 6to4 addressing or a relay',
    );
  }

  return {
    rows,
    sixToFourFixture: validateSixToFourFixture(fixtureText),
    sitCapture: validateSitCapture(captureText, generatorText),
  };
}

function main() {
  const result = validateEvidence(
    fs.readFileSync(DATASET_PATH, 'utf8'),
    fs.readFileSync(SIX_TO_FOUR_FIXTURE_PATH, 'utf8'),
    fs.readFileSync(SIT_CAPTURE_PATH, 'utf8'),
    fs.readFileSync(SIT_GENERATOR_PATH, 'utf8'),
  );
  console.log(`Era 2 evidence validation: pass (${result.rows.length} records)`);
}

if (require.main === module) main();

module.exports = {
  DATASET_PATH,
  SIX_TO_FOUR_FIXTURE_PATH,
  SIT_CAPTURE_PATH,
  SIT_GENERATOR_PATH,
  SIT_LIMITATION_NOTE,
  parseCsv,
  parseDataset,
  rejectDuplicateJsonKeys,
  sixToFourMentions,
  validateEvidence,
  validateSixToFourFixture,
  validateSitCapture,
  validateSitGenerator,
  validateSitMetadata,
};
