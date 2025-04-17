# Ramfill

A simple Linux RAM filler utility for testing memory pressure using tmpfs.

## Purpose

This script allows you to simulate RAM pressure by filling a temporary filesystem (`tmpfs`) with zeroed or random data. Useful for:

- Stress testing systems under memory load
- Observing behavior under RAM exhaustion
- Simulating production environments with limited free memory

## Features

- Uses `tmpfs` under `/tmp/ramfill` for safety (RAM-only, not disk)
- Reads config from `~/.config/ramfill.conf`
- Fill using `/dev/zero` (default) or `/dev/urandom`
- CLI with `start`, `stop`, and `restart`
- Reports memory usage and what will be freed on stop

## Installation

1. Copy `ramfill.sh` to a directory in your `$PATH`, e.g., `~/bin`
2. Make it executable:

```bash
chmod +x ~/bin/ramfill.sh
```

3. Create a config file at `~/.config/ramfill.conf`:

```bash
# ~/.config/ramfill.conf
RAM_FILL_SIZE="2G"
FILL_SOURCE="zero"   # or "urandom"
```

## Usage

```bash
ramfill.sh start     # Mounts tmpfs and fills it
ramfill.sh stop      # Unmounts tmpfs and frees memory
ramfill.sh restart   # Stops and then starts again
```

## Notes

- Requires `sudo` for mounting tmpfs
- Only uses RAM, no risk to disk
- Don't use `urandom` unless you specifically need entropy-based fill

## License

MIT


