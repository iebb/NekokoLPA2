# Update delivery

The updater, channel selection, metadata publisher and release workflow are maintained in NekokoLPA2. Android has an **Community** variant. Desktop and web builds are **NekokoLPA 2**, built from this public application.

## Channels

| Platform / channel | Artifact |
| --- | --- |
| Android `community` | Public Community APK; the universal APK also supports ARMv7 clients |
| Android `community-rooted` | Public full rooted APK with its existing rooted package identity |
| Android legacy `open` / `open-rooted` | Aliases to the matching Community normal/rooted APKs |
| Windows `std` | NekokoLPA 2 installer |
| Linux `std` / `std-appimage` / `std-tgz` | NekokoLPA 2 AppImage / AppImage / tarball |
| Earlier desktop `open`, `open-portable`, `open-appimage`, `open-tgz`, `store` | Compatibility aliases to the same desktop downloads |

Android selects the exact variant and signing certificate, then the highest build newer than the installed version. Normal and rooted Community APKs cannot match each other's channels. Windows/Linux standard feeds and historical public aliases now use the same desktop application. macOS/iOS use Store/TestFlight delivery.

## Earlier builds

The original 2.4.0+600 public artifacts embedded `store`. Windows/Linux compatibility entries point to the shared desktop downloads.

Both original public Android flavors embedded `store` and used the same community certificate. Their updater cannot distinguish the normal package from the rooted package, so its compatibility entry opens the release chooser. Choose the Community Android APK for `ee.nekoko.nlpa2.open`, or the Community rooted APK/module for `ee.nekoko.nlpa2`. Vendor Android APKs retain their different package/signing identities.

New Android filenames use `ee.nekoko.nlpa2.community-<version>-...`; the normal APK keeps its installed package `ee.nekoko.nlpa2.open` and its certificate. The publisher prefers Community filenames and accepts older `.open-` assets. Both Community and legacy Open Android channels are written from the same verified APKs.

Canonical desktop filenames omit `.open-`. Earlier filenames remain valid links to byte-identical downloads. The publisher accepts historical names for older releases, and prefers canonical desktop names when both exist.

## Publishing

[Publish update feeds](../.github/workflows/publish_update_feeds.yml) runs after a stable release or successful public release build. It can also be dispatched manually with a published release tag. It:

1. Requires the latest published stable release and every expected uploaded asset.
2. Downloads and verifies Android Community APKs' community certificate.
3. Writes direct artifact URLs, sizes, version and build to each channel.
4. Refuses a feed downgrade and fails if a write is rejected.

Publishing standard Windows/Linux feeds from the public repository is enabled by default, including automatic release events. The manual `migrate_standard_desktop` input retains an opt-out for release maintenance; the CLI flag with the same name supports older automation. This changes desktop metadata only, never Android package/signing channels.

The 601 desktop release includes eSIM.cc/eSIM.gg but predates the public 3HK plugin. All three provider plugins are now public source; 3HK is included from the next build. Migration notes refer to the selected release's actual integrations.

`UPDATE_WORKER_URL` and `UPDATE_WORKER_KEY` are encrypted GitHub Actions secrets. Authentication is sent in a header, never a URL query. The shared [metadata writer](../scripts/update_config_json.py) also supports branded Android release callers.

The public [feed row mapper](../tools/update_feed_entry.ts) preserves direct artifact downloads separately from release-page links. Deployment-specific D1/cache configuration remains outside this repository.

The feed is served at <https://updates.lpa.ee/nlpa2.json>. Edge caching can take up to five minutes to expose a new entry. Update buttons open downloads externally; they do not silently install software.
