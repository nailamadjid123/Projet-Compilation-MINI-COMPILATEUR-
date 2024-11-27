
%{

 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "syntaxessai.tab.h"




int line_number = 1;
int column_number = 1;



void yyerror(const char *s);
%}




%option noyywrap


DIGIT       [0-9]
LETTER      [A-Z]
LOWERCASE   [a-z]
WHITESPACE  [ \t]



%%



"%%".*              { /* Ignore single-line comments */ }



{WHITESPACE}+       { column_number += yyleng; }

\n                  { line_number++; column_number = 1; }



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
"&&"                    { return AND; }
"||"                    { return OR; }
"!"                     { return NOT; }

"=="                    { return EQUAL; }
"!="                    { return NOT_EQUAL; }
"<="                    { return LESS_EQUAL; }
">="                    { return GREATER_EQUAL; }
">"                     { return GREATER; }
"<"                     { return LESS; }
"{"                     { return LBRACE; } 
"}"                     { return RBRACE; }  



[0-9]+                  { return INTEGER_CONSTANT; }
[0-9]+\.[0-9]+          { return FLOAT_CONSTANT; }
\"[^\"\n]*\"            { return STRING_LITERAL; }


{LETTER}({LETTER}|{DIGIT}){0,7} {
   
    if (yyleng > 8) {
        yyerror("Identifier exceeds 8 characters");
        return ERROR;
    }
    
    yylval.strval = strdup(yytext);
    return IDENTIFIER;
}

"("?[-+]?{DIGIT}+")"? {
    char *num_str = yytext;

    
    if (num_str[0]) == '(') {
        num_str++;
        num_str[strlen(num_str)-1] = '\0';
    }

   
    int val = atoi(num_str);
    if (val < -32768 || val > 32767) {
        yyerror("Integer out of range (-32768 to 32767)");
        return ERROR;
    }
    yylval.intval = val;
    return INT_CONST;
}

"("?[-+]?{DIGIT}+"."{DIGIT}+")"? {
    char *num_str = yytext;
    if (num_str[0] )== '(') {
        num_str++;
        num_str[strlen(num_str)-1] = '\0';
    }
    
    yylval.floatval = atof(num_str);
    return FLOAT_CONST;
}

\'[^\']\' {
    yylval.charval = yytext[1];
    return CHAR_CONST;
}


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


.       { 
    fprintf(stderr, "Ligne %d, Colonne %d : Caractère non reconnu '%s'\n", 
            line_number, column_number, yytext);
    return ERROR;
}
%%

void yyerror(const char *s) {
    fprintf(stderr, "Erreur : %s\n", s);
}
