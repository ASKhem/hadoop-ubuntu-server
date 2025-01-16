# Use Ubuntu 22.04
FROM ubuntu:22.04

# Build arguments
ARG HADOOP_VERSION=3.3.6
ARG HADOOP_USER=hadoopuser
ARG HADOOP_UID=1000
ARG HADOOP_GROUP=hadoop
ARG HADOOP_GID=1000
ARG FLUME_VERSION=1.11.0
ARG FLUME_USER=flumeuser
ARG FLUME_UID=1001
ARG FLUME_GROUP=flume
ARG FLUME_GID=1001

# Environment variables
ENV HADOOP_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    PATH=/opt/hadoop/bin:/opt/hadoop/sbin:/opt/flume/bin:${PATH} \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    FLUME_HOME=/opt/flume \
    HDFS_NAMENODE_USER=hadoopuser \
    HDFS_DATANODE_USER=hadoopuser \
    HDFS_SECONDARYNAMENODE_USER=hadoopuser \
    YARN_RESOURCEMANAGER_USER=hadoopuser \
    YARN_NODEMANAGER_USER=hadoopuser \
    DEBIAN_FRONTEND=noninteractive \
    NAMENODE_PORT=9870 \
    DATANODE_PORT=9864 \
    RESOURCEMANAGER_PORT=8088 \
    NODEMANAGER_PORT=8042 \
    FLUME_PORT=41414

