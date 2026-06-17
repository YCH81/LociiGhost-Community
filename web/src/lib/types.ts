// Row shapes mirror the Postgres tables defined in
// supabase/schema.sql. Keep these in sync — when the SQL changes,
// re-export with `supabase gen types typescript` later. For W3.1
// they're hand-rolled.

export type MushroomType =
    | 'red'
    | 'yellow'
    | 'blue'
    | 'white'
    | 'purple'
    | 'gray'
    | 'rock'
    | 'wing'
    | 'rainbow';

export interface Mushroom {
    id: string;
    mushroom_type: MushroomType;
    name: string;
    description: string | null;
    lat: number;
    lng: number;
    uploader_id: string;
    uploader_name: string;
    created_at: string;
    updated_at: string;
}

export interface Postcard {
    id: string;
    name: string;
    description: string | null;
    lat: number;
    lng: number;
    photo_path: string | null;
    uploader_id: string;
    uploader_name: string;
    created_at: string;
    updated_at: string;
}

export interface Route {
    id: string;
    name: string;
    description: string | null;
    gpx_path: string;
    point_count: number;
    distance_m: number;
    start_lat: number;
    start_lng: number;
    uploader_id: string;
    uploader_name: string;
    created_at: string;
    updated_at: string;
}

export interface Profile {
    id: string;
    display_name: string;
    created_at: string;
    updated_at: string;
}

/** Human label + tint for a mushroom type. */
export const MUSHROOM_LABELS: Record<MushroomType, { zh: string; en: string; color: string }> = {
    red: { zh: '紅菇', en: 'Red', color: '#dc2626' },
    yellow: { zh: '黃菇', en: 'Yellow', color: '#eab308' },
    blue: { zh: '藍菇', en: 'Blue', color: '#2563eb' },
    white: { zh: '白菇', en: 'White', color: '#e5e7eb' },
    purple: { zh: '紫菇', en: 'Purple', color: '#9333ea' },
    gray: { zh: '灰菇', en: 'Gray', color: '#6b7280' },
    rock: { zh: '岩菇', en: 'Rock', color: '#78716c' },
    wing: { zh: '翼菇', en: 'Wing', color: '#ec4899' },
    rainbow: { zh: '彩虹菇', en: 'Rainbow', color: '#f59e0b' },
};
