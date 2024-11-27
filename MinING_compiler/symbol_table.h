/****************CREATION DE LA TABLE DES SYMBOLES ******************/
/***Step 1: Definition des structures de données ***/
#include<stdio.h>
#include<stdlib.h>
#include<string.h>



// structure des idfs et cst

typedef struct
{
   int state;
   char name[20];
   char code[20];
   char type[20];
   float val;
   char  valstring[10];   // pour stocker les valeur de CHAR BOOL
 } element;


// structure des mots cle et separateur 
typedef struct
{ 
   int state; 
   char name[20];
   char type[20];
} elt;

element tab[1000]; 			//tab: IDF et constantes
elt tabs[40],tabm[40]; 			//tabs: séparateurs, tabm:mots clés
int cpt, cpts, cptm;


char type_idf[15];

/***Step 2: initialisation de l'état des cases des tables des symbloles***/
/*0: la case est libre    1: la case est occupée*/

void initialisation()
{

//initialiser state à 0 dans toutes les tables. Ex: tab[i].state=0;
//initialiser les compteurs à 0
//printf("Init\n");
int i;
for(i=0;i<1000;i++) tab[i].state=0;
for(i=0;i<40;i++) {tabs[i].state=0; tabm[i].state=0;}
 
cpt=0; cpts=0; cptm=0;

}

/***Step 4: insertion des entititées lexicales dans les tables des symboles ***/

void inserer (char entite[], char code[],char type[],float val,char val_string[], int i, int y)
{
  switch (y)
 { 
   case 0:/*insertion dans la table des IDF et CONST
			mettre state à 1, incrémenter cpt;
			insérer: name, code, type, val*/
       tab[i].state=1;
       strcpy(tab[i].name,entite);
       strcpy(tab[i].code,code);
	   strcpy(tab[i].type,type);
	   tab[i].val=val;
	   strcpy(tab[i].valstring,val_string);
	   cpt++;
	   break;

   case 1:/*insertion dans la table des mots clés
			mettre state à 1, incrémenter cptm;
			insérer: name, code*/
       tabm[i].state=1;
       strcpy(tabm[i].name,entite);
       strcpy(tabm[i].type,code);
	   cptm++;
       break; 
    
   case 2:/*insertion dans la table des séparateurs
			mettre state à 1, incrémenter cpts
			insérer: name, code*/
      tabs[i].state=1;
      strcpy(tabs[i].name,entite);
      strcpy(tabs[i].type,code);
	  cpts++;
      break;
 }

}


/***Step 3: La fonction Rechercher permet de verifier  si l'entité existe dèja dans la table des symboles */
void rechercher (char entite[], char code[],char type[],float val,char val_string[],int y)	
{

int j,i;

switch(y) 
  {
   case 0:

			/*Chercher si entite existe dans tab: si non on appelle la fonction inserer:
			inserer(entite, code, type, val, y);*/
		//printf("Rechercher idf cst\n");

		if(cpt==0) inserer(entite,code,type,val,val_string,0,0);
		else {
				for (i=0;((i<1000)&&(tab[i].state==1))&&(strcmp(entite,tab[i].name)!=0);i++); 
				if((i<1000) && (strcmp(entite,tab[i].name)!=0))
				{
         
				 inserer(entite,code,type,val,val_string,i,0);     
				}
				//else printf("Entite %s existe deja\n",entite);
		}
        break;

   case 1:
       //printf("Recherche mot cle, cptm=%d\n",cptm);
       /*Chercher si entite existe dans tabm: si non on appelle la fonction inserer*/
	   if(cptm==0) inserer(entite,code,type,val,val_string,0,1); 
	   else {	   
			   for(i=0;((i<40)&&(tabm[i].state==1))&&(strcmp(entite,tabm[i].name)!=0);i++); 
			   
			  // printf("i=%d\n",i);
				if(i<40)
				{ 	        
				 inserer(entite,code,type,val,val_string,i,1); 	      
				}
				else printf("Entite %s existe deja\n",entite);
	   }
        break; 
    
   case 2:
			//printf("Rechercher séparateur\n");
         /*Chercher si entite existe dans tabs: si non on appelle la fonction inserer*/
		if(cpts==0) inserer(entite,code,type,val,val_string,0,2); 
	    else {
				for (i=0;((i<40)&&(tabs[i].state==1))&&(strcmp(entite,tabs[i].name)!=0);i++); 
				if(i<40)
				{ 	        
				inserer(entite,code,type,val,val_string,i,2); 	      
				}
				else printf("Entite %s existe deja\n",entite);
		}
        break;

  }

}


/***Step 5 L'affichage du contenue de la table des symboles ***/

