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

int* get_identifier_value(char *identifier) {
    if (identifier == NULL) {
        printf("Error: NULL identifier passed to get_identifier_value.\n");
       return 0;
    }

    for (int i = 0; i < sizeof(symbol_table)/sizeof(symbol_table[0]); i++) {
        if (strcmp(symbol_table[i].identifier, identifier) == 0) {
            return symbol_table[i].value;
        }
    }
    printf("Identifier not found: %s\n", identifier);
    return 0;
}

void print_string(const char* str) {
    char* tmp = strdup(str + 1);
    tmp[strlen(tmp)-1] = '\0';
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
    char* str;
    int num;
    int intval;
    float floatval;
    char charval;
    char* strval;
}

%token LBRACE RBRACE
%token VAR_GLOBAL DECLARATION INSTRUCTION
%token INTEGER FLOAT CHAR CONST
%token IF ELSE FOR READ WRITE
%token AND OR NOT
%token EQUAL NOT_EQUAL LESS_EQUAL GREATER_EQUAL GREATER LESS
%token <integer> INTEGER_CONSTANT
%token <floating> FLOAT_CONSTANT
%token <str> STRING_LITERAL
%token <string> IDENTIFIER

// Declare the types of the non-terminals
%type <string> relational_operator
%type <integer> expression
%type <boolean> condition
%type <boolean> if_statement 
%type <boolean> else_part
%type <str> write_params
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
    /* vide */ { /* No action needed for empty declarations */ }
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
    /* vide */ { /* No action needed for empty instructions */ }
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
        printf("Condition evaluated as: %d\n", $3);
        if ($3) {
            printf("Executing if block\n");
        }
    }
    ;

else_part:
    /* empty */ { $$ = 0; }
    | ELSE LBRACE instructions RBRACE
    {
        printf("Executing else block\n");
    }
    ;

write_params:
    STRING_LITERAL    { print_string($1); }
    | IDENTIFIER { $$ = get_identifier_value($1); }
    | write_params ',' STRING_LITERAL { print_string($3); }
    | write_params ',' IDENTIFIER    { printf("%s\n", $3); }
    ;

condition:
    expression relational_operator expression 
    { 
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
    | FLOAT_CONSTANT { $$ = $1; }
    | IDENTIFIER { $$ = (char *) get_identifier_value($1); }
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
    return yyparse();
}
