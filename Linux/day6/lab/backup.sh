#!/bin/bash
TARGET_DIR=${1:-"/etc"} # Default to /etc if no arg provided
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

DATE=$(date +%Y%m%d_%H%M%S)
DAY_OF_WEEK=$(date +%u)

# Full backup on Sunday (7), Incremental otherwise
if [ "$DAY_OF_WEEK" -eq 7 ]; then
    echo "[INFO] Running Weekly Full Backup for $TARGET_DIR..."
    tar -czf "$BACKUP_DIR/full_backup_$DATE.tar.gz" "$TARGET_DIR" 2>/dev/null
    echo "Success: $BACKUP_DIR/full_backup_$DATE.tar.gz"
else
    echo "[INFO] Running Daily Incremental Backup for $TARGET_DIR..."
    tar -czf "$BACKUP_DIR/inc_backup_$DATE.tar.gz" --newer-mtime="1 day ago" "$TARGET_DIR" 2>/dev/null
    echo "Success: $BACKUP_DIR/inc_backup_$DATE.tar.gz"
fi

# Cleanup old backups (keep for 30 days)
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +30 -delete
