%option noyywrap

%{
#include <bits/stdc++.h>
#include "SymbolTable.h"

#include"y.tab.h"


using namespace std;

extern int count_line;
extern ofstream logprint;
extern SymbolTable symtable;

void countLine(char *arr) {
	for (int i=0; i < strlen(arr); i++) {
		if (arr[i] == '\n') {
			count_line++;
		}
	}
}
%}


WHITESPACE [ \t\f\r\v]+
LETTER [a-zA-Z]
DIGIT [0-9]

FLOAT_LITERALS {DIGIT}+?(\.{DIGIT}+)?([Ee][+-]?{DIGIT}+)?
CHARACTERS [a-zA-Z0-9]
NEWLINE \n

RELOP ("<"|"<="|">"|">="|"=="|"!=")
LOGICOP ("&&"|"||")
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
%%

{WHITESPACE} { }

{NEWLINE} { count_line++; }

"if"	{
		return IF;
		}

"for"	{
		return FOR;
		}

"do"	{
		return DO;
		}


"int"	{
		return INT;
		}

"float"	{
		return FLOAT;
		}

"void"	{
		return VOID;
		}



"else"	{
		return ELSE;
		}


"while"	{
		return WHILE;
		}

"char"	{
		return CHAR;
		}


"return" {
		return RETURN;
		}


"continue" {
		return CONTINUE;
		}


"switch" {
		return SWITCH;
		}

"break"	{
		return BREAK;
		}

"case"	{
		return CASE;
		}

"default"	{
		return DEFAULT;
		}

"double"	{
		return DOUBLE;
		}

"printf" { return PRINTLN; }

{DIGIT}+ 	{


		SymbolInfo *symbolinfo = new SymbolInfo();
		symbolinfo->setName(yytext);
		symbolinfo->setType("CONST_INT");
		yylval.symbol = symbolinfo;
		return CONST_INT;
}
{FLOAT_LITERALS} {


		SymbolInfo *symbolinfo = new SymbolInfo();
		symbolinfo->setName(yytext);
		symbolinfo->setType("CONST_FLOAT");
		yylval.symbol = symbolinfo;
		return CONST_FLOAT;
			}



"+" 	|
"-"  	{
			//tokenout<<"<ADDOP, " <<yytext<<">";
			//logout<<"Line no : "<<line_count<<" TOKEN <ADDOP> Lexeme "<<yytext<<" found\n"<<endl;
		SymbolInfo *symbolinfo = new SymbolInfo();
		symbolinfo->setName(yytext);
		symbolinfo->setType("ADDOP");
		yylval.symbol = symbolinfo;
		return ADDOP;
		}



"*"		|
"/"		|
"%"		 {
			//tokenout<<"<MULOP, " <<yytext<<">";
			//logout<<"Line no :  "<<line_count<<" TOKEN <MULOP> Lexeme "<<yytext<<" found\n"<<endl;
		SymbolInfo *symbolinfo = new SymbolInfo();
		symbolinfo->setName(yytext);
		symbolinfo->setType("MULOP");
		yylval.symbol = symbolinfo;
		return MULOP;
		}



{RELOP} {
			//tokenout<<"<RELOP, " <<yytext<<">";
			//logout<<"Line no :  "<<line_count<<" TOKEN <RELOP> Lexeme "<<yytext<<" found\n"<<endl;
		SymbolInfo *symbolinfo = new SymbolInfo();
		symbolinfo->setName(yytext);
		symbolinfo->setType("RELOP");
		yylval.symbol = symbolinfo;
		return RELOP;

		}


{LOGICOP} {
			//tokenout<<"<LOGICOP, " <<yytext<<">";
			//logout<<"Line no : "<<line_count<<" TOKEN <LOGICOP> Lexeme "<<yytext<<" found\n"<<endl;
		SymbolInfo *symbolinfo = new SymbolInfo();
		symbolinfo->setName(yytext);
		symbolinfo->setType("LOGICOP");
		yylval.symbol = symbolinfo;
		return LOGICOP;
		}





"++"	{
		return INCOP;
		}

"--"	{
		return DECOP;
		}

"=" {
		return ASSIGNOP;
		}

"!"		{
		return NOT;
		}

"("		{
		return LPAREN;
		}

")"		{
		return RPAREN;
		}

"{"		{
		return LCURL;
		}


"}"		{
		return RCURL;
		}


"["		{
		return LTHIRD;
		}

"]"		{
		return RTHIRD;
		}

","		 {
		return COMMA;
		}

";"	 	{
		return SEMICOLON;
		}






{IDENTIFIER} {


		SymbolInfo *symbolinfo = new SymbolInfo();
		symbolinfo->setName(yytext);
		symbolinfo->setType("ID");
		yylval.symbol = symbolinfo;
		return ID;
}




%%

