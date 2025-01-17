# Stage 1: Download and prepare dependencies
FROM ubuntu:22.04 AS builder

# Build arguments
ARG HADOOP_VERSION=3.3.6
ARG FLUME_VERSION=1.11.0

# Download Hadoop and Flume
WORKDIR /tmp
RUN apt-get update && \
    apt-get install -y wget && \
    wget -O hadoop.tar.gz https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    wget -O flume.tar.gz https://downloads.apache.org/flume/${FLUME_VERSION}/apache-flume-${FLUME_VERSION}-bin.tar.gz && \
    tar -xzf hadoop.tar.gz && \
    tar -xzf flume.tar.gz && \
    mv hadoop-${HADOOP_VERSION} /hadoop && \
    mv apache-flume-${FLUME_VERSION}-bin /flume

# Stage 2: Final image
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
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    HADOOP_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    PATH=/usr/lib/jvm/java-11-openjdk-amd64/bin:/opt/hadoop/bin:/opt/hadoop/sbin:/opt/flume/bin:${PATH} \
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

# Create hadoop-env.sh with environment variables
RUN mkdir -p /opt/hadoop/etc/hadoop && \
    echo "export JAVA_HOME=${JAVA_HOME}" > /opt/hadoop/etc/hadoop/hadoop-env.sh && \
    echo "export HADOOP_HOME=${HADOOP_HOME}" >> /opt/hadoop/etc/hadoop/hadoop-env.sh && \
    echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> /opt/hadoop/etc/hadoop/hadoop-env.sh && \
    echo "export PATH=\${JAVA_HOME}/bin:\${HADOOP_HOME}/bin:\${HADOOP_HOME}/sbin:\${PATH}" >> /opt/hadoop/etc/hadoop/hadoop-env.sh && \
    chmod +x /opt/hadoop/etc/hadoop/hadoop-env.sh

# Install minimal required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-11-jdk-headless \
    openssh-server \
    openssh-client \
    sudo \
    netcat \
    net-tools \
    iputils-ping \
    curl \
    lsb-release \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create users and groups
RUN groupadd -g ${HADOOP_GID} ${HADOOP_GROUP} && \
    useradd -u ${HADOOP_UID} -g ${HADOOP_GROUP} -m -s /bin/bash ${HADOOP_USER} && \
    groupadd -g ${FLUME_GID} ${FLUME_GROUP} && \
    useradd -u ${FLUME_UID} -g ${FLUME_GROUP} -m -s /bin/bash ${FLUME_USER} && \
    echo "${HADOOP_USER}:hadoop123" | chpasswd && \
    usermod -aG sudo ${HADOOP_USER} && \
    echo "${HADOOP_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hadoop_user && \
    chmod 0440 /etc/sudoers.d/hadoop_user

# Copy Hadoop and Flume from builder stage
COPY --from=builder /hadoop /opt/hadoop
COPY --from=builder /flume /opt/flume

# Create necessary directories
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
    rm -f /etc/ssh/ssh_host_* && \
    ssh-keygen -A && \
    chmod 0755 /var/run/sshd && \
    echo "Port 22" > /etc/ssh/sshd_config && \
    echo "Protocol 2" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "AllowUsers ${HADOOP_USER}" >> /etc/ssh/sshd_config && \
    echo "StrictModes yes" >> /etc/ssh/sshd_config && \
    echo "IgnoreRhosts yes" >> /etc/ssh/sshd_config && \
    echo "X11Forwarding yes" >> /etc/ssh/sshd_config && \
    echo "PrintMotd no" >> /etc/ssh/sshd_config && \
    echo "PrintLastLog yes" >> /etc/ssh/sshd_config && \
    echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config && \
    echo "AcceptEnv LANG LC_* JAVA_HOME HADOOP_* PATH" >> /etc/ssh/sshd_config && \
    echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config && \
    echo "Subsystem sftp /usr/lib/openssh/sftp-server" >> /etc/ssh/sshd_config && \
    chmod 600 /etc/ssh/ssh_host_*_key && \
    chmod 644 /etc/ssh/ssh_host_*_key.pub

