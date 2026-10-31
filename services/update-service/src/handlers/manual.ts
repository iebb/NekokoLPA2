import type { D1Database } from "@cloudflare/workers-types";
import type { Env } from '../types.ts';

export async function handleManualUpdate(request: Request, body: any, env: Env, appName: string, db: D1Database): Promise<Response> {
    const { platform, identifier, data } = body;

    if (!platform || !identifier || !data) {
        return new Response('Missing required fields: platform, identifier, data', { status: 400 });
    }

    const updated_at = new Date().toISOString();
    const version = data.version || '';
    const build = data.build || 0;
    const url = data.url || data.download_url || '';

    await db.prepare(`
        INSERT INTO app_updates (app_name, platform, identifier, version, build, url, data, updated_at)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
        ON CONFLICT(app_name, platform, identifier) DO UPDATE SET
            version = excluded.version,
            build = excluded.build,
            url = excluded.url,
            data = excluded.data,
            updated_at = excluded.updated_at
    `).bind(appName, platform, identifier, version, build, url, JSON.stringify(data), updated_at).run();

    return new Response(JSON.stringify({
        success: true,
        message: `Build for ${platform}/${identifier} updated successfully via Manual API.`
    }), {
        headers: { 'Content-Type': 'application/json' },
    });
}
