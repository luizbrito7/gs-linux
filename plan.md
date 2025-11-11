## ANTRES DE EXECUTAR O SCRIPT 

# 1. configurar placas de redes 
- nic nat
- nic host-only  

# 2. ip fixo na nic host-only 
- ifconfig enp0s8 192.168.56.201 netmask 255.255.255.0

# ================================

# 0. atualizar vm 
- yum update && yum upgrade -y 

# 1. instalar o webserver
- yum install httpd -y

# 2. start do processo do webserver
- systemctl enable httpd && systemctl start httpd && systemctl status httpd
- se o status retornar RUNNING deu tudo certo, se não me retorna erro e para o script 

# 3. copiar os arquivos do site para a pasta do apache
- rm -rf /var/www/html/*
- wget -q https://www.tooplate.com/zip-templates/2129_crispy_kitchen.zip -O /tmp/site.zip
- unzip -q /tmp/site.zip -d /tmp/site
- mv /tmp/site/*/* /var/www/html/

4. 