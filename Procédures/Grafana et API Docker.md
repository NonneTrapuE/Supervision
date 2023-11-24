# Grafana et API de Docker

> Grafana est capable de créer des graphes grâce à quasiment n'importe quelle source. Qu'en est-il des APIs ? 
> C'est ce que l'on verra ici avec l'API de Docker, et un container contenant un service.

## Docker

### Installation 
Nous installerons la dernière version de Docker sur Debian 11. La procédure est [ici](https://docs.docker.com/engine/install/debian/).   
A l'heure où j'écris cette procédure, nous sommes sur la version 24.0.7 de Docker, et la version 1.43 de l'API.
Vous pouvez savoir sur quelle version vous êtes en tapant dans votre terminal :

```bash
docker version
``` 
  
### Lancer l'API 
A des fins de tests, nous ne l'implémenterons pas dans systemd. Si vous souhaitez le faire, la procédure est [ici](https://docs.docker.com/config/daemon/remote-access/).
Si vous avez installé Docker par le gestionnaire de paquets, le service est déjà lancé. Il faudra le stopper.

```bash
systemctl stop dockerd.service
``` 
Ensuite dans votre terminal, lancer le service ***dockerd*** manuellement.

```bash
dockerd -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375  
```
Ne stoppez pas le prompt, sinon le service se stoppera. Connectez vous avec un autre terminal.

Pour vérifier que le service est bien accessible, nous enverrons une requête ***curl*** à partir d'une autre machine (celle de Grafana par exemple).

```bash
curl http://192.168.198.131:2375
```
Si la réponse est : 
```json
{
  "message": "page not found"
}
```
L'API est bien disponible, la requête est juste vide, elle n'interroge donc rien dans l'API.

### Téléchargement de l'image

Pour faire nos essais, nous téléchargerons l'image [httpd](https://hub.docker.com/_/httpd) sur le DockerHub.

```bash
sudo docker pull httpd
```
Puis nous l'exécuterons.

```bash
docker --run -d -p 8080:80 httpd
``` 
Si vous utilisez déjà le port 8080, mettez-en un autre libre.

### Requête curl  

Avant de nous attaquer à la remontée des informations sur Grafana, il nous faut comprendre comment l'API de Docker fonctionne. Nous utiliserons donc ***curl*** ainsi que la [documentation officielle](https://docs.docker.com/engine/api/v1.43/) de l'API de Docker afin de forger nos propres requêtes pour remonter les informations que l'on souhaite. 

* Lister les containers
Tout d'abord, une requête simple : nous allons faire une requête sur l'API afin de vérifier que nous voyons notre container ***httpd***. Le port par défaut de Docker est le 2375.

```bash
curl http://<ip_du_serveur_docker>:<port>/v1.43/containers/json
```
Voici le résultat que vous devriez avoir :
[![Capture-d-cran-2023-11-24-161852.png](https://i.postimg.cc/nzr7dcHg/Capture-d-cran-2023-11-24-161852.png)](https://postimg.cc/Vrydvw0W)

On a une belle bouillie incompréhensible. Il faut donc le rendre un peu plus lisible. Nous installerons sur notre Debian l'utilitaire ***jq***.

```bash
apt install jq
``` 
On recommence, mais cette fois ci, nous allons mettre un pipe dans notre commande vers ***jq*** afin qu'il nous transforme tout ça.

```bash
curl http://<ip_du_serveur_docker>:<port>/v1.43/containers/json | jq
```

[![Capture-d-cran-2023-11-24-162348.png](https://i.postimg.cc/mg68Bqtv/Capture-d-cran-2023-11-24-162348.png)](https://postimg.cc/18wpKv0B)

Voilà, tout de suite ça à un peu plus de gueule !

Il nous remonte bien une pléthore d'informations, plus ou moins utiles. 

* Lister les processus à l'intérieur d'un container

Celui-ci peut être pratique dans une démarche de supervision des services, ou dans une phase de debug

```bash
curl http://<ip_docker>:<port>/v1.43/containers/eeeee7ecefb5/top
``` 
:warning: En cas de destruction du container, cette commande ne renverra plus rien puisque celle-ci se base sur l'ID du container. Si vous êtes dans un environnement de production, préférez utiliser le nom du container (et de garder le même nom)  

```bash
curl http://<ip_docker>:<port>/v1.43/containers/httpd/top
```

* Récupérer les métriques d'un container 

C'est celui-ci qui nous intéressera dans le cadre de la supervision. Il nous permet de toujours avoir un oeil sur la consommation des ressources par un ou plusieurs containers.

```bash
curl http://<ip_docker>:<port>/v1.43/containers/httpd/stats
``` 
:warning: Attention ! Comme vous avez pu le constater, cette commande ne s'arrête pas, elle effectue des requêtes constantes, ce qui peut être un problème. (Avec Grafana, il y'a un conflit).
Pour effectuer une seule requête, utilisez plutôt :

```bash
curl http://<ip_docker>:<port>/v1.43/containers/httpd/stats?stream=false
```

Pour rappel, la documentation officielle de l'API se situe [ici](https://docs.docker.com/engine/api/v1.43/) !


## Connexion de l'API à Grafana
 
Maintenant que nous avons un peu joué avec ***curl*** et l'API de Docker, il est temps de se pencher sur Grafana. Comment allons nous connecter l'API de Docker à Grafana et pouvoir créer un beau graphique ?

### Installation de Grafana

 Pour l'installation, ca se passe [ici](https://grafana.com/grafana/download/10.0.0?pg=oss-graf&plcmt=hero-btn-1) !

### Installation du plugin 

Nous installerons ici le plugin Infinity Datasource, disponible [ici](https://grafana.com/grafana/plugins/yesoreyeram-infinity-datasource/?tab=installation)
Sur le serveur Grafana :

```bash
grafana-cli plugins install yesoreyeram-infinity-datasource
systemctl retart grafana-server.service
```

### Import de la datasource

Dans la page d'accueil de Grafana, panneau latéral gauche, sélectionnez **Connections** pour dérouler le menu, puis sélectionnez **Data sources**.

[![Screenshot-2023-11-24-at-17-29-49-Data-sources-Connections-Grafana.png](https://i.postimg.cc/1RV1gf2d/Screenshot-2023-11-24-at-17-29-49-Data-sources-Connections-Grafana.png)](https://postimg.cc/c6Wb24s7)

Cliquez sur le bouton **Add new data source**.

[![Screenshot-2023-11-24-at-17-30-47-Data-sources-Connections-Grafana.png](https://i.postimg.cc/JnBYhB0c/Screenshot-2023-11-24-at-17-30-47-Data-sources-Connections-Grafana.png)](https://postimg.cc/2br7cy4V)


Dans la barre de recherche, tapez **Infinity**, puis cliquez sur l'encart.

[![Screenshot-2023-11-24-at-17-31-55-Add-data-source-Data-sources-Connections-Grafana.png](https://i.postimg.cc/wjymZ5GV/Screenshot-2023-11-24-at-17-31-55-Add-data-source-Data-sources-Connections-Grafana.png)](https://postimg.cc/QFDCW7s9)

Nous nommerons cette **data source** Docker, puis cliquez sur le bouton **Save & test**. 

[![Screenshot-2023-11-24-at-17-33-27-Docker-Data-sources-Connections-Grafana.png](https://i.postimg.cc/cJfXyGbX/Screenshot-2023-11-24-at-17-33-27-Docker-Data-sources-Connections-Grafana.png)](https://postimg.cc/yJYFctBZ)

Cliquez sur **Ajouter une visualisation**.

[![Screenshot-2023-11-24-at-17-34-27-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/Sss2LWCC/Screenshot-2023-11-24-at-17-34-27-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/McCpqfsp)

Sélectionnez votre **data source** Docker.

[![Screenshot-2023-11-24-at-17-34-52-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/GtDkYFnz/Screenshot-2023-11-24-at-17-34-52-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/sGVQCZXZ)

Et voilà, nous sommes prêts à faire de belles requêtes à notre API.

[![Screenshot-2023-11-24-at-17-35-52-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/sDRWqZrd/Screenshot-2023-11-24-at-17-35-52-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/HjBj7nnB)

Dans l'onglet **Query**, changez le **parser** en ***Backend***.
Puis changez l'URL (par défaut, elle mène à un fichier JSON sur Github) par notre url remontant les métriques du container Docker **httpd**:

http://<ip_docker>:<port>/v1.43/containers/httpd/stats?stream=false

N'hésitez pas à cliquer sur la carte **Switch to table**.

[![Screenshot-2023-11-24-at-17-42-55-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/8csrBh8x/Screenshot-2023-11-24-at-17-42-55-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/N2qMQ2jx)

Nos données sont bien remontées, mais cela reste illisible. Maintenant que Grafana est connecté à notre source, il va falloir y mettre les formes !

### Mise en forme des données

Les données nous intéressant ici sont la RAM. Nous sélectionnerons donc la colonne ***memory_stats***.
Revenons dans l'onglet **Query** , descendez l'onglet jusqu'à tomber sur l'option **Parsing options & Result fields**, puis cliquez dessus.

 [![Screenshot-2023-11-24-at-17-50-25-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/y8CyBbCd/Screenshot-2023-11-24-at-17-50-25-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/GHzyxz2w)

Dans le champs **Rows/Root**, tapez **memory_stats**. 
Le tableau devrait se mettre à jour avec de nouvelles données.

[![Screenshot-2023-11-24-at-17-52-52-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/50Dnz9T5/Screenshot-2023-11-24-at-17-52-52-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/S276F4yj)

Nos informations sont un peu plus épurées, mais il reste une colonne que nous ne souhaitons pas la colonne **stats**.
Nous allons donc choisir maintenant les valeurs que nous voulons.

Nous retournons dans l'option **Parsing options & Result fields**.
A côté du champs **Rows/Root** se trouve un cadre **Columns**.
Cliquez sur le bouton **Add Columns**.

Quelques explications

[![Screenshot-2023-11-24-at-18-10-04-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/PrqV7xn4/Screenshot-2023-11-24-at-18-10-04-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/vDpvgGBg)
 
La colonne **Selector** est le nom de la colonne dans ton tableau. Ici, ce sera ***limit***.
La colonne **Title** sera le nom que l'on veut lui donner pour l'affichage. Ici ce sera ***Mémoire Max***.
Et enfin, la colonne **Format as** donne le type de la valeur entrée. Ici ce sera un ***Number***.

[![Screenshot-2023-11-24-at-18-13-01-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/ZR2PDT8f/Screenshot-2023-11-24-at-18-13-01-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/G8Ps4nSY)


On ajoute une deuxième colonne, on fait la même chose, sauf qu'on remplace ***limit*** par ***usage***, le nom par **Utilisation**, et le format toujours en **Number**.

[![Screenshot-2023-11-24-at-18-15-13-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/SNqYQ2x6/Screenshot-2023-11-24-at-18-15-13-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/Jt6zPhJ0)

Maintenant, nous avons un beau tableau avec les valeurs que nous voulions !

Mais c'est toujours pas un beau graphique ...
Pour changer ça, nous allons tout en haut à droite, il y a une liste déroulante avec comme valeur **Table**. Changeons là pour **Gauge**.

[![Screenshot-2023-11-24-at-18-17-06-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/NFNtwz0P/Screenshot-2023-11-24-at-18-17-06-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/N2rS6bm1)

Ah bah voilà ! Enfin un beau graphique !

Mais ... Pourquoi il y a des chiffres qui riment à rien ??

Pas de panique, nous ne sommes juste pas sur la bonne unité de mesure.

Dans le panel de droite, descendez jusqu'à trouver **Unit**.
Ici, nous taperons ***bytes***. Selectionnez ***bytes(IEC)***.

[![Screenshot-2023-11-24-at-18-19-27-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/WbQKJvxw/Screenshot-2023-11-24-at-18-19-27-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/ppJkggWm)

Cliquez sur le bouton **Apply** et voilà, vous avez votre premier panneau sur votre dashboard ! 

[![Screenshot-2023-11-24-at-18-20-38-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/Bn9YnC1h/Screenshot-2023-11-24-at-18-20-38-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/QHmk61m5)





# Annexe


## Commandes avancées

* Permet de filtrer les containers par leur status : **running**, **exited**, etc...
```bash
curl -G -XGET http://<ip_docker>:<port>/v1.43/containers/json --data-urlencode 'filters={"status":["running"]}'
```


> Written with [StackEdit](https://stackedit.io/).
