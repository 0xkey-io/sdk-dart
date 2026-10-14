---
title: "Fix hosted OAuth relay defaults to the 0xkey.io hosts"
date: "2026-10-14"
packages:
  zeroxkey_sdk_flutter: "patch"
---

`ZEROXKEY_OAUTH_ORIGIN_URL` and `ZEROXKEY_OAUTH_REDIRECT_URL` pointed at
`oauth-origin.0xkey.com` / `oauth-redirect.0xkey.com`, a domain 0xkey does not
operate. They now default to `https://oauth-origin.0xkey.io` and
`https://oauth-redirect.0xkey.io/`, so the default Google/Apple callback is
`https://oauth-redirect.0xkey.io/?scheme=<app scheme>`, the same value the React
Native wallet kit generates. Apps that registered the old `0xkey.com` callback
in their provider console must register the new one.
