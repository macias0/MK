%{
#include <stdlib.h>
#include <string.h>
#include "def.tab.hh"
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2
extern int yylineno;
int yyerror(const char *,...);
%}
%%
[\+\-\*\/\(\)\^\;\{\}\=]	{return yytext[0];}

main						{return MAIN;};
if							{return IF;}
else						{return ELSE;}

int							{return TYPE_INT;}
real 						{return TYPE_REAL;}
text						{return TYPE_TEXT;}

print						{return PRINT;}
read						{return READ;}

[1-9][0-9]*					{
								yylval.integer = atoi(yytext);
								return INT;
							}	
[A-Za-z_][A-Za-z0-9_]*		{
								fprintf(yyout, "nazwa %s\n", yytext);
								yylval.text = strdup(yytext);
								return ID;
							}
[1-9]+[.]{2}				{
								fprintf(yyout, "float\n");
								yylval.real = atof(yytext);
								return DOUBLE;
							}



\ |\t						{;}
\n							{yylineno++;}
.							{yyerror("Blad leksykalny\n");}
%%
int yyerror(const char *msg,...)
{
	printf("%d: %s", yylineno, msg);
	exit(1);
}

