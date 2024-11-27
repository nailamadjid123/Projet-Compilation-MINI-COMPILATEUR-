%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lex.yy.h"
#include <stdbool.h>

extern int yylineno;


void yyerror(const char *s);
int yylex();

int evaluate_condition(int left, char* op, int right) {
    if (op == NULL) {
        fprintf(stderr, "Error: NULL relational operator!\n");
        return 0;  
    }

    if (strcmp(op, "==") == 0) return left == right;
    if (strcmp(op, "!=") == 0) return left != right;
    if (strcmp(op, "<") == 0) return left < right;
    if (strcmp(op, "<=") == 0) return left <= right;
    if (strcmp(op, ">") == 0) return left > right;
    if (strcmp(op, ">=") == 0) return left >= right;

    return 0; 
}


typedef struct {
    char* identifier;
    int value;
} Symbol;

Symbol symbol_table[] = {
    {"A", 5},
    {"B", 10},
};

int get_identifier_value(char *identifier) {
    if (identifier == NULL) {
        printf("Error: NULL identifier passed to get_identifier_value.\n");
        return 0;
    }

    for (int i = 0; i < sizeof(symbol_table)/sizeof(symbol_table[0]); i++) {
        printf("Checking identifier: %s\n", symbol_table[i].identifier);
        if (strcmp(symbol_table[i].identifier, identifier) == 0) {
            printf("Found value for %s: %d\n", identifier, symbol_table[i].value);
            return symbol_table[i].value;
        }
    }
    printf("Identifier not found: %s\n", identifier);
    return 0;
}



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
    char *string;
    char *operator;
    int boolean;
}

%token LBRACE RBRACE
%token VAR_GLOBAL DECLARATION INSTRUCTION
%token INTEGER FLOAT CHAR CONST
%token IF ELSE FOR READ WRITE
%token AND OR NOT
%token EQUAL NOT_EQUAL LESS_EQUAL GREATER_EQUAL GREATER LESS
%token STRING_LITERAL
%token <string> IDENTIFIER
%token <integer> INTEGER_CONSTANT
%token <floating> FLOAT_CONSTANT



// Declare the types of the non-terminals
%type <string> relational_operator
%type <string> write_params
%type <integer> expression
%type <boolean> condition
%type <boolean> if_statement 
%type <boolean> else_part


/* Define operator precedence */
%left OR
%left AND
%left EQUAL NOT_EQUAL LESS_EQUAL GREATER_EQUAL GREATER LESS
%left '+' '-'
%left '*' '/'


%%

program:
    VAR_GLOBAL LBRACE declarations RBRACE declaration_block instruction_block
    ;

declaration_block:
    DECLARATION LBRACE declarations RBRACE
    ;

declarations:
    /* vide */
    | declarations declaration
    ;

declaration:
    type var_list ';'
    | CONST type IDENTIFIER '=' constant_value ';'
    ;

type:
    INTEGER
    | FLOAT
    | CHAR
    ;

var_list:
    IDENTIFIER
    | var_list ',' IDENTIFIER
    ;

constant_value:
    INTEGER_CONSTANT
    | FLOAT_CONSTANT
    | STRING_LITERAL
    ;

instruction_block:
    INSTRUCTION LBRACE instructions RBRACE
    ;

instructions:
    /* vide */
    | instructions instruction
    ;

instruction:
    IDENTIFIER '=' expression ';'
    | if_statement
    | FOR '(' IDENTIFIER '=' expression ':' expression ':' expression ')' LBRACE instructions RBRACE
    | READ '(' IDENTIFIER ')' ';'
    | WRITE '(' write_params ')' ';'
    ;

if_statement:
    IF '(' condition ')' 
    LBRACE instructions RBRACE 
    else_part
    {
        $$ = $3;
        printf("Condition evaluated as: %d\n", $$);  // Debugging output
        if ($$) {
            printf("Executing if block\n");
        }
    }
    
    ;

else_part:
    /* empty */
    | ELSE LBRACE instructions RBRACE
    {
        printf("In else_part, condition is: %d\n", $$);  // Debugging output
        if (!$$) {
            printf("Executing else block\n");
        }
    }
    ;

write_params:
    STRING_LITERAL    { print_string(yytext); }
    | IDENTIFIER { $$ = get_identifier_value(yytext); }
    | write_params ',' STRING_LITERAL { print_string(yytext); }
    | write_params ',' IDENTIFIER    { printf("%s\n", yytext); }
    ;

condition:
    expression relational_operator expression 
    { 
        printf("Relational operator: %s\n", $2); 
        $$ = evaluate_condition($1, $2, $3);
    }
    | '(' condition ')' { $$ = $2; }
    | condition AND condition 
    { 
        $$ = $1 && $3;
    }
    | condition OR condition 
    { 
        $$ = $1 || $3;
    }
    ;

relational_operator:
    EQUAL            { $$ = "=="; }
  | NOT_EQUAL        { $$ = "!="; }
  | LESS_EQUAL       { $$ = "<="; }
  | GREATER_EQUAL    { $$ = ">="; }
  | GREATER          { $$ = ">"; }
  | LESS             { $$ = "<"; }
  ;

expression:
    INTEGER_CONSTANT { $$ = $1; }
    | FLOAT_CONSTANT { $$ = $1; }  // $1 est du type float
    | IDENTIFIER { $$ = get_identifier_value(yytext); }
    | expression '+' expression { $$ = $1 + $3; }
    | expression '-' expression { $$ = $1 - $3; }
    | expression '*' expression { $$ = $1 * $3; }
    | expression '/' expression { $$ = $1 / $3; }
    | '(' expression ')' { $$ = $2; }
    ;
%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s at line %d\n", s, yylineno);
}


int main() {
    //yydebug = 1;
    return yyparse();
}
