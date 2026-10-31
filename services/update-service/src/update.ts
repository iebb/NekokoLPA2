import type { Env } from './types.ts';
import { handleGitRecord } from './handlers/git.ts';
import { handleAppleWebhook } from './handlers/apple.ts';
import { handleManualUpdate } from './handlers/manual.ts';
import { handleSubmission } from './handlers/submission.ts';

export default {
    async fetch(request: Request, env: Env): Promise<Response> {
        if (request.method !== 'POST') {
            return new Response('Method not allowed. Use POST.', { status: 405 });
        }

        const url = new URL(request.url);
        const authKey = request.headers.get('X-Access-Key') || url.searchParams.get('key');

        if (!env.ACCESS_KEY || authKey !== env.ACCESS_KEY) {
            return new Response('Unauthorized', { status: 401 });
        }

        const pathSegments = url.pathname.split('/').filter(s => s !== '');
        let appName = pathSegments[0];
        const isGitEndpoint = pathSegments[1] === 'git';

        if (!appName || appName === '') {
            appName = env.DEFAULT_COLLECTION || 'app_updates';
        }

        if (appName.endsWith('.json')) {
            appName = appName.substring(0, appName.length - 5);
        }

        try {
            const body = await request.json() as any;
            const type = url.searchParams.get('type');

            if (isGitEndpoint) {
                return await handleGitRecord(request, body, env, appName, env.DB);
            } else if (type === 'submission' || body.notificationType) {
                return await handleSubmission(request, body, env, appName, env.DB);
            } else if (type === 'apple' || body.ciBuildRun || (body.data?.type === 'ciBuildRuns')) {
                return await handleAppleWebhook(request, body, env, appName, env.DB);
            } else {
                return await handleManualUpdate(request, body, env, appName, env.DB);
            }
        } catch (e: any) {
            return new Response(e.message || 'Internal Server Error', { status: 500 });
        }
    },
};
