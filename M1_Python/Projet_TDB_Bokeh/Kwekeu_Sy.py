import pandas as pd
from bokeh.plotting import figure, output_file, show
from bokeh.models import CustomJS,ColumnDataSource,HoverTool,ColorPicker,Spinner,Div,Paragraph,Dropdown,Tabs,Panel
#la fonction Panel devra etre remplacee par TabPanel dans les versions plus recentes de bokeh
from bokeh.layouts import row, column
import bokeh.palettes as bp
from bokeh.transform import factor_cmap,transform
from bokeh.io import output_notebook
from bokeh.tile_providers import get_provider, Vendors
from bokeh.models.transforms import CustomJSTransform
import matplotlib.pyplot as plt
import json
import numpy as np
import math
import re

#Converts decimal longitude/latitude to Web Mercator format
def coor_wgs84_to_web_mercator(lon, lat):
    k = 6378137
    x = lon * (k * np.pi/180.0)
    y = np.log(np.tan((90 + lat) * np.pi/360.0)) * k
    return (x,y)

#Fonction qui convertit une liste d'angle en un tuple d'angle de departs et d'angles d'arrivée
#Nous aurons besoin de cette fonction pour les diagrammes circulaires.
def convertisseur_de_liste_d_angles(liste_angles_radians): 
    # valeur de departs des angles
    start_angle = [math.radians(0)]
    prev = start_angle[0]
    for i in liste_angles_radians[:-1]:
        start_angle.append(i + prev)
        prev = i + prev
    
    # valeurs d'arrivee des angles
    end_angle = start_angle[1:] + [math.radians(0)]
    
    return start_angle,end_angle

###################### Partie: Traitement et creation des jeux de données dont on aura besoin #####################

# importation du jeu de donnees 
## Attention!! Pour l'importation des donnees, il faut ouvrir le fichier du projet sur VSCode.
## Sinon l'importation pourrait echouer.
df=pd.read_csv("recensement-de-la-population-en-bretagne-structure-de-la-population.csv",
               sep=";")

# Selection des donnees les plus recentes pour chaque EPCI
df_epci=df.loc[df["level"]=="EPCI"].reset_index(drop=True) # selection des EPCI
epci=set(df_epci["nom"])
df1=df_epci.loc[[0]]
for nom in epci:
    if nom != df_epci.loc[0,"nom"]:# Car le nom qui apparait en premier est deja utilise
        donnee_epci=df_epci.loc[df_epci["nom"]==nom]
        #Selection des donnees a la date la + recente
        donnee_epci_max=donnee_epci.loc[donnee_epci["millesime"]==max(donnee_epci["millesime"])]
        donnee_epci_max=donnee_epci_max.reset_index(drop=True)
        if len(donnee_epci_max["nom"]) > 1:#car il y a des doublons(la date recente apparait plusieurs fois)
            donnee_epci_max=donnee_epci_max.loc[[0]]
        df1=pd.concat([df1,donnee_epci_max]).reset_index(drop=True)

# Transformation des longitudes et latitudes en coordonnees mercator pour tracer la surface de l'EPCI
coordx=[]
coordy=[]
for elt in df1["Geo Shape"]:
    dico=json.loads(elt) #Transformation de str en dictionnaire
    listeX=[]
    listeY=[]
    for liste_coordonnees in dico["coordinates"]:
        for coordonnees in liste_coordonnees:
            for coor in coordonnees:#les coordonnees sont des polygones
                longitude=coor[1] 
                latitude=coor[0]
                X,Y=coor_wgs84_to_web_mercator(float(longitude), float(latitude))
                listeX+=[X]
                listeY+=[Y]
    coordx+=[listeX]
    coordy+=[listeY]
    listeX=[]
    listeY=[]
    
# Aggrégation des données par année
df2=df[["p_pop","p_poph","p_popf","p_pop0014","p_pop1529","p_pop3044","p_pop4559","p_pop6074","p_pop75p","millesime"]]
df2=df2.groupby(["millesime"], group_keys=False).sum()
df2=df2.drop(index=1999)

