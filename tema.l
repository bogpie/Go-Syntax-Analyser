/* Options */
%option noyywrap yylineno

/* Libraries, C macro-definitions, global variables, auxiliary functions used in RegEx code*/
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #define NO_FUNCTIONS 100
    #define ERROR_LENGTH 100
    #define NO_TYPES 4
    #define NO_LETTERS 26

    #define PENDING -1
    #define INACTIVE 0
    #define INT 1
    #define FLOAT32 2
    #define STRING 3
    #define BOOL 4
    int stringFirstToType[26];

    char error[ERROR_LENGTH];
    char** functions;
    char** types;
    int noFunctions = 0;

    int noParameters = 0;
    int isReturnable = 0;
    int returnedType = 0;
    int isDeclare = 0;
    int varType[26];

    int varQueue[26];
    int varQueueSize = 0;
    int typeQueue[26];
    int typeQueueSize = 0;

    void printError(char* error){
        printf("line %d: %s\n", yylineno, error);
    }

    void resetFunction()
    {
        noParameters = 0;
        isReturnable = 0;
        returnedType = 0;
        varQueueSize = 0;
        typeQueueSize = 0;
        for(int idLetter = 0; idLetter < NO_LETTERS; ++idLetter){
            varType[idLetter] = INACTIVE;
        }
    }


%}


/* RegEx macro-definitions and states */
Type "int"|"float32"|"string"|"bool"
Letter [A-Za-z]
Word [A-Za-z]*
Digit [0-9]
Sign [+-]?
Natural {Digit}+ 
Int {Sign}{Natural}
Float32 {Sign}{Natural}\.{Natural}?
Bool "true"|"false"
String ["].*["]

%x COMMENT FUNCTION ARGUMENTS FUNCTION_TYPE BODY DECLARE_AND_ASSIGN

/* Rules for RegEx */
%%