# Instalar sudo primero
RUN apt-get update && \
    apt-get install -y sudo iputils-ping && \
    rm -rf /var/lib/apt/lists/*

# Create non-root users and groups
RUN groupadd -g ${HADOOP_GID} ${HADOOP_GROUP} && \
    useradd -u ${HADOOP_UID} -g ${HADOOP_GROUP} -m -s /bin/bash ${HADOOP_USER} && \
    groupadd -g ${FLUME_GID} ${FLUME_GROUP} && \
    useradd -u ${FLUME_UID} -g ${FLUME_GROUP} -m -s /bin/bash ${FLUME_USER} && \
    echo "${HADOOP_USER}:hadoop123" | chpasswd && \
    usermod -aG sudo ${HADOOP_USER} && \
    echo "${HADOOP_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hadoop_user && \
    chmod 0440 /etc/sudoers.d/hadoop_user

# Install required dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-11-jdk-headless \
    curl \
    netcat \
    gnupg \
    libsnappy1v5 \
    openssh-server \
    nano \
    lsof \
    wget \
    net-tools \
    lsb-release \
    tmux \
    libevent-dev \
    ncurses-dev \
    iputils-ping \
    htop \
    vim \
    telnet \
    dnsutils \
    procps \
    less \
    tree \
    cron \
    logrotate \
    fail2ban \
    iptables \
    auditd \
    rkhunter \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> /etc/profile.d/java.sh && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> /etc/environment && \
    . /etc/environment

# Copiar scripts de seguridad
COPY conf/scripts/setup-iptables.sh /opt/hadoop/scripts/
COPY conf/scripts/setup-security.sh /opt/hadoop/scripts/
RUN chmod +x /opt/hadoop/scripts/setup-iptables.sh /opt/hadoop/scripts/setup-security.sh

# Create base directories
RUN mkdir -p /data/hdfs/namenode /data/hdfs/datanode && \
    mkdir -p /opt/hadoop/logs && \
    mkdir -p /opt/hadoop/data && \
    chown -R ${HADOOP_USER}:${HADOOP_GROUP} /data/hdfs && \
    chown -R ${HADOOP_USER}:${HADOOP_GROUP} /opt/hadoop && \
    chmod 755 /data/hdfs && \
    chmod 700 /data/hdfs/namenode && \
    chmod 700 /data/hdfs/datanode

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    chmod 0755 /var/run/sshd && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "AllowUsers ${HADOOP_USER}" >> /etc/ssh/sshd_config && \
    rm -f /etc/ssh/ssh_host_* && \
    ssh-keygen -A && \
    chmod 600 /etc/ssh/ssh_host_*_key && \
    chmod 644 /etc/ssh/ssh_host_*_key.pub && \
    # Dar permisos al usuario hadoopuser para manejar SSH
    chown -R root:${HADOOP_GROUP} /etc/ssh && \
    chmod 755 /etc/ssh && \
    chmod 755 /usr/sbin/sshd && \
    chmod -R g+r /etc/ssh

# Configurar sudo sin contraseña para sshd
RUN echo "${HADOOP_USER} ALL=(ALL) NOPASSWD: /usr/sbin/sshd" >> /etc/sudoers.d/hadoop_user && \
    echo "${HADOOP_USER} ALL=(ALL) NOPASSWD: /bin/chmod" >> /etc/sudoers.d/hadoop_user && \
    echo "${HADOOP_USER} ALL=(ALL) NOPASSWD: /usr/bin/ssh-keygen" >> /etc/sudoers.d/hadoop_user

# Configure SSH for hadoopuser
RUN su - ${HADOOP_USER} -c "ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys" && \
    chown -R ${HADOOP_USER}:${HADOOP_GROUP} /home/${HADOOP_USER}/.ssh && \
    chmod 700 /home/${HADOOP_USER}/.ssh && \
    chmod 600 /home/${HADOOP_USER}/.ssh/authorized_keys && \
    chmod 600 /home/${HADOOP_USER}/.ssh/id_rsa && \
    chmod 644 /home/${HADOOP_USER}/.ssh/id_rsa.pub && \
    # Exportar la clave privada a un archivo temporal
    cp /home/${HADOOP_USER}/.ssh/id_rsa /tmp/hadoop_key && \
    chown ${HADOOP_USER}:${HADOOP_GROUP} /tmp/hadoop_key && \
    chmod 600 /tmp/hadoop_key

# Download and configure Hadoop
WORKDIR /tmp
RUN wget -O hadoop.tar.gz https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop.tar.gz && \
    mv hadoop-${HADOOP_VERSION}/* /opt/hadoop/ && \
    rm -rf hadoop-${HADOOP_VERSION} hadoop.tar.gz && \
    mkdir -p /opt/hadoop/{logs,scripts,config,data} && \
    chown -R ${HADOOP_USER}:${HADOOP_GROUP} /opt/hadoop

# Install Apache Flume
RUN wget -O flume.tar.gz https://downloads.apache.org/flume/${FLUME_VERSION}/apache-flume-${FLUME_VERSION}-bin.tar.gz && \
    tar -xzf flume.tar.gz && \
    mv apache-flume-${FLUME_VERSION}-bin /opt/flume && \
    rm -rf flume.tar.gz && \
    mkdir -p /opt/flume/conf /opt/flume/logs && \
    chown -R ${FLUME_USER}:${FLUME_GROUP} /opt/flume && \
    chmod 755 /opt/flume/bin/* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Verify installation and configure permissions
RUN if [ -d "/opt/hadoop/bin" ] && [ -d "/opt/hadoop/sbin" ]; then \
    chmod +x /opt/hadoop/bin/* /opt/hadoop/sbin/* || true; \
    else \
    echo "Error: Hadoop directories not found"; \
    exit 1; \
    fi

# Copy configuration files
COPY --chown=${HADOOP_USER}:${HADOOP_GROUP} conf/hadoop/* ${HADOOP_HOME}/config/
COPY --chown=${HADOOP_USER}:${HADOOP_GROUP} conf/scripts/entrypoint.sh ${HADOOP_HOME}/scripts/
COPY --chown=${HADOOP_USER}:${HADOOP_GROUP} conf/scripts/welcome.sh ${HADOOP_HOME}/scripts/
COPY --chown=${HADOOP_USER}:${HADOOP_GROUP} conf/scripts/check-services.sh ${HADOOP_HOME}/scripts/
COPY --chown=root:root conf/scripts/hadoop-welcome.sh /etc/profile.d/

# Configure symlinks and permissions
RUN ln -sf ${HADOOP_HOME}/config/* ${HADOOP_CONF_DIR}/ && \
    ln -sf ${HADOOP_HOME}/scripts/entrypoint.sh /entrypoint.sh && \
    chmod +x ${HADOOP_HOME}/scripts/* && \
    chmod +x /etc/profile.d/hadoop-welcome.sh && \
    echo "source /etc/profile.d/hadoop-welcome.sh" >> /home/${HADOOP_USER}/.bashrc

# Copiar scripts de mantenimiento
COPY conf/scripts/rotate-logs.sh /opt/hadoop/scripts/
COPY conf/scripts/backup-hdfs.sh /opt/hadoop/scripts/
RUN chmod +x /opt/hadoop/scripts/rotate-logs.sh /opt/hadoop/scripts/backup-hdfs.sh

# Copiar scripts de seguridad y monitorización
COPY conf/scripts/security-audit.sh /opt/hadoop/scripts/
COPY conf/scripts/monitor-hadoop.sh /opt/hadoop/scripts/
RUN chmod +x /opt/hadoop/scripts/security-audit.sh /opt/hadoop/scripts/monitor-hadoop.sh

# Configurar cron y logrotate
RUN touch /var/log/cron.log && \
    chown ${HADOOP_USER}:${HADOOP_GROUP} /var/log/cron.log && \
    (crontab -l -u ${HADOOP_USER} 2>/dev/null; \
    echo "0 0 * * * /opt/hadoop/scripts/rotate-logs.sh >> /var/log/cron.log 2>&1"; \
    echo "0 1 * * * /opt/hadoop/scripts/backup-hdfs.sh >> /var/log/cron.log 2>&1"; \
    echo "*/15 * * * * /opt/hadoop/scripts/monitor-hadoop.sh >> /var/log/cron.log 2>&1"; \
    echo "0 */4 * * * /opt/hadoop/scripts/security-audit.sh >> /var/log/cron.log 2>&1") | crontab -u ${HADOOP_USER} - && \
    echo "#!/bin/bash\nservice cron start" > /opt/hadoop/scripts/start-cron.sh && \
    chmod +x /opt/hadoop/scripts/start-cron.sh

