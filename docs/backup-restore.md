# Backup & Restore

`kennethl-ws` backs up user data with [restic](https://restic.net/), configured
declaratively in `home.nix` via home-manager's `services.restic.backups` module.

## Overview

| Item | Value |
| --- | --- |
| Job name | `kennethl-ws` |
| Repository | `/mnt/backup/restic-repositories/kennethl-ws` |
| Password file | `~/.config/restic/password` (mode `0600`) |
| Backup service/timer | `restic-backups-kennethl-ws.{service,timer}` |
| Weekly check timer | `restic-check-kennethl-ws.timer` |
| CLI wrapper | `restic-kennethl-ws` |
| Success notifier | `notify-restic backup-success` (via `ExecStartPost`) |
| Staleness timer | `restic-stale-check.timer` |
| Alert sender | `restic-notify@kennethlieyanto.com` (Resend API) |

The repo is encrypted; the password is a user-only file, never in the Nix store
or git.

## Scope

Backed up: `~/Documents`, `~/Pictures`, `~/Videos`, `~/Calibre Library`,
`~/Music`, `~/Vaults`, `~/.ssh`. Excluded: `**/.cache`,
`**/.local/share/Trash`. `~/.config` is intentionally not backed up (churny app
state; editable source lives in the Nix config).

## Schedule

- **Backup + prune:** daily 03:00 + `RandomizedDelaySec=30min`, `Persistent=true`.
- **Integrity check:** weekly (Mon 00:00), `restic check --read-data-subset=5%`.

`Persistent` runs a missed job once at the next opportunity (for user timers,
your next login); it does not back-fill multiple misses.

## Wrapper

`restic-kennethl-ws` pre-sets `RESTIC_REPOSITORY`, `RESTIC_PASSWORD_FILE`, and
`RESTIC_CACHE_DIR`, then runs the real `restic`. Equivalent to:

```sh
restic -r /mnt/backup/restic-repositories/kennethl-ws \
  --password-file ~/.config/restic/password snapshots
```

## Manual use

```sh
systemctl --user start restic-backups-kennethl-ws.service   # backup now
restic-kennethl-ws snapshots                                # list
restic-kennethl-ws stats
restic-kennethl-ws ls latest
restic-kennethl-ws check                                    # metadata only
restic-kennethl-ws check --read-data-subset=5%              # sample data
systemctl --user list-timers 'restic-*'                     # next fire times
```

## Restore

```sh
restic-kennethl-ws restore latest --target /tmp/restore      # whole snapshot
restic-kennethl-ws snapshots                                 # find an id
restic-kennethl-ws restore <id> --target /tmp/restore \
  --include /home/kennethl/Documents/file.pdf                # one path
mkdir -p /tmp/restic-mount && restic-kennethl-ws mount /tmp/restic-mount
fusermount -u /tmp/restic-mount                              # browse via FUSE
```

## Retention

`restic forget --prune` after each backup: keep 7 daily, 4 weekly, 6 monthly.

## Password rotation

Editing the password file alone won't open the existing repo; add a new key
first:

```sh
restic-kennethl-ws key add
pass backup/restic > ~/.config/restic/password && chmod 600 ~/.config/restic/password
restic-kennethl-ws key list
restic-kennethl-ws key remove <old-key-id>
```

## Notifications

Email alerts are sent via the [Resend](https://resend.com) HTTP API (no SMTP
server needed). There are two kinds:

1. **Success** — every *fully successful* backup run sends an email immediately
   (systemd `ExecStartPost=` on `restic-backups-kennethl-ws.service`, which only
   runs when all of backup/prune/check exit 0). The body summarises the new
   snapshot.
2. **Staleness** — a daily watchdog (`restic-stale-check.timer`, 09:00,
   `Persistent=true`) reads the newest snapshot and emails if it is older than
   **7 days** (or if the repository is unreadable/empty). While still stale it
   re-reminds at most every **3 days**; it clears itself once a fresh backup
   lands.

There are deliberately **no per-run failure emails**: if the machine is simply
off, no run happens and nothing is sent — the staleness watchdog is what tells
you backups have lapsed. Because the watchdog is a local, persistent timer, a
long power-off is reported at the next boot alongside the catch-up backup.

- **Sender:** `restic-notify@kennethlieyanto.com` (verified domain).
- **Recipient:** `kennethlieyanto99@gmail.com`.
- **API key:** `~/.config/restic-notify/api-key` (mode `0600`, not in the Nix
  store or git). Override the path with `RESTIC_NOTIFY_API_KEY_FILE`.
- **Stale state:** `~/.local/state/restic-notify/last-stale-alert` (re-alert
  throttle; removed automatically when a fresh backup is seen).

Test delivery:

```sh
notify-restic backup-success                     # preview the success email now
systemctl --user start restic-backups-kennethl-ws.service   # full end-to-end
systemctl --user start restic-stale-check.service           # no-op when healthy
journalctl --user -u restic-backups-kennethl-ws.service     # ExecStartPost logs
```

Rotate the API key by creating a new one in Resend and overwriting the file:

```sh
printf '%s' 're_...' > ~/.config/restic-notify/api-key && chmod 600 ~/.config/restic-notify/api-key
```

## Troubleshooting

- **Service fails:** `journalctl --user -xeu restic-backups-kennethl-ws.service`.
- **No success email:** check `journalctl --user -u restic-backups-kennethl-ws.service`
  for the `notify-restic backup-success` run; verify the API key file is readable
  and the domain is verified in Resend. (An email failure cannot mark the backup
  failed — the hook is prefixed with `-`.)
- **No staleness alert:** `systemctl --user list-timers restic-stale-check.timer`;
  run `journalctl --user -u restic-stale-check.service`.
- **Wrong/missing password file:** ensure it exists, is correct, and is `0600`.
- **Disk not mounted:** `mount | grep backup` (repo needs `/mnt/backup`).
- **Repo missing:** `initialize = true` creates it on first successful run.
- **Why not `pass`?** Unattended `pass` fails: `gpg-agent`'s cache expires and
  `pinentry` has no TTY in systemd (`public key decryption failed: No such
  file or directory`). The `passwordFile` avoids gpg/pinentry entirely.

## Rebuild

Units and the wrapper are generated by home-manager; apply changes with:

```sh
sudo nixos-rebuild switch --flake .#kennethl
```