# Sélection des données de 2019
df3=df2.loc[[2019]]
        

# Création d'un DataFrame des données dont on aura besoin pour la carte
data=pd.DataFrame({"surface_x":coordx,
                   "surface_y":coordy,
                   "nom":df1["nom"],
                   "population":df1["p_pop"],
                   "pop_homme":df1["p_poph"],
                   "pop_femme":df1["p_popf"],
                   "pop_jeunes":df1["p_pop0014"]+df1["p_pop1529"],
                   "pop_adultes":df1["p_pop3044"]+df1["p_pop4559"],
                   "pop_vieux":df1["p_pop6074"]+df1["p_pop75p"],
                   "annee":df1["millesime"],
                   "alphas":df1["p_pop"]/max(df1["p_pop"])})# valeur qui change la transparence de l'EPCI en fct de sa population

donnees=ColumnDataSource(data)

# Création d'un DataFrame des données dont on aura besoin pour les autres graphes
annees = list(df2.index)
data_pop=pd.DataFrame({"population":df2["p_pop"],
                       "pop_totale":df2["p_pop"],
                   "pop_homme":df2["p_poph"],
                   "pop_femme":df2["p_popf"],
                   "pop_jeunes":df2["p_pop0014"]+df2["p_pop1529"],
                   "pop_adultes":df2["p_pop3044"]+df2["p_pop4559"],
                   "pop_vieux":df2["p_pop6074"]+df2["p_pop75p"],
                   "annee":annees})
donnees_pop=ColumnDataSource(data_pop)

# Création d'un DataFrame des données de 2019
data_2019=pd.DataFrame({"population":df3["p_pop"],
                   "pop_homme":df3["p_poph"],
                   "pop_femme":df3["p_popf"],
                   "pop_jeunes":df3["p_pop0014"]+df3["p_pop1529"],
                   "pop_adultes":df3["p_pop3044"]+df3["p_pop4559"],
                   "pop_vieux":df3["p_pop6074"]+df3["p_pop75p"],
                   "annee":2019})

# Création d'un DataFrame pour le diagramme circulaire de la répartition des hommes et des femmes en 2019
sexes = ["Homme", "Femme"]
values1=[data_2019["pop_homme"],data_2019["pop_femme"]]
proportions1=[valeurs / data_2019["population"] for valeurs in values1]
### Transformation des proportions d'hommes et de femmes en angle
radians1 = [math.radians(valeurs * 360) for valeurs in proportions1]
### Transformation des angles en parametes nécessaires au tracé du diagramme circulaire
angle_depart1,angle_arrivee1=convertisseur_de_liste_d_angles(radians1)
colors=["red","yellow"]

data_sexes_2019=pd.DataFrame({"x":[0 for sexe in sexes],
                              "y":[0 for sexe in sexes],
                              "rayon":[0.8 for sexe in sexes],
                              "depart":angle_depart1,
                              "arrivee":angle_arrivee1,
                              "colors":colors,
                              "sexes":sexes,
                              "proportions":proportions1})
donnees_sexes_2019=ColumnDataSource(data_sexes_2019)

# Création d'un DataFrame pour le diagramme circulaire de la répartition des générations en 2019
generations = ["Jeunes(- de 30 ans)","Adultes(- de 60 ans)","Vieux(60 et +)"]
values2=[data_2019["pop_jeunes"],data_2019["pop_adultes"],data_2019["pop_vieux"]]
proportions2=[valeurs / data_2019["population"] for valeurs in values2]
### Transformation des proportions de jeunes, d'adultes et de vieux en angle
radians2 = [math.radians(valeurs * 360) for valeurs in proportions2]
### Transformation des angles en parametes nécessaires au tracé du diagramme circulaire
angle_depart2,angle_arrivee2=convertisseur_de_liste_d_angles(radians2)

