# Define a range of blue colors for gradient effect
BLUE='\033[0;34m'
BLUE1='\033[0;34m'
BLUE2='\033[1;34m'
BLUE3='\033[0;94m'
BLUE4='\033[1;94m'
BLUE5='\033[4;34m'
NC='\033[0m'
# Obtener información del sistema
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')  # Obtiene la primera dirección IP
OS_VERSION=$(lsb_release -d | awk -F'\t' '{print $2}')  # Obtiene la descripción del sistema operativo
CURRENT_DATE_TIME=$(date "+%Y-%m-%d %H:%M")

# ASCII art in blue
echo -e "${BLUE1}    ___   _____ __ __ __  __          __                    ${NC}"
echo -e "${BLUE2}   /   | / ___// //_// / / /___  ____/ /___  ____  _____    ${NC}"
echo -e "${BLUE3}  / /| | \__ \/ ,<  / /_/ / __ \/ __  / __ \/ __ \/  __  \  ${NC}"
echo -e "${BLUE4} / ___ |___/ / /| |/ __  / /_/ / /_/ / /_/ / /_/  / /_/  /  ${NC}"
echo -e "${BLUE5}/_/  |_/____/_/ |_/_/ /_/\__,_/\__,_/\____/\____ / .___ /   ${NC}"
echo -e "${BLUE}                                                /_/         ${NC}"
echo -e "${BLUE}  author: @ASKhem                                            ${NC}"
echo -e "${BLUE}  ${CURRENT_DATE_TIME} ${NC}"
echo -e "${BLUE}  ╔═══════════════════════════════════════════════════╗    ${NC}"
echo -e "${BLUE}  ║  ¡Cluster ASKHadoop listo!                        ║    ${NC}"
echo -e "${BLUE}  ║  Puedes comenzar a ejecutar comandos de Hadoop.   ║    ${NC}"
echo -e "${BLUE}  ║  Información del sistema:                         ║    ${NC}"
echo -e "${BLUE}  ║    - Hostname: $HOSTNAME                         ║    ${NC}"
echo -e "${BLUE}  ║    - Password: hadoop123                          ║    ${NC}"
echo -e "${BLUE}  ║    - IP: $IP_ADDRESS                               ║    ${NC}"
echo -e "${BLUE}  ║    - OS: $OS_VERSION                       ║    ${NC}"
echo -e "${BLUE}  ║  Algunos comandos útiles:                         ║    ${NC}"
echo -e "${BLUE}  ║    - \$ hadoop version                             ║    ${NC}"
echo -e "${BLUE}  ║    - \$ hdfs dfs -ls /                             ║    ${NC}"
echo -e "${BLUE}  ║    - \$ yarn node -statuses                        ║    ${NC}"
echo -e "${BLUE}  ╚═══════════════════════════════════════════════════╝    ${NC}"
echo -e ""
echo -e ""
