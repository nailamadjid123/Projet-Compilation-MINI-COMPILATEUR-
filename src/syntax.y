%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "lex.yy.h"
    #include <stdbool.h>
    #include "pile.h"
    #include "quadruplets.h"
    #include "TS_tabFormat.h"

    //extern int qc;
    //extern qdr quad[1000];

    extern int yylineno;

    char *op1, *op2 ,*id1 , *id2; // gerer les exp_arthimetique pour maj de idf et test conditions 
    char tmp[50];  
    char tempexp[10];
    int quadindex0, quadindex1 ,quadindex2;
    char  sauvindex1[4];
    char  sauvindex2[4];
    char  sauvindex[4];
    char quad1[10]; 
    char quad2[10];
    int  notcond = 0 ; // pour not condition initially 0
    char sauvidf[10];  // save type  ( CHAR FLOAT INTEGER ) , pour màj de type idf 
    char sauvval[10]; // save val  pour maj de valeur idf 



    void yyerror(const char *s);
    int yylex();


    void print_string(const char* str) {
        // Enlève les guillemets et affiche
        char* tmp = strdup(str + 1);  // Skip first quote
        tmp[strlen(tmp)-1] = '\0';    // Remove last quote
        printf("%s\n", tmp);
        free(tmp);
    }

%}

%union {
    int integer;
    float floating;
    char* string;
    char *operator;
    int boolean;
    double val_tmps;
}

%token LBRACE RBRACE
%token VAR_GLOBAL DECLARATION INSTRUCTION
%token <string>INTEGER 
%token <string>FLOAT 
%token <string>CHAR 
%token <string>CONST
%token IF ELSE FOR READ WRITE
%token AND OR NOT
%token EQUAL NOT_EQUAL LESS_EQUAL GREATER_EQUAL GREATER LESS
%token <string>STRING_LITERAL
%token <string>IDENTIFIER
%token <string>INTEGER_CONSTANT
%token <string>FLOAT_CONSTANT


%type <string> type
%type <string> constant_value

/* Define operator precedence */
%left OR
%left AND
%left EQUAL NOT_EQUAL LESS_EQUAL GREATER_EQUAL GREATER LESS
%left '+' '-'
%left '*' '/'


%%

program: { printf("-----------------------Debut du bloc var_global------------------------------------\n");}
    VAR_GLOBAL LBRACE declarations RBRACE declaration_block instruction_block
    
    ;

//==========================DECLARATION===============================================
declaration_block:
    DECLARATION LBRACE declarations RBRACE
    ;

declarations:
    /* vide */
    | declarations declaration {printf("-----------------------------------Declaration------------------------\n");}
    ;

declaration: type IDENTIFIER var_list ';'
    {  printf("Debut de var_global\n");
        // Déclaration d'une variable simple sans valeur initiale
        insertSymbol($2, sauvidf, 0, 0, 0, ""); 
    }
    | CONST type IDENTIFIER '=' constant_value ';'
    {
        char value[50];
        //sprintf(value, "%s", $5); // Convertir la valeur constante en chaîne
        //*****************************************semantic check=double declaration***********************************************************
        if(!lookupSymbol($3))
       {     insertConstantSymbol($3,sauvidf,$5) ;   
             ajout_quad_affect_val($3,$5);            }
       else { yyerror("Double declared variable");  }
    }
    | type IDENTIFIER '[' INTEGER_CONSTANT ']' ';'
    {
        // Déclaration de tableau sans valeur initiale
        char sizeS[10];
        strcpy(sizeS,$4); // Sauvegarder la taille sous forme de chaîne
        int size =  atoi(sizeS); // Conversion de la chaîne en entier
        if(size<=0){ yyerror("Size of the array cannot be negative");}
        else {
        insertSymbol($2, $1, 1, size, 0, ""); }
    }
    ;

