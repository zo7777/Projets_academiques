#22210576   SY Omar Saip
#22210455   KWEKEU KWEKEU Aymard Loic
#22210574   SOILAHOUDINE Ibrahim 

#Section 1: imports
from abc import ABC,abstractmethod

#Section 2: fonctions
class Expression(object):
    def __init__(self,u): #exp):
        self.u=u
        
    def __add__(self,other):
        somme=Somme(self,other)
        return somme
    
    def __str__(self):
        return f'{self.u}'
   
    @abstractmethod
    def forward(self,x):
        raise NotImplementedError
    
    @abstractmethod
    def grad(self,x):
        raise NotImplementedError
    
    def descente_grad(self,x0,taux,iterations_max):
        ite=0
        eps=10**(-7)
        x=x0
        while(ite<iterations_max and abs(self.grad(x0))>eps):
            x=x0-(taux*self.grad(x0))
            x0=x
            ite+=1
        return x
    

class Constante(Expression):
    def __init__(self, c):
        super().__init__(c)
        self.u=c
        
    def __str__(self):
        return f'{self.u}'
    
    def __neg__(self):
        return Constante(-self.u)
    
    def forward(self, x):
        return self.u
    
    def grad(self, x):
        return 0
    
class Variable(Expression):
    def __init__(self,x="x"):
        super().__init__(x)
        
    def __str__(self):
        return f'x'
    
    def __add__(self, o):
        if isinstance(self.u,str):
            return Somme(self,Constante(o))
        return self.u + o
    
    def __mul__(self, o):
        if isinstance(self.u,str) and (isinstance(o,int) or isinstance(o,float)):
            return Produit(self,Constante(o))
        elif isinstance(self.u,str) and isinstance(o,Expression):
            return Produit(self,o)
        return self.u * o
    
    def __rmul__(self,o):
        if isinstance(self.u,str) and (isinstance(o,int) or isinstance(o,float)):
            return Produit(Constante(o),self)
        elif isinstance(self.u,str) and isinstance(o,Expression):
            return Produit(o,self)
        return o*self.u 
    
    def __sub__(self, o):
        if isinstance(self.u,str):
            return Somme(self,Constante(-o))
        return self.u - o
    
    def __pow__(self,o):
        if isinstance(self.u,str):
            return Produit(self,self,compteur=o)
        return self.u ** o
    
    def forward(self, x):
        return x
    
    def grad(self, x):
        return 1
    
class Somme(Expression):
    def __init__(self,u,v):
        super().__init__(u)
        self.u=u
        self.v=v
        
    def __str__(self):
        if (isinstance(self.v,int) or isinstance(self.v,float)) and self.v<0:
            return f'({self.u} - {-self.v})'
        elif isinstance(self.v,Constante) and self.v.u<0:
            return f'({self.u} - {-self.v.u})'
        elif isinstance(self.v,Somme):
            return f'({self.u} + {self.v.u} + {self.v.v})'
        elif isinstance(self.v,Produit) and self.v.compteur==1:
            return f'({self.u} + {self.v.u} * {self.v.v})'
        elif isinstance(self.v,Produit) and self.v.compteur!=1:
            return f'({self.u} + {self.v.u}**{self.v.compteur})'
        return f'({self.u} + {self.v})'
    
    def __mul__(self,o):
        if isinstance(o,int) or isinstance(o,float):
            return Produit(self,Constante(o))
        elif isinstance(o,Expression):
            return Produit(self,o)
        
    def __rmul__(self,o):
        if isinstance(o,int) or isinstance(o,float):
            return Produit(Constante(o),self)
        elif isinstance(o,Expression):
            return Produit(o,self)
        
    
    def forward(self, x):
        f1=self.u.forward(x)
        f2=self.v.forward(x)
        return f1+f2
    
    def grad(self, x):
        f1=self.u.grad(x)
        f2=self.v.grad(x)
        return f1+f2
    
class Produit(Expression):
    def __init__(self,u,v,compteur=1):
        super().__init__(u)
        self.u=u
        self.v=v
        self.compteur=compteur
        
    def __str__(self):
        if self.u==1:
            return f'{self.v}'
        elif self.v==1:
            return f'{self.u}'
        elif self.u==self.v:
            return f'{self.u}**{self.compteur}'
        return f'({self.u} * {self.v})'
    
    def __add__(self, other):
        if isinstance(other,int) or isinstance(other,float):
            return Somme(self,Constante(other))
        else:
            return Somme(self,other)
    
    def __sub__(self, other):
        if isinstance(other,int) or isinstance(other,float):
            return Somme(self,Constante(-other))
        else:
            return Somme(self,-other)
    
    def forward(self, x):
        f1=0
        f2=0
        if(self.compteur==1):
            f1=self.u.forward(x)
            f2=self.v.forward(x)
            return f1*f2
        else:
            f1=self.u.forward(x)
            f2=self.compteur
            return f1**f2
    
    def grad(self, x):
        f1=0
        f2=0
        u1=0
        u2=0
        if self.compteur==1:
            f1=self.u.grad(x)
            u1=self.u.forward(x)
            f2=self.v.grad(x)
            u2=self.v.forward(x)
            return f1*u2 + f2*u1
        else:
            f1=self.u.grad(x)
            u1=self.u.forward(x) ** (self.compteur-1)
            return self.compteur * f1 * u1
    
class Division(Expression):
    def __init__(self,u,v):
        super().__init__(u)
        self.u=u
        self.v=v
        
    def __str__(self):
        return f'({self.u} / {self.v})'
    
    def forward(self, x):
        f1=self.u.forward(x)
        f2=self.v.forward(x)
        return f1/f2
    
    def grad(self, x):
        f1=self.u.grad(x)
        u1=self.u.forward(x)
        f2=self.v.grad(x)
        u2=self.v.forward(x)
        return (f1*u2 - f2*u1) / (u2)**2
    

#Section 1: tests

e1=Variable()
#print(e1.forward(5))
#print(e1.grad(7))
e2=Variable()
e3=Constante(5)
#print(e3.forward(1000))
#print(e3.grad(45))
e4=Constante(10)
somme=Somme(e1,e4)
#print(somme.forward(30))
#print(somme.grad(100))
prod=Produit(e1,e2)
#print(prod.forward(7))
#print(prod.grad(7))
expA=Expression("expA")
expB=Expression("expB")
sommeexp=Somme(expA,expB)
#print(sommeexp)
prodexp=Produit(expA,expB)
#print(prodexp)
#print(e3.descente_grad(5,0.3,15))
#print(e1.descente_grad(10,0.3,35))
quotient=Division(e3,e1)
#print(quotient)
#print(quotient.forward(10))
#print(quotient.grad(10))

x=Variable()
expr=x**2 + 2 * (x-2)
print(expr)
#print(expr.forward(1))
#print(expr.grad(3))
print(expr.descente_grad(25,0.7,1000))

expr33= x**3 +x**2 + x + 2*(x-7)
#print(expr33)
#print(expr33.forward(1))
#print(expr33.grad(2))