colors2=["yellow","blue","purple"]

data_gen_2019=pd.DataFrame({"x":[0 for gen in generations],
                              "y":[0 for gen in generations],
                              "rayon":[0.8 for gen in generations],
                              "depart":angle_depart2,
                              "arrivee":angle_arrivee2,
                              "colors":colors2,
                              "generation":generations,
                              "proportions":proportions2})
donnees_gen_2019=ColumnDataSource(data_gen_2019)



######################### Partie: Création des graphes ############################

tile_provider = get_provider(Vendors.OSM)

# graphe1: carte des EPCI de bretagne(les EPCI les moins peuplees sont plus transparents)

##On crée la carte avec fond de carte
p1=figure(title="Carte des EPCI de bretagne",x_axis_type="mercator", y_axis_type="mercator", active_scroll="wheel_zoom")
p1.add_tile(tile_provider)
p1.patches(xs="surface_x",ys="surface_y",source =donnees,color = factor_cmap('nom', palette=bp.inferno(61), factors=list(epci)),fill_alpha = "alphas")
## Outil de survol
hover_tool1 = HoverTool(tooltips=[('EPCI',  '@nom')])
p1.add_tools(hover_tool1)

# graphe2: nuage de points de l'évolution de la population de bretagne au cours des années
## On cree le nuage de points de l'evolution de la population de bretagne
p2=figure(title="Nuage de points: Evolution de la population de bretagne au cours des années",x_range=(2006,2020),
          x_axis_label="Année",y_axis_label="Nombre d'habitants")
p2.title.align="center"
ligne1=p2.cross(x="annee",y="population",source=donnees_pop,line_color="red",line_width=8)

picker1 = ColorPicker(title="Couleur de remplissage", color=ligne1.glyph.line_color)
picker1.js_link('color', ligne1.glyph, 'line_color')

spinner1 = Spinner(title="Epaisseur de la courbe", low=0,high=60, step=5, value=ligne1.glyph.line_width) 
spinner1.js_link("value", ligne1.glyph, "line_width")

## On crée un widget pour la sélection de la variable a tracer
menu = Dropdown(label ="Choix de la variable à tracer",menu=[('population totale','pop_totale'),
                                                             ('Nombre d hommes','pop_homme'),
                                                             ('Nombre de femmes','pop_femme'),
        ('Nombre de jeunes','pop_jeunes'),('Nombre d adultes','pop_adultes'),('Nombre de vieux','pop_vieux')])
callback = CustomJS(args=dict(source = donnees_pop), code="""
    const data = source.data;
    const val = cb_obj.item
    const y = data['population']
    const ynew = data[val]
    for (let i = 0; i < y.length; i++) {
            y[i] = ynew[i]
    }
    source.change.emit();
""")

menu.js_on_event('menu_item_click', callback)
## Outil de survol
hover_tool2 = HoverTool(tooltips=[( 'Année','@annee'),( "Nbre d'hbts",  '@population' )])
p2.add_tools(hover_tool2)

p2.title.text_color='red'
p2.title.background_fill_color="black"
p2.xaxis.axis_label_text_font_size="15pt"
p2.yaxis.axis_label_text_font_size="15pt"

nuage_widgets=row(p2,column(menu,picker1,spinner1))

# graphe3: diagramme de chaque variable
p3=figure(title="Diagramme de l'évolution de la population de bretagne au cours des années",
          x_axis_label="Année",y_axis_label="Nombre d'habitants")
p3.title.align="center"
barres=p3.vbar(x="annee",top="population",source=donnees_pop,fill_color="grey",line_color="black",
        width=0.5,line_width=1,fill_alpha=1)

#### Création et mise a jour des widgets 
picker2 = ColorPicker(title="Couleur de la ligne séparatrice",color=barres.glyph.line_color)
picker2.js_link('color', barres.glyph, 'line_color')

picker3 = ColorPicker(title="Couleur du diagramme", color=barres.glyph.fill_color)
picker3.js_link('color', barres.glyph, 'fill_color')

