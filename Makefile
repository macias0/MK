

C=gcc
CPP=g++
LEX=flex
BIS=bison


all: comp


comp:		def.tab.o lex.yy.o
			$(CPP) -std=c++11 lex.yy.o def.tab.o -o compiler -ll

lex.yy.o:	lex.yy.c
			$(C) -c lex.yy.c
			
lex.yy.c:	lex.l
			$(LEX) lex.l
			
def.tab.o:	def.tab.cc
			$(CPP) -std=c++11 -c def.tab.cc
			
def.tab.cc:	def.yy
			$(BIS) -d def.yy

			