# 22210576   SY Omar Saip
# 22210455   KWEKEU KWEKEU Aymard Loic
# 22210574   SOILAHOUDINE Ibrahim 


# Section 1: imports

from graphh import GraphHopper
import datetime
import csv
import requests
import json
from pprint import pprint

# Section 2: fonctions

#fonction qui retourne une liste du nom et du prenom des suspects
def suspect(nom_fichier):
    l = []
    with open(nom_fichier, 'r', encoding='utf8') as obj_fic:
        for suspect in csv.DictReader(obj_fic, delimiter=";"):
            l += [suspect["NOM"]+" "+suspect["PRENOM"]]
    return l

#fonction qui retourne la liste des identifiants twitter des suspects
def identifiant_twi(nom_fichier):
    l = []
    with open(nom_fichier, 'r', encoding='utf8') as obj_fic:
        for suspect in csv.DictReader(obj_fic, delimiter=";"):
            l += [suspect["IDENTIFIANT_TWITTER"]]
    return l

#fonction qui retourne la liste des identifiants snapchat des suspects
def identifiant_sc(nom_fichier):
    l = []
    with open(nom_fichier, 'r', encoding='utf8') as obj_fic:
        for suspect in csv.DictReader(obj_fic, delimiter=";"):
            l += [suspect["IDENTIFIANT_SNAPCHAT"]]
    return l

def api_reseau_sociaux(url1,url2):
    http_headers = {'User-Agent': "Mozilla/5.0"}
    contenu_brut = requests.get(url1, headers=http_headers)
    contenu_json = contenu_brut.json()
    contenu_brut2 = requests.get(url2, headers=http_headers)
    contenu_json2 = contenu_brut2.json()
    return contenu_json,contenu_json2

#La fonction temps_parcours_ur2(dico,suspects) est une fonction qui retourne le nom du suspect et le temps qu'il mettra pour arriver au lieu du crime(UR2)
def temps_parcours_ur2(dico,suspects):
    id_liste_suspect = {suspects[0]: id_jean_mi, suspects[1]: id_geo, suspects[2]: id_rob}
    if "coordinates" in dico.keys():
        for cle, val in id_liste_suspect.items():
            for id in val:
                if dico["author"] == id:
                    voiture = gh_client.duration([tuple(dico["coordinates"]), ur2], vehicle="car", unit="min")
                    velo = gh_client.duration([tuple(dico["coordinates"]), ur2], vehicle="bike", unit="min")
                    pied = gh_client.duration([tuple(dico["coordinates"]), ur2], vehicle="foot", unit="min")
                    return cle,min(voiture,velo,pied)
    elif "loc" in dico.keys():
        for cle, val in id_liste_suspect.items():
            for id in val:
                if dico["author"] == id:
                    lng, lat = dico["loc"]["lng"], dico["loc"]["lat"]
                    voiture= gh_client.duration([(lat, lng), ur2], vehicle="car", unit="min")
                    velo = gh_client.duration([(lat, lng), ur2], vehicle="bike", unit="min")
                    pied = gh_client.duration([(lat, lng), ur2], vehicle="foot", unit="min")
                    return cle,min(voiture,velo,pied)

#fonction qui convertit le temps en minute
def convertion_min(temps):
    if temps.days==-1:
        temps=24*60*60-temps.seconds
    else:
        temps=temps.seconds
    return(temps/60)

#fonction qui retourne un tuple du suspect et de la difference de temps entre l'heure du message et l'heure du crime
def difference_temps(dico,suspects):
    id_liste_suspect = {suspects[0]: id_jean_mi,suspects[1]: id_geo, suspects[2]: id_rob}
    for cle, val in id_liste_suspect.items():
        for id in val:
            if dico["author"] == id:
                temps_message = datetime.datetime.fromisoformat(dico["iso_date"])
                return cle, convertion_min(heure_crime-temps_message)
    
#fonction qui associe à chaque suspect s'il est possiblement coupable ou pas
def possible_criminel(nom_fichier,url1,url2):
    suspects=suspect(nom_fichier)
    d=dict.fromkeys((suspects[0],suspects[1],suspects[2]))
    for sus in suspects:
        alibi=0
        for dicos in api_reseau_sociaux(url1,url2):
            for dico in dicos:
                parcours=temps_parcours_ur2(dico,suspects) #tuple (nom_du_respect,temps qu il faut au suspect pour arriver à rennes 2)
                diff=difference_temps(dico,suspects) #tuple (nom_du_suspect,difference entre temps de crime et heure du message)
                if sus==diff[0]: #diff[0] est le nom du suspect
                    if "coordinates" in dico.keys() or "loc" in dico.keys():
                        if parcours[1]>diff[1]:
                            alibi+=1
        if alibi!=0:
            d[sus]="n a pas pu commetre le crime"
        else:
            d[sus]="a possiblement commis le crime"

    return d



# Section 3: tests
nom_fichier="path//suspects.csv"
#pprint(suspect(nom_fichier))

id_twi=identifiant_twi(nom_fichier)
id_sc=identifiant_sc(nom_fichier)
id_jean_mi = [id_twi[0], id_sc[0]]
id_geo = [id_twi[1], id_sc[1]]
id_rob = [id_twi[2], id_sc[2]]

heure_crime = datetime.datetime(2022, 10, 8, 16, 23, 00)

url_twi = "https://my-json-server.typicode.com/rtavenar/fake_api/twitter_posts"
url_sc = "https://my-json-server.typicode.com/rtavenar/fake_api/snapchat_posts"

creds = open("//credentials.json","r", encoding="utf-8")
credentials = json.load(creds)
gh_client = GraphHopper(api_key=credentials["graphhopper"]['API_KEY'])

ur2 = gh_client.address_to_latlong(address="Pl. Recteur Henri le Moal, 35000 Rennes")

#for dicos in api_reseau_sociaux(url_twi,url_sc):
#    for dico in dicos:
#        pprint(temps_parcours_ur2(dico,suspect(nom_fichier)))
#        pprint(difference_temps(dico,suspect(nom_fichier)))    
#pprint(temps_parcours_ur2(api_reseau_sociaux(url_twi,url_sc)[1][0],suspect(nom_fichier)))
#pprint(difference_temps(api_reseau_sociaux(url_twi,url_sc)[0][7],suspect(nom_fichier)))
#pprint(possible_criminel(nom_fichier,url_twi,url_sc))
for cle, val in possible_criminel(nom_fichier,url_twi,url_sc).items():
    print(cle+" "+val)