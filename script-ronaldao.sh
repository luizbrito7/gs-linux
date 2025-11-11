#!/bin/bash

set -e

echo "=== INICIANDO CONFIGURAÇÃO COMPLETA DA GS ==="

############################################
# VARIÁVEIS
############################################
DOMAIN="ronaldo.com.br"
ZONE_DIR="/etc/named/zones"
ZONE_FILE="$ZONE_DIR/db.$DOMAIN"
REV_ZONE_FILE="$ZONE_DIR/db.192.168.0"
HOST_IFACE="enp0s8"
IP="192.168.56.201"
NETMASK="255.255.255.0"
GATEWAY="192.168.0.1"

############################################
# CONFIGURAÇÃO DE REDE VIA IFCONFIG
############################################
echo "[REDE] Configurando interface host-only com ifconfig..."

dnf -y install net-tools

ifconfig $HOST_IFACE down
ifconfig $HOST_IFACE $IP netmask $NETMASK up
route add default gw $GATEWAY $HOST_IFACE || true

echo "[OK] Interface configurada:"
ifconfig $HOST_IFACE

############################################
# INSTALANDO SERVIDOR WEB E TEMPLATE
############################################
echo "[WEB] Instalando Apache e publicando site..."

dnf -y install httpd wget unzip

systemctl enable --now httpd

rm -rf /var/www/html/*
wget -q https://www.tooplate.com/zip-templates/2129_crispy_kitchen.zip -O /tmp/site.zip
unzip -q /tmp/site.zip -d /tmp/site
mv /tmp/site/*/* /var/www/html/

chown -R apache:apache /var/www/html
restorecon -R /var/www/html || true

echo "[OK] Site publicado em http://$IP"

############################################
# INSTALANDO E CONFIGURANDO DNS (BIND)
############################################
echo "[DNS] Instalando Bind..."

dnf -y install bind bind-utils

mkdir -p $ZONE_DIR
chown named:named $ZONE_DIR

echo "[DNS] Criando Zona Direta..."

cat > $ZONE_FILE <<EOF
\$TTL 300
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. (
        2024022201
        7200
        3600
        86400
        300
)
@       IN      NS      ns1.$DOMAIN.
@       IN      NS      ns2.$DOMAIN.

ns1     IN      A       $IP
ns2     IN      A       $IP
www     IN      A       $IP
mail    IN      A       $IP

@       IN      MX 10   mail.$DOMAIN.
EOF

echo "[DNS] Criando Zona Reversa..."

cat > $REV_ZONE_FILE <<EOF
\$TTL 300
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. (
        2024022201
        7200
        3600
        86400
        300
)
@       IN      NS      ns1.$DOMAIN.
@       IN      NS      ns2.$DOMAIN.

201     IN      PTR     ns1.$DOMAIN.
201     IN      PTR     ns2.$DOMAIN.
201     IN      PTR     mail.$DOMAIN.
EOF

echo "[DNS] Declarando zonas no named.conf..."

cat >> /etc/named.conf <<EOF

zone "$DOMAIN" IN {
    type master;
    file "$ZONE_FILE";
};

zone "0.168.192.in-addr.arpa" IN {
    type master;
    file "$REV_ZONE_FILE";
};
EOF

chown named:named "$ZONE_FILE" "$REV_ZONE_FILE"

named-checkconf
named-checkzone $DOMAIN $ZONE_FILE
named-checkzone 0.168.192.in-addr.arpa $REV_ZONE_FILE

systemctl enable --now named

############################################
# FIREWALL E SELINUX
############################################
echo "[FIREWALL] Ajustando regras..."

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --reload

setsebool -P httpd_can_network_connect on || true

############################################
# FINALIZAÇÃO
############################################
echo ""
echo "======================================"
echo " AMBIENTE CONFIGURADO COM SUCESSO!"
echo "======================================"
echo "Acesse o site no navegador:"
echo "  → http://$IP"
echo ""
echo "Para acessar usando o nome do domínio em outra máquina:"
echo "  Adicione no /etc/hosts:"
echo "  $IP www.$DOMAIN $DOMAIN"
echo "======================================"