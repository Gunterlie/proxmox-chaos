# Proxmox Chaos

Chaos Monkey Lite for Proxmox LXC containers. Randomly pauses a non-critical container for a few seconds, then resumes it with a dramatic notification.

## Usage

```bash
# Dry run to see what it would do
./chaos-lxc.sh --dry-run

# Pause a random LXC for 3 seconds
./chaos-lxc.sh --duration 3

# Exclude critical containers
./chaos-lxc.sh --exclude 100,101,200
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--dry-run` | Show what would happen without actually pausing anything | - |
| `--duration SECONDS` | How long to pause the container | `5` |
| `--exclude CTID1,CTID2` | Comma-separated list of container IDs to exclude | - |

## Requirements

- Proxmox VE
- Root access (or sudo with `pct` permissions)
- Running LXC containers

## Cron Example

Add to crontab for scheduled chaos:

```bash
# Random chaos every hour
0 * * * * /path/to/chaos-lxc.sh --duration 3 --exclude 100
```

## Disclaimer

This is for fun and testing resilience. Don't run it on production unless you enjoy surprise outages and angry colleagues.
