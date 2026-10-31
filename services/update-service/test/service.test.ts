import { afterEach, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import update from '../src/update.ts';
import config from '../src/config.ts';

let sqlite: DatabaseSync;
let env: any;
let background: Promise<unknown>[];
const context = { waitUntil(promise: Promise<unknown>) { background.push(promise); } };

beforeEach(() => {
  sqlite = new DatabaseSync(':memory:');
  sqlite.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  env = {
    DEFAULT_COLLECTION: 'app_updates', ACCESS_KEY: 'test-access-key',
    DB: {
      prepare(sql: string) {
        let values: any[] = [];
        const query = sqlite.prepare(sql.replace(/\?\d+/g, '?'));
        return {
          bind(...arguments_: any[]) { values = arguments_; return this; },
          async first() { return query.get(...values) ?? null; },
          async all() { return { results: query.all(...values) }; },
          async run() { query.run(...values); return { success: true }; },
        };
      },
    },
  };
  background = [];
  const cached = new Map<string, Response>();
  Object.defineProperty(globalThis, 'caches', { configurable: true, value: {
    default: {
      async match(request: Request) { return cached.get(request.url)?.clone(); },
      async put(request: Request, response: Response) { cached.set(request.url, response.clone()); },
    },
  } });
});
afterEach(async () => { await Promise.all(background); sqlite.close(); });

async function write(body: unknown, path = '/app_updates.json', key = 'test-access-key') {
  return update.fetch(new Request('https://writer.example.test' + path, {
    method: 'POST', headers: { 'X-Access-Key': key, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }), env);
}
async function read() {
  return config.fetch(new Request('https://reader.example.test/app_updates.json'), env, context);
}

test('writes fail closed without a valid configured access key', async () => {
  assert.equal((await write({}, '/app_updates.json', 'wrong')).status, 401);
  env.ACCESS_KEY = '';
  assert.equal((await write({})).status, 401);
  assert.equal(sqlite.prepare('SELECT COUNT(*) AS count FROM app_updates').get()!.count, 0);
});

test('entry points retain their read and write method boundaries', async () => {
  assert.equal((await update.fetch(new Request('https://writer.example.test'), env)).status, 405);
  assert.equal((await config.fetch(new Request('https://reader.example.test', { method: 'POST' }), env, context)).status, 405);
});

test('manual updates preserve direct artifact URLs and signature metadata in public feeds', async () => {
  const download = 'https://github.com/iebb/NekokoLPA2/releases/download/v2.4.2%2B602/example.apk';
  const response = await write({ platform: 'android', identifier: 'community', data: {
    version: '2.4.2', build: 602, url: 'https://example.test/release', download_url: download,
    signatures: ['TEST-SIGNER'], file_size: 123,
  } });
  assert.equal(response.status, 200);
  const feed = await (await read()).json();
  assert.equal(feed.android.community.download_url, download);
  assert.deepEqual(feed.android.community.signatures, ['TEST-SIGNER']);
  assert.equal(feed.android.community.build, 602);
});

test('reader cache is populated through waitUntil and serves a later hit', async () => {
  assert.equal((await read()).headers.get('X-Config-Cache'), 'MISS');
  await Promise.all(background);
  assert.equal((await read()).headers.get('X-Config-Cache'), 'HIT');
});

test('a missing manual-update field returns an error without writing', async () => {
  assert.equal((await write({ platform: 'ios' })).status, 400);
  assert.equal(sqlite.prepare('SELECT COUNT(*) AS count FROM app_updates').get()!.count, 0);
});

test('git records resolve version and build for successful Xcode Cloud notifications', async () => {
  assert.equal((await write({ commit: 'test-commit', version: '2.4.2', build: '602' }, '/app_updates/git')).status, 200);
  const response = await write({
    app: { id: '6757540723' }, ciProduct: { attributes: { name: 'Nekoko iOS' } },
    ciBuildRun: { attributes: { completionStatus: 'SUCCEEDED', number: '100', sourceCommit: { commitSha: 'test-commit' } } },
  });
  assert.equal(response.status, 200);
  const feed = await (await read()).json();
  assert.equal(feed.ios['std-testflight'].version, '2.4.2');
  assert.equal(feed.ios['std-testflight'].build, 602);
  assert.equal(feed.ios['std-testflight'].appleBuild, 100);
});

test('failed Xcode Cloud notifications do not publish a build', async () => {
  const response = await write({ ciBuildRun: { attributes: { completionStatus: 'FAILED' } } });
  assert.equal(response.status, 200);
  assert.equal(sqlite.prepare('SELECT COUNT(*) AS count FROM app_updates').get()!.count, 0);
});

test('ready-for-distribution webhook promotes the matching TestFlight build', async () => {
  await write({ platform: 'ios', identifier: 'std-testflight', data: { version: '2.4.2', build: 602 } });
  const response = await write({ notificationType: 'APP_STORE_VERSION_STATE_CHANGED', data: {
    app: { id: '6757540723', bundleId: 'ee.nekoko.nlpa.std' },
    appStoreVersion: { attributes: { state: 'READY_FOR_DISTRIBUTION', platform: 'IOS', versionString: '2.4.2' } },
  } });
  assert.equal(response.status, 200);
  const feed = await (await read()).json();
  assert.equal(feed.ios.std.build, 602);
  assert.equal(sqlite.prepare('SELECT COUNT(*) AS count FROM submissions').get()!.count, 1);
});

test('manual submissions can derive a version from a git relation', async () => {
  await write({ commit: 'test-commit', version: '2.4.2', build: 602 }, '/app_updates/git');
  const response = await write({ variant: 'macos-std', commit: 'test-commit' }, '/app_updates?type=submission');
  assert.equal(response.status, 200);
  const feed = await (await read()).json();
  assert.equal(feed.macos.std.version, '2.4.2');
  assert.equal(feed.macos.std.build, 602);
});
