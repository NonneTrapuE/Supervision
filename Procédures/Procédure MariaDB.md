# Supervision de MariaDB

## Installation et configuration de MariaDB sur Debian 11

Sur le site de MariaDB, allez dans la section **Download**. Dans cette section, il existe 3 onglets : 

- MariaDB Server
- MariaDB Server Repositories
- Connectors

Selectionnez l'onglet **MariaDB Server Repositories** 

[![Capture-d-cran-2023-11-22-114408.png](https://i.postimg.cc/yNmjkMbS/Capture-d-cran-2023-11-22-114408.png)](https://postimg.cc/p9dzS6x2)
 
Nous utiliserons dans ce tutoriel mariadb 11.2, la version 11.3 étant encore en RC.

Suivez simplement les instructions dispensées par le site, celles-ci étant facilement adaptables pour chaque distribution Linux.

Une fois MariaDB installé, il faut le configurer.

```bash
mysql_secure_installation
 ```

Pour cette procédure, je vous recommande de ne pas activer l'authentification Unix. Par contre, il est nécessaire de changer le mot de passe **root**
Une fois configuré, il faut nous connecter dans MariaDB en **root**. 

```bash
mariadb -u root -p
 ```

Nous allons créer un utilisateur unique pour exporter les données vers Prometheus.

```sql
 create user 'exporter' identified by 'motdepasse' with max_user_connections 3;
 grant process, replication client, select on *.* to 'exporter';
 flush privileges;
 ```

Quittez MariaDB.
Nous allons créer un fichier de configuration pour le MariaDB Exporter.
Dans **/etc/mysql**, nous créerons le fichier **mysqld_exporter.cnf**.

```bash
 nano /etc/mysql/mysqld_exporter.cnf
 ```

Nous ajouterons les informations suivantes :

 ```ini
 [client]
  user = exporter
  password = "motdepasse"
```

## Mysqld Exporter

Les exporters sont disponibles à cette [adresse](https://github.com/prometheus/mysqld_exporter/releases/tag/v0.15.0). Nous téléchargerons la version linux-amd64.

```bash
cd /tmp
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.0/mysqld_exporter-0.15.0.linux-amd64.tar.gz
tar xzvf mysqld_exporter-0.15.0.linux-amd64.tar.gz
mv mysqld_exporter-0.15.0.linux-amd64 /opt/mysql_exporter
 ```

Créer un utilisateur système qui sera dédié à notre exporter.

```bash
useradd mysqld_exporter --system --shell /bin/false
```

Attribuez les droits aux différents fichiers de configuration ainsi qu'aux exécutables

```bash
chown mysqld_exporter -R /opt/mysqld_exporter
chmod 755 -R /opt/mysqld_exporter
chown root:mysqld_exporter /etc/mysql/mysqld_exporter.cnf
chmod 755 /etc/mysqld_exporter.cnf
```
Créez le script systemd.

```bash
nano /etc/systemd/system/mysqld_exporter.service
``` 

Puis intégrez cette configuration

```ini
[Unit]
Description=Prometheus MySQL Exporter
After=network.target
User=prometheus
Group=prometheus

[Service]
Type=simple
Restart=always
ExecStart=/opt/mysqld_exporter/mysqld_exporter \
--config.my-cnf /etc/mysql/mysqld_exporter.cnf \
--collect.global_status \
--collect.info_schema.innodb_metrics \
--collect.auto_increment.columns \
--collect.info_schema.processlist \
--collect.binlog_size \
--collect.info_schema.tablestats \
--collect.global_variables \
--collect.info_schema.query_response_time \
--collect.info_schema.userstats \
--collect.info_schema.tables \
--collect.perf_schema.tablelocks \
--collect.perf_schema.file_events \
--collect.perf_schema.eventswaits \
--collect.perf_schema.indexiowaits \
--collect.perf_schema.tableiowaits \
--collect.slave_status \
--web.listen-address=0.0.0.0:9104

[Install]
WantedBy=multi-user.target
```
Lancez le service.

```bash
systemctl daemon-reload
systemctl enable --now mysqld_exporter.service
systemctl status mysqld_exporter.service
``` 

Le service devrait être opérationnel. Pour le vérifier, lancez votre navigateur et rejoignez l'IP:Port de votre serveur MariaDB, vous devriez trouver cette page :

[![Capture-d-cran-2023-11-22-122728.png](https://i.postimg.cc/1tLtn3Y9/Capture-d-cran-2023-11-22-122728.png)](https://postimg.cc/8JmDxNS3)  


## Connexion à Prometheus

Sur le serveur Prometheus, il faudra modifier le fichier **prometheus.yml** pour y ajouter un job.

```bash
nano /opt/prometheus/prometheus.yml
``` 
A la suite des autres jobs, y ajouter :
 
```yml
- job_name: "MariaDB"
  static_configs:
    - targets: ['ip_serveur_mariadb:9104'] 
```
Relancez le service Prometheus

```bash
systemctl restart prometheus.service
```
Pour vérifier que Prometheus soit relancé et que l'exporter soit **up**, dans votre navigateur, tapez l'adresse ip du serveur Prometheus, ainsi que le port 9090. Vous devriez avoir une page comme celle-ci :

[![Screenshot-2023-11-22-at-13-44-40-Prometheus-Time-Series-Collection-and-Processing-Server.png](https://i.postimg.cc/W1zzww94/Screenshot-2023-11-22-at-13-44-40-Prometheus-Time-Series-Collection-and-Processing-Server.png)](https://postimg.cc/rD6q8x26)

Sur cette image, nous voyons que Prometheus remonte bien l'exporter MariaDB.


## Dashboard Grafana

1) Importez le tableau de bord MySQL
Dans **Tableau de Bord**,  Cliquez sur le bouton **Nouveau**, puis sélectionnez **Importer**.

[![Screenshot-2023-11-22-at-13-49-02-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/VvTtjZjX/Screenshot-2023-11-22-at-13-49-02-Tableaux-de-bord-Grafana.png)](https://postimg.cc/tn37b5vg)

Copiez l'ID du tableau de bord à importer :
ID : 14031
Lien du [tableau de bord](https://grafana.com/grafana/dashboards/14031-mysql-dashboard/)
Et cliquez sur **Load**

[![Screenshot-2023-11-22-at-13-52-12-Import-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/vTW1V8Zw/Screenshot-2023-11-22-at-13-52-12-Import-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/8fzP8SvZ)

 Ici, nous remplirons le nom du tableau de bord, et nous y ajouterons comme source de données notre serveur Prometheus. 

[![Screenshot-2023-11-22-at-13-54-48-Import-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/MZr3PW5m/Screenshot-2023-11-22-at-13-54-48-Import-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/9zZBzHvD)

Cliquez sur **Import**

Et voilà, les remontées devraient se faire automatiquement !

[![Screenshot-2023-11-22-at-13-55-43-Maria-DB-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/1RgbZnfj/Screenshot-2023-11-22-at-13-55-43-Maria-DB-Tableaux-de-bord-Grafana.png)](https://postimg.cc/kDmTQ5NQ)

> Written with [StackEdit](https://stackedit.io/).
