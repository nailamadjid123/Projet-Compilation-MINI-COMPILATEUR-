/* 1er Bloc des déclarations*/
%{

 /*Importation des bibliothèques standard pour les opérations d'E/S, allocation mémoire et manipulation de chaînes*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*les fichiers d'en-tête générés par Bison pour les définitions de tokens et la gestion de la table des symboles*/

#include "y.tab.h"
#include "symbol_table.h"

/*Initialise les compteurs de ligne et de colonne*/

int line_number = 1;
int column_number = 1;

/*Déclare une fonction de gestion des erreurs*/

void yyerror(const char *s);
%}

/* 2eme Bloc définitions des motif */

/*Désactive la demande de fichiers supplémentaires à analyser*/

%option noyywrap

/* Définitions des classes de caractères pour faciliter les expressions régulières */

DIGIT       [0-9]
LETTER      [A-Z]
LOWERCASE   [a-z]
WHITESPACE  [ \t]

/*3éme Bloc Règles de correspondance et actions*/

%%


/*Ignore les commentaires commençant par %% */

%% .*               { /* Ignore single-line comments */ }

/*Incrémente le compteur de colonnes pour les espaces*/

{WHITESPACE}+       { column_number += yyleng; }

/* Gère les sauts de ligne en incrémentant le numéro de ligne*/

\n                  { line_number++; column_number = 1; }

/*retourne les mots-clés spécifiques du langage MinING*/

"VAR_GLOBAL"        { return VAR_GLOBAL; }
"DECLARATION"       { return DECLARATION; }
"INSTRUCTION"       { return INSTRUCTION; }
"INTEGER"           { return INTEGER; }
"FLOAT"             { return FLOAT; }
"CHAR"              { return CHAR; }
"CONST"             { return CONST; }
"IF"                { return IF; }
"ELSE"              { return ELSE; }
"FOR"               { return FOR; }
"READ"              { return READ; }
"WRITE"             { return WRITE; }

"&&"                { return AND_OP; }
"||"                { return OR_OP; }
"!"                 { return NOT_OP; }
"=="                { return EQ_OP; }
"!="                { return NEQ_OP; }
"<="                { return LE_OP; }
">="                { return GE_OP; }
"<"                 { return LT_OP; }
">"                 { return GT_OP; }

/*Vérifiez que l'identificateur commence par une majuscule*/

{LETTER}({LETTER}|{DIGIT}){0,7} {
    /*Limite la longueur à 8 caractères*/
    if (yyleng > 8) {
    /*Gènere une erreur si la longueur est dépassée*/
        yyerror("Identifier exceeds 8 characters");
        return ERROR;
    }
    /*allouez dynamiquement une copie du texte correspondant à un identificateur (stockée dans yylval.strval) et retourne le token IDENTIFIER à l'analyseur syntaxique*/
    yylval.strval = strdup(yytext);
    return IDENTIFIER;
}
/*Gére les entiers signés et non signés*/
"("?[-+]?{DIGIT}+")"? {
    char *num_str = yytext;

    /*Gère les parenthèses optionnelles*/
    if (num_str[0] == '(') {
        num_str++;
        num_str[strlen(num_str)-1] = '\0';
    }

    /*Vérifie la plage des valeurs (-32768 à 32767)*/
    int val = atoi(num_str);
    if (val < -32768 || val > 32767) {
        yyerror("Integer out of range (-32768 to 32767)");
        return ERROR;
    }
    yylval.intval = val;
    return INT_CONST;
}
/* la meme chose mais avec les nombres avec virgule*/
"("?[-+]?{DIGIT}+"."{DIGIT}+")"? {
    char *num_str = yytext;
    if (num_str[0] == '(') {
        num_str++;
        num_str[strlen(num_str)-1] = '\0';
    }
    
    yylval.floatval = atof(num_str);
    return FLOAT_CONST;
}

/*Reconnaît un caractère  entre apostrophes*/
\'[^\']\' {
    yylval.charval = yytext[1];
    return CHAR_CONST;
}

/*Retourne le token correspondant à chaque opérateur/séparateur*/
"+"     { return '+'; }
"-"     { return '-'; }
"*"     { return '*'; }
"/"     { return '/'; }
"("     { return '('; }
")"     { return ')'; }
"{"     { return '{'; }
"}"     { return '}'; }
"["     { return '['; }
"]"     { return ']'; }
","     { return ','; }
";"     { return ';'; }
"="     { return '='; }
":"     { return ':'; }

/*Signale tout caractère non reconnu avec sa position*/
.       { 
    fprintf(stderr, "Ligne %d, Colonne %d : Caractère non reconnu '%s'\n", 
            line_number, column_number, yytext);
    return ERROR;
}
%%

void yyerror(const char *s) {
    fprintf(stderr, "Erreur : %s\n", s);
}
