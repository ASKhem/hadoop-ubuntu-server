#!/bin/bash

# Script para realizar backup de datos HDFS importantes

# Configuración
BACKUP_DIR="/data/backup"
DATE=$(date +%Y%m%d)
HDFS_DIRS_TO_BACKUP=(
    "/user"
    "/tmp"
    "/data"
)

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"

# Función para verificar el estado de HDFS
check_hdfs_status() {
    if ! hdfs dfsadmin -report >/dev/null 2>&1; then
        echo "Error: HDFS no está disponible"
        exit 1
    fi
}

# Función para realizar el backup
do_backup() {
    local dir=$1
    local backup_file="$BACKUP_DIR/hdfs_${dir//\//_}_$DATE.tar.gz"
    
    echo "Realizando backup de $dir..."
    if hdfs dfs -test -d "$dir"; then
        hdfs dfs -get "$dir" - | gzip > "$backup_file"
        echo "Backup completado: $backup_file"
    else
        echo "Advertencia: Directorio $dir no existe en HDFS"
    fi
}

# Verificar HDFS
check_hdfs_status

# Realizar backup de cada directorio
for dir in "${HDFS_DIRS_TO_BACKUP[@]}"; do
    do_backup "$dir"
done

# Limpiar backups antiguos (mantener últimos 7 días)
find "$BACKUP_DIR" -type f -name "hdfs_*_*.tar.gz" -mtime +7 -delete

echo "Proceso de backup completado"
