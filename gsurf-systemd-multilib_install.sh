#!/bin/bash

# Recomendado PDV-2.U1604.415.1.4-* pra cima
# Sistema 64 bits deve ser multilib

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then
  echo "Este script deve ser executado como super usuário (root)."
  exit 1
fi

# Verificar se os pacotes estão instalados
if dpkg -s libc6:i386 libgcc1:i386 libstdc++6:i386 >/dev/null 2>&1; then
    echo "Todos os pacotes de dependências estão instalados."
# Verificar se os pacotes estão instalados Ubuntu 22.04
 elif dpkg -s libc6:i386 libgcc-s1:i386 libstdc++6:i386 >/dev/null 2>&1; then
 echo "Todos os pacotes de dependências estão instalados."
else
    # Caso algum pacote esteja faltando, exibir mensagem e sair
    echo "Algumas dependências estão faltando. Instale os seguintes pacotes antes de prosseguir:"
    dpkg -s libc6:i386 libgcc1:i386 libstdc++6:i386 2>&1 | grep "is not installed"
    exit 1
fi

# Função para verificar a conectividade externa
check_connectivity() {
    #ping -c 2 google.com > /dev/null 2>&1
    ping -c 2 m3.gsurfnet.com > /dev/null 2>&1
    return $?
}

# Verifica a conectividade
check_connectivity

# Verifica o status do retorno
if [ $? -eq 0 ]; then
    echo "Conectividade externa OK."
else
    echo "Sem conectividade externa."
    exit 1
fi

# Configurando GSurf
if [ -e /usr/gsurf/gsurfcli.txt ] ; then
	echo "Gsurf ja esta instalado!"
	exit 0
fi

mkdir -p /gsurf
cd /gsurf
wget -c http://gsurf.com.br/lib/linux/gsclient_ubuntu_x86.zip

if [ ! -e /gsurf/gsclient_ubuntu_x86.zip ]; then
	echo "gsclient nao foi baixado..."
	exit 0
fi

unzip -o gsclient_ubuntu_x86.zip
chmod +x *
cp -rfv *.so /usr/lib
ldconfig
./instalador

#./serverSSL -s sitef &

#if ! grep 'serverSSL' /etc/rc.local ; then
#sed -i '/startup/i /gsurf/serverSSL -s sitef &' /etc/rc.local
#fi

sed -i '/serverSSL/s/^/#/' /etc/rc.local

cat <<'EOF' > /etc/systemd/system/libssl.service
[Unit]
Description=LibSSL_GSurf
After=network-online.target zanthus.service
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
Restart=always
RestartSec=1
ExecStart=/gsurf/serverSSL -s sitef

[Install]
WantedBy=multi-user.target
EOF
chmod +x /etc/systemd/system/libssl.service
systemctl daemon-reload
systemctl enable libssl.service
systemctl start libssl.service
systemctl status libssl.service

echo -e "\n"
ps aux | grep -v grep | grep sitef

echo -e "\nListar porta 4096...\n"
netstat -anp | grep 4096 | grep -i listen ; 
lsof -i | grep 4096 ; 
nc -z -v 127.0.0.1 4096 | grep "succeeded"

echo -e "\nTestando conectividade com a porta 4096...\n"
sleep 5
telnet 127.0.0.1 4096
