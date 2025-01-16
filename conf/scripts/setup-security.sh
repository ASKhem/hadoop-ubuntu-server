#!/bin/bash

# Configurar auditd
auditctl -w /opt/hadoop/etc/hadoop -p wa -k hadoop_config
auditctl -w /data/hdfs -p wa -k hdfs_data

# Iniciar servicios de seguridad
service fail2ban start

# Verificar permisos críticos
chmod 700 /data/hdfs/namenode
chmod 700 /data/hdfs/datanode
chmod 600 /opt/hadoop/etc/hadoop/*
chmod 644 /var/log/audit/*

# Configurar límites de recursos
ulimit -n 65535
ulimit -u 65535

# Limpiar archivos temporales
find /tmp -type f -delete
find /var/tmp -type f -delete
