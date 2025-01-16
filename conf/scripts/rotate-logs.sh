#!/bin/bash

# Script para rotar logs de Hadoop y Flume

# Configuración
MAX_LOG_DAYS=7
HADOOP_LOG_DIR="/opt/hadoop/logs"
FLUME_LOG_DIR="/opt/flume/logs"
DATE=$(date +%Y%m%d)

# Función para comprimir logs antiguos
compress_old_logs() {
    local log_dir=$1
    find "$log_dir" -type f -name "*.log" -mtime +1 -not -name "*.gz" -exec gzip {} \;
}

# Función para eliminar logs más antiguos que MAX_LOG_DAYS
delete_old_logs() {
    local log_dir=$1
    find "$log_dir" -type f -name "*.gz" -mtime +"$MAX_LOG_DAYS" -delete
}

# Rotar logs de Hadoop
if [ -d "$HADOOP_LOG_DIR" ]; then
    compress_old_logs "$HADOOP_LOG_DIR"
    delete_old_logs "$HADOOP_LOG_DIR"
fi

# Rotar logs de Flume
if [ -d "$FLUME_LOG_DIR" ]; then
    compress_old_logs "$FLUME_LOG_DIR"
    delete_old_logs "$FLUME_LOG_DIR"
fi
