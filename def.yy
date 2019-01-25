%{
//#include <string.h>
//#include <stdio.h>
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2
#include <iostream>
#include <string>
#include <stack>
#include <fstream>
#include <map>
#include <string>
#include <sstream>
#include <vector>

using namespace std;

extern "C" int yylex();
extern "C" int yyerror(const char* msg,...);

class Variable
{
public:
	enum Type
	{
		None = 0,
		Integer,
		Real,
		Text,
	} valueType;
	//for empty variables with no value
	Variable(Type t, std::string n) 
	{ 
		valueType = t; 
		name = n; 
		cout << "Stworzylem pusta zmienna o nazwie : " << name << endl;
	}
	 
	Variable(int i, std::string n = "") { value.integer = i;  valueType = Integer; name = n;}
	Variable(double d, std::string n = "") { value.real = d;  valueType = Real; name = n;}
	Variable(const char *t, std::string n = "") { value.text = t;  valueType = Text; name = n;}



	std::string name; //variable name if null - then this is literal
	
	union
	{
		int integer;
		double real;
		const char* text;
		
	} value;		
};

std::stack<Variable> variables;

std::map<std::string, Variable::Type> symbols;

std::vector<std::string> asmCode;

Variable::Type tempType;



std::ofstream trojki("trojki.txt", std::ofstream::out);

std::ofstream outputFile("output.asm", std::ofstream::out);

int tempCounter = 0;

void writeOperation(char op);
void generateASM(std::ofstream &stream);
void writeDataSection(std::ofstream &stream);
void writeTextSection(std::ofstream &stream);
std::string getAsmType(Variable::Type type);

void assignment();
void loadVariableToRegister(const Variable &var, int regIndex, std::stringstream &stream);
void asm_print();
void asm_read();


%}

%union
{
	char *text;
	int	integer;
	double real;
}
//%type <text> expr
%token <text> ID
%token <integer> INT
%token <real> DOUBLE
%token MAIN
%token IF
%token ELSE
%token TYPE_INT
%token TYPE_REAL
%token TYPE_TEXT
%token PRINT
%token READ

%%
prog:
	MAIN '{' code '}' 
	{
		cout << "Zajebisty program milordzie\n";
		return 0;
	};

code:
	block {cout << "Code line\n";}
	| code block { cout << "Code multiple block\n";}
	;

block:
	line { cout << "Line\n";}
	| if_stat { cout << "If\n"; };
	


line:
	assign ';' 
	{
		assignment();
	}
	| expr ';'
	| variable_definition ';'
	| PRINT '(' expr ')' ';' 
	{ 
		cout << "Print\n";
		asm_print(); 
	}
	| READ '(' ID ')' ';'
	{
		asm_read();
	}
	;

assign:
	ID '=' expr 
	{ 
		cout << "INstrukcja przypisania do id: " << $1 << "\n";
	}
	|
	variable_definition '=' expr { cout << "Definicja zmiennej z przypisaniem\n";};

// instr:
// 	expr ';'
// 	{
// 		//int expr = stos.top();
// 		//cout << "Obliczone wyrazenie: " << expr  << "\n";
// 	}
// 	;
	
variable_definition:
	type ID 
	{ 
		cout << "Variable definition: " << $2 << endl; 
		symbols[$2] = tempType;
		variables.push(Variable(tempType, $2));
	} 
	;
	
type:
	TYPE_INT {tempType = Variable::Integer;}
	| TYPE_REAL {tempType = Variable::Real;}
	| TYPE_TEXT{tempType = Variable::Text;}
	;
	
if_stat:
	IF '(' expr ')' '{' code '}' { cout << "If statement\n";};

expr:
	expr '+' skladnik	
	{
		cout << "wyrazenie z + \n";
		writeOperation('+');
	}
	|expr '-' skladnik	
	{
		cout << "wyrazenie z - \n";
		writeOperation('-');

	}
	|skladnik		
	{
		cout << "wyrazenie pojedyncze \n";
	};

skladnik:
	skladnik '*' czynnik	
	{
		cout << "skladnik z * \n";
		writeOperation('*');

		
	}
	|skladnik '/' czynnik	
	{
		cout << "skladnik z / \n";
		writeOperation('/');

	}
	|czynnik		
	{
		cout << "skladnik pojedynczy \n";
	};
czynnik:
	ID			
	{
		cout << "Identyfikator\n";
		variables.push(Variable(symbols[$1], $1));
	} 
	|INT			
	{
		cout << "czynnik liczbowy\n";
		variables.push($1);
	}
	|DOUBLE
	{
		cout << "Czynnik double\n";
	}
	|'(' expr ')'		
	{
		cout << "wyrazenie w nawiasach\n";
	};


