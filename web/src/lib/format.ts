/**
 * Human-friendly distance formatter for the list-page card subtitle.
 * Switches between "823 m" and "12.4 km" at the 1 km mark so the
 * number always reads in 3-4 characters.
 */
export function formatDistance(meters: number): string {
    if (meters < 1000) {
        return `${Math.round(meters)} m`;
    }
    const km = meters / 1000;
    return `${km.toFixed(km >= 100 ? 0 : 1)} km`;
}

/** Coarse relative-time formatter — for "uploaded 3 天前" lines. */
export function formatRelativeTime(iso: string): string {
    const then = new Date(iso).getTime();
    const now = Date.now();
    const seconds = Math.max(0, Math.floor((now - then) / 1000));
    if (seconds < 60) return `剛剛`;
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `${minutes} 分鐘前`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours} 小時前`;
    const days = Math.floor(hours / 24);
    if (days < 30) return `${days} 天前`;
    const months = Math.floor(days / 30);
    if (months < 12) return `${months} 個月前`;
    const years = Math.floor(days / 365);
    return `${years} 年前`;
}
