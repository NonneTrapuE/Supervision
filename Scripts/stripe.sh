#!/bin/bash

# Variables

FILE=/opt/http_response.csv
TOKEN=
ACCOUNT=
API_CALL=$(curl  -I -X 'GET' -H 'Accept: application/json;q=0.9,text/plain' 'https://api.stripe.com/v1/accounts/'$ACCOUNT'key?='$TOKEN | head -n 1 | cut -d ' ' -f 2)
DATE=$(date +"%Y/%m/%d")
HOUR=$(date +"%H/%M")

# Fonctions

# Tri des erreurs 4XX les plus courantes
function http_400_errors()
        {
                if [[ $API_CALL == 401 ]]; then
                        echo $DATE,$HOUR,$API_CALL,"Requête non authorisée" >> $FILE
                elif [[ $API_CALL == 403 ]]; then
                        echo $DATE,$HOUR,$API_CALL,"Accès non authorisé" >> $FILE
                elif [[ $API_CALL == 404 ]]; then
                        echo $DATE,$HOUR,$API_CALL,"Non trouvé" >> $FILE
                else
                        echo $DATE,$HOUR,$API_CALL,"Autre problème" >> $FILE
                fi
        }


#################
#       Main    #
#################

# Test si le fichier existe et le crée si il n'existe pas
if [[ ! -f $FILE ]]; then
        touch $FILE
        echo "date,heure,code,message" >> $FILE
fi


# Test du code erreur de l'API Stripe
if [[ $API_CALL == 2*  ]]; then
        echo $DATE,$HOUR,$API_CALL,"OK" >> $FILE
elif [[ $API_CALL == 4* ]]; then
        http_400_errors
elif [[ $API_CALL == 5* ]]; then
        echo $DATE,$HOUR,$API_CALL,"Erreur Serveur" >> $FILE
else
        echo $DATE,$HOUR,$API_CALL,"Autre Problème" >> $FILE
fi