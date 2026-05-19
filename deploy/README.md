# Deployment companion files

These files belong on the Zettair server but live in the iOS repo
because they're tightly coupled to the iOS app's identity and would
churn here without affecting `zettair-search`.

## `apple-app-site-association.json`

For iOS Universal Links — a tap on `https://zettair.io/?q=...` in
Safari, Messages, etc. opens the app instead of the website (when the
app is installed).

**Setup:**

1. Replace `TEAMID` with your Apple Developer Team ID. Find it in the
   Apple Developer portal under Membership.
2. Copy this file to the server, e.g.
   `/var/www/zettair.io/.well-known/apple-app-site-association`
3. Configure Caddy to serve `/.well-known/` as static files. Example:

```caddy
zettair.io {
    @aasa path /.well-known/apple-app-site-association
    handle @aasa {
        header Content-Type application/json
        root * /var/www/zettair.io
        file_server
    }
    # ... existing reverse_proxy to :8765 ...
}
```

4. Verify with:

```bash
curl -I https://zettair.io/.well-known/apple-app-site-association
# expect: Content-Type: application/json
```

5. On the device, after installing a build with the matching App ID
   and Associated Domains capability, open Safari → tap a
   `zettair.io?q=...` link → app should open instead of the page.

iOS caches AASA aggressively. After changing the file, force a fresh
fetch by uninstalling and reinstalling the app.