var_list:
    ',' IDENTIFIER var_list
    {
        // Déclaration de variables supplémentaires sans valeur initiale
        if(!lookupSymbol($2))
       {          insertSymbol($2, sauvidf, 0, 0, 0, "");          }
       else { yyerror("Double declared variable");  }
         
    }
    | ',' IDENTIFIER '[' INTEGER_CONSTANT ']' var_list
    {
        // Déclaration de tableaux supplémentaires sans valeur initiale
        char sizeS[10];
        strcpy(sizeS,$4); // Sauvegarder la taille sous forme de chaîne
        int size =  atoi(sizeS); // Conversion de la chaîne en entier
        if(size<=0){ yyerror("Size of the array cannot be negative");}
        else {insertSymbol($2, $<string>1, 1, size, 0, ""); }
    }
    | /* empty */
    ;

type:
    INTEGER {strcpy(sauvidf,"INTEGER");}
    | FLOAT {strcpy(sauvidf,"FLOAT");}
    | CHAR {strcpy(sauvidf,"CHAR");}
    ;

constant_value:
      INTEGER_CONSTANT { $$ = $1; strcpy(sauvidf, "INTEGER"); }
    | FLOAT_CONSTANT   { $$ = $1; strcpy(sauvidf, "FLOAT"); }
    | STRING_LITERAL   { $$ = $1; strcpy(sauvidf, "CHAR"); }
    ;


//==========================INSTRUCTION===============================================
instruction_block:
    { printf("------------------------Debut du bloc d'instructions-------------------\n");}
    INSTRUCTION LBRACE instruction RBRACE

    ;

instruction: affectation instruction { /* printf("*********AFFECTATION**********\n"); */ }
             | condition instruction {  printf("*********CONDITION**********\n");  }
             | if_statement instruction { printf("*********IF ELSE**********\n"); }
             | for_loop instruction 
             | write_inst instruction 
             | read_inst instruction 
             | /*empty*/
             ;

