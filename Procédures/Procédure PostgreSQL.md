# Extraction de données de PostgreSQL vers Grafana Dashboard


## Setup de Grafana Dashboard sur Debian 11

Vérifier que certains paquets soient installés.

```
apt install sudo gnupg
```

Pour installer Grafana Dashboard, il suffit de télécharger le script selon la méthode suivante.

```
cd /tmp
wget https://raw.githubusercontent.com/NonneTrapuE/Supervision/main/Install_grafana_server_deb.sh
chmod +x Install_grafana_server_deb.sh
./Install_grafana_server_deb.sh
```

Grafana devrait être disponible à partir de l'adresse **localhost:3000** ou **<ip_machine>:3000** si vous vous connectez à distance.

## PostgreSQL

### Installation

La documentation de l'installation est disponible à l'adresse [suivante](https://www.postgresql.org/download/) pour plus de détails. Nous installerons ici PostgreSQL 15.

```
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-15
```

### Configuration

Pour configurer PostgreSQL afin de l'utiliser à distance, deux fichiers sont à modifier : pg_hba.conf et postgresql.conf. Tous deux se trouvent dans le répertoire **/etc/postgresql/15/main/**.

#### Fichier pg_hba.conf

Commenter la ligne commençant par **host** dans le paragraphe **IPv4 local connections:**.
Puis ajouter cette ligne à la suite :
```
host	all	all		0.0.0.0/0	scram-sha-256
```
/!\ Ne pas utiliser en production, c'est une pratique à effectuer en cas de test/lab/debug. Cela autorise toutes les ip à pouvoir se connecter sur toutes les bases de données avec tous les identifiants disponibles. /!\    

#### Fichier postgresql.conf

Trouvez la ligne **listen_addresses** et remplacez **localhost** par __*__.

/!\ Ne pas utiliser en production. Cela veut dire que PostgreSQL écoute toutes les IPs pouvant lui envoyer des requêtes. Ici, il ne faudrait mettre que les IPs ayant besoin d'y accéder, en l’occurrence, le serveur PostgreSQL. /!\ 

Il faudra également trouver la ligne **password_encryption**, la décommenter et passer sa valeur à **scram-sha-256** comme ceci
```
password_encryption = scram-sha-256
```
Redémarrer PostgreSQL après ces modifications

```
sudo systemctl restart postgresql
```
 
### Alimenter la base de données

#### Générer des données

Pour exploiter une base de données, il faut l'alimenter afin d'y avoir des données. Pour cela, nous utiliserons un site : generatedata.com.

[![Image](https://i.goopics.net/pkp3ul.png)](https://goopics.net/i/pkp3ul)

Cliquez sur **Generate** en bas de la page.

[![Image](https://i.goopics.net/swutnn.png)](https://goopics.net/i/swutnn)

Ici, aucune donnée n'est pour le moment créée. 
Pour en ajouter, ajoutez le nombre de colonnes voulues. Nous en créerons 5 :
  
  - Nom
  - Prénom
  - Mail
  - Date de naissance
  - Mot de passe

[![Image](https://i.goopics.net/o5anmz.png)](https://goopics.net/i/o5anmz)

Après avoir rempli le tableau des types de valeurs que nous souhaitons, nous nous retrouvons avec notre code à entrer dans PostgreSQL afin de l'alimenter

[![Image](https://i.goopics.net/q94tiz.png)](https://goopics.net/i/q94tiz)


#### Intégrer les données dans PostgreSQL

Nous allons créer un nouvel utilisateur : **grafana_user**.
```
createuser --interactive
```
Indiquez le nom, puis non et non aux questions.

Connectez vous sur votre base de données PostgreSQL
```
sudo -iu postgres
psql
```

Vous serez connecté avec l'utilisateur par défaut **postgres** sur la base par défaut **postgres**.

Pour créer une nouvelle base de données :
```
create database grafana_db;
```

Maintenant nous allons ajouter la nouvelle table, ainsi que les données correspondantes générées par generatedata.com. Ici, nous retrouverons mes données générées, mais vous pouvez utiliser les vôtres. 
 ```
 CREATE TABLE "accounts" (
  id SERIAL PRIMARY KEY,
  Firstname varchar(255) default NULL,
  Lastname varchar(255) default NULL,
  email varchar(255) default NULL,
  date varchar(255),
  password varchar(255)
);

INSERT INTO accounts (Firstname,Lastname,email,date,password)
VALUES
  ('Jaime','Vinson','lorem@protonmail.com','12/09/1987','WMh87pHQ3WP5nu1CF5hv'),
  ('Ishmael','Baker','adipiscing@aol.com','05/11/1996','SXt78vRW7DY0cc1YS8ni'),
  ('Lester','Lamb','ligula@yahoo.ca','22/07/1979','GZu82pXN1CQ4go3BZ6mm'),
  ('Erin','Reeves','tellus@protonmail.net','03/06/1998','YOf53oBG7NF7my2WO4ih'),
  ('Maxwell','Vasquez','at.fringilla@hotmail.net','05/03/1995','WCi74gUM0SC7wh4JS1no'),
  ('Desirae','Everett','ac@icloud.org','11/05/2012','TPa42oKL3HD2bi9HU0mg'),
  ('Channing','Lamb','enim.mauris@icloud.couk','30/06/2006','NFm08rOW6VP5dc3TT6ir'),
  ('Ezekiel','Bright','et.malesuada@icloud.org','10/12/1969','DXi75aNY1WQ8qn8WD5pz'),
  ('Adam','Francis','et.ipsum@protonmail.com','07/02/1977','YIi85xPH6RT7cc2PP3co'),
  ('Scott','Lawrence','lorem.eget.mollis@hotmail.ca','24/04/2008','UCi66wDD3EI6ez6CU7xj'),
  ('Cairo','Patterson','sit.amet.risus@aol.org','27/07/1989','CLk22vIH1DE6ez0NT2ry'),
  ('Yardley','French','mauris.blandit@hotmail.ca','31/05/1977','RLr45rJC8WQ9nj7VQ1iw'),
  ('Ariel','Hale','nibh@aol.ca','23/03/2008','ZLv35fLO6KT1nr1SB7fv'),
  ('William','Fox','commodo.auctor@icloud.org','01/05/2001','FJf27mRO2SK8ql6YH8mx'),
  ('Simone','Cote','sollicitudin@hotmail.ca','21/09/1986','DXo26zNV5ZV3ik6RF2up'),
  ('Lucius','Gregory','neque@aol.edu','03/12/1968','JWj88xOU3SG7kr2BL4jj'),
  ('Reed','Gaines','lorem@google.com','06/09/2015','PNi16pYX1RL6bf2NB3vu'),
  ('Mollie','Becker','nibh.vulputate@outlook.net','20/11/2002','KHh31pVD7IY7dl5GD4um'),
  ('Lucy','Hernandez','erat.vitae@outlook.com','22/11/1969','JUd72yLC4YR1qj3LT3cv');
``` 
 Une fois la table créée et les données importées, il suffit de mettre les droits de lecture à l'utilisateur **grafana_user** sur la base de données **grafana_db** ainsi que sur la table **accounts**.
Pour se faire :
```
grant connect on grafana_db TO grafana_user;
grant select on table accounts to grafana_user
```

## Connecter la base de données PostgreSQL à Grafana Dashboard

Rendez-vous dans la page home de Grafana et allez dans la section **Add new connection**

[![Image](https://i.goopics.net/g65anj.png)](https://goopics.net/i/g65anj)

Recherchez le plugin PostgreSQL
[![Image](https://i.goopics.net/9y7jin.png)](https://goopics.net/i/9y7jin)

Et Appuyez sur le bouton **Add new data source**

 Entrez maintenant toutes les informations requises : adresse ip et port du serveur PostgreSQL, nom de l'utilisateur et nom de la base de données.
 N'oubliez pas d'indiquer la version de PostgreSQL à la fin de la page.
 Vous pouvez ensuite cliquer sur le bouton **Save & test**
[![Image](https://i.goopics.net/zbnu99.png)](https://goopics.net/i/zbnu99)

Si tout est opérationnel, il devrait y avoir un liseré vert affiché en bas de la page comme ceci :

[![Image](https://i.goopics.net/fw16du.png)](https://goopics.net/i/fw16du) 

Il ne vous reste plus qu'a cliquer sur le lien **Building a dashboard**.



## Métriques de PostgreSQL avec Postgres_Exporter

Pour exporter les métriques de votre serveur PostgreSQL, vous devez déployer l'agent PostgreSQL_Exporter afin de remonter les métriques sur votre instance Prometheus. 

Procédure pour l'installation et la configuration de l'Exporter :

1) [Téléchargements de Postgres_Exporter](https://github.com/prometheus-community/postgres_exporter/releases/tag/v0.15.0)

2) Sur votre serveur PostgreSQL, téléchargez et décompressez l'archive
```
cd /tmp
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.15.0/postgres_exporter-0.15.0.linux-amd64.tar.gz
tar xzvf postgres_exporter-0.15.0.linux-amd64.tar.gz
mv postgres_exporter-0.15.0.linux-amd64.tar.gz /opt/postgres_exporter
```

3) Configuration de Postgres_Exporter 
 
```
cd /opt/postgres_exporter
nano postgres_exporter.env
```
Insérez dans le fichier texte  postgres_exporter.env

```
#Pour une base de données précise
DATA_SOURCE_NAME="postgresql://username:password@localhost:5432/database-name?sslmode=disable"
#Ou
DATA_SOURCE_NAME="postgresql://postgres:postgres@localhost:5432/?sslmode=disable"
#Pour toutes les bases de données
```
Vous pouvez également lancer le service à la main comme ceci :
```
cd /opt/postgres_exporter
DATA_SOURCE_NAME="postgresql://username:password@localhost:5432/database-name?sslmode=disable" ./postgres_exporter --web.listen-address=:9187 --web.telemetry-path=/metrics
``` 
4) Configuration du service

```
useradd postgres_exporter --system --shell /bin/false
nano /etc/systemd/system/postgres_exporter.service
```
Dans le fichier postgres_exporter.service, insérez :

```
 [Unit]  
Description=Prometheus exporter for Postgresql  
Wants=network-online.target  
After=network-online.target

[Service]  
User=postgres_exporter  
Group=postgres_exporter  
WorkingDirectory=/opt/postgres_exporter  
EnvironmentFile=/opt/postgres_exporter/postgres_exporter.env  
ExecStart=/opt/postres_exporter/postgres_exporter --web.listen-address=:9187 --web.telemetry-path=/metrics
Restart=always

[Install]  
WantedBy=multi-user.target
 ```

Sauvegardez puis quitter **nano**.
Activez le service 

```
systemctl daemon-reload
systemctl enable postgres_exporter
```
4) Droits sur la base de données

Il vous faut les droits de lecture sur la base de données, mais également le droit d'effectuer certaines requêtes, notamment la fonction **pg_ls_waldir**. Pour l'activer:

```
sudo -iu postgres
psql
grant execute on function pg_ls_waldir to grafana_user
\q
```

5) Démarrer le service

```
systemctl start postres_exporter
systemctl status postgres_exporter
```

6) Configuration de Prometheus 

Dans notre serveur Prometheus, nous allons modifier le fichier /opt/prometheus/prometheus.yml pour ajouter une nouvelle cible.

```
- job_name: 'postgres_exporter'
    static_config:
    - targets: ['ip_serveur_postgres:9187'] 
``` 
On enregistre et on relance le service Prometheus

```
systemctl restart prometheus.service
systemctl status prometheus.service
```

7) Dashboard Grafana

Dans Grafana, vous pouvez importer le dashboard spécifique à Postgres_Exporter.
ID : 12485
Et connectez le à Prometheus, sélectionner le **job** visé. 



> Written with [StackEdit](https://stackedit.io/).