# Configurar logrotate para logs del sistema
RUN echo "/var/log/cron.log {\n\
    daily\n\
    rotate 7\n\
    compress\n\
    delaycompress\n\
    missingok\n\
    notifempty\n\
    create 640 root adm\n\
}" > /etc/logrotate.d/cron

# Healthcheck para verificar servicios críticos
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD netstat -tulpn | grep -q ":$NAMENODE_PORT" && \
        netstat -tulpn | grep -q ":$RESOURCEMANAGER_PORT" && \
        netstat -tulpn | grep -q ":22" || exit 1

# Volumes for persistence
VOLUME ["/data/hdfs/namenode", "/data/hdfs/datanode", "/opt/flume/logs", "/opt/hadoop/logs"]

# Required ports
EXPOSE ${NAMENODE_PORT} ${DATANODE_PORT} ${RESOURCEMANAGER_PORT} ${NODEMANAGER_PORT} ${FLUME_PORT} 22

# Modificar el ENTRYPOINT para incluir la configuración de seguridad
ENTRYPOINT ["/bin/bash", "-c", "/opt/hadoop/scripts/entrypoint.sh & sleep 5 && /opt/hadoop/scripts/setup-security.sh && /opt/hadoop/scripts/setup-iptables.sh && /opt/hadoop/scripts/start-cron.sh && wait"]

# Agregar un script para extraer la clave
RUN echo '#!/bin/bash' > /opt/hadoop/scripts/extract_key.sh && \
    echo "cat /home/${HADOOP_USER}/.ssh/id_rsa" >> /opt/hadoop/scripts/extract_key.sh && \
    chown ${HADOOP_USER}:${HADOOP_GROUP} /opt/hadoop/scripts/extract_key.sh && \
    chmod +x /opt/hadoop/scripts/extract_key.sh

# Después de la instalación de SSH y antes de la configuración de SSH
USER root
RUN truncate -s 0 /etc/motd && \
    rm -f /etc/update-motd.d/* && \
    rm -f /etc/legal && \
    # Configurar variables de entorno de ASKHadoop
    echo "export HADOOP_HOME=/opt/hadoop" >> /etc/profile.d/hadoop.sh && \
    echo "export PATH=\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$PATH" >> /etc/profile.d/hadoop.sh && \
    echo "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop" >> /etc/profile.d/hadoop.sh && \
    chmod +x /etc/profile.d/hadoop.sh && \
    # Configurar permisos de ASKHadoop
    chown -R ${HADOOP_USER}:${HADOOP_GROUP} ${HADOOP_HOME} && \
    chmod -R 755 ${HADOOP_HOME}/bin && \
    chmod -R 755 ${HADOOP_HOME}/sbin

# Cambiar al usuario Hadoop
USER ${HADOOP_USER}

# Asegurar que el archivo .bashrc del usuario Hadoop cargue las variables
RUN echo "source /etc/profile.d/hadoop.sh" >> /home/${HADOOP_USER}/.bashrc