affectation:   IDENTIFIER '=' IDENTIFIER ';'
            {    printf("*********ICI idf = idf **********\n");
                get_type_of_idf($3,sauvidf);
                Symbol* sym = lookupSymbol($1);
                if (!sym) { yyerror("Undeclared variable"); } 
                else { if (sym->isConstant) { yyerror("Cannot modify a constant"); } 
                     else {if(!isTypeCompatible(sym->type,sauvidf)) { yyerror("Type mismatch in assignment");  }
                     else{
                    get_type_of_idf($<string>3,sauvidf);
                    insert_type($<string>1,sauvidf);
                    get_value_of_idf($<string>3,sauvval);
                    set_value_of_idf($<string>1,sauvval);
                    ajout_quad_affect_val($<string>1,$<string>3);
                     }}}
    
            } 
            | IDENTIFIER '=' INTEGER_CONSTANT ';'
            {       printf("*********ICI idf = integer **********\n");
                    get_type_of_idf($1,sauvidf);
                    printf("ICI LA VAL DE INTEGER_CONSTANT %s\n",$3);
                 //verifier la compatibilité des types
                 Symbol* sym = lookupSymbol($1);
                if (!sym) { yyerror("Undeclared variable"); } 
                else { if (sym->isConstant) { yyerror("Cannot modify a constant"); } 
                     else {
                if (isTypeCompatible("INTEGER",sauvidf)==0) {
                yyerror("Type mismatch in assignment.");
                }else{
                    set_value_of_idf($1,$3);
                    ajout_quad_affect_val($1,$3);}}}
                  
            }
            | IDENTIFIER '=' FLOAT_CONSTANT ';'
            {       printf("*********ICI idf = float **********\n");
                    get_type_of_idf($1,sauvidf);
                    printf("ICI LA VAL DE FLOAT_CONSTANT %s\n",$3);
                 //verifier la compatibilité des types
                 Symbol* sym = lookupSymbol($1);
                if (!sym) { yyerror("Undeclared variable"); } 
                else { if (sym->isConstant) { yyerror("Cannot modify a constant"); } 
                     else {
                        if (isTypeCompatible("FLOAT",sauvidf)==0) {
                        yyerror("Type mismatch in assignment.");
                        }else{
                    set_value_of_idf($1,$3);
                    //printf("[[[[[[[[[[[[[[[[[   avant : qc = %d   ]]]]]]]]]]]]]]]]]]\n",qc);
                    ajout_quad_affect_val($1,$3); }}}
                    //printf("[[[[[[[[[[[[[[[[[   apres : qc = %d   ]]]]]]]]]]]]]]]]]]\n",qc);
                  
            }
            | IDENTIFIER '=' STRING_LITERAL ';'
            {       printf("*********ICI idf = string_literal **********\n");
                    get_type_of_idf($1,sauvidf);
                    printf("ICI LA VAL DE STRING_LITERAL %s\n",$3);
               
                //verifier la compatibilité des types
                Symbol* sym = lookupSymbol($1);
                        if (!sym) { yyerror("Undeclared variable"); } 
                        else { if (sym->isConstant) { yyerror("Cannot modify a constant"); } 
                            else {
                            if (isTypeCompatible("CHAR",sauvidf)==0) {
                            yyerror("Type mismatch in assignment.");
            
                } else{
                    set_value_of_idf($1,$3);
                    ajout_quad_affect_val($1,$3);}}}
                  // VERIFIER SI CHAR ET SI SIZE > AU NOMBRE DE CARACTERES
            }
            | IDENTIFIER '=' expression ';'
            {     printf("*********ICI idf = exp **********\n");
                  strcpy(tmp, Depiler());
                  get_type_of_idf($1,sauvidf);
                  printf("ICI LA VAL DE TMP %s\n",tmp);
                  printf("ICI SET DE LA VAL\n");
                  //sauvegarder le type de tmp
                char* type_tmp;
                if(is_int_or_float(tmp)){type_tmp ="INTEGER";}
                else{type_tmp="FLOAT";} 
                
                Symbol* sym = lookupSymbol($1);
                if (!sym) { yyerror("Undeclared variable"); } 
                else { if (sym->isConstant) { yyerror("Cannot modify a constant"); } 
                     else {
                    //verifier la compatibilité des types
                    if (isTypeCompatible(type_tmp,sauvidf)==0) {
                    yyerror("Type mismatch in assignment.");
        
                    }else{
                  set_value_of_idf($1,tmp);
                  quadruplet("=",tempexp,"",$1);
                 // ajout_quad_affect_val($1,tmp);
                   // maj_quad(qc-2, 3, tmp);
                    }}}
            }
            | IDENTIFIER '=' condition ';'
            {     printf("*********ICI idf = condition  **********\n");
                  // LA PROF DIDN'T ASK FOR THIS BUT I'M JUST CHECKING IF CONDITIONS ARE WORKING CORRECTLY
                  strcpy(tmp, Depiler());
                  get_type_of_idf($1,sauvidf);
                  printf("ICI LA VAL DE TMP %s\n",tmp);
                  printf("ICI SET DE LA VAL\n");
                  set_value_of_idf($1,tmp);
                  ajout_quad_affect_val($1,tmp);
                  if(is_int_or_float(tmp)==1)
                   {
                       // printf("\n its an int ");
                        insert_type($1,"INTEGER");
                    }else{
                       // printf("its a float");
                        insert_type($1,"FLOAT");
                    }  
                   // maj_quad(qc-2, 3, tmp);
            }

;


