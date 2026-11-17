// Iron v2.3.0 — offline cache. Serves the saved copy instantly and downloads updates in the
// background, so a new version only applies the NEXT time Iron is opened (never mid-chat).
const CACHE = "iron-v2.3.0";
const SHELL = ["./", "./index.html", "./manifest.webmanifest", "./icons/icon-192.png", "./icons/icon-512.png", "./icons/maskable-512.png", "./icons/apple-touch-icon.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)));
});
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const r = e.request;
  if (r.method !== "GET") return;
  const u = new URL(r.url);
  const mine = u.origin === location.origin;
  if (!mine) return; // AI provider calls always go straight to the network
  const nav = r.mode === "navigate";
  e.respondWith(caches.open(CACHE).then(async c => {
    const hit = await c.match(nav ? "./index.html" : r, { ignoreSearch: nav });
    const net = fetch(r).then(res => { if (res.ok) c.put(nav ? "./index.html" : r, res.clone()); return res; }).catch(() => hit);
    return hit || net;
  }));
});

