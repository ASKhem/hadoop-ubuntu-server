#!/bin/bash

# Verificar estado de SSH
if ! pgrep -f sshd > /dev/null; then
    echo "Error: SSH no está en ejecución en askhadoopx"
    exit 1
fi

# Verificar claves SSH
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "Error: Faltan claves SSH del host en askhadoopx"
    exit 1
fi

# Verificar puerto SSH
if ! netstat -tln | grep -q ":22 "; then
    echo "Error: SSH no está escuchando en el puerto 22 en askhadoopx"
    exit 1
fi

echo "Todos los servicios están funcionando correctamente en askhadoopx" 