expression:
    expression '+' expression { 
                printf("*********ICI exp + exp **********\n");
                op2 = malloc(50); 
                op1 = malloc(50); 
                strcpy(op2, Depiler());  printf("op2 = %s\n",op2); printf("op2 est toujours valide et vaut = %s\n",op2); 
                strcpy(op1, Depiler());  printf("op1 = %s\n",op1); 
                //printf("op2 = %s /// op1 =  %s ",op2,op1);
            //sauvegarder les types 1 et 2
        char* type1;
        char* type2;
        if(is_int_or_float(op1)){type1 ="INTEGER";}
        else{type1="FLOAT";} //affecter le type de op1 à type1
        if(is_int_or_float(op2)){type2 ="INTEGER";}
        else{type2="FLOAT";} //affecter le type de op2 à type2
        
         //verifier la compatibilité des types
        if (isTypeCompatible(type1,type2)==0) {
        yyerror("Type mismatch in addition.");
        free(op2); free(op1);

        } else{
                if(!is_int_or_float(op2)){
                       float ope1 = atof(op1); // Convertir en float
                       float ope2 = atof(op2); 
                       float res = ope1 + ope2;
                        // Convertir le résultat en chaîne
                        sprintf(tmp, "%.2f", res);
                    }else{  // convertir en int
                       int ope1 = atoi(op1);  printf("ope1 = %d\n",ope1);
                       int ope2 = atoi(op2);  printf("ope2 = %d\n",ope2);
                       int res = ope1 + ope2; printf("++++++++++++++++++++++++++++++++++++++++++ICI RESULTAT %d+++++++++++++++++++++++++++",res);
                       sprintf(tmp, "%d",res); printf("tmp = %s\n",tmp);
                    }
                
                
                Empiler(tmp);
                sprintf(tempexp, "T%d", newTemp());
                quadruplet("+",op1,op2,tempexp);
                // ajout_quad_opbinaire('+',op1,op2);
                free(op2); free(op1);}
             }
    | expression '-' expression { 
                printf("*********ICI exp - exp **********\n");
                op2 = malloc(50); 
                op1 = malloc(50); 
                strcpy(op2, Depiler());  printf("op2 = %s\n",op2); printf("op2 est toujours valide et vaut = %s\n",op2); 
                strcpy(op1, Depiler());  printf("op1 = %s\n",op1); 
            //sauvegarder les types 1 et 2
        char* type1;
        char* type2;
        if(is_int_or_float(op1)){type1 ="INTEGER";}
        else{type1="FLOAT";} //affecter le type de op1 à type1
        if(is_int_or_float(op2)){type2 ="INTEGER";}
        else{type2="FLOAT";} //affecter le type de op2 à type2
        
         //verifier la compatibilité des types
        if (isTypeCompatible(type1,type2)==0) {
        yyerror("Type mismatch in substraction.");
        free(op2); free(op1);
        
        } else{
                if(!is_int_or_float(op2)){
                       float ope1 = atof(op1); // Convertir en float
                       float ope2 = atof(op2); 
                           float res = ope1 - ope2;
                        // Convertir le résultat en chaîne
                        sprintf(tmp, "%.2f", res);
                    }else{
                       int ope1 = atoi(op1); // convertir en int 
                       int ope2 = atoi(op2); 
                        int res = ope1 - ope2;
                        sprintf(tmp, "%d",res);
                    }
                Empiler(tmp);
                sprintf(tempexp, "T%d", newTemp());
                quadruplet("-",op1,op2,tempexp);
                //ajout_quad_opbinaire('-',op1,op2);
                free(op2); free(op1);}
             }
    | expression '*' expression { 
                printf("*********ICI exp * exp **********\n");
                op2 = malloc(50); 
                op1 = malloc(50); 
                strcpy(op2, Depiler());  printf("op2 = %s\n",op2); printf("op2 est toujours valide et vaut = %s\n",op2); 
                strcpy(op1, Depiler());  printf("op1 = %s\n",op1); 
            //sauvegarder les types 1 et 2
        char* type1;
        char* type2;
        if(is_int_or_float(op1)){type1 ="INTEGER";}
        else{type1="FLOAT";} //affecter le type de op1 à type1
        if(is_int_or_float(op2)){type2 ="INTEGER";}
        else{type2="FLOAT";} //affecter le type de op2 à type2
        
         //verifier la compatibilité des types
        if (isTypeCompatible(type1,type2)==0) {
        yyerror("Type mismatch in muliplication.");
        free(op2); free(op1);
        } else{
                if(!is_int_or_float(op2)){
                       float ope1 = atof(op1); // Convertir en float
                       float ope2 = atof(op2); 
                           float res = ope1 * ope2;
                        // Convertir le résultat en chaîne
                        sprintf(tmp, "%.2f", res);
                    }else{
                       int ope1 = atoi(op1); // convertir en int 
                        int ope2 = atoi(op2); 
                        int res = ope1 * ope2;
                        sprintf(tmp, "%d",res);
                    }
                Empiler(tmp);
                //printf("///////////////QC = %d tmp = %s//////////////////",qc,tmp);
                //ajout_quad_opbinaire('*',op1,op2);
                sprintf(tempexp, "T%d", newTemp());
                quadruplet("*",op1,op2,tempexp);
                printf("///////////////QC = %d tmp = %s//////////////////",qc,tmp);
                free(op2); free(op1);}
             }
    | expression '/' expression {
        
                printf("*********ICI exp / exp **********\n");
                op2 = malloc(50); 
                op1 = malloc(50); 
                strcpy(op2, Depiler());  printf("op2 = %s\n",op2); 
                strcpy(op1, Depiler());  printf("op1 = %s\n",op1);
        //verifier la division par zero       
        if (atof(op2) == 0) {
        yyerror("Division by zero");
        //free(op2); free(op1);
        //YYABORT; // arreter ici 
                    } else{
        //sauvegarder les types 1 et 2
        char* type1;
        char* type2;
        if(is_int_or_float(op1)){type1 ="INTEGER";}
        else{type1="FLOAT";} //affecter le type de op1 à type1
        if(is_int_or_float(op2)){type2 ="INTEGER";}
        else{type2="FLOAT";} //affecter le type de op2 à type2
        
         //verifier la compatibilité des types
        if (isTypeCompatible(type1,type2)==0) {
        yyerror("Type mismatch in division.");
        free(op2); free(op1);
        YYABORT;
        }
                if(!is_int_or_float(op2)){
                       float ope1 = atof(op1); // Convertir en float
                       float ope2 = atof(op2); 
                           float res = ope1 / ope2;
                        // Convertir le résultat en chaîne
                        sprintf(tmp, "%.2f", res);
                    }else{
                       int ope1 = atoi(op1); // convertir en int 
                       int ope2 = atoi(op2); 
                        int res = ope1 / ope2;
                        sprintf(tmp, "%d",res);
                    }
                Empiler(tmp);
                //ajout_quad_opbinaire('/',op1,op2);
                sprintf(tempexp, "T%d", newTemp());
                quadruplet("/",op1,op2,tempexp);
                free(op2); free(op1);}
             }                
    |'-' expression{
                     op1 = malloc(50); 
                     strcpy(op1, Depiler());  printf("op1 = %s\n",op1);
                      if(!is_int_or_float(op1)){
                       float ope1 = atof(op1); // Convertir en float
                           float res = - ope1;
                        // Convertir le résultat en chaîne
                        sprintf(tmp, "%.2f", res);
                    }else{
                       int ope1 = atoi(op1); // convertir en int 
                        int res = - ope1;
                        sprintf(tmp, "%d",res);
                    }
                    Empiler(tmp);
                    //ajout_quad_opunaire(op1);
                    sprintf(tempexp, "T%d", newTemp());
                    quadruplet("-","0",op1,tempexp);
                    free(op1);
                  }
    |IDENTIFIER
       { Symbol* sym = lookupSymbol($1);
           if (!sym) {
               yyerror("Undeclared variable");
           } else {
         get_value_of_idf($1,tmp);
         printf("tmp de %s = %s\n",$1,tmp);
         Empiler($1);
         Empiler(tmp);
         Afficher_pile();}
       }
    |INTEGER_CONSTANT { Empiler($1); Afficher_pile(); }
    |FLOAT_CONSTANT { Empiler($1);}
    | '(' expression ')' 
    ;   