%%
int main(int argc, char *argv[])
{


	yyparse();


	//cout << "Skonczylem parsowac\n";
	if(argc > 1) //input file
	{}
	if(argc > 2) //output file
	{}
	generateASM(outputFile);
	trojki.close();
	outputFile.close();

	return 0;
}

std::ostream& operator<<(std::ostream& stream, const Variable &variable)
{
	if(variable.name.empty())
	{
		switch(variable.valueType)
		{
			case Variable::Integer:
				stream << variable.value.integer;
				break;
			case Variable::Real:
				stream << variable.value.real;
				break;
			case Variable::Text:
	//		case Variable::Id:
				stream << variable.value.text;
				break;
		}
	}
	else
		stream << variable.name;
	return stream;
}

void loadVariableToRegister(const Variable &var, std::string reg, std::stringstream &stream)
{
	stream << "\t";
	cout << "Laduje zmnienna " << var.name << " typu: " << var.valueType << endl;
	if(!var.name.empty()) //load from variable
	{
		stream << "lw ";// << "$t" << regIndex << ", " << var.name;
	}
	else
		stream << "li ";

	stream << "$" << reg << ", "  << var << endl;
	
	//stream << "\n";
}


void writeOperation(char op)
{
	auto op2 = variables.top();
	variables.pop();
	auto op1 = variables.top();
	variables.pop();

	std::stringstream resultVar;

	resultVar << "temp" << tempCounter++;

	symbols[resultVar.str()] = op1.valueType;

	variables.push(Variable(op1.valueType, resultVar.str()));

	std::stringstream operation;

	loadVariableToRegister(op1, "t0", operation);
	loadVariableToRegister(op2, "t1", operation);

	operation << "\t";
	switch(op)
	{
		case '+':
			operation << "add";
			break;
		case '-':
			operation << "sub";
			break;
		case '*':
			operation << "mul";
			break;
		case '/':
			operation << "div";
			break;
	}

	operation << " $t0, $t0, $t1\n";

	operation << "\tsw $t0, " << resultVar.str() << endl;

	asmCode.push_back(operation.str());

}

void generateASM(std::ofstream &stream)
{
	writeDataSection(stream);
	writeTextSection(stream);
}

void writeDataSection(std::ofstream &stream)
{
	cout << "Tworze data section\n";
	stream << ".data\n";
	auto it = symbols.begin();
	while(it != symbols.end())
	{
		cout << "Wpisuje zmienna " << it->first << endl;
		stream << "\t" << it->first << ":\t" << getAsmType(it->second) << "\t0\n"; 
		++it;
	}
}

void writeTextSection(std::ofstream &stream)
{
	stream << ".text\n";
	auto it = asmCode.begin();
	while(it != asmCode.end())
	{
		stream << *it;
		++it;
	}
}


std::string getAsmType(Variable::Type type)
{
	switch(type)
	{
		case Variable::Integer:
			return ".word";
		case Variable::Real:
			return ".word";
		case Variable::Text:
//		case Variable::Id:
			return ".word";
	}
	return "";
}

void assignment()
{
	cout << "Assignment()\n";
	auto rvalue = variables.top();
	variables.pop();
	cout << "rvalue: " << rvalue << endl;
	auto var = variables.top();
	variables.pop();
	cout << "var: " << var << endl;
	std::stringstream ss;
	loadVariableToRegister(rvalue, "t0", ss);
	ss << "\tsw $t0, " << var.name << endl;
	asmCode.push_back(ss.str());

}

void asm_print()
{
	auto expr = variables.top();
	variables.pop();

	std::stringstream ss;
	int op;
	switch(expr.valueType)
	{
		case Variable::Integer:
			op = 1;
			break;
		case Variable::Real:
			op = 2;
			break;
		case Variable::Text:
			op = 4;
			break;
	}
	ss << "\tli $v0, " << op << endl;
	loadVariableToRegister(expr, "a0", ss);
	ss << "\tsyscall\n"; 

	asmCode.push_back(ss.str());
}

void asm_read()
{
	auto var = variables.top();
	variables.pop();
	std::stringstream ss;
	int op;
	switch(var.valueType)
	{
		case Variable::Integer:
			op = 5;
			break;
		case Variable::Real:
			op = 6;
			break;
		case Variable::Text:
			//op = 4;
			break;
	}
	ss << "\tli $v0, " << op << endl;
	ss << "\tsyscall\n";
	ss << "\tsw $v0, " << var << endl;

	asmCode.push_back(ss.str());
}