spinner2 = Spinner(title="Epaisseur des diagrammes", low=0,high=2, step=0.2, value=barres.glyph.width) 
spinner2.js_link("value", barres.glyph, "width") 

spinner3 = Spinner(title="Transparence", low=0,high=1, step=0.1, value=barres.glyph.fill_alpha) 
spinner3.js_link("value", barres.glyph, "fill_alpha")

menu = Dropdown(label ="Choix de la variable à tracer",menu=[('population totale','pop_totale'),
                                                             ('Nombre d hommes','pop_homme'),
                                                             ('Nombre de femmes','pop_femme'),
        ('Nombre de jeunes','pop_jeunes'),('Nombre d adultes','pop_adultes'),('Nombre de vieux','pop_vieux')])
callback = CustomJS(args=dict(source = donnees_pop), code="""
    const data = source.data;
    const val = cb_obj.item
    const y = data['population']
    const ynew = data[val]
    for (let i = 0; i < y.length; i++) {
            y[i] = ynew[i]
    }
    source.change.emit();
""") 
menu.js_on_event('menu_item_click', callback)

p3.title.text_color='black'
p3.title.background_fill_color="grey"
p3.xaxis.axis_label_text_font_size="15pt"
p3.yaxis.axis_label_text_font_size="15pt"

diagramme_widgets=row(p3,column(menu,picker2,spinner3,picker3,spinner2))

# graphe4: courbe d'évolution de la population de bretagne au cours des années
## On cree le graphe de l'évolution de la population de bretagne
p4=figure(title="Courbe d'évolution de la population de bretagne au cours des années",x_range=(2006,2020),
          x_axis_label="Année",y_axis_label="Nombre d'habitants")

p4.line(x="annee",y="population",source=donnees_pop,color="red",legend_label="nbre hbts total")
p4.line(x="annee",y="pop_homme",source=donnees_pop,color="blue",legend_label="nbre d'homme")
p4.line(x="annee",y="pop_femme",source=donnees_pop,color="pink",legend_label="nbre de femme")
p4.line(x="annee",y="pop_jeunes",source=donnees_pop,color="black",legend_label="nbre de jeunes")
p4.line(x="annee",y="pop_adultes",source=donnees_pop,color="green",legend_label="nbre d'adultes")
p4.line(x="annee",y="pop_vieux",source=donnees_pop,color="purple",legend_label="nbre de vieux")

## On parametre la legende
p4.legend.location="top_right"
p4.legend.click_policy="hide"

## On parametre le titre et les axes
p4.title.align="center"
p4.title.text_color='red'
p4.title.background_fill_color="black"
p4.xaxis.axis_label_text_font_size="15pt"
p4.yaxis.axis_label_text_font_size="15pt"

# graphe5: diagramme empile
p5=figure(title="Diagramme de la répartition de la population de bretagne au cours des années",
          x_axis_label="Année",y_axis_label="Nombre d'habitants")

p5.vbar(x="annee",top="population",source=donnees_pop,color="grey",line_color="black",
        width=0.5,legend_label="nbre hbts total")
p5.vbar(x="annee",top="pop_femme",source=donnees_pop,color="pink",line_color="black",
        width=0.5,legend_label="nbre de femme")
p5.vbar(x="annee",top="pop_homme",source=donnees_pop,color="red",line_color="black",
        width=0.5,legend_label="nbre d'homme")
p5.vbar(x="annee",top="pop_adultes",source=donnees_pop,color="yellow",line_color="black",
        width=0.5,legend_label="nbre d'adultes")
p5.vbar(x="annee",top="pop_jeunes",source=donnees_pop,color="blue",line_color="black",
        width=0.5,legend_label="nbre de jeunes")
p5.vbar(x="annee",top="pop_vieux",source=donnees_pop,color="purple",line_color="black",
        width=0.5,legend_label="nbre de vieux")

