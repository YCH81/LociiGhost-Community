/**
 * URL scheme builders that hand items off to the LociiGhost macOS app.
 *
 * `lociighost://` is registered by the app's Info.plist (Phase 2 of
 * the macOS-side W2 work). When the user clicks one of these links on
 * a Mac that has the app installed, macOS launches / focuses it and
 * routes the URL into the app's onOpenURL handler, which then performs
 * the matching action (teleport, route import, etc.).
 *
 * On a device without the app (iPhone, Android, Windows), nothing
 * happens — these links are deliberately a "nice to have if you've
 * got the app" surface, not the only way to use the data.
 */

export function teleportLink(lat: number, lng: number): string {
    return `lociighost://teleport?lat=${encodeURIComponent(lat)}&lng=${encodeURIComponent(lng)}`;
}

export function importRouteLink(routeId: string): string {
    return `lociighost://import-route?id=${encodeURIComponent(routeId)}`;
}

export function browseMushroomLink(mushroomId: string): string {
    return `lociighost://browse?type=mushroom&id=${encodeURIComponent(mushroomId)}`;
}

export function browsePostcardLink(postcardId: string): string {
    return `lociighost://browse?type=postcard&id=${encodeURIComponent(postcardId)}`;
}
