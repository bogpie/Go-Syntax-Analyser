%option noyywrap
%{
/* exemplu.l */
#include <stdio.h>
int nc = 0;
%}
%%
[0-9]+ {printf("sir format din cifre: %s\n", yytext);}
[a-zA-Z]+ {printf("sir format din litere: %s\n", yytext);}
.|\n {;}
%%

main()
{
    yylex();
}