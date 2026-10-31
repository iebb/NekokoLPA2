// ServiceBindings is generated from the local Wrangler configuration.
export type Env = ServiceBindings;

export interface GitRelation {
    commit: string;
    version: string;
    build: number;
    updated_at: string;
}

export interface BuildData {
    version: string;
    build: number;
    appleBuild?: number;
    url: string;
    download_url?: string;
    changelog: string;
    published_at: string;
    signatures?: string[];
    file_size?: number;
}
