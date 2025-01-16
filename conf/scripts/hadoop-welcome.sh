#!/bin/bash

# Asegurarnos de que solo se ejecute en sesiones interactivas
if [ -t 0 ]; then
    # Cargar variables de entorno de Hadoop
    export HADOOP_HOME=/opt/hadoop
    export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
    export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

    # Variable de control para evitar ejecuciones múltiples
    if [ -n "$WELCOME_SHOWN" ]; then
        return 0
    fi
    export WELCOME_SHOWN=1

    if [ -f /opt/hadoop/scripts/welcome.sh ]; then
        /opt/hadoop/scripts/welcome.sh
    fi
fi
