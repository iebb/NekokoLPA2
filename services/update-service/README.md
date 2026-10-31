# Public update and config service

The source for both legacy NekokoLPA update Workers lives here:

- `src/update.ts`: authenticated manual updates, source-commit records, Xcode Cloud notifications and App Store submission events.
- `src/config.ts`: public config feeds, shared update-entry normalization and edge caching.
- `schema.sql`: schema for a new local/test database. It is not automatically applied to a production database.

The existing Kasutera deployment directories import these handlers. Their Worker names, compatibility dates, D1 bindings, credentials and deployment commands remain in that repository. Moving this source does not deploy a Worker or alter stored update records.

## Local checks

Use Node 26 and the committed npm lockfile:

```sh
npm ci
npm run typecheck
npm test
npm run bundle:update
npm run bundle:config
```

Tests use a fresh in-memory SQLite database and simulated edge cache. They exercise authorization, direct artifact URLs and signatures, cache lifetime handling, git version lookup and Apple webhook routing. They do not access Cloudflare, Apple or production databases. Bundle commands use Wrangler's dry-run mode.

The two JSONC configurations are local examples with placeholder database IDs. For local development, copy `.dev.vars.example` to an ignored `.dev.vars` and choose a development access key. Never publish a production key or local `.wrangler` state. Supply the deployed writer's `ACCESS_KEY` through a Worker secret. The reader needs no access key.

`worker-configuration.d.ts` is generated with:

```sh
npx wrangler types worker-configuration.d.ts --config wrangler.update.jsonc --env-interface ServiceBindings --include-runtime=false
```

Existing query-key webhook compatibility is retained. For new callers, use the `X-Access-Key` header. Local type generation uses the example variable names; production credentials are not part of the generated types.