"/*"    BEGIN(COMMENT); // Multi-line comment
[//].* ; // Single-line comment

<INITIAL>{
    "func" BEGIN(FUNCTION);
  
}

<FUNCTION>{
    "}" BEGIN(INITIAL);
    
    [A-Za-z_]+\( {
        // function name followed by bracket
        yytext[strlen(yytext) - 1] = '\0'; 
        int length = strlen(yytext);
        functions[noFunctions++] = (char*)malloc(length);
        strcpy(functions[noFunctions - 1], yytext);
        for (int idFunction = 0; idFunction < noFunctions - 1; ++idFunction) {
            if(!strcmp(functions[idFunction], yytext)){
                sprintf(error, "'%s' redeclared in this file", yytext); 
                printError(error);
            }
        }
        // printf("Function name is: %s\n", functions[noFunctions - 1]);
        BEGIN(ARGUMENTS);
    }

    . ;

    \n ;
}

<ARGUMENTS>{
    [)] {
        BEGIN(FUNCTION_TYPE);
    }

    {Type} {
        for(int idLetter = 0; idLetter < NO_LETTERS; ++idLetter){
            if(varType[idLetter] == PENDING){
                varType[idLetter] = stringFirstToType[yytext[0] - 'a'];
            }
        }
    }

    {Word} {
        // mark variable type as pending (name is one letter)
        varType[yytext[0] - 'a'] = PENDING; 
    }

    .|\n ;
}

<FUNCTION_TYPE>{
    {Type} {
        isReturnable = 1;
        returnedType = stringFirstToType[yytext[0] - 'a'];
    }

    [{] {
        BEGIN(BODY);
    }

    .|\n ;
}

<BODY>{
    "return "{Letter} {
        if (isReturnable == 0){
            strcpy(error, "Too many arguments to return");
            printError(error);
        }
        else {
            int actualType = varType[yytext[7] - 'a']; // trim "return " 

            if(returnedType != actualType){
                sprintf(error, "Invalid return type for function '%s'", functions[noFunctions - 1]);
                printError(error);
            }
        }
    }

    "var" {
    }

    {Type} {
        for(int idLetter = 0; idLetter < NO_LETTERS; ++idLetter){
            if(varType[idLetter] == PENDING){
                varType[idLetter] = stringFirstToType[yytext[0] - 'a'];
            }
        }
    }


    {Letter} {
        varQueue[varQueueSize++] = yytext[0] - 'a';
        if(varType[yytext[0]-'a'] == INACTIVE){
            varType[yytext[0] - 'a'] = PENDING;
        }
    }

    ":="|"=" {
        if(!strcmp(yytext, ":=")) {
            isDeclare = 1; // mark if operator is ":=" (declare and assign) instead of "=" (assign)
        }
        else{
            isDeclare = 0;
        }
        int isError = 0;
        for(int idVarQueued = 0; idVarQueued < varQueueSize; ++idVarQueued){
            int idVar = varQueue[idVarQueued];

            if(varType[idVar] > INACTIVE && isDeclare == 1){
                strcpy(error, "No new variables on the left side of :=");
                varQueueSize = 0; 
                typeQueueSize = 0;
                printError(error);
                isError = 1;
                break;
            }
        }
        if(isError == 0) {
            BEGIN(DECLARE_AND_ASSIGN);
        }

    }

    [}] {
        resetFunction();
        BEGIN(INITIAL);
    }

    .|\n ;
}

<DECLARE_AND_ASSIGN>{
    {String} {
        typeQueue[typeQueueSize++] = STRING;
    }
    
    {Bool} {
        typeQueue[typeQueueSize++] = BOOL;
    }

    {Float32} {
        typeQueue[typeQueueSize++] = FLOAT32;
    }

    {Int} {
        typeQueue[typeQueueSize++] = INT;
    }

    {Letter} {
        typeQueue[typeQueueSize++] = varType[yytext[0] - 'a'];
    }

    . {
    }

    \n {
        for (int idQueued = 0; idQueued < varQueueSize; ++idQueued){
            int idVar = varQueue[idQueued];

            // if type was already mentioned for the variable
            if(varType[idVar] > INACTIVE && isDeclare == 0) {

                if(varType[idVar] != typeQueue[idQueued]){   
                    --yylineno; // newline spotted, yylineno was already incremented
                    sprintf(error, "(%s) cannot be represented by the (%s)", 
                    types[typeQueue[idQueued]], 
                    types[varType[idVar]]);
                    printError(error);
                    ++yylineno;
                }
            }
            else {
                varType[idVar] = typeQueue[idQueued];
            }
        }
        varQueueSize = typeQueueSize = 0;
        BEGIN(BODY);
     }
}

<COMMENT>{
    "*/" BEGIN(INITIAL); // end comment
    [^*\n]+ ; // eat comment in chunks
    "*" ; // eat the lone star
    \n ; // lineNo++;  // track the number of lines
}

.|\n ;
%%

/* C-code */
char** initializeTypes()
{
    types = (char**)malloc(sizeof(char*) * (NO_TYPES + 1) ); 
    // we index from 1 so we can keep type 0 for inactive variables

    types[INT] = (char*)malloc(3);
    strcpy(types[INT], "int");

    types[FLOAT32] = (char*)malloc(7);
    strcpy(types[FLOAT32], "float32");

    types[STRING] = (char*)malloc(6);
    strcpy(types[STRING], "string");

    types[BOOL] = (char*)malloc(3);
    strcpy(types[BOOL], "bool");

    stringFirstToType['i' - 'a'] = INT; 
    stringFirstToType['f' - 'a'] = FLOAT32; 
    stringFirstToType['s' - 'a'] = STRING; 
    stringFirstToType['b' - 'a'] = BOOL; 

    return types;
}

int main(int argc, char *argv[])
{
    if (argc < 1)
    {
        fprintf(stderr, "Usage: ./exec file\n");
        return 0;
    }

    FILE *input = fopen(argv[1], "r");
    yyin = input;
    if(!yyin)
    {
        fprintf(stderr, "File doesn't exist\n");
    }

    functions = (char**)malloc(sizeof(char*) * NO_FUNCTIONS);

    types = initializeTypes();

    yylex();
    return 0; 
}