#!/bin/bash
set -e

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Función para manejo de errores
handle_error() {
    local exit_code=$?
    log "ERROR: Un error ha ocurrido en la línea $1"
    exit $exit_code
}

# Configurar trap para manejo de errores
trap 'handle_error $LINENO' ERR

# Configurar el PATH para Hadoop
export HADOOP_HOME=/opt/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Verificación del entorno
log "Verificando entorno Hadoop..."
log "ASKHadoop HOME: $HADOOP_HOME"
log "PATH: $PATH"

# Verificar comandos esenciales
for cmd in hdfs yarn hadoop; do
    if ! command -v $cmd &> /dev/null; then
        log "Error: comando $cmd no encontrado en askhadoopx"
        exit 1
    fi
done

# Iniciar el servicio SSH
log "Iniciando servicio SSH en askhadoopx..."
if [ -f /var/run/sshd.pid ]; then
    rm -f /var/run/sshd.pid
fi

# Regenerar claves SSH si no existen
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    log "Regenerando claves SSH del host en askhadoopx..."
    /usr/bin/ssh-keygen -A
fi

# Verificar permisos de las claves SSH
/usr/sbin/sshd -t || {
    log "Error: Configuración de SSH inválida en askhadoopx"
    exit 1
}

# Iniciar SSH en primer plano para depuración
/usr/sbin/sshd -D -e &
SSH_PID=$!

# Esperar a que SSH esté disponible
log "Esperando que el servicio SSH esté disponible..."
for i in {1..30}; do
    if netstat -tln | grep -q ":22 "; then
        log "Servicio SSH está escuchando en el puerto 22"
        break
    fi
    if ! kill -0 $SSH_PID 2>/dev/null; then
        log "Error: El proceso SSH ha terminado inesperadamente"
        exit 1
    fi
    log "Esperando que SSH esté disponible... ($i/30)"
    sleep 1
done

# Verificar que SSH está corriendo
if ! kill -0 $SSH_PID 2>/dev/null; then
    log "Error: El proceso SSH no está corriendo"
    exit 1
fi

# Función para verificar y crear directorios
setup_directories() {
    local dirs=("/data/hdfs/namenode" "/data/hdfs/datanode")
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log "Creando directorio $dir"
            mkdir -p "$dir"
            chmod 700 "$dir"
        fi
    done
}

# Configurar directorios
setup_directories

# Función para verificar puerto
verify_port() {
    local port=$1
    local service=$2
    local max_attempts=30
    local attempt=1
    
    log "Verificando puerto $port para $service..."
    while ! nc -z localhost $port; do
        if [ $attempt -ge $max_attempts ]; then
            log "Error: Puerto $port para $service no disponible después de $max_attempts intentos"
            return 1
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    log "Puerto $port para $service está disponible"
    return 0
}

# Función para liberar puerto
free_port() {
    local port=$1
    local service=$2
    if netstat -tln | grep ":${port} " > /dev/null; then
        log "Puerto ${port} para ${service} está en uso, intentando liberar..."
        fuser -k ${port}/tcp || true
        sleep 2
    fi
}

# Liberar puertos necesarios
declare -A ports=(
    [9000]="NameNode RPC"
    [9870]="NameNode HTTP"
    [9864]="DataNode HTTP"
    [9866]="DataNode"
    [9867]="DataNode IPC"
    [8088]="ResourceManager"
)

for port in "${!ports[@]}"; do
    free_port "$port" "${ports[$port]}"
done

# Inicializar NameNode si es necesario
if [ ! -d "/data/hdfs/namenode/current" ]; then
    log "Formateando NameNode..."
    hdfs namenode -format -force || {
        log "Error al formatear NameNode"
        exit 1
    }
fi

# Función para iniciar servicio HDFS
start_hdfs_service() {
    local service=$1
    log "Iniciando $service..."
    hdfs --daemon start $service || {
        log "Error al iniciar $service"
        return 1
    }
}

# Iniciar servicios HDFS
start_hdfs_service namenode
verify_port 9000 "NameNode RPC" || exit 1
verify_port 9870 "NameNode HTTP" || exit 1

