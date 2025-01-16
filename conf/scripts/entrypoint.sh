#!/bin/bash

# Set strict error handling
set -euo pipefail

# Export environment variables
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Update SSH environment file
update_ssh_environment() {
    cat > ~/.ssh/environment << EOF
JAVA_HOME=${JAVA_HOME}
HADOOP_HOME=${HADOOP_HOME}
HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
PATH=${PATH}
EOF
    chmod 600 ~/.ssh/environment
}

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to verify environment
verify_environment() {
    log "Verificando entorno Hadoop..."
    log "JAVA_HOME: ${JAVA_HOME}"
    log "HADOOP_HOME: ${HADOOP_HOME}"
    log "PATH: ${PATH}"
    
    # Verify Java installation
    if ! command -v java &> /dev/null; then
        log "Error: Java no está disponible en el PATH"
        exit 1
    fi
    
    # Verify Java version
    java -version || {
        log "Error: No se puede verificar la versión de Java"
        exit 1
    }
}

# Function to start SSH service
start_ssh() {
    log "Iniciando servicio SSH en $(hostname)..."
    
    # Update SSH environment
    update_ssh_environment
    
    # Remove old keys and generate new ones
    sudo rm -f /etc/ssh/ssh_host_*
    sudo ssh-keygen -A
    
    # Start SSH service
    sudo /usr/sbin/sshd
    
    # Verify SSH is running
    for i in {1..30}; do
        if netstat -tln | grep -q ":22 "; then
            log "Servicio SSH iniciado correctamente"
            return 0
        fi
        sleep 1
    done
    
    log "Error: No se pudo iniciar el servicio SSH"
    return 1
}

# Function to initialize Hadoop
init_hadoop() {
    log "Inicializando Hadoop..."
    
    # Ensure environment variables are available to Hadoop scripts
    cat > /tmp/hadoop-env.sh << EOF
export JAVA_HOME=${JAVA_HOME}
export HADOOP_HOME=${HADOOP_HOME}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
export PATH=${JAVA_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${PATH}
EOF
    
    source /tmp/hadoop-env.sh
    
    # Format namenode if needed
    if [ ! -d "/data/hdfs/namenode/current" ]; then
        log "Formateando NameNode..."
        hdfs namenode -format -force
    fi
    
    # Start HDFS with environment variables
    log "Iniciando HDFS..."
    bash -c "source /tmp/hadoop-env.sh && start-dfs.sh"
    
    # Start YARN with environment variables
    log "Iniciando YARN..."
    bash -c "source /tmp/hadoop-env.sh && start-yarn.sh"
    
    # Wait for services to be available
    log "Esperando que los servicios estén disponibles..."
    timeout 300 bash -c 'until hdfs dfsadmin -report &>/dev/null; do sleep 5; done'
    
    log "Hadoop inicializado correctamente"
}

# Function to start Flume
start_flume() {
    log "Iniciando servicio Flume..."
    
    # Create Flume log directory if it doesn't exist
    mkdir -p /opt/flume/logs
    
    # Start Flume agent
    nohup flume-ng agent \
        --name AxenteHadoop \
        --conf /opt/flume/conf \
        --conf-file /opt/flume/conf/axente-web-avro-hdfs.conf \
        -Dflume.root.logger=INFO,console \
        -Xmx512m \
        > /opt/flume/logs/flume.log 2>&1 &
    
    # Wait for Flume to start (with timeout)
    local timeout=30
    local counter=0
    while [ $counter -lt $timeout ]; do
        if netstat -tln | grep -q ":41414 "; then
            log "Servicio Flume iniciado correctamente"
            return 0
        fi
        counter=$((counter + 1))
        sleep 1
    done
    
    log "Error: No se pudo iniciar el servicio Flume después de $timeout segundos"
    cat /opt/flume/logs/flume.log
    return 1
}

# Main execution
main() {
    verify_environment
    
    # Start SSH
    if ! start_ssh; then
        log "Error: Configuración de SSH inválida en $(hostname)"
        exit 1
    fi
    
    # Initialize Hadoop
    init_hadoop
    
    # Start Flume
    if ! start_flume; then
        log "Error: No se pudo iniciar Flume"
        exit 1
    fi
    
    # Keep container running
    while true; do
        sleep 60
        
        # Verify services are running
        if ! netstat -tln | grep -q ":22 "; then
            log "Error: Servicio SSH no está ejecutándose"
            start_ssh
        fi
        
        if ! hdfs dfsadmin -report &>/dev/null; then
            log "Error: HDFS no está ejecutándose"
            init_hadoop
        fi
        
        if ! netstat -tln | grep -q ":41414 "; then
            log "Error: Servicio Flume no está ejecutándose"
            start_flume
        fi
    done
}

# Execute main function
main