//if_statement: IF '(' condition ')' LBRACE <A> instructions RBRACE ELSE LBRACE <B> instructions RBRACE <C>

if_statement: B instruction RBRACE{
    sprintf(sauvindex2,"%d",qc+1);
	maj_quad(quadindex1,1,sauvindex2);
}

B: A instruction RBRACE ELSE LBRACE {
    quadindex1 = qc;
	quadruplet("BR","temp_fin","","");
    sprintf(sauvindex1,"%d",qc+1);
	maj_quad(quadindex0,1,sauvindex1);
}

A: IF '(' condition ')' LBRACE {
    quadindex0 = qc;
    strcpy(sauvval, Depiler());
    quadruplet("BZ" ,"temp_qc",sauvval,""); 
    
	
}

condition: 
    expression EQUAL expression 
            {  
            strcpy(quad1,"BNE");
            printf("*********ICI exp = exp **********\n");
                op2 = malloc(50); id2 = malloc(50);
                op1 = malloc(50); id1 = malloc(50);
                strcpy(op2, Depiler()); strcpy(id2, Depiler());
                strcpy(op1, Depiler()); strcpy(id1, Depiler());
            if(!is_int_or_float(op1)){
                float ope1 = atof(op1); 
                float  ope2 = atof(op2); 
                int res = (ope1 == ope2);
                sprintf(tmp, "%d",res);
                }
            else{
                int ope1 = atoi(op1); // convertir en int 
                int ope2 = atoi(op2); 
                int res = (ope1 == ope2);
                sprintf(tmp, "%d",res);
                }
            sprintf(tempexp, "T%d", newTemp());
            quadruplet(quad1,id1,id2,tempexp);
            Empiler(tmp);
            free(op2); free(op1); free(id2); free(id1);
            }
    |expression NOT_EQUAL expression {  
            strcpy(quad1,"BE");
            printf("*********ICI exp != exp **********\n");
                op2 = malloc(50); id2 = malloc(50);
                op1 = malloc(50); id1 = malloc(50);
                strcpy(op2, Depiler()); strcpy(id2, Depiler());
                strcpy(op1, Depiler()); strcpy(id1, Depiler());
            if(!is_int_or_float(op1)){
                float ope1 = atof(op1); 
                float  ope2 = atof(op2); 
                int res = (ope1 != ope2);
                sprintf(tmp, "%d",res);
                }
            else{
                int ope1 = atoi(op1); // convertir en int 
                int ope2 = atoi(op2); 
                int res = (ope1 != ope2);
                sprintf(tmp, "%d",res);
                }
            Empiler(tmp);
            sprintf(tempexp, "T%d", newTemp());
            quadruplet(quad1,id1,id2,tempexp);
            free(op2); free(op1); free(id2); free(id1);
            }
    |expression LESS expression {  
            strcpy(quad1,"BGE");
            printf("*********ICI exp < exp **********\n");
                op2 = malloc(50); id2 = malloc(50);
                op1 = malloc(50); id1 = malloc(50);
                strcpy(op2, Depiler()); strcpy(id2, Depiler()); 
                strcpy(op1, Depiler()); strcpy(id1, Depiler()); 
            if(!is_int_or_float(op1)){
                float ope1 = atof(op1); 
                float  ope2 = atof(op2); 
                int res = (ope1 < ope2);
                sprintf(tmp, "%d",res);
                }
            else{// convertir en int
                int ope1 = atoi(op1);  printf("ope1 = %d\n",ope1);
                int ope2 = atoi(op2);  printf("ope2 = %d\n",ope2);
                int res = (ope1 < ope2); printf("res = %d\n",res);
                sprintf(tmp, "%d",res);
                }
            
            sprintf(tempexp, "T%d", newTemp());
            quadruplet(quad1,id1,id2,tempexp);
            Empiler(tmp); Afficher_pile();
            free(op2); free(op1); free(id2); free(id1);
            }
    |expression LESS_EQUAL expression {  
            strcpy(quad1,"BG");
            printf("*********ICI exp <= exp **********\n");
                op2 = malloc(50); id2 = malloc(50);
                op1 = malloc(50); id1 = malloc(50);
                strcpy(op2, Depiler()); strcpy(id2, Depiler()); 
                strcpy(op1, Depiler()); strcpy(id1, Depiler()); 
            if(!is_int_or_float(op1)){
                float ope1 = atof(op1); 
                float  ope2 = atof(op2); 
                int res = (ope1 <= ope2);
                sprintf(tmp, "%d",res);
                }
            else{
                int ope1 = atoi(op1); // convertir en int 
                int ope2 = atoi(op2); 
                int res = (ope1 <= ope2);
                sprintf(tmp, "%d",res);
                }
            Empiler(tmp); Afficher_pile();
            sprintf(tempexp, "T%d", newTemp());
            quadruplet(quad1,id1,id2,tempexp);
            free(op2); free(op1); free(id2); free(id1);
            }
    |expression GREATER expression {  
            strcpy(quad1,"BLE");
            printf("*********ICI exp > exp **********\n");
                Afficher_pile();
                op2 = malloc(50); id2 = malloc(50);  
                op1 = malloc(50); id1 = malloc(50);
                strcpy(op2, Depiler()); strcpy(id2, Depiler()); 
                strcpy(op1, Depiler()); strcpy(id1, Depiler()); 
            if(!is_int_or_float(op1)){
                float ope1 = atof(op1); 
                float  ope2 = atof(op2); 
                int res = (ope1 > ope2);
                sprintf(tmp, "%d",res);
                }
            else{
                int ope1 = atoi(op1); // convertir en int 
                int ope2 = atoi(op2); 
                int res = (ope1 > ope2); 
                sprintf(tmp, "%d",res); 
                }
            Empiler(tmp);
            sprintf(tempexp, "T%d", newTemp());
            quadruplet(quad1,id1,id2,tempexp);
            free(op2); free(op1); free(id2); free(id1);
            }
    |expression GREATER_EQUAL expression {  
            strcpy(quad1,"BL");
            printf("*********ICI exp >= exp **********\n");
                op2 = malloc(50); id2 = malloc(50);
                op1 = malloc(50); id1 = malloc(50);
                strcpy(op2, Depiler()); strcpy(id2, Depiler()); 
                strcpy(op1, Depiler()); strcpy(id1, Depiler()); 
            if(!is_int_or_float(op1)){
                float ope1 = atof(op1); 
                float  ope2 = atof(op2); 
                int res = (ope1 >= ope2);
                sprintf(tmp, "%d",res);
                }
            else{
                int ope1 = atoi(op1); // convertir en int 
                int ope2 = atoi(op2); 
                int res = (ope1 >= ope2);
                sprintf(tmp, "%d",res);
                }
            Empiler(tmp);
            sprintf(tempexp, "T%d", newTemp());
            quadruplet(quad1,id1,id2,tempexp);
            free(op2); free(op1); free(id2); free(id1);
            }
    | condition AND condition {   
        printf("*********ICI condition AND condition **********\n");
        char *cond1, *cond2;
        cond1 = malloc(50); cond2 = malloc(50); 
        strcpy(cond2, Depiler()); strcpy(cond1, Depiler()); 
        strcpy(quad2,"BZ");
        int qccond1 = qc;
        quadruplet(quad2 ,"temp_index",cond1,"");
        int qccond2 = qc;
        quadruplet(quad2 ,"temp_index",cond2,"");
        char temp1[10];
        sprintf(temp1, "T%d", newTemp());
        quadruplet("=" ,"1","",temp1);
        int qcgotofin = qc;
        quadruplet("BR" ,"index_de_fin","","");
        char  qcfaux[4];
        sprintf(qcfaux,"%d",qc+1);
        quadruplet("=" ,"0","",temp1);
        char  qcfin[4];
        sprintf(qcfin,"%d",qc+1);
        maj_quad(qccond1,1,qcfaux);
        maj_quad(qccond2,1,qcfaux);
        maj_quad(qcgotofin,1,qcfin);
        Empiler(temp1);

    }
    | condition OR condition { 
        printf("*********ICI condition OR condition **********\n");
        char *cond1, *cond2;
        cond1 = malloc(50); cond2 = malloc(50); 
        strcpy(cond2, Depiler()); strcpy(cond1, Depiler());
        strcpy(quad2,"BNZ");
        int qccond1 = qc;
        quadruplet(quad2 ,"temp_index",cond1,"");
        int qccond2 = qc;
        quadruplet(quad2 ,"temp_index",cond2,"");
        char temp2[10];
        sprintf(temp2, "T%d", newTemp());
        quadruplet("=" ,"0","",temp2);
        int qcgotofin = qc;
        quadruplet("BR" ,"index_de_fin","","");
        char  qcvrai[4];
        sprintf(qcvrai,"%d",qc+1);
        quadruplet("=" ,"1","",temp2);
        char  qcfin[4];
        sprintf(qcfin,"%d",qc+1);
        maj_quad(qccond1,1,qcvrai);
        maj_quad(qccond2,1,qcvrai);
        maj_quad(qcgotofin,1,qcfin);
        Empiler(temp2);

    }
    | NOT condition
    {
        printf("*********ICI NOT condition **********\n");
        //notcond = 1;
        char *cond1;
        cond1 = malloc(50);
        strcpy(cond1, Depiler());
        strcpy(quad2,"BNZ");
        int qccond1 = qc;
        quadruplet(quad2 ,"temp_index",tempexp,"");
        //char temp3[10];
        //sprintf(temp3, "T%d", newTemp());
        quadruplet("=" ,"1","",tempexp);
        int qcgotofin = qc;
        quadruplet("BR" ,"index_de_fin","","");
        char  qcvrai[4];
        sprintf(qcvrai,"%d",qc+1);
        quadruplet("=" ,"0","",tempexp);
        char  qcfin[4];
        sprintf(qcfin,"%d",qc+1);
        maj_quad(qccond1,1,qcvrai);
        maj_quad(qcgotofin,1,qcfin);
        Empiler(tempexp);
      
    }
    ;




