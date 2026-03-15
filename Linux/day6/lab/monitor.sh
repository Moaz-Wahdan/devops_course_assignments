#!/bin/bash
LOG_FILE="system_alerts.log"
echo "=== System Monitor Run: $(date) ===" >> "$LOG_FILE"

# Check Disk Space (> 80%)
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then 
    echo "[ALERT] High Disk Usage: ${DISK_USAGE}%" >> "$LOG_FILE"
else
    echo "[OK] Disk Usage: ${DISK_USAGE}%" >> "$LOG_FILE"
fi

# Check Memory Usage (> 90%)
MEM_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100)}')
if [ "$MEM_USAGE" -gt 90 ]; then 
    echo "[ALERT] High Memory Usage: ${MEM_USAGE}%" >> "$LOG_FILE"
else
    echo "[OK] Memory Usage: ${MEM_USAGE}%" >> "$LOG_FILE"
fi

# Check CPU Load
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs)
echo "[INFO] Current CPU Load Average (1 min): $CPU_LOAD" >> "$LOG_FILE"
