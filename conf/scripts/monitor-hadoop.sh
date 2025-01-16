#!/bin/bash

# Script de monitorización para Hadoop

# Configuración
ALERT_EMAIL="admin@example.com"
THRESHOLD_DISK=80  # Porcentaje
THRESHOLD_MEMORY=90  # Porcentaje
LOG_FILE="/opt/hadoop/logs/monitoring.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Verificar espacio en HDFS
check_hdfs_space() {
    log_message "Verificando espacio HDFS..."
    hdfs dfsadmin -report | grep "DFS Remaining%"
}

# Verificar salud de nodos
check_node_health() {
    log_message "Verificando salud de nodos..."
    yarn node -list -all | grep -E "RUNNING|UNHEALTHY"
}

# Verificar uso de memoria
check_memory_usage() {
    log_message "Verificando uso de memoria..."
    free -m | grep "Mem:" | awk '{print "Uso de memoria: " $3/$2 * 100 "%"}'
}

# Verificar aplicaciones YARN
check_yarn_apps() {
    log_message "Verificando aplicaciones YARN..."
    yarn application -list | grep -E "RUNNING|ACCEPTED"
}

# Verificar uso de CPU
check_cpu_usage() {
    log_message "Verificando uso de CPU..."
    top -bn1 | grep "Cpu(s)" | awk '{print "Uso de CPU: " 100 - $8 "%"}'
}

# Verificar logs por errores
check_logs_for_errors() {
    log_message "Verificando logs por errores..."
    for log in /opt/hadoop/logs/*.log; do
        errors=$(grep -i "error\|exception" "$log" | wc -l)
        log_message "Errores en $log: $errors"
    done
}

# Verificar replicación de bloques
check_block_replication() {
    log_message "Verificando replicación de bloques..."
    hdfs fsck / | grep -E "Under-replicated|Missing"
}

# Función principal
main() {
    log_message "=== Iniciando monitorización ==="
    
    check_hdfs_space
    check_node_health
    check_memory_usage
    check_yarn_apps
    check_cpu_usage
    check_logs_for_errors
    check_block_replication
    
    log_message "=== Monitorización completada ==="
}

# Ejecutar monitorización
main