start_hdfs_service datanode
verify_port 9864 "DataNode HTTP" || exit 1
verify_port 9866 "DataNode" || exit 1
verify_port 9867 "DataNode IPC" || exit 1

# Verificar registro del DataNode
log "Verificando registro del DataNode..."
attempt=1
max_attempts=30
while [ $attempt -le $max_attempts ]; do
    if hdfs dfsadmin -report | grep "Live datanodes (1)"; then
        log "DataNode registrado correctamente"
        break
    fi
    log "Intento $attempt de $max_attempts..."
    sleep 2
    attempt=$((attempt + 1))
    if [ $attempt -gt $max_attempts ]; then
        log "Error: DataNode no se registró después de $max_attempts intentos"
        exit 1
    fi
done

# Esperar salida del modo seguro
log "Esperando que el NameNode salga del modo seguro..."
hdfs dfsadmin -safemode wait

# Preparar HDFS
log "Preparando HDFS..."
hdfs dfs -mkdir -p /user/hadoopuser
hdfs dfs -chown hadoopuser:hadoop /user/hadoopuser

# Crear archivo de ejemplo
log "Creando archivo de ejemplo para WordCount..."
mkdir -p ${HADOOP_HOME}/data
cat > ${HADOOP_HOME}/data/input.txt << EOL
Hello World Hadoop MapReduce
This is a test file
Hello Hadoop
This is another line
World is beautiful
MapReduce is awesome
EOL

# Asegurar que el archivo se creó correctamente
if [ ! -f ${HADOOP_HOME}/data/input.txt ]; then
    log "Error: No se pudo crear el archivo de ejemplo"
    exit 1
fi

log "Subiendo archivo de ejemplo a HDFS..."
hdfs dfs -put ${HADOOP_HOME}/data/input.txt /user/hadoopuser/

# Iniciar servicios YARN
log "Iniciando ResourceManager..."
yarn --daemon start resourcemanager
verify_port 8088 "ResourceManager" || exit 1

log "Iniciando NodeManager..."
yarn --daemon start nodemanager

# Verificar estado de HDFS
log "Verificando estado de HDFS..."
hdfs dfsadmin -report

# Almacenar PID
echo $$ > ${HADOOP_HOME}/hadoop.pid

# Función de limpieza mejorada
cleanup() {
    log "Iniciando apagado graceful..."
    yarn --daemon stop nodemanager
    yarn --daemon stop resourcemanager
    hdfs --daemon stop datanode
    hdfs --daemon stop namenode
    log "Servicios detenidos"
    exit 0
}

# Registrar función de limpieza
trap cleanup SIGTERM SIGINT SIGQUIT

# Monitoreo de servicios
monitor_services() {
    local services=("namenode" "datanode" "resourcemanager" "nodemanager")
    for service in "${services[@]}"; do
        if ! pgrep -f "$service" > /dev/null; then
            log "$service no está ejecutándose. Reiniciando..."
            case $service in
                "namenode")
                    free_port 9000 "NameNode RPC"
                    free_port 9870 "NameNode HTTP"
                    hdfs --daemon start namenode
                    ;;
                "datanode")
                    free_port 9864 "DataNode HTTP"
                    free_port 9866 "DataNode"
                    free_port 9867 "DataNode IPC"
                    hdfs --daemon start datanode
                    ;;
                "resourcemanager")
                    free_port 8088 "ResourceManager"
                    yarn --daemon start resourcemanager
                    ;;
                "nodemanager")
                    yarn --daemon start nodemanager
                    ;;
            esac
            sleep 10
        fi
    done
}

# Bucle principal de monitoreo
log "Iniciando monitoreo de servicios..."
while true; do
    monitor_services
    sleep 30
done

echo "Starting Hadoop Session" > /home/${HADOOP_USER}/welcome_message.txt
echo "cat /home/${HADOOP_USER}/welcome_message.txt" >> /home/${HADOOP_USER}/.bashrc 