for_loop:  FOR '(' IDENTIFIER '=' expression ':' expression ':' expression ')' LBRACE instruction RBRACE 
    {
        // Initialization
        char *initVar = $3;  // Loop variable
        char *startValue = Depiler(); // Starting value from expression 1
        quadruplet("=", startValue, "-", initVar); // Generate quadruplet for initialization

        // Condition check
        int loopStart = qc; // Save the current quadruplet index for the start of the loop
        char *endValue = Depiler(); // Ending value from expression 2
        char temp1[10]; // Temporary variable for condition result
        sprintf(temp1, "T%d", newTemp());
        quadruplet("<=", initVar, endValue, temp1); // Temporary for condition
        int conditionQuad = qc - 1; // Remember this quadruplet for backpatching

        // Jump to loop exit
        quadruplet("IF_FALSE", temp1, "-", "_"); // Placeholder for jump out of loop
        int jumpExit = qc - 1;

        // Loop body
        //$12;  Execute instructions inside the loop

        // Increment
        char *stepValue = Depiler(); // Step value from expression 3
        char temp2[10]; // Temporary variable for increment
        sprintf(temp2, "T%d", newTemp());
        quadruplet("+", initVar, stepValue, temp2); // Increment operation
        quadruplet("=", temp2, "-", initVar); // Assign incremented value back to loop variable

        // Jump back to loop start
        quadruplet("GOTO", ToSTR(loopStart), "-", "-");

        // Backpatch the jump exit location
        maj_quad(jumpExit, 3, ToSTR(qc)); // Update the exit jump to the current quadruplet index
    }