# Configure SSH environment for hadoopuser
RUN su - ${HADOOP_USER} -c "ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    echo 'JAVA_HOME=${JAVA_HOME}' > ~/.ssh/environment && \
    echo 'HADOOP_HOME=${HADOOP_HOME}' >> ~/.ssh/environment && \
    echo 'HADOOP_CONF_DIR=${HADOOP_CONF_DIR}' >> ~/.ssh/environment && \
    echo 'PATH=${PATH}' >> ~/.ssh/environment" && \
    chown -R ${HADOOP_USER}:${HADOOP_GROUP} /home/${HADOOP_USER}/.ssh && \
    chmod 700 /home/${HADOOP_USER}/.ssh && \
    chmod 600 /home/${HADOOP_USER}/.ssh/authorized_keys && \
    chmod 600 /home/${HADOOP_USER}/.ssh/environment

# Copy configuration files
COPY --chown=${HADOOP_USER}:${HADOOP_GROUP} conf/hadoop/* ${HADOOP_HOME}/config/
COPY --chown=${HADOOP_USER}:${HADOOP_GROUP} conf/flume/* /opt/flume/conf/
COPY --chown=${HADOOP_USER}:${HADOOP_GROUP} conf/scripts/entrypoint.sh ${HADOOP_HOME}/scripts/
COPY --chown=${HADOOP_USER}:${HADOOP_GROUP} conf/scripts/welcome.sh ${HADOOP_HOME}/scripts/
COPY --chown=${HADOOP_USER}:${HADOOP_GROUP} conf/scripts/check-services.sh ${HADOOP_HOME}/scripts/
COPY --chown=root:root conf/scripts/hadoop-welcome.sh /etc/profile.d/

# Configure symlinks and permissions
RUN ln -sf ${HADOOP_HOME}/config/* ${HADOOP_CONF_DIR}/ && \
    ln -sf ${HADOOP_HOME}/scripts/entrypoint.sh /entrypoint.sh && \
    chmod +x ${HADOOP_HOME}/scripts/* && \
    chmod +x /etc/profile.d/hadoop-welcome.sh && \
    chown -R ${HADOOP_USER}:${HADOOP_GROUP} /opt/flume && \
    chmod -R 755 /opt/flume/conf

# Create extract_key script
RUN echo '#!/bin/bash' > /opt/hadoop/scripts/extract_key.sh && \
    echo "cat /home/${HADOOP_USER}/.ssh/id_rsa" >> /opt/hadoop/scripts/extract_key.sh && \
    chown ${HADOOP_USER}:${HADOOP_GROUP} /opt/hadoop/scripts/extract_key.sh && \
    chmod +x /opt/hadoop/scripts/extract_key.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD netstat -tulpn | grep -q ":$NAMENODE_PORT" && \
    netstat -tulpn | grep -q ":$RESOURCEMANAGER_PORT" && \
    netstat -tulpn | grep -q ":22" || exit 1

# Volumes for persistence
VOLUME ["/data/hdfs/namenode", "/data/hdfs/datanode", "/opt/flume/logs", "/opt/hadoop/logs"]

# Required ports
EXPOSE ${NAMENODE_PORT} ${DATANODE_PORT} ${RESOURCEMANAGER_PORT} ${NODEMANAGER_PORT} ${FLUME_PORT} 22

# Switch to hadoopuser
USER ${HADOOP_USER}

# Set working directory
WORKDIR /home/${HADOOP_USER}

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Create Flume logs directory
RUN mkdir -p /opt/flume/logs && \
    chown -R ${HADOOP_USER}:${HADOOP_GROUP} /opt/flume && \
    chmod -R 755 /opt/flume