## On parametre la legende
p5.legend.location="top_right"
p5.legend.click_policy="hide"

## On parametre le titre et les axes
p5.title.align="center"
p5.title.text_color='black'
p5.title.background_fill_color="grey"
p5.xaxis.axis_label_text_font_size="15pt"
p5.yaxis.axis_label_text_font_size="15pt"

# graphe6: répartition des hommes et des femmes en bretagne en 2019
p6 = figure(title = "Répartition des hommes et des femmes en bretagne en 2019")

## wedge permet de tracer des diagrammes circulaires
p6.wedge(x="x",y="y",radius="rayon",
        start_angle = "depart",
        end_angle = "arrivee",
        color = "colors",
        legend_field="sexes",
        source=donnees_sexes_2019)

outilsurvol = HoverTool(tooltips=[( 'Sexe','@sexes'),('Proportions',  '@proportions')])
p6.add_tools(outilsurvol)

## On enleve les grilles sur le plan du diagramme circulaire    
p6.axis.visible = False
p6.ygrid.visible = False
p6.xgrid.visible = False

## Parametrage du titre
p6.title.align = 'center' 
p6.title.text_color='red'
p6.title.background_fill_color="black"
p6.title.text_font_size='15pt'


# graphe7: répartition des generations en bretagne en 2019
p7 = figure(title = "Répartition des generations en bretagne en 2019") 

p7.wedge(x="x",y="y",radius="rayon",
        start_angle = "depart",
        end_angle = "arrivee",
        fill_color = "colors",
        legend_field="generation",
        source=donnees_gen_2019)
outilsurvol2 = HoverTool(tooltips=[( 'Génération','@generation'),('Proportions',  '@proportions')])
p7.add_tools(outilsurvol2)

## On enleve les grilles sur le plan du diagramme circulaire
p7.axis.visible = False
p7.ygrid.visible = False
p7.xgrid.visible = False

## Parametrage du titre
p7.title.align = 'center'
p7.title.text_color='white'
p7.title.background_fill_color="black"
p7.title.text_font_size='15pt'
    

####################### Partie: Création du texte de description ###############################

## Création de l'entete avec les noms d'auteur et les numero d'etudiant
div1=Div(text="""<h1>Auteurs: </h1>
         <p> Omar Saip SY , Aymard Loic KWEKEU-KWEKEU </p>""",  style={'font-style': 'italic'})
div2=Div(text="""<h1>Num_etudiants: </h1>
         <p> 22210576 , 22210455 </p>""",  style={'font-style': 'italic'})
auteurs=column(div1,div2)

## Création de l'entete avec le titre de la page et le lien de telechargement du jeu de donnees
div3 = Div(text="""
<h1> Description du site </h1>
<p> Cette page est consacré à la description des pages et de notre travail</p>""",  
style={'font-style': 'italic'})
div4=Div(text="""<a href=
"https://data.bretagne.bzh/explore/dataset/recensement-de-la-population-en-bretagne-structure-de-la-population/information/?location=12,48.64528,-2.2871&basemap=jawg.streets  ">
lien pour telecharger notre jeu de donnees</a>""",  style={'font-style': 'italic', 'color': '#00AAAA'} )
desc=column(div3,div4)

par1 = Paragraph(text="Nous avons importé du site de la bretagne les données portant sur le " +
                 "recensement de la population(structure de la population). Grace à cela, "+
                 "nous avons voulu décrire la population de bretagne. Pour se faire, nous"+
                 "séparerons le site en 4 onglets nommés: 'Carte','Widgets','Superposition' et 'Diagramme Circulaire'.")

par2=Paragraph(text="L'onglet 'Carte' affiche la carte des EPCI(regroupement de communes). "+
               "De plus, cette carte est moins transparente en fonction de la proportion de "+
               "la population du EPCI concerné, par rapport à la population du EPCI (plus peuplé). "+
               "C'est-à-dire que l'EPCI le plus peuplé sera plus foncé sur cette carte, et "+
               "le moins peuplé sera plus transparent.")
