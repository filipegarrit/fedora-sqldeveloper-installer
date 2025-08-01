#!/bin/bash

# ==============================================================================
# Script Totalmente Automático para Instalação do Oracle SQL Developer com JDK 21
#
# Autor: Seu Nome/Empresa
# Versão: 9.0
#
# PRÉ-REQUISITOS:
# Antes de executar, baixe e coloque os SEGUINTES DOIS ARQUIVOS na sua
# pasta de Downloads (`~/Downloads`):
#
#   1. Oracle JDK 21 RPM (ex: jdk-21_linux-x64_bin.rpm)
#      Link: https://www.oracle.com/java/technologies/downloads/#jdk21-linux
#
#   2. Oracle SQL Developer 24.3.1 RPM (sqldeveloper-24.3.1-347.1826.noarch.rpm)
#      Link: https://download.oracle.com/otn_software/java/sqldeveloper/sqldeveloper-24.3.1-347.1826.noarch.rpm
#
# Instruções de Uso:
# 1. Garanta que os dois arquivos RPM estão na sua pasta de Downloads.
# 2. Salve este código como 'instalar_sqldev_fedora_v9.sh'.
# 3. Dê permissão de execução: chmod +x instalar_sqldev_fedora_v9.sh
# 4. Execute o script com sudo: sudo ./instalar_sqldev_fedora_v9.sh
#
# ==============================================================================

# --- Cores e Configurações ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Verificações Iniciais ---
echo -e "${GREEN}Iniciando a instalação automática do Oracle SQL Developer com JDK 21...${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Erro: Este script precisa ser executado com privilégios de root (sudo).${NC}"
  exit 1
fi

if [ -z "$SUDO_USER" ]; then
    echo -e "${RED}Erro: Não foi possível determinar o usuário que executou o sudo. Execute como 'sudo ./script.sh'.${NC}"
    exit 1
fi

# Detecta o diretório home do usuário que chamou o sudo, não do root
USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
USER_DOWNLOADS_DIR="$USER_HOME/Downloads"

if [ ! -d "$USER_DOWNLOADS_DIR" ]; then
    echo -e "${RED}Erro: A pasta de Downloads '$USER_DOWNLOADS_DIR' não foi encontrada.${NC}"
    exit 1
fi

# --- Passo 1: Localizar Arquivos RPM ---
echo -e "\n${YELLOW}Passo 1: Procurando arquivos RPM em '$USER_DOWNLOADS_DIR'...${NC}"

JDK_RPM_PATH=$(find "$USER_DOWNLOADS_DIR" -maxdepth 1 -name "jdk-21*.rpm" -type f | head -n 1)
SQLDEV_RPM_PATH=$(find "$USER_DOWNLOADS_DIR" -maxdepth 1 -name "sqldeveloper-*.rpm" -type f | head -n 1)

# Validação dos arquivos
if [ -z "$JDK_RPM_PATH" ]; then
    echo -e "${RED}Erro: O arquivo RPM do Oracle JDK 21 não foi encontrado na sua pasta de Downloads.${NC}"
    echo -e "${RED}Por favor, baixe o 'jdk-21_linux-x64_bin.rpm' e tente novamente.${NC}"
    exit 1
fi

if [ -z "$SQLDEV_RPM_PATH" ]; then
    echo -e "${RED}Erro: O arquivo RPM do SQL Developer não foi encontrado na sua pasta de Downloads.${NC}"
    echo -e "${RED}Por favor, baixe o 'sqldeveloper-*.rpm' e tente novamente.${NC}"
    exit 1
fi

echo -e "${GREEN}Arquivos encontrados:${NC}"
echo -e "  - JDK: $JDK_RPM_PATH"
echo -e "  - SQL Developer: $SQLDEV_RPM_PATH"

# --- Passo 2: Instalação dos Pacotes ---
echo -e "\n${YELLOW}Passo 2: Instalando pacotes via DNF...${NC}"

echo "Instalando o Oracle JDK 21..."
dnf install -y "$JDK_RPM_PATH"
if [ $? -ne 0 ]; then echo -e "${RED}Falha na instalação do JDK.${NC}"; exit 1; fi

echo "Instalando o SQL Developer..."
dnf install -y "$SQLDEV_RPM_PATH"
if [ $? -ne 0 ]; then echo -e "${RED}Falha na instalação do SQL Developer.${NC}"; exit 1; fi

echo -e "${GREEN}Pacotes RPM instalados com sucesso!${NC}"


# --- Passo 3: Verificação e Correção do Atalho de Aplicativo ---
echo -e "\n${YELLOW}Passo 3: Verificando atalho e aplicando correção gráfica...${NC}"

DESKTOP_ENTRY_PATH=$(find /usr/share/applications -name "*sqldeveloper*.desktop" -type f | head -n 1)

if [ -n "$DESKTOP_ENTRY_PATH" ]; then
    echo "Atalho encontrado em: $DESKTOP_ENTRY_PATH"
    if grep -q "env GDK_BACKEND=x11" "$DESKTOP_ENTRY_PATH"; then
        echo -e "${GREEN}Correção para Wayland/X11 já aplicada.${NC}"
    else
        echo "Modificando o atalho existente para garantir a compatibilidade..."
        sed -i 's/^Exec=/Exec=env GDK_BACKEND=x11 /' "$DESKTOP_ENTRY_PATH"
        echo -e "${GREEN}Atalho corrigido com sucesso!${NC}"
    fi
else
    echo -e "${YELLOW}Aviso: O pacote RPM não criou um atalho de aplicativo. Criando um manualmente...${NC}"
    
    SQLDEV_EXEC_PATH="/opt/sqldeveloper/sqldeveloper.sh"
    ICON_PATH="/opt/sqldeveloper/icon.png"
    NEW_DESKTOP_PATH="/usr/share/applications/oracle-sqldeveloper.desktop"

    if [ ! -f "$SQLDEV_EXEC_PATH" ]; then
        echo -e "${RED}Erro Crítico: O executável do SQL Developer não foi encontrado em $SQLDEV_EXEC_PATH.${NC}"
    else
        cat > "$NEW_DESKTOP_PATH" <<EOL
[Desktop Entry]
Name=Oracle SQL Developer
Comment=Oracle SQL Developer
Exec=env GDK_BACKEND=x11 $SQLDEV_EXEC_PATH
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Development;IDE;Database;
EOL
        echo -e "${GREEN}Atalho manual criado e corrigido em $NEW_DESKTOP_PATH com sucesso!${NC}"
    fi
fi

# --- Conclusão ---
echo -e "\n\n${GREEN}====================================================="
echo -e " Instalação Concluída!"
echo -e "=====================================================${NC}"
echo -e "Você já pode encontrar e usar o Oracle SQL Developer no seu menu de aplicativos."
echo -e "O ambiente foi configurado com o moderno e recomendado ${YELLOW}Oracle JDK 21${NC}."
echo -e "\n"
