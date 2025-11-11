#!/bin/bash

set -e

# Variáveis
readonly NETMASK="255.255.255.0"
readonly IP_FIXO="192.168.56.201"


readonly NIC="enp0s8"
readonly SITE_URL="https://www.tooplate.com/zip-templates/2129_crispy_kitchen.zip"
readonly WEB_DIR="/var/www/html"


readonly DOMAIN="luandi.local"
readonly DNS_CONF="/etc/named.conf"

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Funções de log
log_info() {
    echo -e "${YELLOW}[→] $1${NC}"
}

log_ok() {
    echo -e "${GREEN}[✓] $1${NC}"
}

log_erro() {
    echo -e "${RED}[✗] $1${NC}"
    exit 1
}

# Configura IP na interface
configurar_ip() {
    log_info "Configurando IP $IP_FIXO..."
    ifconfig "$NIC" "$IP_FIXO" netmask "$NETMASK" || log_erro "Falha ao configurar IP"
    log_ok "IP configurado"
}

# Instala dependências
instalar_dependencias() {
    log_info "Instalando dependências..."
    yum install -y httpd wget unzip bind &>/dev/null || log_erro "Falha na instalação"
    log_ok "Dependências instaladas"
}

# Inicia servidor web
iniciar_webserver() {
    log_info "Iniciando Apache..."
    systemctl enable --now httpd &>/dev/null || log_erro "Falha ao iniciar Apache"
    systemctl is-active --quiet httpd || log_erro "Apache não está rodando"
    log_ok "Apache rodando"
}

# Configura arquivos do site
configurar_site() {
    log_info "Configurando site..."
    
    rm -rf "$WEB_DIR"/* || log_erro "Falha na limpeza"
    
    wget -q "$SITE_URL" -O /tmp/site.zip || log_erro "Falha no download"
    
    unzip -q /tmp/site.zip -d /tmp/site || log_erro "Falha ao descompactar"
    
    mv /tmp/site/*/* "$WEB_DIR"/ 2>/dev/null || mv /tmp/site/* "$WEB_DIR"/ || log_erro "Falha ao mover arquivos"
    
    rm -rf /tmp/site*
    log_ok "Site configurado"
}

# Configura DNS (BIND)
configurar_dns() {
    log_info "Configurando DNS..."
    
    # Copia arquivo base para /etc/named.conf
    cp dns/named.conf "$DNS_CONF" || log_erro "Falha ao copiar named.conf"
    
    # Substitui VARIAVEL pelo domínio real
    sed -i "s/VARIAVEL/$DOMAIN/g" "$DNS_CONF"
    
    log_ok "DNS configurado"
}

# Inicia serviço DNS
iniciar_dns() {
    log_info "Iniciando serviço DNS..."
    systemctl enable named &>/dev/null || log_erro "Falha ao iniciar DNS"
    log_ok "DNS rodando"
}


# Função principal
main() {
    configurar_ip
    instalar_dependencias
    iniciar_webserver
    configurar_site


    configurar_dns
    iniciar_dns
    
    
    echo ""
    log_ok "Configuração concluída!"
    echo -e "  → Site: http://$IP_FIXO"
    echo -e "  → DNS: $DOMAIN"
}

# Execução
main
