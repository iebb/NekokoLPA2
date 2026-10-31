import type { D1Database } from "@cloudflare/workers-types";
import type { Env } from '../types.ts';

export async function handleGitRecord(request: Request, body: any, env: Env, appName: string, db: D1Database): Promise<Response> {
    try {
        const { commit, version, build } = body;

        if (!commit || !version) {
            return new Response('Missing commit or version', { status: 400 });
        }

        const updated_at = new Date().toISOString();
        const buildNum = parseInt(build) || 0;

        await db.prepare(`
            INSERT INTO git_records (app_name, commit_hash, version, build, updated_at)
            VALUES (?1, ?2, ?3, ?4, ?5)
            ON CONFLICT(app_name, commit_hash) DO UPDATE SET
                version = excluded.version,
                build = excluded.build,
                updated_at = excluded.updated_at
        `).bind(appName, commit, version, buildNum, updated_at).run();

        return new Response(JSON.stringify({ success: true, message: 'Git relation recorded.' }), {
            headers: { 'Content-Type': 'application/json' },
        });
    } catch (err: any) {
        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        });
    }
}
