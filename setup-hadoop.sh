#!/bin/bash

# Establecer opciones de bash para mejor manejo de errores
set -euo pipefail

# Variables de configuración
MEMORY_LIMIT="4g"
CPU_LIMIT="2"
CONTAINER_NAME="askhadoopx"

# Función para verificar si el contenedor está en ejecución
check_container() {
    if ! docker ps | grep -q ${CONTAINER_NAME}; then
        echo "Error: El contenedor no está en ejecución"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
}

# Función para verificar servicios específicos
check_services() {
    local services=(
        "NameNode:9870"
        "ResourceManager:8088"
        "SSH:22"
        "DataNode:9864"
        "Flume:41414"
    )
    
    for service in "${services[@]}"; do
        IFS=':' read -r name port <<< "$service"
        if ! docker exec ${CONTAINER_NAME} netstat -tln | grep -q ":$port "; then
            echo "Error: $name no está disponible en el puerto $port"
            return 1
        fi
        echo "✅ $name está funcionando correctamente"
    done
    return 0
}

# Limpiar contenedor anterior si existe
echo "Limpiando contenedor anterior si existe..."
docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

# Construir la imagen
echo "Construyendo imagen Docker..."
docker build -t askhadoop .

# Iniciar el contenedor con límites de recursos
echo "Iniciando contenedor con límites de recursos..."
docker run -d \
    --name ${CONTAINER_NAME} \
    --memory=${MEMORY_LIMIT} \
    --cpus=${CPU_LIMIT} \
    --memory-swap=${MEMORY_LIMIT} \
    --privileged \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    -p 22:22 \
    -p 9870:9870 \
    -p 8088:8088 \
    -p 9000:9000 \
    -p 9864:9864 \
    -p 41414:41414 \
    --hostname ${CONTAINER_NAME} \
    -e HADOOP_USER=hadoopuser \
    --health-cmd="netstat -tulpn | grep -q ':9870' && netstat -tulpn | grep -q ':8088' && netstat -tulpn | grep -q ':22'" \
    --health-interval=30s \
    --health-retries=3 \
    --health-timeout=10s \
    --health-start-period=30s \
    --restart unless-stopped \
    askhadoop

# Esperar a que el contenedor esté saludable
echo "Esperando a que el contenedor esté saludable..."
TIMEOUT=60
for i in $(seq 1 $TIMEOUT); do
    if [ "$(docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME})" = "healthy" ]; then
        echo "✅ Contenedor está saludable"
        break
    fi
    if [ $i -eq $TIMEOUT ]; then
        echo "❌ Error: El contenedor no alcanzó el estado saludable después de $TIMEOUT segundos"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
    echo "⏳ Esperando que el contenedor esté saludable... ($i/$TIMEOUT)"
    sleep 1
done

# Verificar logs del contenedor
docker logs ${CONTAINER_NAME}

# Verificar que el contenedor está en ejecución
check_container

# Verificar servicios específicos
echo "Verificando servicios..."
if ! check_services; then
    echo "❌ Error: No todos los servicios están funcionando correctamente"
    docker logs ${CONTAINER_NAME}
    exit 1
fi

# Esperar a que el servicio SSH esté disponible
echo "Esperando a que SSH esté disponible..."
for i in {1..30}; do
    if ! docker ps | grep -q ${CONTAINER_NAME}; then
        echo "❌ Error: El contenedor se ha detenido"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
    if docker exec ${CONTAINER_NAME} netstat -tln | grep -q ":22 "; then
        echo "✅ SSH está disponible"
        break
    fi
    echo "⏳ Esperando que SSH esté disponible... ($i/30)"
    sleep 1
done

# Limpiar known_hosts si existe
if [ -f ~/.ssh/known_hosts ]; then
    echo "Limpiando known_hosts..."
    ssh-keygen -R "[localhost]:22" 2>/dev/null
fi

# Eliminar la clave id_rsa si existe
if [ -f id_rsa ]; then
    echo "Eliminando clave SSH anterior..."
    rm -f id_rsa
fi

# Extraer la clave privada
echo "Extrayendo clave SSH..."
if ! docker exec ${CONTAINER_NAME} /opt/hadoop/scripts/extract_key.sh > id_rsa; then
    echo "❌ Error al extraer la clave SSH"
    docker logs ${CONTAINER_NAME}
    exit 1
fi

# Verificar que la clave se extrajo correctamente
if [ ! -s id_rsa ]; then
    echo "❌ Error: La clave SSH está vacía"
    exit 1
fi

chmod 600 id_rsa

echo "✅ Configuración completada. Puedes conectarte usando:"
echo "ssh -i id_rsa hadoopuser@localhost -p 22"

# Probar la conexión
echo "Probando conexión SSH..."
for i in {1..5}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i id_rsa hadoopuser@localhost -p 22 echo "✅ Conexión SSH exitosa"; then
        echo "✅ Configuración completada exitosamente"
        exit 0
    fi
    echo "⏳ Intento $i de 5 para conectar por SSH..."
    sleep 2
done

echo "❌ Error: No se pudo establecer la conexión SSH después de 5 intentos"
docker logs ${CONTAINER_NAME}
exit 1