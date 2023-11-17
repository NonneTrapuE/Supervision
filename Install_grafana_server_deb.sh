#!/bin/bash

clear

echo "Installation de Grafana Dashboard...."
apt install -y apt-transport-https software-properties-common wget gpg sudo

if [[ $? != "0" ]]; then
        echo "Impossible d'installer les dépendances. Le programme va quitter."
        exit 1
fi

mkdir -p /etc/apt/keyrings/

if [[ $? != "0" ]]; then
        echo "Impossible de créer le dossier des clés APT. Le programme va quitter."
        exit 2
fi

wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

if [[ $? != "0" ]]; then
        echo "Impossible d'ajouter la clé APT dans Debian. Le programme va quitter."
        exit 3
fi


echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

if [[ $? != "0" ]]; then
        echo "Impossible d'ajouter la signature de la clé GPG. Le programme va quitter."
        exit 4
fi

apt update
apt install -y grafana

if [[ $? != "0" ]]; then
        echo "Impossible d'installer le package grafana. Le programme va quitter."
        exit 5
fi

cp /etc/grafana/grafana.ini /etc/grafana/grafana.ini.bak
echo "http_port = 3000" > /etc/grafana/grafana.ini

systemctl daemon-reload
systemctl enable --now grafana-server

if [[ $? != "0" ]]; then
        echo "Impossible de lancer le service grafana-server. Le programme va quitter."
        exit 6
fi

clear

echo "#######################################"
echo "Installation de grafana-server terminée"
echo -e "\n\t * Identifiant: admin\n\t * Mot de passe: admin"
echo "#######################################"


