#!/bin/bash

# Set strict error handling
set -euo pipefail

# Configuration
BACKUP_ROOT="/data/backups"
HDFS_ROOT="/data/hdfs"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_ROOT}/${DATE}"
LOG_FILE="/var/log/hadoop/backup.log"

# Ensure backup directory exists
mkdir -p "${BACKUP_ROOT}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Function to clean old backups
cleanup_old_backups() {
    log "Cleaning up backups older than ${RETENTION_DAYS} days..."
    find "${BACKUP_ROOT}" -type d -mtime +${RETENTION_DAYS} -exec rm -rf {} \;
}

# Function to check available disk space
check_disk_space() {
    local required_space=$(du -s "${HDFS_ROOT}" | awk '{print $1}')
    local available_space=$(df "${BACKUP_ROOT}" | awk 'NR==2 {print $4}')
    
    if [ "${available_space}" -lt "${required_space}" ]; then
        log "ERROR: Not enough disk space for backup"
        return 1
    fi
}

# Function to backup HDFS data
backup_hdfs() {
    log "Starting HDFS backup..."
    
    # Create backup directory
    mkdir -p "${BACKUP_DIR}"
    
    # Stop HDFS services
    log "Stopping HDFS services..."
    stop-dfs.sh
    
    # Backup NameNode data
    log "Backing up NameNode data..."
    cp -r "${HDFS_ROOT}/namenode" "${BACKUP_DIR}/"
    
    # Backup DataNode data
    log "Backing up DataNode data..."
    cp -r "${HDFS_ROOT}/datanode" "${BACKUP_DIR}/"
    
    # Create tarball
    log "Creating compressed backup..."
    tar -czf "${BACKUP_DIR}.tar.gz" -C "${BACKUP_ROOT}" "${DATE}"
    
    # Remove uncompressed backup
    rm -rf "${BACKUP_DIR}"
    
    # Start HDFS services
    log "Starting HDFS services..."
    start-dfs.sh
    
    # Wait for services to be available
    log "Waiting for HDFS services to be available..."
    timeout 300 bash -c 'until hdfs dfsadmin -report &>/dev/null; do sleep 5; done'
    
    log "Backup completed successfully: ${BACKUP_DIR}.tar.gz"
}

# Function to verify backup integrity
verify_backup() {
    log "Verifying backup integrity..."
    
    if ! tar -tzf "${BACKUP_DIR}.tar.gz" &>/dev/null; then
        log "ERROR: Backup verification failed"
        return 1
    fi
    
    log "Backup verification successful"
}

# Main execution
main() {
    log "Starting backup process..."
    
    # Check disk space
    if ! check_disk_space; then
        log "ERROR: Backup failed due to insufficient disk space"
        exit 1
    fi
    
    # Perform backup
    if ! backup_hdfs; then
        log "ERROR: Backup failed"
        exit 1
    fi
    
    # Verify backup
    if ! verify_backup; then
        log "ERROR: Backup verification failed"
        exit 1
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    log "Backup process completed successfully"
}

# Execute main function
main
