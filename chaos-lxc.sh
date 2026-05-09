#!/bin/bash
#
# chaos-lxc.sh - Chaos Monkey Lite for Proxmox LXC containers
# Randomly pauses a non-critical LXC container for a few seconds,
# then resumes it with a dramatic notification.
#
# Usage: ./chaos-lxc.sh [--dry-run] [--duration SECONDS] [--exclude CTID1,CTID2]
#

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

DEFAULT_DURATION=5
DRY_RUN=false
EXCLUDE_LIST=()
DURATION=$DEFAULT_DURATION

# ─── Parse arguments ─────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --exclude)
            IFS=',' read -ra EXCLUDE_LIST <<< "$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--duration SECONDS] [--exclude CTID1,CTID2]"
            exit 1
            ;;
    esac
done

# ─── Drama scripts ───────────────────────────────────────────────────────────

PAUSED_MESSAGES=(
    "CT-{ctid} has entered the void. It will return... eventually."
    "Pausing CT-{ctid} because it looked at me wrong."
    "CT-{ctid} needed a timeout. We all do sometimes."
    "Sending CT-{ctid} to the shadow realm for {duration}s."
    "CT-{ctid} said something rude about the hypervisor. This is its punishment."
    "Brief existential crisis induced on CT-{ctid}. It'll be fine. Probably."
    "CT-{ctid} is taking an unscheduled nap."
    "Chaos demands sacrifice. Today it is CT-{ctid}."
)

RESUMED_MESSAGES=(
    "CT-{ctid} has returned from the abyss. It has seen things."
    "CT-{ctid} is back. It remembers what you did."
    "CT-{ctid} has been released. It forgives you. Maybe."
    "CT-{ctid} survived the void. Barely."
    "CT-{ctid} is back online and absolutely traumatized."
    "The darkness releases CT-{ctid}. It is changed."
    "CT-{ctid} returns, forever haunted by the {duration}-second gap."
    "CT-{ctid} is back. It's fine. Everything is fine."
)

# ─── Helper functions ────────────────────────────────────────────────────────

random_element() {
    local -n arr=$1
    echo "${arr[RANDOM % ${#arr[@]}]}"
}

format_message() {
    local msg="$1"
    msg="${msg//\{ctid\}/$CTID}"
    msg="${msg//\{duration\}/$DURATION}"
    echo "$msg"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# ─── Main logic ──────────────────────────────────────────────────────────────

log "Chaos Monkey Lite for LXC initializing..."

# Get running LXC containers
mapfile -t ALL_CTS < <(pct list | awk 'NR>1 && $4 == "running" {print $1}')

if [[ ${#ALL_CTS[@]} -eq 0 ]]; then
    log "No running LXC containers found. Chaos is thwarted... for now."
    exit 0
fi

# Filter out excluded containers
TARGET_CTS=()
for ct in "${ALL_CTS[@]}"; do
    excluded=false
    for ex in "${EXCLUDE_LIST[@]+"${EXCLUDE_LIST[@]}"}"; do
        if [[ "$ct" == "$ex" ]]; then
            excluded=true
            break
        fi
    done
    if ! $excluded; then
        TARGET_CTS+=("$ct")
    fi
done

if [[ ${#TARGET_CTS[@]} -eq 0 ]]; then
    log "All running containers are excluded. Chaos is denied."
    exit 0
fi

# Pick a random victim
CTID="${TARGET_CTS[RANDOM % ${#TARGET_CTS[@]}]}"

log "Available containers: ${ALL_CTS[*]}"
log "Excluded: ${EXCLUDE_LIST[*]:-none}"
log "Selected victim: CT-$CTID"

# Get container name for extra drama
CT_NAME=$(pct config "$CTID" 2>/dev/null | grep -E "^hostname:" | awk '{print $2}' || echo "unknown")

if $DRY_RUN; then
    log "[DRY RUN] Would pause CT-$CTID ($CT_NAME) for ${DURATION}s"
    PAUSED_MSG=$(format_message "$(random_element PAUSED_MESSAGES)")
    log "[DRY RUN] Message: $PAUSED_MSG"
    exit 0
fi

# ─── Execute chaos ───────────────────────────────────────────────────────────

PAUSED_MSG=$(format_message "$(random_element PAUSED_MESSAGES)")
log "PAUSED: $PAUSED_MSG"

pct pause "$CTID"

sleep "$DURATION"

RESUMED_MSG=$(format_message "$(random_element RESUMED_MESSAGES)")
log "RESUMED: $RESUMED_MSG"

pct resume "$CTID"

log "Chaos complete. CT-$CTID ($CT_NAME) has endured ${DURATION}s of existential dread."
