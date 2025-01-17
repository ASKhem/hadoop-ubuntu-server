# 🐘 Hadoop Docker Environment

> Entorno Hadoop containerizado completo para desarrollo y pruebas, listo para usar en minutos.

<div align="center">

![Hadoop Version](https://img.shields.io/badge/Hadoop-3.3.6-blue)
![Flume Version](https://img.shields.io/badge/Flume-1.11.0-green)
![Ubuntu Version](https://img.shields.io/badge/Ubuntu-22.04%20LTS-orange)
![License](https://img.shields.io/badge/license-Apache%202.0-red)
![CI/CD](https://img.shields.io/badge/CI/CD-GitHub%20Actions-blue)

</div>

## 🚀 Características Principales

- ✨ **Hadoop 3.3.6** - Última versión estable
- 🌊 **Apache Flume 1.11.0** - Recolección de datos en tiempo real
- 🔄 **Rotación automática de logs**
- 💾 **Backup automático de HDFS**
- 📊 **Monitorización de salud del sistema**
- ⚡ **Gestión automática de recursos**
- 🔒 **Seguridad mejorada**
- 📈 **CI/CD integrado**

## 📋 Requisitos Previos

| Componente | Mínimo Requerido | Recomendado |
|------------|------------------|-------------|
| Docker     | 20.10+          | 23.0+       |
| RAM        | 4GB             | 8GB         |
| Disco      | 20GB            | 50GB        |
| CPU        | 2 cores         | 4 cores     |

## 🏃‍♂️ Inicio Rápido

1️⃣ Clonar el repositorio
```bash
git clone https://github.com/ASKhem/hadoop-ubuntu-server.git
cd hadoop-ubuntu-server
```

2️⃣ Configurar recursos (opcional)
```bash
# Editar variables en setup-hadoop.sh
MEMORY_LIMIT="4g"  # Límite de memoria
CPU_LIMIT="2"      # Límite de CPU
```

3️⃣ Ejecutar el script de configuración
```bash
./setup-hadoop.sh
```

4️⃣ Conectarse al contenedor
```bash
ssh -i id_rsa hadoopuser@localhost -p 22
```

## 🔌 Puertos y Servicios

| Puerto | Servicio                  | Healthcheck |
|--------|---------------------------|-------------|
| 22     | SSH                       | ✅          |
| 9870   | HDFS NameNode Web UI      | ✅          |
| 8088   | YARN ResourceManager UI   | ✅          |
| 9000   | HDFS                      | ✅          |
| 9864   | DataNode HTTP             | ✅          |
| 41414  | Flume                     | ✅          |

## 📁 Estructura del Proyecto

```
hadoop-docker/
├── 📂 .github/
│   └── 📂 workflows/        # Configuración CI/CD
├── 📂 conf/
│   ├── 📂 flume/           # Configuración Flume
│   ├── 📂 hadoop/          # Configuración Hadoop
│   └── 📂 scripts/         # Scripts de utilidad
├── 📄 Dockerfile           # Definición multi-stage
├── 📄 setup-hadoop.sh      # Script de configuración
└── 📄 README.md           # Documentación
```

## 🛠️ Configuración Avanzada

### Límites de Recursos

El contenedor está configurado con límites de recursos para garantizar un rendimiento óptimo:

```bash
# Límites por defecto
--memory=4g           # Límite de memoria
--memory-swap=4g      # Límite de swap
--cpus=2             # Límite de CPU
```

Para modificar estos límites, edita las variables en `setup-hadoop.sh`:

```bash
MEMORY_LIMIT="8g"    # Aumentar memoria
CPU_LIMIT="4"        # Aumentar CPU
```

### Backup y Restauración

#### Realizar Backup Manual

```bash
# Ejecutar backup
/opt/hadoop/scripts/backup-hdfs.sh

# Los backups se almacenan en:
/data/backups/YYYYMMDD_HHMMSS.tar.gz
```

#### Restaurar desde Backup

```bash
# Listar backups disponibles
ls -l /data/backups/

# Restaurar desde backup específico
/opt/hadoop/scripts/restore-hdfs.sh /data/backups/20240315_120000.tar.gz
```

### Monitorización

#### Healthchecks Automáticos

El sistema realiza verificaciones automáticas de salud cada 30 segundos:

- ✅ Estado de servicios HDFS
- ✅ Disponibilidad de YARN
- ✅ Conectividad SSH
- ✅ Uso de recursos

#### Logs y Diagnóstico

```bash
# Ver logs de Hadoop
tail -f /opt/hadoop/logs/hadoop-*.log

# Ver logs de backup
tail -f /var/log/hadoop/backup.log

# Ver logs de restauración
tail -f /var/log/hadoop/restore.log
```

## 🔍 Troubleshooting

### Problemas Comunes

<details>
<summary>El contenedor no inicia</summary>

1. Verificar recursos disponibles:
```bash
docker stats
```

2. Verificar logs del contenedor:
```bash
docker logs askhadoopx
```

3. Comprobar límites de recursos:
```bash
cat /sys/fs/cgroup/memory/memory.limit_in_bytes
```
</details>

<details>
<summary>NameNode no está disponible</summary>

1. Verificar estado del servicio:
```bash
hdfs haadmin -getServiceState nn1
```

2. Revisar logs específicos:
```bash
tail -f /opt/hadoop/logs/hadoop-hadoopuser-namenode-*.log
```

3. Reiniciar servicio:
```bash
stop-dfs.sh && start-dfs.sh
```
</details>

<details>
<summary>Problemas de rendimiento</summary>

1. Verificar uso de recursos:
```bash
htop
```

2. Comprobar configuración de memoria:
```bash
grep -r "heap" /opt/hadoop/etc/hadoop/
```

3. Ajustar parámetros:
```bash
# Editar hadoop-env.sh
export HADOOP_HEAPSIZE=4096
```
</details>

### Mejores Prácticas

1. **Monitorización Regular**
   - Revisar logs diariamente
   - Configurar alertas para healthchecks
   - Monitorear uso de recursos

2. **Mantenimiento**
   - Realizar backups periódicos
   - Rotar logs regularmente
   - Actualizar componentes

3. **Seguridad**
   - Cambiar contraseñas regularmente
   - Mantener actualizados los certificados
   - Revisar logs de acceso

## 🔐 Seguridad

### Autenticación y Autorización

#### SSH y Control de Acceso
```bash
# Generar nuevo par de claves SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/hadoop_rsa

# Configurar permisos adecuados
chmod 600 ~/.ssh/hadoop_rsa
chmod 644 ~/.ssh/hadoop_rsa.pub
```

#### Kerberos (Opcional)
```bash
# Instalar Kerberos
apt-get install krb5-kdc krb5-admin-server

# Configurar principal
kadmin.local -q "addprinc hadoop/hadoopuser@REALM"
```

### Cifrado y SSL/TLS

#### Certificados
```bash
# Generar certificado SSL
keytool -genkey -alias hadoop -keyalg RSA \
  -keystore hadoop.keystore -keysize 2048
```

#### Configuración HTTPS
```xml
<!-- ssl-server.xml -->
<property>
  <name>ssl.server.keystore.location</name>
  <value>/opt/hadoop/conf/hadoop.keystore</value>
</property>
```

### Políticas de Seguridad

#### ACLs en HDFS
```bash
# Configurar ACLs
hdfs dfs -setfacl -m user:usuario:rw- /ruta/segura
hdfs dfs -getfacl /ruta/segura
```

#### Firewall y Puertos
```bash
# Configurar iptables
iptables -A INPUT -p tcp --dport 9000 -j ACCEPT  # HDFS
iptables -A INPUT -p tcp --dport 8088 -j ACCEPT  # YARN
iptables -P INPUT DROP  # Política por defecto
```

### Auditoría y Logging

#### Logs de Seguridad
```bash
# Monitorear intentos de acceso
tail -f /var/log/auth.log

# Logs de auditoría HDFS
tail -f /opt/hadoop/logs/SecurityLog.audit
```

#### Monitorización de Seguridad
- 🔍 Detección de accesos no autorizados
- 📊 Análisis de patrones de uso
- 🚨 Alertas de seguridad configurables

### Mejores Prácticas de Seguridad

1. **Gestión de Credenciales**
   - Rotación regular de claves SSH
   - Almacenamiento seguro de contraseñas
   - Uso de secretos cifrados

2. **Hardening del Sistema**
   - Actualizaciones de seguridad automáticas
   - Principio de mínimo privilegio
   - Aislamiento de contenedores

3. **Cumplimiento y Políticas**
   - Conformidad con GDPR/LOPD
   - Políticas de retención de datos
   - Procedimientos de respuesta a incidentes

## 🤝 Contribuir

1. Fork el repositorio
2. Crea tu rama (`git checkout -b feature/mejora`)
3. Commit tus cambios (`git commit -am 'Añadir mejora'`)
4. Push a la rama (`git push origin feature/mejora`)
5. Abre un Pull Request

### Guía de Contribución

- ✅ Añadir tests para nuevas funcionalidades
- ✅ Actualizar documentación
- ✅ Seguir estilo de código existente
- ✅ Mantener compatibilidad hacia atrás

## 🔧 Variables de Entorno

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `HADOOP_HOME` | Directorio de instalación de Hadoop | `/opt/hadoop` |
| `JAVA_HOME` | Directorio de instalación de Java | `/usr/lib/jvm/java-11` |
| `FLUME_HOME` | Directorio de instalación de Flume | `/opt/flume` |
| `HADOOP_CONF_DIR` | Directorio de configuración | `/opt/hadoop/etc/hadoop` |
| `HADOOP_LOG_DIR` | Directorio de logs | `/opt/hadoop/logs` |

## 🔗 Integración con Otras Herramientas

### Apache Spark
```bash
# Configurar Spark con YARN
export SPARK_HOME=/opt/spark
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
spark-submit --master yarn ...
```

### Apache Hive
```bash
# Configurar Hive con HDFS
export HIVE_HOME=/opt/hive
hive --service metastore
```

### Kafka Connect
```bash
# Ejemplo de conector HDFS
connect-standalone.sh connect-hdfs.properties
```

## 📊 Guía de Optimización

### Configuración de Memoria
```xml
<!-- mapred-site.xml -->
<property>
  <name>mapreduce.map.memory.mb</name>
  <value>2048</value>
</property>
```

### Optimización de YARN
```xml
<!-- yarn-site.xml -->
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>8192</value>
</property>
```

## 📝 Ejemplos de Uso Común

### MapReduce WordCount
```bash
# Compilar y ejecutar WordCount
hadoop jar wc.jar WordCount /input /output
```

### Streaming de Datos con Flume
```bash
# Configurar agente Flume
flume-ng agent -n agent1 -c conf -f conf/flume.conf
```

### Operaciones HDFS Básicas
```bash
# Operaciones comunes
hdfs dfs -put localfile /hdfs/path
hdfs dfs -get /hdfs/path localfile
hdfs dfs -ls /
```

## 📅 Changelog

### v1.0.0 (2024-03-15)
- ✨ Lanzamiento inicial
- 🔒 Implementación de seguridad básica
- 📊 Configuración de monitoreo

### v1.1.0 (2024-03-20)
- 🚀 Mejoras en el rendimiento
- 🔧 Corrección de bugs menores
- 📝 Actualización de documentación

## 📝 Licencia

Este proyecto está bajo la Licencia Apache 2.0. Ver el archivo [LICENSE](LICENSE) para más detalles.

---

<div align="center">

**¿Necesitas ayuda?** [Abre un Issue](https://github.com/ASKhem/hadoop-ubuntu-server.git/issues) • [Documentación](https://github.com/ASKhem/hadoop-ubuntu-server.git/wiki)

</div>
