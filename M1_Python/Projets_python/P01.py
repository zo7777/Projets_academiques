#22210576   SY Omar Saip
#22210455   KWEKEU KWEKEU Aymard Loic

#Section 1: imports
import P01_utils as pu
import numpy as np
from scipy.spatial.distance import cdist

#Section 2: fonctions
x_train,y_train=pu.lire_donnees(100)
x_test,y_test=pu.lire_donnees(10)

##1ere partie
def dist(x_i,x_j):
    somme=0
    if len(x_i)!=len(x_j):
        print("vecteurs de longueur differentes")
    else:
        for i in range(len(x_i)):
            for j in range(len(x_j)):
                if i==j:
                    somme+=(x_i[i]-x_j[j])**2
    return somme**(1/2)
        
def k_plus_proche_voisin_index(k,X_train,individu):
    l=[dist(individu,X_train[i]) for i in range(len(X_train))]
    liste_k=np.argsort(l) 
    return liste_k[:k]


def classe_plus_represente(classe):
    d={}
    max_val=0
    cle_plus_represente=None
    for chaine in classe:
        d[chaine]=classe.count(chaine)
    for cle,valeur in d.items():
        if valeur>max_val:
            max_val=valeur
            cle_plus_represente=cle
            
    return cle_plus_represente


def k_plus_proche_voisin_liste(X_train,Y_train,X_test,k=1):
    l=[]
    classe=[]
    for ind in X_test:
        for indices in k_plus_proche_voisin_index(k,X_train,ind):
            classe+=[Y_train[indices]]
        l+=[classe_plus_represente(classe)]
        classe=[]
    
    return l


##2e partie
def dist_scipy(X_i,X_j):
    m=cdist([X_i,X_j],[X_j,X_i])
    return m[0,0]

def k_plus_proche_voisin_index_numpy(k,X_train,individu):
    l=[dist_scipy(individu,X_train[i]) for i in range(len(X_train))]
    liste_k=np.argsort(l)
    return liste_k[:k]

def classe_plus_represente_numpy(classe):
    nbre_F=np.sum(np.ones(len(np.where(np.array(classe)=="F")[0])))
    nbre_H=np.sum(np.ones(len(np.where(np.array(classe)=="H")[0])))
    if nbre_F>=nbre_H:
        return "F"
    return "H"

def k_plus_proche_voisin_numpy(X_train,Y_train,X_test,k=1):
    l=[]
    classe=[]
    for ind in X_test:
        for indices in k_plus_proche_voisin_index_numpy(k,X_train,ind):
            classe+=[Y_train[indices]]
        l+=[classe_plus_represente_numpy(classe)]
        classe=[]
        
    return l
        

#Section 3: tests

#pu.visualiser_donnees(x_train, y_train,X_test=x_test)

#print(dist([4,1],[1,5]))
#print(classe_plus_represente(["F","H","H","H","H","F"]))
#print([y_train[i+41] for i in range(20)])
#print(classe_plus_represente([y_train[i+41] for i in range(20)]))
#print(k_plus_proche_voisin_index(9,x_train,x_test[2]))
print(k_plus_proche_voisin_liste(x_train,y_train,x_test,k=5))

#print (dist_scipy([5,1],[1,4]))
#print(classe_plus_represente_numpy(["H","H","H","F","H","F"]))
#print([y_train[i+41] for i in range(20)])
#print(classe_plus_represente_numpy([y_train[i+41] for i in range(20)]))
#print(k_plus_proche_voisin_index_numpy(9,x_train,x_test[2]))
print(k_plus_proche_voisin_numpy(x_train,y_train,x_test,k=5))





