#22210576   SY Omar Saip
#22210455   KWEKEU KWEKEU Aymard Loic

afcm_tableau <- function(XX){
  K <- ncol(XX)
  n <- nrow(XX)
  D <- (1/n)*diag(n) # calcul de la metrique D
  
  ###calcul de la matrice disjonctif U
  rep <- c() 
  ###### on met chaque element de la matrice X (une seule fois) dans un vecteur rep
  for(colonne in 1:K){
    for (ligne in 1:n){
      if(!(XX[ligne,colonne] %in% rep)){
        rep <- c(rep,XX[ligne,colonne])
      }
    }
  }
  ###### calcul de la matrice disjonctif U
  U <- 0
  for(val in XX){
    if (is.character(val)){
      U <- matrix(rep(0,length(rep)*n),nrow=n,ncol=length(rep))# initialise la matrice disjonctif U a la matrice nulle ayant n ligne et le nombre de reponses differentes colonnes
      colnames(U) <- rep
      indicateurs <- c()
    
      for(elt in rep){
        for(colonne in 1:K){
          for(ligne in 1:n){
            if (elt == XX[ligne,colonne]){
              indicateurs <- c(indicateurs,ligne,elt) # cherche la ligne ou se trouve l'element X[i,j] de la matrice X
            }
          }
        }
      }
      
      for(j in 1:length(rep)){
        for(long in 1:length(indicateurs)){
          if(long %% 2==0){
            if(indicateurs[long]==rep[j]){
              U[as.integer(indicateurs[long-1]),j] <- 1# affecte 1 a la ligne de X[i,j] sur la matrice disjonctif
            }
          }
        }
      }
    }
  }
  ### calcul de D_sigma
  vec <- c()
  for (k in 1:ncol(U)){
    vec <- c(vec,sum(U[,k]))
  }
  
  D_sigma <- diag(vec)
  ### calcul de Q
  D_sigma_inv <- diag(diag(1/D_sigma))
  Q <- (1/(n*K)) * D_sigma
  ### calcul de x
  X <- n*U %*% D_sigma_inv - 1
  ### calcul de V
  V <- t(X) %*% D %*% X
  ### calcul des valeurs propres et des vecteurs propres Q-normes de VQ
  val_props <- eigen(V %*% Q)$values
  indices_val_props_decroissant <- order(val_props,decreasing = T)
  val_props <- val_props[indices_val_props_decroissant] #valeurs propres ordonnees par ordre decroissant
  Q_1_2 <- diag(diag(sqrt(D_sigma)))
  Q_1_2_inv <- diag(diag(1/Q_1_2))
  bk_s <- eigen(Q_1_2 %*% V %*% Q_1_2)$vectors
  A <- Q_1_2_inv %*% bk_s #vecteurs propres Q-normes de VQ
  
  ### calcul de la matrice C a partir des formules de transitions
  C <- matrix(rep(0,n*n),ncol=n,nrow = n)
  for(colonne in 1:ncol(A)){
    if( !( is.nan( (1/sqrt(val_props[colonne])) ) ) ){
      C[,colonne] <- (1/Mod(sqrt(val_props[colonne]))) * X %*% Q %*% A[,colonne]
    }else{C <- C[,-colonne]}
  }
  
  ### calcul de la matrice du pourcentage d'inertie
  taux_inertie <- diag( Re(val_props/sum(val_props)) *100 )
  
  ### calcul des coordonnees des lignes
  C_tilde <- matrix(rep(0,n*ncol(C)),ncol=ncol(C),nrow=n)
  for (j in 1:ncol(C)) {
    if( !( is.nan( Mod(sqrt(val_props[j])) ) ) ){
      C_tilde[,j] <- Mod(sqrt(val_props[j])) * C[,j]
    }else{C_tilde <- C_tilde[,-j]}
  }
  
  ### calcul des coordonnees des colonnes
  A_tilde <- matrix(rep(0,nrow(A)*ncol(A)),ncol=ncol(A),nrow=nrow(A))
  for (j in 1:length(val_props)) {
    A_tilde[,j] <- Mod(sqrt(val_props[j])) * A[,j]
  }
  colnames(A_tilde) <- colnames(U)[indices_val_props_decroissant]
  
  return(list(taux_inertie,A,C,A_tilde,C_tilde))
  
}

graphe_lignes <- function(liste){
  ###selection des axes dont la somme des pourcentages des inerties donne 70%
  axes=0
  ine <- c()
  for(i in 1:ncol(liste[[1]])){
    ine <- c(ine,Re(liste[[1]][i,i]))
    if (sum(Re(liste[[1]][i,i])) < 70){
      axes=axes+1
    }
  }
  barplot(liste[[1]])#histogramme des pourcentages d inertie
  ### Nous choisissons les axes 1 et 2 car elles ont les taux les plus eleves
  
  plot.new()
  par(mar=c(5, 4, 4, 8) + 0.1)
  
  
  grid(nx = NULL, ny = NULL,lty = 1,col = "gray")      
  par(new=T)
  plot(liste[[5]][,1],-liste[[5]][,2], main="AFCM des individus",xlab="axe1"
       , ylab="axe2", pch=18,col="blue",ylim=range(-0.4,0.4),xlim=range(-0.4,0.4))
  text(liste[[5]][c(1,3,5,8),1], -liste[[5]][c(1,3,5,8),2], rownames(XX)[c(1,3,5,8)], cex=0.9,pos=3, col="red")
  text(liste[[5]][c(2,4,6),1], -liste[[5]][c(2,4,6),2], rownames(XX)[c(2,4,6)], cex=0.9,pos=1, col="red")
  text(liste[[5]][7,1], -liste[[5]][7,2], rownames(XX)[7], cex=0.9,pos=2, col="red")
  text(liste[[5]][9,1], -liste[[5]][9,2], rownames(XX)[9], cex=0.9,pos=4, col="red")
  
  abline(h=0,lty=2)
  abline(v=0,lty=2)
  
  
}

graphe_var <- function(liste){
  ###selection des axes dont la somme des pourcentages des inerties donne 70%
  axes=0
  ine <- c()
  for(i in 1:ncol(liste[[1]])){
    ine <- c(ine,Mod(liste[[1]][i,i]))
    if (sum(Mod(liste[[1]][i,i])) < 70){
      axes=axes+1
    }
  }
  
  plot.new()
  par(mar=c(5, 4, 4, 8) + 0.1)
  
  
  grid(nx = NULL, ny = NULL,lty = 1,col = "gray")      
  par(new=T)
  plot(abs(liste[[4]][,1]),abs(liste[[4]][,2]), main="AFCM des variables",xlab="axe1"
       , ylab="axe2", pch=18,col="blue")
  text(abs(liste[[4]][,1]), abs(liste[[4]][,2]), colnames(liste[[4]]), cex=0.9, pos=3, col="red")
  
  
  abline(h=0,lty=2)
  abline(v=0,lty=2)
  
  
  
}


XX=read.table("exacm.csv",header=T,sep=";",row.names = 1)
afc <- afcm_tableau(XX)
graphe_lignes(afc)
graphe_var(afc)