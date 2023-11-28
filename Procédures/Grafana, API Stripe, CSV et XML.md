
# Grafana, API Stripe, CSV et XML


> En tentant de vérifier la disponibilité de l'API de Stripe, nous nous sommes rendu compte que l'API en elle-même ne renvoyait pas de code de retour HTTP. Le status n'était renvoyé que dans son en-tête. Voici notre contournement.

> Nous verrons également comment s'abonner au flux RSS de Stripe afin d'être maintenu au courant en cas d'incident sur la plateforme.

## Scripting API Stripe

Etant donné que l'API Stripe ne renvoit pas directement le code de status, nous allons extraire le header d'une requête sur l'API.
Celle-ci nous renverra un code. 
Voici la commande bash pour y arriver : 

```bash
ACCOUNT=<Numéro de compte>
TOKEN=<Token généré sur Stripe>
curl  -I -X 'GET' -H 'Accept: application/json;q=0.9,text/plain' 'https://api.stripe.com/v1/accounts/'$ACCOUNT'key?='$TOKEN | head -n 1 | cut -d ' ' -f 2
```

Les variables **ACCOUNT** et **TOCKEN** sont à remplir par vos informations. Elles sont disponibles dans votre dashboard Stripe.
Cette commande renverra le code HTTP de la requête, et permettra de déterminer si l'API est fonctionnelle ou non, si le compte et le token sont valides.
Les différents codes HTTP se trouvent [ici](https://fr.wikipedia.org/wiki/Liste_des_codes_HTTP) et vous donnerons les indications nécessaires.  

Nous allons mettre en place un script permettant, à heure régulière, de faire une requête à l'API, de traiter son code de retour, et de l'inscrire dans un fichier. Ici, ce sera un fichier CSV, mais il est également possible avec un fichier JSON, une base de données SQL, NoSQL, etc... Il n'y a pas de mauvaise façon de faire.

[Lien du script](https://github.com/NonneTrapuE/Supervision/blob/main/Scripts/stripe.sh)

Télécharger le script, remplissez les variables avec vos identifiants de compte et votre token. Le script est à exécuter en ***root***, ou vous pouvez modifier la destination du fichier CSV afin de correspondre avec les droits de votre utilisateur. 

Ensuite, il ne vous reste plus qu'à effectuer une tâche régulière.

```bash
crontab -e
```

## Gestion des CSV dans Grafana

### Installation et configuration du plugin

Maintenant que nous avons généré un fichier CSV avec des données, il est temps de le remonter dans Grafana afin que nous ayons une visualisation.

Nous installerons le plugin CSV de Grafana. Pour se faire :

```bash
grafana-cli plugins install marcusolsson-csv-datasource
```

Il faudra églement modifier le fichier de configuration de Grafana afin de l'autoriser à utiliser les fichiers locaux.

```bash
nano /etc/grafana/grafana.ini
```

Et ajouter les lignes suivantes au fichier.

```ini
[plugin.marcusolsson-csv-datasource]
allow_local_mode = true
```

Redémarrer grafana

```bash
systemctl restart grafana-server.service
```

### Import des données dans Grafana


Allez dans **Data Sources**

[![Screenshot-2023-11-28-at-11-16-17-Grafana.png](https://i.postimg.cc/5t4rPy9w/Screenshot-2023-11-28-at-11-16-17-Grafana.png)](https://postimg.cc/nXWTrHDz)

Cliquez sur le bouton **Add new data source**

 [![Screenshot-2023-11-28-at-11-17-10-Data-sources-Connections-Grafana.png](https://i.postimg.cc/wvsQFYNX/Screenshot-2023-11-28-at-11-17-10-Data-sources-Connections-Grafana.png)](https://postimg.cc/BL4FQyMb)

Puis cliquez sur la source **CSV**. 

[![Screenshot-2023-11-28-at-11-18-31-Add-data-source-Data-sources-Connections-Grafana.png](https://i.postimg.cc/RFRVkNw4/Screenshot-2023-11-28-at-11-18-31-Add-data-source-Data-sources-Connections-Grafana.png)](https://postimg.cc/mzPsMZd5)

Dans la partie **Storage Location**, changez de HTTP à Local, puis renseignez le chemin du fichier CSV. Enfin, cliquez sur le bouton **Save & test**.

 [![Screenshot-2023-11-28-at-11-21-27-CSV-2-Data-sources-Connections-Grafana.png](https://i.postimg.cc/zGzBkwhp/Screenshot-2023-11-28-at-11-21-27-CSV-2-Data-sources-Connections-Grafana.png)](https://postimg.cc/TpsfdDCW)

En bas de la page, dans l'encart vert, cliquez sur **Building a dashboard**

Sélectionner la source de données. Dans notre cs, cela sera CSV.

[![Screenshot-2023-11-28-at-13-38-57-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/xdXQQmd3/Screenshot-2023-11-28-at-13-38-57-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/yJCtXkcD)

Nous voici avec la table des données. Toutes ne nous intéresse pas. Nous souhaitons uniquement récupérer le message.

Pour se faire, nous allons dans l'onglet **Transform Data**, puis nous cliquons sur la carte **Filter by name**.

[![Screenshot-2023-11-28-at-13-44-07-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/Pf3gM4Qf/Screenshot-2023-11-28-at-13-44-07-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/BtF7S2zR)

Dans l'option **Filter** nous décochons toutes les valeurs, sauf ***message***.

[![Screenshot-2023-11-28-at-13-45-12-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/JhFTk6WS/Screenshot-2023-11-28-at-13-45-12-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/bGQHXRrR)

Notre tableau n'indique plus que les valeurs ***message***. Nous, ce que nous souhaitons, c'est la dernière valeur retournée.
Dans le panel de droite, changez la visualisation sur **Stat** sur le menu déroulant.
En descendant, dans la partie **Value Options**, il y'a un menu déroulant **Calculation**. Mettez la valeur à ***Last \****.
Vous devriez avoir le dernier message créé par le script.
  
[![Screenshot-2023-11-28-at-13-51-09-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/W3dFK8Cm/Screenshot-2023-11-28-at-13-51-09-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/LYM8gtHh)

Voilà, vous avez importé et mis en forme une valeur à partir d'un fichier CSV. N'oubliez pas de cliquer sur le bouton **Apply** en haut à droite afin de sauvegarder votre panneau !


## Flux RSS : gérer le XML

Maintenant que nous savons si l'API de Stripe est fonctionnelle ou pas, il ne nous reste plus qu'à connecter leur flux RSS  afin de connaitre le pourquoi d'une panne, sa gravité, son explication, sa résolution, etc...
Les flux RSS sont transmis en XML. Il faudra donc le récupéré, le parser et enfin filtrer les données que nous souhaitons. C'est parti !

Pour les flux RSS, nous utiliserons le plugin Infinity Datasource.

### Installation du plugin Infinity Datasource

Sur votre serveur Grafana :

```bash
grafana-cli plugins install yesoreyeram-infinity-datasource
systemctl restart grafana-server.service
```

Rien de sorcier !

### Import et traitement des données

Allez dans **Data sources**

![Screenshot-2023-11-28-at-11-16-17-Grafana.png](https://i.postimg.cc/5t4rPy9w/Screenshot-2023-11-28-at-11-16-17-Grafana.png)](https://postimg.cc/nXWTrHDz)

Puis cliquez sur le bouton **Add new data source**.

![Screenshot-2023-11-28-at-11-17-10-Data-sources-Connections-Grafana.png](https://i.postimg.cc/wvsQFYNX/Screenshot-2023-11-28-at-11-17-10-Data-sources-Connections-Grafana.png)](https://postimg.cc/BL4FQyMb)

Tapez **Infinity**

[![Screenshot-2023-11-28-at-14-11-18-Add-data-source-Data-sources-Connections-Grafana.png](https://i.postimg.cc/jqhxYmYs/Screenshot-2023-11-28-at-14-11-18-Add-data-source-Data-sources-Connections-Grafana.png)](https://postimg.cc/XXpSw2vh)

Laissez tout par défaut, puis cliquez sur le bouton **Save & test**

[![Screenshot-2023-11-28-at-14-12-16-Flux-RSS-Data-sources-Connections-Grafana.png](https://i.postimg.cc/4dLWzXhf/Screenshot-2023-11-28-at-14-12-16-Flux-RSS-Data-sources-Connections-Grafana.png)](https://postimg.cc/BLF539gk).

Cliquez sur le bouton **Build  dashboard**.
Puis sélectionnez la source de données. Ici, j'ai appelé la data source **Flux RSS**.

[![Screenshot-2023-11-28-at-14-14-05-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/7hbwVPsm/Screenshot-2023-11-28-at-14-14-05-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/Cny3M0Vq)
 
Nous arrivons ici, avec des données fictionnelles.

  [![Screenshot-2023-11-28-at-14-15-24-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/3JFQvvxY/Screenshot-2023-11-28-at-14-15-24-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/Vdvhy5tV)

Nous allons ajouter notre source de données (l'URL du flux RSS), ainsi que son type.
Nous sélectionnerons le **Type** ***XML***, et l'**URL** ***https://www.stripestatus.com/history.rss***. Il faudra également passer le **Parser** à la valeur ***Backend***.

[![Screenshot-2023-11-28-at-14-20-11-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/cCMYWmMv/Screenshot-2023-11-28-at-14-20-11-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/Lg5hBjWS)

Bon, d'accord, on comprend rien. Mais le flux nous remonte déjà des données. Il ne nous reste plus qu'à les gérer.
Dans l'encart **Parsing options & Result fields**, indiquez la valeur ***rss.channel[0].item***

[![Screenshot-2023-11-28-at-14-22-37-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/5NWdkmRw/Screenshot-2023-11-28-at-14-22-37-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/bdgBZ18J)


Nous voilà avec des données enfin intelligibles ! Mais maintenant, on n'en veut que certaines:
les colonnes **link**, **pubDate** et **title** .
Toujours dans la partie **Parsing options & Result fields**, il y a un encart **Columns**.
Ici nous allons sélectionner les valeurs qui nous intéressent, ainsi que le nom des colonnes.

Cliquez sur le bouton **Add Columns**.

 [![Screenshot-2023-11-28-at-14-26-17-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/MKn5VkD5/Screenshot-2023-11-28-at-14-26-17-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/qzd2H5W6)
 
L'encart **Selector** servira à mettre le titre de la colonne, **Title** à le remplacer par le titre qu'on souhaite lui donner, et enfin la dernière à formater si besoin les valeurs remontées. Ici nous n'en auront pas besoin, nous laisserons donc sur **String** à chaque fois.

[![Screenshot-2023-11-28-at-14-35-08-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/tTM5MytB/Screenshot-2023-11-28-at-14-35-08-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/DJ1LS9NG)   

Et voilà, vous avez les rapports d'incidents Stripe en direct depuis leur flux RSS, ce qui peut vous permettre de comprendre le pourquoi si le script remonte une erreur et prendre les mesures adéquates !   

> Written with [StackEdit](https://stackedit.io/).
