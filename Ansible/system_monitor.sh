#!/bin/bash
LOGFILE=/var/log/system_monitor.log
IP=$(hostname -I | awk '{print $1}')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOAD=$(cut -d' ' -f1 /proc/loadavg)
DISK=$(df -h / | awk 'NR==2 {print $5}')
echo "$TIMESTAMP ip=$IP load=$LOAD disk_used=$DISK" >> "$LOGFILE"
