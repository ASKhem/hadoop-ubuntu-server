#!/bin/bash

# Set strict error handling
set -euo pipefail

# Configuration
BACKUP_ROOT="/data/backups"
HDFS_ROOT="/data/hdfs"
LOG_FILE="/var/log/hadoop/restore.log"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Function to list available backups
list_backups() {
    log "Available backups:"
    ls -lh "${BACKUP_ROOT}"/*.tar.gz 2>/dev/null || echo "No backups found"
}

# Function to verify backup file
verify_backup() {
    local backup_file=$1
    
    log "Verifying backup file integrity..."
    if ! tar -tzf "${backup_file}" &>/dev/null; then
        log "ERROR: Backup file is corrupted or invalid"
        return 1
    fi
}

# Function to stop HDFS services
stop_services() {
    log "Stopping HDFS services..."
    stop-dfs.sh
    
    # Wait for services to stop
    sleep 5
    
    # Verify services are stopped
    if pgrep -f "hadoop" > /dev/null; then
        log "ERROR: Failed to stop Hadoop services"
        return 1
    fi
}

# Function to restore HDFS data
restore_hdfs() {
    local backup_file=$1
    local temp_dir="${BACKUP_ROOT}/temp_restore"
    
    log "Starting HDFS restore process..."
    
    # Create temporary directory
    mkdir -p "${temp_dir}"
    
    # Extract backup
    log "Extracting backup..."
    tar -xzf "${backup_file}" -C "${temp_dir}"
    
    # Verify extracted files
    if [ ! -d "${temp_dir}"/*/{namenode,datanode} ]; then
        log "ERROR: Invalid backup structure"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # Backup current data (just in case)
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local current_backup="${HDFS_ROOT}_${timestamp}.bak"
    log "Creating backup of current data: ${current_backup}"
    mv "${HDFS_ROOT}" "${current_backup}"
    
    # Restore data
    log "Restoring HDFS data..."
    mkdir -p "${HDFS_ROOT}"
    cp -r "${temp_dir}"/*/{namenode,datanode} "${HDFS_ROOT}/"
    
    # Fix permissions
    log "Setting correct permissions..."
    chown -R hadoopuser:hadoop "${HDFS_ROOT}"
    chmod 700 "${HDFS_ROOT}/namenode"
    chmod 700 "${HDFS_ROOT}/datanode"
    
    # Cleanup
    rm -rf "${temp_dir}"
    
    log "Restore completed successfully"
}

# Function to start HDFS services
start_services() {
    log "Starting HDFS services..."
    start-dfs.sh
    
    # Wait for services to start
    log "Waiting for HDFS services to be available..."
    timeout 300 bash -c 'until hdfs dfsadmin -report &>/dev/null; do sleep 5; done'
    
    # Verify services are running
    if ! hdfs dfsadmin -report &>/dev/null; then
        log "ERROR: Failed to start HDFS services"
        return 1
    fi
}

# Function to verify restore
verify_restore() {
    log "Verifying HDFS filesystem..."
    
    # Check if HDFS is accessible
    if ! hdfs dfs -ls / &>/dev/null; then
        log "ERROR: Cannot access HDFS filesystem"
        return 1
    fi
    
    # Check NameNode status
    if ! hdfs haadmin -getServiceState nn1 &>/dev/null; then
        log "ERROR: NameNode is not functioning properly"
        return 1
    fi
    
    log "HDFS restore verification completed successfully"
}

# Main execution
main() {
    # Check if backup file is provided
    if [ $# -ne 1 ]; then
        log "Usage: $0 <backup_file>"
        list_backups
        exit 1
    fi
    
    local backup_file=$1
    
    # Check if backup file exists
    if [ ! -f "${backup_file}" ]; then
        log "ERROR: Backup file does not exist: ${backup_file}"
        list_backups
        exit 1
    fi
    
    # Verify backup integrity
    if ! verify_backup "${backup_file}"; then
        exit 1
    fi
    
    # Stop services
    if ! stop_services; then
        exit 1
    fi
    
    # Perform restore
    if ! restore_hdfs "${backup_file}"; then
        log "ERROR: Restore failed"
        exit 1
    fi
    
    # Start services
    if ! start_services; then
        log "ERROR: Failed to start services after restore"
        exit 1
    fi
    
    # Verify restore
    if ! verify_restore; then
        log "ERROR: Restore verification failed"
        exit 1
    fi
    
    log "Restore process completed successfully"
}

# Execute main function with provided arguments
main "$@" 