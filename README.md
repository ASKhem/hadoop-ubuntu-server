# 🐘 Hadoop Docker Environment

> Entorno Hadoop containerizado completo para desarrollo y pruebas, listo para usar en minutos.

<div align="center">

![Hadoop Version](https://img.shields.io/badge/Hadoop-3.3.6-blue)
![Flume Version](https://img.shields.io/badge/Flume-1.11.0-green)
![Ubuntu Version](https://img.shields.io/badge/Ubuntu-22.04%20LTS-orange)
![License](https://img.shields.io/badge/license-Apache%202.0-red)

</div>

## 🚀 Características Principales

- ✨ **Hadoop 3.3.6** - Última versión estable
- 🌊 **Apache Flume 1.11.0** - Recolección de datos en tiempo real
- 🔄 **Rotación automática de logs**
- 💾 **Backup automático de HDFS**
- 📊 **Monitorización de salud del sistema**
- ⚡ **Gestión automática de recursos**

## 📋 Requisitos Previos

| Componente | Mínimo Requerido |
|------------|------------------|
| Docker     | 20.10+          |
| RAM        | 4GB             |
| Disco      | 20GB            |

## 🏃‍♂️ Inicio Rápido

1️⃣ Clonar el repositorio
```bash
git clone https://github.com/ASKhem/hadoop-ubuntu-server.git
```

2️⃣ Ejecutar el script de configuración
```bash
./setup-hadoop.sh
```

3️⃣ Conectarse al contenedor
```bash
ssh -i id_rsa hadoopuser@localhost -p 22
```

## 🔌 Puertos Expuestos

| Puerto | Servicio                  |
|--------|---------------------------|
| 22     | SSH                       |
| 9870   | HDFS NameNode Web UI      |
| 8088   | YARN ResourceManager UI   |
| 9000   | HDFS                      |
| 9864   | DataNode HTTP             |
| 41414  | Flume                     |

## 📁 Estructura del Proyecto

```
hadoop-docker/
├── 📂 conf/
│   ├── 📂 flume/          # Configuración Flume
│   ├── 📂 hadoop/         # Configuración Hadoop
│   └── 📂 scripts/        # Scripts de utilidad
├── 📄 Dockerfile          # Definición del contenedor
├── 📄 setup-hadoop.sh     # Script de configuración
└── 📄 README.md          # Documentación
```

## 🛠️ Características Principales

### 📊 Monitorización Automática

- ✅ Healthchecks cada 30 segundos
- 🔄 Verificación continua de servicios
- 🔁 Reinicio automático ante fallos

### 🔒 Seguridad Integrada

- 🔑 SSH con autenticación por clave
- 👤 Usuario no-root para servicios
- 📝 Logs seguros y rotados

### 💾 Backup y Mantenimiento

- 📅 Backups diarios automatizados
- 🗜️ Compresión automática
- ⏰ Retención configurable

## 🔧 Ejemplos de Uso

### MapReduce
```bash
# Ejemplo WordCount
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
    wordcount /input /output
```

### HDFS
```bash
# Operaciones básicas
hdfs dfs -put local_file.txt /user/hadoopuser/
hdfs dfs -ls /user/hadoopuser/
hdfs dfs -du -h /user/hadoopuser/
```

## 🔍 Monitorización

### Métricas Clave
- 📊 Uso de HDFS
- ⚡ Rendimiento MapReduce
- 💻 Estado de nodos
- 📈 Uso de recursos

### Herramientas
- 📉 Grafana
- 📊 Prometheus
- 📈 Ganglia

## 🤝 Contribuir

1. Fork el repositorio
2. Crea tu rama (`git checkout -b feature/caracteristica`)
3. Commit tus cambios (`git commit -am 'Añadir característica'`)
4. Push a la rama (`git push origin feature/caracteristica`)
5. Abre un Pull Request

## ❓ Preguntas Frecuentes

<details>
<summary>¿Cómo mejorar el rendimiento de MapReduce?</summary>

- Ajustar parámetros de memoria
- Usar compresión
- Optimizar número de mappers/reducers
</details>

<details>
<summary>¿Qué hacer si el NameNode no inicia?</summary>

1. Verificar logs en `/opt/hadoop/logs/`
2. Comprobar permisos
3. Revisar configuración
</details>

## 📝 Licencia

Este proyecto está bajo la Licencia Apache 2.0. Ver el archivo [LICENSE](LICENSE) para más detalles.

---

<div align="center">

**¿Necesitas ayuda?** [Abre un Issue](https://github.com/ASKhem/hadoop-ubuntu-server.git/issues) • [Documentación](https://github.com/ASKhem/hadoop-ubuntu-server.git/wiki)

</div>
