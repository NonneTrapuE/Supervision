# Dashboard personnalisé Grafana


Pour ce tuto, nous utiliserons le plug-in Grafana Pour Redis.

Pour l'installer, connectez-vous sur le serveur hébergeant Grafana.
Il existe un exécutable ***grafana-cli*** permettant l'installation des plug-ins.

```bash
grafana-cli plugins list-remote	| grep redis
```

 [![Capture-d-cran-2023-11-23-213451.png](https://i.postimg.cc/hjV1TMDj/Capture-d-cran-2023-11-23-213451.png)](https://postimg.cc/Q9x7rQWG)
  
Nous installerons ici le plug-in ***redis-datasource***.  Il faudra relancer le serveur Grafana après l'installation.

```bash
grafana-cli plugins install redis-datasource
systemctl restart grafana-server.service
```
Retour sur la page d'accueil de Grafana, allez dans ***Data sources***

[![Screenshot-2023-11-23-at-21-39-20-Grafana.png](https://i.postimg.cc/rz26gfWP/Screenshot-2023-11-23-at-21-39-20-Grafana.png)](https://postimg.cc/fSCgRj8c)
 
Cliquez sur le bouton ***Add new data source***

[![Screenshot-2023-11-23-at-21-40-51-Data-sources-Connections-Grafana.png](https://i.postimg.cc/SxN4Pt3B/Screenshot-2023-11-23-at-21-40-51-Data-sources-Connections-Grafana.png)](https://postimg.cc/zVM4bpJ7)

Cherchez ***Redis*** et sélectionnez le.

Entrez les informations correspondantes (nous ne verrons pas ici en détails la connexion de Redis à Grafana) et cliquez sur ***Save & test***, puis sur ***Building a dashboard***.

[![Screenshot-2023-11-23-at-21-43-56-Redis-Data-sources-Connections-Grafana.png](https://i.postimg.cc/Qd5QR07q/Screenshot-2023-11-23-at-21-43-56-Redis-Data-sources-Connections-Grafana.png)](https://postimg.cc/cvxt37XK)

Cliquez sur le bouton ***Ajoutez une visualisation***, puis la prochaine fenêtre sélectionner votre data source.

Nous voici avec une belle page vide !

[![Screenshot-2023-11-23-at-21-46-37-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/FR1xzczW/Screenshot-2023-11-23-at-21-46-37-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/wy8Nb1hL)
 
Nous voudrons seulement remonter l'utilisation de la RAM dans notre cas.

Dans l'onglet ***Query***, vérifiez que notre data source soit bien sur Redis.
 En dessous, dans l'encart ***Type***, nous mettrons notre valeur sur **Redis**. 
Dans l'encart ***Command***, nous sélectionnerons la valeur ***INFO***. 
Puis dans l'encart du dessous, ***Section***, nous sélectionnerons la valeur ***Memory***. 
Et quand vous cliquez sur le bouton ***Run*** en dessous ... ça ne marche pas ! 

[![Screenshot-2023-11-23-at-21-51-13-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/rw0c1ZbM/Screenshot-2023-11-23-at-21-51-13-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/K12dFfxH)

C'est normal, Redis nous informe d'énormément de données, elles ne sont pas forcément toutes affichables de la même façon.

Nous allons changer de visualisation. En haut, à droite, Vous devriez être en ***Time Series***. Passez cette valeur à ***Table***.

[![Screenshot-2023-11-23-at-21-53-40-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/VNg7dmR6/Screenshot-2023-11-23-at-21-53-40-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/yJJhGq24) 


Les données remontent ! Mais ... C'est moche ! Ils sont où les beaux graphiques ?

Pour faire de beaux graphiques, nous avons besoin de trier les données que Redis nous envoie. Et ici, il nous en envois beaucoup !

 A côté de l'onglet ***Query***, en bas de page, il y'a un deuxième onglet, ***Transform Data***.

[![Screenshot-2023-11-23-at-21-56-45-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/tgs5CWYr/Screenshot-2023-11-23-at-21-56-45-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/qtdn1tcn)

Cherchez le vignette ***Filter by name*** et cliquez dessus.

[![Screenshot-2023-11-23-at-21-57-57-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/SQfW4DgS/Screenshot-2023-11-23-at-21-57-57-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/bddGHHXW)


Il ne reste plus qu'à décocher toutes les informations qui ne nous intéressent pas !
Ici nous garderons que les informations ***total_system_memory*** et ***used_memory***. 

[![Screenshot-2023-11-23-at-22-00-04-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/kGR3QB1w/Screenshot-2023-11-23-at-22-00-04-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/BP3VsQG1)


Maintenant, j'ai un tableau à deux colonnes. C'est pas très sexy !
En haut, à droite, nous rechangerons la visualisation et nous la passerons sur la valeur ***Gauge***

[![Screenshot-2023-11-23-at-22-01-25-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/pdd29XHc/Screenshot-2023-11-23-at-22-01-25-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/nX68gxMq)

Ah ! Tout de suite, ça à de la gueule !  Mais pourquoi il y'a des gros chiffres auxquels je comprends rien ? 

C'est parce que nous ne sommes pas sur la bonne unité de mesure ! Il suffit de sélectionner la bonne !

Sur la droite de l'écran, nous avons un panneau latéral avec un onglet ***All***.
Faites défiler jusqu'à voir l'encart ***Unit***.
Ici, nous indiquerons l'unité de mesure que l'on souhaite, ici ce sera le **bytes**. Nous taperons donc la valeur dans le champs prévu à cet effet.  

Mais il y en a deux !!

Pas de panique. Ici, nous souhaitons mesurer la RAM. Nous sélectionnerons donc 
 IEC. (pour la [ref](https://fr.wikipedia.org/wiki/Byte)).

Et nous voilà avec un panneau qui déchire tout !

[![Screenshot-2023-11-23-at-22-09-12-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png](https://i.postimg.cc/TPkHwTd9/Screenshot-2023-11-23-at-22-09-12-Edit-panel-New-dashboard-Tableaux-de-bord-Grafana.png)](https://postimg.cc/3yvZf5D4)

N'oubliez pas de cliquez sur le bouton en haut à droite ***Apply***, ça serait bête d'avoir à tout recommencer !



> Written with [StackEdit](https://stackedit.io/).
