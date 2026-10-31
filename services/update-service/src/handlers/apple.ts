import type { D1Database } from "@cloudflare/workers-types";
import type { Env, BuildData } from '../types.ts';

async function getVersionFromGit(db: D1Database, appName: string, commitHash: string): Promise<{ version: string, build: number } | null> {
    try {
        const stmt1 = db.prepare('SELECT version, build FROM git_records WHERE app_name = ? AND commit_hash = ?');
        const result1 = await stmt1.bind(appName, commitHash).first();
        if (result1) {
            return {
                version: result1.version as string,
                build: result1.build as number
            };
        } else {
            const stmt2 = db.prepare('SELECT version, build FROM git_records WHERE app_name = ? ORDER BY updated_at DESC LIMIT 1');
            const result2 = await stmt2.bind(appName).first();
            if (result2) {
                return {
                    version: result2.version as string,
                    build: result2.build as number
                };
            }
        }
    } catch (e) {
        console.error("Git lookup failed", e);
    }
    return null;
}

export async function handleAppleWebhook(request: Request, body: any, env: Env, appName: string, db: D1Database): Promise<Response> {
    const url = new URL(request.url);
    const buildRun = body.ciBuildRun || (body.data?.type === 'ciBuildRuns' ? body.data : null);

    if (!buildRun) {
        return new Response('Invalid Apple webhook payload', { status: 400 });
    }

    const workflow = body.ciWorkflow || body.included?.find((i: any) => i.type === 'ciWorkflows');
    const product = body.ciProduct || body.included?.find((i: any) => i.type === 'ciProducts');

    // Only process completed successful builds
    const status = buildRun.attributes?.completionStatus;
    if (status && status !== 'SUCCEEDED') {
        return new Response(JSON.stringify({
            success: true,
            message: `Xcode build status is ${status}. Skipping update.`
        }), { headers: { 'Content-Type': 'application/json' } });
    }

    const productName = product?.attributes?.name || '';
    const workflowName = workflow?.attributes?.name || '';

    let platform: string | undefined;
    if (productName.toLowerCase().includes('ios') || workflowName.toLowerCase().includes('ios')) {
        platform = 'ios';
    } else if (productName.toLowerCase().includes('macos') || workflowName.toLowerCase().includes('macos')) {
        platform = 'macos';
    } else {
        platform = productName.toLowerCase().includes('nekoko') ? 'ios' : undefined;
    }

    if (!platform) {
        return new Response('Could not determine platform (ios/macos) from Xcode webhook', { status: 400 });
    }
    const appleAppId = body.app?.id || buildRun.relationships?.app?.data?.id || body.data?.relationships?.app?.data?.id || "6757540723";
    let appId: string = ({
        "6757540723": "std",
        "6746965678": "esim9"
    } as any)[appleAppId] || "std";

    const isTestFlight = true; //workflowName.toLowerCase().includes('testflight');
    const identifier = isTestFlight ? `${appId}-testflight` : appId;

    // Attempt to find version/build from git DB
    let version = "2.0.2";
    let buildNumber = 0;

    const commitHash = buildRun.attributes?.sourceCommit?.commitSha;

    if (commitHash) {
        const gitInfo = await getVersionFromGit(db, appName, commitHash);
        if (gitInfo) {
            version = gitInfo.version;
            buildNumber = gitInfo.build;
        }
    }

    const existing = await db.prepare('SELECT data FROM app_updates WHERE app_name = ? AND platform = ? AND identifier = ?')
        .bind(appName, platform, identifier).first();

    let dataObj: any = {};
    if (existing && existing.data) {
        try {
            dataObj = JSON.parse(existing.data as string);
        } catch (e) { }
    }

    dataObj.version = version;
    dataObj.appleAppId = body.app?.id;
    dataObj.commitHash = commitHash;
    dataObj.appleBuild = parseInt(buildRun.attributes?.number) || 0;
    dataObj.changelog = `Xcode Cloud Build ${buildRun.attributes?.number} succeeded.`;
    dataObj.published_at = new Date().toISOString();

    if (buildNumber) {
        dataObj.build = buildNumber;
    }

    const updated_at = new Date().toISOString();
    const urlValue = dataObj.url || dataObj.download_url || '';

    await db.prepare(`
        INSERT INTO app_updates (app_name, platform, identifier, version, build, url, data, updated_at, raw)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
        ON CONFLICT(app_name, platform, identifier) DO UPDATE SET
            version = excluded.version,
            build = excluded.build,
            url = excluded.url,
            data = excluded.data,
            updated_at = excluded.updated_at,
            raw = excluded.raw
    `).bind(appName, platform, identifier, dataObj.version || '', dataObj.build || 0, urlValue, JSON.stringify(dataObj), updated_at, JSON.stringify(body)).run();

    return new Response(JSON.stringify({
        success: true,
        message: `Build for ${platform}/${identifier} updated successfully via Xcode Webhook.`
    }), {
        headers: { 'Content-Type': 'application/json' },
    });
}
