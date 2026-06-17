import { createClient, type SupabaseClient } from '@supabase/supabase-js';

/**
 * Shared Supabase client. Reads PUBLIC_SUPABASE_URL + PUBLIC_SUPABASE_ANON_KEY
 * from Astro env at build time (they're embedded into the static bundle).
 *
 * When the user hasn't set them yet (initial scaffolding, before W1 Supabase
 * setup is complete), we fall back to placeholder strings so the page still
 * renders — every component that touches the client should also gracefully
 * surface a "Backend not configured yet" empty state instead of crashing.
 */
const url =
    import.meta.env.PUBLIC_SUPABASE_URL ||
    'https://placeholder.supabase.co';
const anonKey =
    import.meta.env.PUBLIC_SUPABASE_ANON_KEY ||
    'placeholder-anon-key';

export const supabase: SupabaseClient = createClient(url, anonKey, {
    auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
    },
});

/**
 * True when the build picked up real Supabase credentials. Use this from
 * pages to swap a "Coming soon — backend not connected yet" empty state
 * for the actual list while we're still in the early bring-up phase.
 */
export const isSupabaseConfigured =
    !!import.meta.env.PUBLIC_SUPABASE_URL &&
    !!import.meta.env.PUBLIC_SUPABASE_ANON_KEY &&
    import.meta.env.PUBLIC_SUPABASE_URL !== 'https://placeholder.supabase.co';
