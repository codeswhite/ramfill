#!/usr/bin/env bash
set -eu

# Ensure script runs as root
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

CONFIG_FILE="/etc/ramfill.conf"
MOUNT_POINT="/mnt/ramfill"
FILL_FILE="$MOUNT_POINT/fill"
DEFAULT_SIZE="1G"
DEFAULT_SOURCE="zero"  # allowed: zero, urandom

# Load config
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        echo "Config not found. Using defaults."
        RAM_FILL_SIZE="$DEFAULT_SIZE"
        FILL_SOURCE="$DEFAULT_SOURCE"
    fi
    RAM_FILL_SIZE="${RAM_FILL_SIZE:-$DEFAULT_SIZE}"
    FILL_SOURCE="${FILL_SOURCE:-$DEFAULT_SOURCE}"

    if [[ "$FILL_SOURCE" != "zero" && "$FILL_SOURCE" != "urandom" ]]; then
        echo "Invalid FILL_SOURCE in config. Allowed: zero, urandom"
        exit 1
    fi
}

# Convert size like 1G to MB count
size_to_mb() {
    numfmt --from=iec "$1" | awk '{print int($1 / 1048576)}'
}

# Mount tmpfs and fill it
start_fill() {
    if mountpoint -q "$MOUNT_POINT"; then
        echo "tmpfs already mounted at $MOUNT_POINT"
    else
        echo "Mounting tmpfs at $MOUNT_POINT with size $RAM_FILL_SIZE..."
        mkdir -p "$MOUNT_POINT"
        mount -t tmpfs -o size="$RAM_FILL_SIZE" tmpfs "$MOUNT_POINT"
    fi

    if [[ ! -f "$FILL_FILE" ]]; then
        echo "Creating fill file using /dev/$FILL_SOURCE..."
        dd if="/dev/$FILL_SOURCE" of="$FILL_FILE" bs=1M count=$(size_to_mb "$RAM_FILL_SIZE") status=progress
    else
        echo "Fill file already exists."
    fi

    echo -e "\nUsage:"
    df -h "$MOUNT_POINT"
}

# Unmount and cleanup
stop_fill() {
    if mountpoint -q "$MOUNT_POINT"; then
        USED=$(df -h --output=used "$MOUNT_POINT" | tail -1 | tr -d ' ')
        echo "Freeing ~$USED of RAM..."
        umount "$MOUNT_POINT"
        rmdir "$MOUNT_POINT"
    else
        echo "Nothing to stop. Mount point not active."
    fi
}

# Restart logic
restart_fill() {
    stop_fill
    echo
    start_fill
}


# Start in sync mode (sleep forever & stop on ^C)
start_sync() {
    start_fill
    sleep infinity
    stop_fill
}

# CLI handler
main() {
    load_config
    case "$1" in
        start)   start_fill ;;
        stop)    stop_fill ;;
        restart) restart_fill ;;
	start-sync) start_sync ;;
        *) echo "Usage: $0 {start|stop|restart}" && exit 1 ;;
    esac
}

main "$@"

