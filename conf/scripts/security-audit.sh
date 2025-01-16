#!/bin/bash

# Script de auditoría de seguridad para Hadoop

echo "=== Iniciando auditoría de seguridad ==="
date

# Verificar permisos de archivos críticos
check_permissions() {
    echo "Verificando permisos de archivos críticos..."
    for dir in /opt/hadoop/etc/hadoop /data/hdfs/namenode /data/hdfs/datanode; do
        find "$dir" -type f -exec ls -l {} \; | grep -v "^-r--r--r--\|^-rw-r--r--"
    done
}

# Verificar configuraciones de seguridad
check_security_config() {
    echo "Verificando configuraciones de seguridad..."
    
    # Verificar SSL
    grep -r "ssl" /opt/hadoop/etc/hadoop/
    
    # Verificar autenticación
    grep -r "hadoop.security.authentication" /opt/hadoop/etc/hadoop/
    
    # Verificar autorización
    grep -r "hadoop.security.authorization" /opt/hadoop/etc/hadoop/
}

# Verificar usuarios y grupos
check_users() {
    echo "Verificando usuarios y grupos..."
    grep "hadoop" /etc/passwd
    grep "hadoop" /etc/group
}

# Verificar puertos abiertos
check_ports() {
    echo "Verificando puertos abiertos..."
    netstat -tulpn | grep -E ":(9000|9870|8088|9864|41414)"
}

# Verificar logs por intentos de acceso no autorizados
check_auth_logs() {
    echo "Verificando logs de autenticación..."
    grep "Failed password" /var/log/auth.log | tail -n 5
}

# Verificar integridad de archivos críticos
check_file_integrity() {
    echo "Verificando integridad de archivos..."
    if [ -f /opt/hadoop/etc/hadoop/checksums.md5 ]; then
        md5sum -c /opt/hadoop/etc/hadoop/checksums.md5
    else
        find /opt/hadoop/etc/hadoop -type f -exec md5sum {} \; > /opt/hadoop/etc/hadoop/checksums.md5
        echo "Archivo de checksums creado"
    fi
}

# Ejecutar todas las verificaciones
check_permissions
check_security_config
check_users
check_ports
check_auth_logs
check_file_integrity

echo "=== Auditoría completada ==="
date