par3=Paragraph(text="L'onglet 'Widgets' affiche le nuage de points et le diagramme en barre "+
               "du nombre d'habitants en bretagne en 2019. Elle est nommé 'Widgets' car "+
               "l'utilisateur pourra choisir le nuage de points ou le diagramme à tracer "+
               "en fonction des variables. De plus il pourra changer les couleurs "+
               "les tailles (et/ou les épaisseurs) des graphes. Parmi les variables à choisir on dispose: "+
               "du nombre d'hommes, du nombre de femmes, du nombre de jeunes(ayant -de 30ans), "+
               "du nombre d'adultes(ayant - de 60 ans), du nombre de vieux(ayant 60 ans et +). "+
               "De plus, le nuage de points dispose d'un outil de survol. Ce qui permettra "+
               "à l'utilisateur de visualiser, sur un point de la courbe, l'année et le "+
               "nombre exact d'habitants de la variable concernée")
par4=Paragraph(text="L'onglet 'Superposition' affiche le nuage de points et le diagramme en barre "+
               "du nombre d'habitants en bretagne en 2019,du nombre d'hommes, du nombre de femmes, "+
               "du nombre de jeunes(ayant -de 30ans), du nombre d'adultes(ayant - de 60 ans), "+
               "du nombre de vieux(ayant 60 ans et +). Toutes ces variables sont tracées sur le meme graphe. "+
               "En plus, l'utilisateur pourra enlever le tracé d'une variable en cliquant sur son intitulé "+
               "au niveau de la legende. Ce procédé est possible pour le nuage de points et le diagramme en barres. "+
               "Concernant cet onglet, il se peut que le tracé du nombre d'habitants en bretagne en 2019 "+
               "ne s'affiche pas. Il faudra rééxécuter le code pour que cette courbe s'affiche. "+
               "(La cause de ce bug nous est inconnu)")
par5=Paragraph(text="L'onglet 'Diagramme circulaire' affiche les diagrammes circulaires: "+
               "de la répartition des hommes et des femmes en bretagne en 2019 ; "+
               "de la répartition des générations(c'est-a-dire la proportions de jeunes(ayant - de 30 ans), "+
               "d'adultes(ayant entre 30 et 59 ans) et de vieux(ayant de 60 ans et +). "+
               "De plus, l'utilisateur peut survoler chaque diagramme afin de connaitre les "+
               "proportions exactes des différentes variables.")
par6=Paragraph(text="Pour conclure, nous avons créé cette application afin de visualiser "+
               "la répartition de la population de bretagne de 2007 à 2019. Puis, nous nous sommes "+
               "focalisés sur l'année 2019 pour mieux observer la structure de la population de bretagne. ")
texte=column(auteurs,desc,par1,par2,par3,par4,par5,par6)

################################## Partie: Creation des onglets #######################################

# association du graphe 2 et du graphe 3 (les graphes avec widgets)
graph_widgets=column(nuage_widgets,diagramme_widgets)

# association du graphe 4 et du graphe 5 (les graphes superposés)
graph_superposes=row(p4,p5)
p4.x_range = p5.x_range

# association du graphe 6 et du graphe 7 (les diagrammes circulaires)
graph_circu=column(p6,p7)

#Préparation des onglets
#Attention!!! La fonction Panel devra etre remplacee par TabPanel dans les versions plus recentes de bokeh

tab1 = Panel(child=texte,title="Description")
tab2 = Panel(child=p1, title="Carte")
tab3 = Panel(child=graph_widgets, title="Widgets")
tab4 = Panel(child=graph_superposes, title="Superposition")
tab5 = Panel(child=graph_circu, title="Diagramme Circulaire")
tabs = Tabs(tabs = [tab1,tab2, tab3, tab4,tab5])

#Sortie
output_file("population_bretagne.html")
output_notebook()
show(tabs)
  



