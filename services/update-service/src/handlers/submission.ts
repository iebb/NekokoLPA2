import type { D1Database } from "@cloudflare/workers-types";
import type { Env } from '../types.ts';

/**
 * Handles App Store Connect webhooks.
 * Tracks status changes in the 'submissions' database and updates
 * production records when a version is READY_FOR_DISTRIBUTION.
 */
export async function handleSubmission(request: Request, body: any, env: Env, appName: string, db: D1Database): Promise<Response> {
    const url = new URL(request.url);

    // Check if this is an Apple App Store Connect Webhook
    // App Store Connect webhooks usually have notificationType at the top level
    const notificationType = body.notificationType;

    if (notificationType) {
        return await handleAppleAppStoreWebhook(body, env, appName, db);
    }

    // Fallback to manual/generic submission handling
    return await handleManualSubmission(url, body, env, appName, db);
}

async function handleAppleAppStoreWebhook(body: any, env: Env, appName: string, db: D1Database): Promise<Response> {
    const data = body.data;
    if (!data) return new Response('Invalid Apple webhook payload (missing data)', { status: 400 });

    // App Store Connect Webhook Schema
    const appId = data.app?.id;
    const bundleId = data.app?.bundleId;
    const versionInfo = data.appStoreVersion;

    // The state can be in versionInfo.attributes.state or versionInfo.state depending on API version
    const state = versionInfo?.attributes?.state || versionInfo?.state;
    const platformStr = versionInfo?.attributes?.platform || versionInfo?.platform; // IOS, MAC_OS
    const versionString = versionInfo?.attributes?.versionString || versionInfo?.versionString;

    // 1. Log to 'submissions' table
    try {
        await db.prepare(`
            INSERT INTO submissions (app_name, appId, bundleId, version, platform, state, notificationType, raw, timestamp)
            VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
        `).bind(
            appName,
            appId,
            bundleId,
            versionString,
            platformStr,
            state,
            body.notificationType,
            JSON.stringify(body),
            new Date().toISOString()
        ).run();
    } catch (e) {
        console.error("Failed to log submission status to D1", e);
    }

    // 2. Mapping logic: App ID/Bundle ID + Platform -> Variant
    let variantId: string | null = null;
    const isIOS = platformStr === 'IOS';
    const isMacOS = platformStr === 'MAC_OS';

    if (appId === "6757540723" || bundleId === "ee.nekoko.nlpa.std") {
        variantId = isMacOS ? "macos-std" : "ios-std";
    } else if (appId === "6746965678" || bundleId === "ee.nekoko.nlpa.flavor1") {
        variantId = "ios-9esim";
    }

    // 3. Update production records if Ready for Distribution
    if (variantId && state === 'READY_FOR_DISTRIBUTION') {
        const platform = isMacOS ? 'macos' : 'ios';
        const identifier = variantId.split('-').slice(1).join('-');

        let buildNumber = 0;
        let changelog = `App Store version ${versionString} is now available.`;

        const tfRecord = await db.prepare('SELECT data FROM app_updates WHERE app_name = ? AND platform = ? AND identifier = ?')
            .bind(appName, platform, `${identifier}-testflight`).first();

        let dataObj: any = {};
        if (tfRecord && tfRecord.data) {
            try {
                const tfData = JSON.parse(tfRecord.data as string);
                if (tfData.version === versionString) {
                    buildNumber = tfData.build || 0;
                    changelog = tfData.changelog || changelog;
                }
            } catch (e) { }
        }

        const existing = await db.prepare('SELECT data FROM app_updates WHERE app_name = ? AND platform = ? AND identifier = ?')
            .bind(appName, platform, identifier).first();

        if (existing && existing.data) {
            try {
                dataObj = JSON.parse(existing.data as string);
            } catch (e) { }
        }

        dataObj.version = versionString;
        dataObj.build = buildNumber;
        dataObj.changelog = changelog;
        dataObj.published_at = new Date().toISOString();

        const updated_at = new Date().toISOString();
        const urlValue = dataObj.url || dataObj.download_url || '';

        await db.prepare(`
            INSERT INTO app_updates (app_name, platform, identifier, version, build, url, data, updated_at)
            VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
            ON CONFLICT(app_name, platform, identifier) DO UPDATE SET
                version = excluded.version,
                build = excluded.build,
                url = excluded.url,
                data = excluded.data,
                updated_at = excluded.updated_at
        `).bind(appName, platform, identifier, dataObj.version || '', dataObj.build || 0, urlValue, JSON.stringify(dataObj), updated_at).run();

        return new Response(JSON.stringify({
            success: true,
            message: `Submission Accepted: Updated ${variantId} to v${versionString}`
        }), { headers: { 'Content-Type': 'application/json' } });
    }

    return new Response(JSON.stringify({
        success: true,
        message: `Processed ${body.notificationType}: ${bundleId} is now ${state}`
    }), { headers: { 'Content-Type': 'application/json' } });
}

async function handleManualSubmission(url: URL, body: any, env: Env, appName: string, db: D1Database): Promise<Response> {
    const variant = url.searchParams.get('variant') || body.variant;
    const version = body.version;
    const build = body.build;
    const changelog = body.changelog;
    const commit = body.commit;

    if (!variant) return new Response('Missing variant parameter', { status: 400 });

    const parts = variant.split('-');
    const platform = parts[0];
    const identifier = parts.slice(1).join('-');

    let finalVersion = version;
    let finalBuild = parseInt(build) || 0;

    if ((!finalVersion || !finalBuild) && commit) {
        const gitInfo = await db.prepare('SELECT version, build FROM git_records WHERE app_name = ? AND commit_hash = ?')
            .bind(appName, commit).first();
        if (gitInfo) {
            finalVersion = finalVersion || (gitInfo.version as string);
            finalBuild = finalBuild || (gitInfo.build as number);
        }
    }

    if (!finalVersion) {
        const tfRecord = await db.prepare('SELECT data FROM app_updates WHERE app_name = ? AND platform = ? AND identifier = ?')
            .bind(appName, platform, `${identifier}-testflight`).first();

        if (tfRecord && tfRecord.data) {
            try {
                const tfData = JSON.parse(tfRecord.data as string);
                finalVersion = tfData.version;
                finalBuild = finalBuild || tfData.build;
            } catch (e) { }
        }
    }

    if (!finalVersion) return new Response('Could not determine version', { status: 400 });

    const existing = await db.prepare('SELECT data FROM app_updates WHERE app_name = ? AND platform = ? AND identifier = ?')
        .bind(appName, platform, identifier).first();

    let dataObj: any = {};
    if (existing && existing.data) {
        try {
            dataObj = JSON.parse(existing.data as string);
        } catch (e) { }
    }

    dataObj.version = finalVersion;
    dataObj.build = finalBuild;
    dataObj.changelog = changelog || "Version update";
    dataObj.published_at = new Date().toISOString();

    const updated_at = new Date().toISOString();
    const urlValue = dataObj.url || dataObj.download_url || '';

    await db.prepare(`
        INSERT INTO app_updates (app_name, platform, identifier, version, build, url, data, updated_at)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
        ON CONFLICT(app_name, platform, identifier) DO UPDATE SET
            version = excluded.version,
            build = excluded.build,
            url = excluded.url,
            data = excluded.data,
            updated_at = excluded.updated_at
    `).bind(appName, platform, identifier, dataObj.version || '', dataObj.build || 0, urlValue, JSON.stringify(dataObj), updated_at).run();

    return new Response(JSON.stringify({ success: true, message: `Manual update for ${variant} successful.` }));
}