void afficher()
{int i;

printf("\n/***************Table des symboles IDF*************/\n");
printf("____________________________________________________________________\n");
printf("\t| Nom_Entite |  Code_Entite | Type_Entite | Val_Entite\n");
printf("____________________________________________________________________\n");
  

  // si idf or cst a une valeur numerique on affiche val sinon on affiche val_string 

for(i=0;i<cpt;i++)
{	
	
    if(tab[i].state==1)
      { 
		if((strcmp(tab[i].type,"CHAR")==0) || (strcmp(tab[i].type,"BOOLEAN")==0))
		{
        	printf("\t|%10s |%15s | %12s | %12s | \n",tab[i].name,tab[i].code,tab[i].type,tab[i].valstring);}
		else{
			printf("\t|%10s |%15s | %12s | %12f |  \n",tab[i].name,tab[i].code,tab[i].type,tab[i].val);
		}	
         
      }
}

 
printf("\n/***************Table des symboles mots cles*************/\n");

printf("_____________________________________\n");
printf("\t| NomEntite |  CodeEntite | \n");
printf("_____________________________________\n");
  
for(i=0;i<cptm;i++)
    if(tabm[i].state==1)
      { 
        printf("\t|%10s |%12s | \n",tabm[i].name, tabm[i].type);
               
      }

printf("\n/***************Table des symboles separateurs*************/\n");

printf("_____________________________________\n");
printf("\t| NomEntite |  CodeEntite    | \n");
printf("_____________________________________\n");
  
for(i=0;i<cpts;i++)
    if(tabs[i].state==1)
      { 
        printf("\t|%10s |%15s | \n",tabs[i].name,tabs[i].type );
        
      }

}








 int Recherche_position(char entite[])
		{
		int i=0;
		while(i<1000)
		{
		if (strcmp(entite,tab[i].name)==0) return i;	
		i++;
		}
 
		return -1;
		
		}

	 

  	
	int doubleDeclaration(char entite[])
	{
	int pos;
	pos=  Recherche_position(entite);
	if(strcmp(tab[pos].type,"")==0) return 0;
	   else return -1;
  }  
	

		
 // pour recuperer la valeur d'un idf deja initialiser 

void get_value_of_idf(char entite[],float *ttmp){
  int pos; 
  pos = Recherche_position(entite);
 
  *ttmp =tab[pos].val;
 }
 void get_valstring_of_idf(char entite[],char str[]){
	int pos;
	pos = Recherche_position(entite);
	strcpy(str,tab[pos].valstring);


 }

 //   affecter la valeur 

 void set_value_of_idf(char entite[], float *newval){

  int pos = Recherche_position(entite);

  tab[pos].val= *newval ;
 }  


 void set_valstring_of_idf(char entite[],char val_string[]){
	   int pos;
	   pos=Recherche_position(entite);
	   if(pos!=-1)  { strcpy(tab[pos].valstring,val_string); }

 }
 void get_type_of_idf(char entite[], char typ []){
	
	int pos = Recherche_position(entite);
	
	strcpy(typ,tab[pos].type);


 }

 void Inserer_type(char entite[], char type[])
	{
       int pos;
	   pos=Recherche_position(entite);
	   if(pos!=-1)  { strcpy(tab[pos].type,type);  
	}
	}


// type compatible a utiliser dans idf1 = idf2
// si idf1 est char bool table , idf2 doit etre de meme type sinon incompatible
// si idf1 est "" donc nouveau idf , compatible
// si idf1 est int ou float , idf2 doit etre int ou flat 

int type_compatible(char tp1[],char tp2[]){

	if(strcmp(tp1,"CHAR")==0){
		if(strcmp(tp2,"CHAR")!=0){return 0;}else{return 1;}}
	else{
	if(strcmp(tp1,"BOOLEAN")==0){
		if(strcmp(tp2,"BOOLEAN")!=0){return 0;}else{return 1;}	}
	else{
	if(strcmp(tp1,"TABLE")==0){
		if(strcmp(tp2,"TABLE")!=0){return 0;}else{return 1;}}
	else{
	if(strcmp(tp1,"")==0){ return 1;}
	else{
	if(strcmp(tp2,"INTEGER")==0 && strcmp(tp2,"FLOAT")==0){return 0;}else{return 1;}
	}}}}	
				
		
}
// tester si string1==string2 si logop="=="
// tester si string1!=string2 si logop="!="

float test_on_string(char logop[],char op1[],char op2[]){
	if(strcmp(logop,"==")==0)
	{
		if(strcmp(op1,op2)==0){
				return 1;
			}else{
				return 0;
			}
	}else{
		if(strcmp(op1,op2)==0){
				return 0;
			}else{
				return 1;
			}
	}
}	
	

 // savoir si le tmps generer par exp arth est int or float car dans la TS val les deux sont float
 int Is_int(float *N)
{
    int X = *N;

    float temp2 = *N - X;
    if (temp2 != 0) {
        return 0;
    }
    return 1;
}

// incrementer la valeur de idf dans la boucle for in range (bf,bs)

void inc_val_idf (char entite[]){
	float old;
	get_value_of_idf(entite,&old);
	old++;
	set_value_of_idf(entite,&old);
}


/*    A UTLISER POUR LES INT ET FLOAT SIGNEE ! pour eliminer les parenthese et prendre la valeur 
      Fonction subtring ( string , indice debut , indice fin )
      return  string between deb et fin  , exemple substring("(-90)",1,4) = "-90" */


char* substring(const char *src, int m, int n)
{
    int i=m;
    // get the length of the destination string
    int len = n - m;

    // allocate (len + 1) chars for destination (+1 for extra null character)
    char *dest = (char*)malloc(sizeof(char) * (len + 1));

    // extracts characters between m'th and n'th index from source string
    // and copy them into the destination string
    for (i; i < n && (*(src + i) != '\0'); i++)
    {
        *dest = *(src + i);
        dest++;
    }

    // null-terminate the destination string
    *dest = '\0';

    // return the destination string
    return dest - len;
}

