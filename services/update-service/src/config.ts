import { toUpdateFeedEntry } from "../../../tools/update_feed_entry.ts";

import type { Env } from './types.ts';

export default {
    async fetch(request: Request, env: Env, ctx: any): Promise<Response> {
        if (request.method !== 'GET') {
            return new Response('Method not allowed. Use GET.', { status: 405 });
        }

        const url = new URL(request.url);

        // 1. Basic Caching Logic
        const cache = (caches as any).default;
        // Separate this representation from cached responses that replaced artifact URLs.
        const cacheKey = new Request(`${url.origin}${url.pathname}?feed-schema=2`, request);

        let response = await cache.match(cacheKey);
        if (response) {
            const hitHeaders = new Headers(response.headers);
            hitHeaders.set('X-Config-Cache', 'HIT');
            return new Response(response.body, { headers: hitHeaders });
        }

        try {
            // Extract app name from path
            let appName = url.pathname.split('/')[1];
            if (!appName || appName === '') {
                appName = env.DEFAULT_COLLECTION || 'app_updates';
            }

            if (appName.endsWith('.json')) {
                appName = appName.substring(0, appName.length - 5);
            }

            const config: any = {};

            // Retrieve all builds from D1
            const stmt = env.DB.prepare('SELECT platform, identifier, version, build, url, data FROM app_updates WHERE app_name = ?');
            const { results } = await stmt.bind(appName).all();

            const builds = results || [];

            for (const build of builds) {
                const platform = build.platform as string;
                const identifier = build.identifier as string;
                const data = toUpdateFeedEntry({
                    version: build.version as string,
                    build: build.build as number,
                    url: build.url as string | null,
                    data: build.data as string,
                });

                if (!config[platform]) {
                    config[platform] = {};
                }
                config[platform][identifier] = data;
            }

            let responseBody = JSON.stringify(config, null, 4);
            const countryHeader = (request as any).cf?.country || 'Unknown';

            response = new Response(responseBody, {
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'X-Visitor-Country': countryHeader,
                    'X-Config-Cache': 'MISS',
                    // Cache on Cloudflare's edge for 5 minutes
                    'Cache-Control': 'public, s-maxage=300'
                },
            });

            // Store in cache for future requests
            ctx.waitUntil(cache.put(cacheKey, response.clone()));

            return response;
        } catch (err: any) {
            return new Response(JSON.stringify({ error: err.message }), {
                status: 500,
                headers: { 'Content-Type': 'application/json' },
            });
        }
    },
};