;

write_inst:
    WRITE '(' write_args ')' ';'
    ;

write_args:
    STRING_LITERAL
    { print_string($1); /* Affiche une chaîne*/ }
    | IDENTIFIER
    {
        // Rechercher la valeur associée à l'identifiant dans la table des symboles
        Symbol *sym = lookupSymbol($1);
        printf("%s\n", sym->val); // Affiche la valeur de l'identifiant
    }
    | write_args ',' STRING_LITERAL
    { print_string($3); /* Affiche la chaîne littérale suivante */}
    | write_args ',' IDENTIFIER
    {
        // Rechercher la valeur associée à l'identifiant suivant
        Symbol *sym = lookupSymbol($3);
        printf("%s\n", sym->val); // Affiche la valeur de l'identifiant 
    }
    ;

read_inst:
    READ '(' IDENTIFIER ')' ';'
    {
        Symbol *sym = lookupSymbol($3); // Vérifier si l'identifiant est déclaré
            char input[50];
            fgets(input, sizeof(input), stdin); // Lire une valeur de l'utilisateur
            input[strcspn(input, "\n")] = '\0'; // Supprimer le caractère de nouvelle ligne
            set_value_of_idf($3,input);
   
    }
    ;



%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s at line %d\n", s, yylineno);
}

int yywrap()
{
   return 1;
}

int main() {
    yyparse();
    char *x = "nailaaaa";
    Initpile();
    Empiler(x);
    Empiler("hello");
    afficher_qdr();
    //maj_quad(11, 3, "hehe it changed");
    //afficher_qdr();
    test_affichage_pile();
    Afficher_pile();
    
    /*
    insertSymbol("x", "INTEGER", 0, 0, 0, "10");
    insertSymbol("y", "FLOAT", 0, 0, 0, "3.14");
    insertArraySymbol("arr", "INTEGER", 5);
    insertConstantSymbol("PI", "FLOAT", "3.14159");
    */
    afficherTableSymboles();
    return 1;
}
