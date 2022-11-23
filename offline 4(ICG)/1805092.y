%{
#include<bits/stdc++.h>
#include <string.h>
#include"SymbolTable.h"


using namespace std;


int count_line = 1;
int count_error = 0;


vector<parameter> declaredSymbols;
vector<FunctionDef> declaredFunctions;
vector<parameter> declaredArrays;
string parameterCode = "";
extern FILE *yyin;
ofstream errorprint;
ofstream logprint;
vector<gVar> declaredGlobalVars;
// FILE *asmFile;
// FILE *optimizedAsmFile;
ofstream asmFile;
ofstream optimizedAsmFile;



string funcReturnType="Undeclared";
FILE *infile;

SymbolTable symtable(30);



int tempCount = 0;
int labelCount = 0;
int yyparse(void);
int yylex(void);

void yyerror(const char *s){
	logprint << "Error at line " << count_line << ": Syntax Error\n"<<endl;
	errorprint << "Error at line " << count_line << ": Syntax Error\n"<<endl;
	count_error++;

}
//Function to split the string
vector<string> splitString(string line, char delim) {

    stringstream ss(line);
    vector<string> tokens;
    string intermediate;

    while(getline(ss, intermediate, delim)) {
        tokens.push_back(intermediate);
    }
    return tokens;
}

void addPrintProc(ofstream & asm_file)
{
    string code = "";

    code += "PRINTLN PROC NEAR\n";
    code += "\tPUSH AX\n";
    code += "\tPUSH BX\n";
    code += "\tPUSH CX\n";
    code += "\tPUSH DX\n";
    code += "\t\n";
    code += "\tMOV AX, varPrint\n";
    code += "\tOR AX, AX\n";
    code += "\tJGE @END_IF1\n";
    code += "\tPUSH AX\n";
    code += "\tMOV DL, '-'\n";
    code += "\tMOV AH, 2\n";
    code += "\tINT 21H\n";
    code += "\tPOP AX\n";
    code += "\tNEG AX\n";
    code += "\n";
    code += "@END_IF1:\n";
    code += "\tXOR CX, CX\n";
    code += "\tMOV BX, 10D\n";
    code += "\n";
    code += "@REPEAT:\n";
    code += "\tXOR DX, DX\n";
    code += "\tDIV BX\n";
    code += "\tPUSH DX\n";
    code += "\tINC CX\n";
    code += "\tOR AX, AX\n";
    code += "\tJNE @REPEAT\n";
    code += "\tMOV AH, 2\n";
    code += "\n";
    code += "@PRINT_LOOP:\n";
    code += "\tPOP DX\n";
    code += "\tOR DL, 30H\n";
    code += "\tINT 21H\n";
    code += "\tLOOP @PRINT_LOOP\n";
    code += "\tMOV DL, 0DH\n";
    code += "\tMOV AH, 2\n";
    code += "\tINT 21H\n";
    code += "\tMOV DL, 0AH\n";
    code += "\tMOV AH, 2\n";
    code += "\tINT 21H\n";
    code += "\tPOP DX\n";
    code += "\tPOP CX\n";
    code += "\tPOP BX\n";
    code += "\tPOP AX\n";
    code += "\tRET\n";
    code += "\n";
    code += "PRINTLN ENDP\n";

    asmFile<<code<<endl;
}


void initAsmFile(ofstream & asm_file, vector<gVar> globalList)
{
    string code = "";

    code += ".MODEL SMALL\n";
    code += ".STACK 100h\n";
    code += "\n";
    code += ".DATA\n";
    code += "varPrint DW ?\n";



	asm_file<<code.c_str()<<endl;

    for (int i = 0; i < globalList.size(); i++)
    {
        if (globalList[i].getSize() == 0)
        {
           
		   asm_file<<globalList[i].getName()<<" DW ?"<<endl;
        }
        else
        {
     
			asm_file<<globalList[i].getName()<< " DW " << to_string(globalList[i].getSize()) << " DUP(?)"<<endl;
        }
    }

   asm_file<<"";
   asm_file<<".CODE"<<endl;
}

string newTemp() {
	string temp = "temp" + to_string(tempCount++);
	declaredGlobalVars.push_back({ temp, 0 });
	return temp;
}

string newLabel() {
	return "label" + to_string(labelCount++);
}

string getGlobalName(string varName, SymbolTable st) {
    return varName + to_string(st.getScopeNum());
}




%}



%union{
	SymbolInfo *symbol;
}



%token FLOAT INT DO WHILE FOR IF ELSE BREAK CASE CONTINUE DEFAULT RETURN 
%token INCOP DECOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD
%token COMMA SEMICOLON PRINTLN SWITCH VOID CHAR DOUBLE 

%token <symbol> ID
%token <symbol> CONST_INT
%token <symbol> CONST_FLOAT


%token <symbol> ADDOP MULOP RELOP LOGICOP

%type <symbol> type_specifier
%type <symbol> start program unit var_declaration variable declaration_list
%type <symbol> expression_statement func_declaration parameter_list func_definition
%type <symbol> statements unary_expression factor statement arguments compound_statement 
%type <symbol> expression logic_expression simple_expression rel_expression term argument_list


%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%



start
:
program{

	
	$$ = $1;
	logprint << "Line " << count_line << ": start : program"<<endl;
	logprint<<endl;

	string AsmCodeTotal= $1->getCode();
	if(count_error==0)
	{
		asmFile.open("code.asm");
		optimizedAsmFile.open("optimizedCode.asm");
		initAsmFile(asmFile, declaredGlobalVars );
		addPrintProc(asmFile);
		asmFile<<AsmCodeTotal<<endl;

		asmFile.close();
		optimizedAsmFile.close();


	}
}
;



program
:
program unit
{
	logprint << "Line " << count_line << ": program : program unit";
	logprint<<endl;
	
	$$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "program");
	$$->setCode($1->getCode() + $2->getCode());
	logprint<<$$->getName()<<endl;
	//symtable.printAllScopeTable(logprint);
	
	logprint<<endl;
}
|
unit
{
	logprint << "Line " << count_line << ": program : unit";
	logprint<<endl;
	
	$$ = new SymbolInfo($1->getName(), "program");
	$$=$1;

	logprint<<$$->getName()<<endl;

	logprint<<endl;
}
;

unit
:
var_declaration
{
	logprint << "Line " << count_line << ": unit :  var_declaration"<<endl;
	logprint<<endl;
//symtable.printAllScopeTable(logprint);
	$$ = $1;
	logprint<< $$->getName()<<endl;

	logprint<<endl;
}

|

func_declaration
{
	logprint << "Line " << count_line << ": unit :  func_declaration"<<endl;
	logprint<<endl;
//	symtable.printAllScopeTable(logprint);
	$$ = $1;
	logprint<< $$->getName()<<endl;

	logprint<<endl;
}
|

func_definition
{
	logprint << "Line " << count_line << ": unit :  func_definition";
	logprint<<endl;
	//symtable.printAllScopeTable(logprint);
	$$ = $1;
	//cout<< $$->getCode()<<endl;
	//$$->setCode("hi"+ $1->getCode());
	logprint<< $$->getName()<<endl;

	logprint<<endl;
}
;

func_declaration
:
type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
{
	logprint << "Line " << count_line << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON";
	logprint<<endl;

	vector<string> typeName;
	vector<parameter> ListofParamters;
    vector<string> params ;
	string parname= $4->getName();
	bool isParOne=true;
	for(int i=0; i<parname.size(); i++)
	{
		if(parname[i]==',')
		isParOne=false;

	}
	if(isParOne) params.push_back(parname);
	else	params = splitString(parname, ',');
	bool ParamNameExists=false;

	// for(int i=0;i<params.size(); i++)
	// 	cout<<params[i]<<endl;
	string ftype = $1->getName();
    for (string curParam: params)
    {

		
		//cout<<curParam<<endl;
		ParamNameExists=false;
		for(int i=0;i<curParam.size(); i++)
		{
			if(curParam[i]== ' '){
				ParamNameExists=true;
				//break;
			}
		}
        
		
		
		if(!ParamNameExists){
			typeName.push_back(curParam);
	
			string aim= "dummy"+to_string(rand());
			typeName.push_back(aim);
			
			
		}

		else typeName = splitString(curParam, ' ');
		//cout<<typeName[1]<<" "<<typeName[0]<<endl;
		
        ListofParamters.push_back(parameter(typeName[1],typeName[0]));
		typeName.clear();
    }

	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	if(dupID!=nullptr)
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  "Multiple declaration of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  "Multiple declaration of '" << $2->getName() << "'"<<endl;

	}

	else
	{
		string name= $2->getName();
	//	string type= $1->getType();
	
		

	//	cout<<ListofParamters.size()<<endl;



		SymbolInfo* temp= new SymbolInfo(name,"ID", ListofParamters,-1,false);
		
		//temp->setIsDefined(false);

		symtable.InsertSI(temp);
		declaredSymbols.push_back(parameter(name, "function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters,ParamNameExists));
	}
	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
	logprint<< $$->getName()<<endl;
	logprint<<endl;
}
|
type_specifier ID LPAREN parameter_list RPAREN error //int main( int a, int b)
{
	logprint<<" expected ; at the end of the line"<<endl;
	logprint<<endl;

	logprint << "Line " << count_line << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN ";
	logprint<<endl;




vector<string> typeName;
	vector<parameter> ListofParamters;
    vector<string> params ;
	string parname= $4->getName();
	bool isParOne=true;
	for(int i=0; i<parname.size(); i++)
	{
		if(parname[i]==',')
		isParOne=false;

	}
	if(isParOne) params.push_back(parname);
	else	params = splitString(parname, ',');

	bool ParamNameExists=false;
	// for(int i=0;i<params.size(); i++)
	// 	cout<<params[i]<<endl;
	string ftype = $1->getName();
    for (string curParam: params)
    {

		
		//cout<<curParam<<endl;
		 ParamNameExists=false;
		for(int i=0;i<curParam.size(); i++)
		{
			if(curParam[i]== ' '){
				ParamNameExists=true;
				//break;
			}
		}
        
		
		
		if(!ParamNameExists){
			typeName.push_back(curParam);
	
			string aim= "dummy"+to_string(rand());
			typeName.push_back(aim);
			
			
		}

		else typeName = splitString(curParam, ' ');
		//cout<<typeName[1]<<" "<<typeName[0]<<endl;
		
        ListofParamters.push_back(parameter(typeName[1],typeName[0]));
		typeName.clear();
    }

	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	if(dupID!=nullptr)
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  "Multiple declaration of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  "Multiple declaration of '" << $2->getName() << "'"<<endl;

	}

	else
	{
		string name= $2->getName();
	//	string type= $1->getType();
	
		

	//	cout<<ListofParamters.size()<<endl;



		SymbolInfo* temp= new SymbolInfo(name,"ID", ListofParamters,-1,false);
		//temp->setIsDefined(false);

		symtable.InsertSI(temp);
		declaredSymbols.push_back(parameter(name, "function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters,ParamNameExists));
	}
	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
	logprint<< $$->getName()<<endl;
	logprint<<endl;
}
|
type_specifier ID LPAREN parameter_list error RPAREN SEMICOLON  // to handle like: void foo(int x-y);
{
		logprint << "Line " << count_line << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON";
	logprint<<endl;

	vector<string> typeName;
	vector<parameter> ListofParamters;
    vector<string> params ;
	string parname= $4->getName();
	bool isParOne=true;
	for(int i=0; i<parname.size(); i++)
	{
		if(parname[i]==',')
		isParOne=false;

	}
	if(isParOne) params.push_back(parname);
	else	params = splitString(parname, ',');

	bool ParamNameExists=false;
	// for(int i=0;i<params.size(); i++)
	// 	cout<<params[i]<<endl;
	string ftype = $1->getName();
    for (string curParam: params)
    {

		
		//cout<<curParam<<endl;
		ParamNameExists=false;
		for(int i=0;i<curParam.size(); i++)
		{
			if(curParam[i]== ' '){
				ParamNameExists=true;
				//break;
			}
		}
        
		
		
		if(!ParamNameExists){
			typeName.push_back(curParam);
	
			string aim= "dummy"+to_string(rand());
			typeName.push_back(aim);
			
			
		}

		else typeName = splitString(curParam, ' ');
		//cout<<typeName[1]<<" "<<typeName[0]<<endl;
		
        ListofParamters.push_back(parameter(typeName[1],typeName[0]));
		typeName.clear();
    }

	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	if(dupID!=nullptr)
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  "Multiple declaration of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  "Multiple declaration of '" << $2->getName() << "'"<<endl;

	}

	else
	{
		string name= $2->getName();
	//	string type= $1->getType();
	
		

	//	cout<<ListofParamters.size()<<endl;



		SymbolInfo* temp= new SymbolInfo(name,"ID", ListofParamters,-1,false);
		//temp->setIsDefined(false);

		symtable.InsertSI(temp);
		declaredSymbols.push_back(parameter(name, "function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters,ParamNameExists));
	}
	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
	logprint<< $$->getName()<<endl;
	logprint<<endl;
}
|
type_specifier ID LPAREN parameter_list error RPAREN error  //to handle error like: void foo(int x-y)
{
	logprint << "Line " << count_line << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN ";
	logprint<<endl;

	vector<string> typeName;
	vector<parameter> ListofParamters;
    vector<string> params ;
	string parname= $4->getName();
	bool isParOne=true;
	for(int i=0; i<parname.size(); i++)
	{
		if(parname[i]==',')
		isParOne=false;

	}
	if(isParOne) params.push_back(parname);
	else	params = splitString(parname, ',');

	bool ParamNameExists=false;
	// for(int i=0;i<params.size(); i++)
	// 	cout<<params[i]<<endl;
	string ftype = $1->getName();
    for (string curParam: params)
    {

		
		//cout<<curParam<<endl;
		 ParamNameExists=false;
		for(int i=0;i<curParam.size(); i++)
		{
			if(curParam[i]== ' '){
				ParamNameExists=true;
				//break;
			}
		}
        
		
		
		if(!ParamNameExists){
			typeName.push_back(curParam);
	
			string aim= "dummy"+to_string(rand());
			typeName.push_back(aim);
			
			
		}

		else typeName = splitString(curParam, ' ');
		//cout<<typeName[1]<<" "<<typeName[0]<<endl;
		
        ListofParamters.push_back(parameter(typeName[1],typeName[0]));
		typeName.clear();
    }

	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	if(dupID!=nullptr)
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  "Multiple declaration of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  "Multiple declaration of '" << $2->getName() << "'"<<endl;

	}

	else
	{
		string name= $2->getName();
	//	string type= $1->getType();

		SymbolInfo* temp= new SymbolInfo(name,"ID", ListofParamters,-1,false);
		//temp->setIsDefined(false);

		symtable.InsertSI(temp);
		declaredSymbols.push_back(parameter(name, "function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters,ParamNameExists));
	}
	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
	logprint<< $$->getName()<<endl;
	logprint<<endl;
}

|

type_specifier ID LPAREN RPAREN SEMICOLON
{
	logprint << "Line " << count_line << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON";
	logprint<<endl;

	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	if(dupID!=nullptr)
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  " Multiple declaration of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  " Multiple declaration of '" << $2->getName() << "'"<<endl;

	}

	else
	{
		string name= $2->getName();
		string ftype= $1->getType();

		vector<parameter> ListofParamters;
		SymbolInfo* temp= new SymbolInfo(name,"ID", ListofParamters,-1,false);
		//temp->setIsDefined(false);

		symtable.InsertSI(temp);
		declaredSymbols.push_back(parameter(name, "function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters));
	//	cout<<type<<endl;
	}

	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
	logprint<< $$->getName()<<endl;
	logprint<<endl;

}
|
type_specifier ID LPAREN RPAREN error //handle error like  void fun()
{
	logprint<<" expected ;  at the end of the line"<<endl;
	logprint<<endl;


	logprint << "Line " << count_line << ": func_declaration : type_specifier ID LPAREN RPAREN";
	logprint<<endl;

	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	if(dupID!=nullptr)
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  " Multiple declaration of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  " Multiple declaration of '" << $2->getName() << "'"<<endl;

	}

	else
	{
		string name= $2->getName();
		string ftype= $1->getType();

		vector<parameter> ListofParamters;
		SymbolInfo* temp= new SymbolInfo(name,"ID", ListofParamters,-1,false);
		//temp->setIsDefined(false);

		symtable.InsertSI(temp);
		declaredSymbols.push_back(parameter(name, "function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters));
	//	cout<<type<<endl;
	}

	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
	logprint<< $$->getName()<<endl;
	logprint<<endl;
 }
|

type_specifier ID LPAREN error RPAREN SEMICOLON //handle error like void fun(+);
 {
	logprint << "Line " << count_line << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON";
	logprint<<endl;

	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	if(dupID!=nullptr)
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  " Multiple declaration of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  " Multiple declaration of '" << $2->getName() << "'"<<endl;

	}

	else
	{
		string name= $2->getName();
		string ftype= $1->getType();

		vector<parameter> ListofParamters;
		SymbolInfo* temp= new SymbolInfo(name,"ID", ListofParamters,-1,false);
		//temp->setIsDefined(false);

		symtable.InsertSI(temp);
		declaredSymbols.push_back(parameter(name, "function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters));
	//	cout<<type<<endl;
	}

	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
	logprint<< $$->getName()<<endl;
	logprint<<endl;
}

|

 type_specifier ID LPAREN error RPAREN error //to handle error like: int fun(+)

 {
	logprint << "Line " << count_line << ": func_declaration : type_specifier ID LPAREN RPAREN";
	logprint<<endl;

	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	if(dupID!=nullptr)
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  " Multiple declaration of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  " Multiple declaration of '" << $2->getName() << "'"<<endl;

	}

	else
	{
		string name= $2->getName();
		string ftype= $1->getType();

		vector<parameter> ListofParamters;
		SymbolInfo* temp= new SymbolInfo(name,"ID", ListofParamters,-1,false);
		//temp->setIsDefined(false);

		symtable.InsertSI(temp);
		declaredSymbols.push_back(parameter(name, "function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters));
	//	cout<<type<<endl;
	}

	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
	logprint<< $$->getName()<<endl;
	logprint<<endl;

 }


;


func_definition
:
type_specifier ID LPAREN parameter_list RPAREN 
{

	
	string name= $2->getName();
	string ftype= $1->getType();
	funcReturnType=ftype;
	vector<parameter> ListofParamters;
	vector<string>  typeName;
	vector<string>  parlist;
	vector<string> params;
	string parName= $4->getName();
	int parNumber=1;

	for(int i=0; i<parName.size(); i++)
	{
		if(parName[i]==',')
			parNumber++;
	}
	//logprint<<parName<<endl;
	//cout<<parNumber<<endl;
	if(parNumber==1){ params.push_back(parName) ;}
		else{
	params = splitString(parName, ',');
	}
	string curParam;
	

	for (int i=0;i<params.size(); i++)
    {
		//cout<<params[i]<<endl;
		
		curParam= params[i];
		string ParType;
		string ParName;
		
		string str="";
		for(int i=0;i<curParam.size(); i++)
		{
			//cout<<curParam<<endl;
			if(curParam[i]== ' '){
				for(int j=i+1; j<curParam.size(); j++)
				{
					str+=curParam[j];
				}
				break;
			}
		}
        //cout<<str<<endl;
		//cout<<typeName[0]<<endl;

		
		if(str.size()==0){
		count_error++;
		logprint<< "Error at line " << count_line <<" "<< i+1<<"th parameter's name not given in function definition of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " <<count_line <<" "<<i+1<< "th parameter's name not given in function definition of '" << $2->getName() << "'"<<endl;

			
			ParType= curParam;
			ParName="Dummy";
			ParName+=to_string(rand());
			
			typeName.push_back(ParType);
			typeName.push_back(ParName);
			//cout<<ParType<<" "<<ParName<<endl;
			//ListofParamters.push_back(parameter(typeName[1],typeName[0]));
			
		}

		else 
			typeName = splitString(curParam, ' ');
		//cout<<typeName[1]<<" "<<typeName[0]<<endl;
        ListofParamters.push_back(parameter(typeName[1],typeName[0]));
		typeName.clear();
    
	}

	//for(int i=0; i<ListofParamters.size(); i++)
	//	cout<<ListofParamters[i].getName()<<" "<<ListofParamters[i].getType()<<endl;
	
	
	
	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	//cout<<"Hiii";


	if(dupID==nullptr) //isnt declared previously
	{
		SymbolInfo* temp= new SymbolInfo(name, "ID", ListofParamters,-1,true);
		
		
		symtable.InsertSI(temp);
		symtable.EnterScope();
		
		declaredSymbols.push_back(parameter(name,"function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters));
		//cout<<"Hiii"<<endl;
		string param_retrieve_code = "";
		bool inserted = false;
		for (int i=0; i < ListofParamters.size(); i++)
		{


		string global_name = getGlobalName(ListofParamters[i].getName(), symtable);
		declaredGlobalVars.push_back( {global_name, 0} );

						

		// Pop the value of the stacks and store in the local variables
		param_retrieve_code += "\tPOP " + global_name + "\n";
		inserted = symtable.Insert(ListofParamters[i].getName(), ListofParamters[i].getType(),global_name);

		//cout<<ListofParamters[i].getName()<<" "<<ListofParamters[i].getType()<<endl;
		if (!inserted )
		{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Multiple declaration of '" <<ListofParamters[i].getName()<< "' parameter"<<endl;
			errorprint<< "Error at line " << count_line <<  " Multiple declaration of '" << ListofParamters[i].getName() << "' parameter"<<endl;
		}
								
		}

		parameterCode = param_retrieve_code;
						

	}

	else{

		if(dupID->getSize()!=-1) //if not a Function
		{
		symtable.EnterScope();
		count_error++;
		logprint<< "Error at line " << count_line <<  " Multiple Declaration of'" << $2->getName() << "' Identifier"<<endl;
		errorprint<< "Error at line " << count_line<<  " Multiple Declaration of'" << $2->getName() << "' Identifier"<<endl;
		}

		else{ //if is a Function



		if(dupID->getIsDefined()==true) //a Function with declaration and definition
		{
		count_error++;
		logprint<< "Error at line " << count_line <<  "Re-definition of '" << $2->getName() << "' Function"<<endl;
		errorprint<< "Error at line " << count_line <<  "Re-definition of '" << $2->getName() << "' Function"<<endl;

		}
		else //Function declared but not defined
		{	
			FunctionDef cur;
			for(int i=0; i<declaredFunctions.size(); i++)
			{
				if(declaredFunctions[i].getName()==dupID->getName())
				{
					cur= declaredFunctions[i];
				};
			}
			//cout<<cur.getName()<<" "<<cur.getReturnType()<<endl;
			string returnType= cur.getReturnType();
			
			string parameterCode = "";
				
	

			int dupParamsize= dupID->getParameterSize();

			// for(int i=0; i<dupParamsize; i++)
			// 	cout<<dupID->getParameter(i).getName()<<" "<<dupID->getParameter(i).getType()<<endl;
	

			if(dupParamsize!= ListofParamters.size())// parameter numbers dont match
			{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Total number of arguments mismatch with declaration in '" << $2->getName() << "' Function"<<endl;
			errorprint<< "Error at line " << count_line <<  " Total number of arguments mismatch with declaration in '" << $2->getName() << "' Function"<<endl;

			}

			if(returnType!=ftype) //return type doesnt match with declaration and definition
			{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Return type mismatch with function declaration in function '" << $2->getName() << "' Function"<<endl;
			errorprint<< "Error at line " << count_line <<  " Return type mismatch with function declaration in function'" << $2->getName() << "' Function"<<endl;

			}
			if(dupParamsize!=0 &&(dupParamsize== ListofParamters.size())) //check if parameter types dont match
			{	
				
			vector<parameter> Params;
			Params= cur.getParList();

			bool ParamNameExists= cur.IsParNameExists();
			for(int i=0; i<Params.size(); i++)
			{
			//	cout<<Params[i].getName()<<" "<<Params[i].getType()<<" "<<ListofParamters[i].getName()<< " "<<ListofParamters[i].getType()<<endl;
				if(ParamNameExists){
				if(Params[i].getName()!=ListofParamters[i].getName()||Params[i].getType()!=ListofParamters[i].getType())
				{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Type mismatch of Function parameter '" << ListofParamters[i].getName() <<"'"<<endl;
				errorprint<< "Error at line " << count_line <<  " Type mismatch of Function parameter  '" << ListofParamters[i].getName() <<"'"<<endl;
				}
				}

				else
				{
					if(Params[i].getType()!=ListofParamters[i].getType())
				{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Type mismatch of Function parameter '" << ListofParamters[i].getName() <<"'"<<endl;
				errorprint<< "Error at line " << count_line <<  " Type mismatch of Function parameter  '" << ListofParamters[i].getName() <<"'"<<endl;
				}
				}
			}
		}
		}


			symtable.Remove(name);

			SymbolInfo* temp= new SymbolInfo( name, "ID", ListofParamters,-1, true);
			
			string param_retrieve_code = "";
			symtable.InsertSI(temp);
			symtable.EnterScope();	
			bool inserted = false;
			//cout<< ListofParamters.size()<<endl;
			for (int i=0; i < ListofParamters.size(); i++)
			{



			string globalName = getGlobalName(ListofParamters[i].getName(), symtable);
			declaredGlobalVars.push_back( {globalName, 0} );
			inserted = symtable.Insert(ListofParamters[i].getName(), ListofParamters[i].getType(),globalName);						
									
			// Pop the value of the stacks and store in the local variables
			param_retrieve_code += "\tPOP " + globalName + "\n";
 
			//cout<<ListofParamters[i].getName()<<" "<<ListofParamters[i].getType()<<endl;
			if (!inserted)
			{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Multiple definition of '" << ListofParamters[i].getName() << "' parameter"<<endl;
				errorprint<< "Error at line " << count_line <<  " Multiple definition of '" << ListofParamters[i].getName() << "' parameter"<<endl;
			}
								
		}
		parameterCode = param_retrieve_code;

	
		}

		

	}
}
compound_statement{
	string code = "";
	string funcName = $2->getName();
	logprint << "Line " << count_line << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement ";
	logprint<<endl;
	//cout << funcName << endl;
	if (funcName == "main") {
						code += "MAIN PROC \n";
						code += "\tMOV AX, @DATA \n";
						code += "\tMOV DS, AX\n";

						code += $7->getCode();
					//	cout << "In compd stmt:: \n" << $7->getCode() << endl;

						code += "\tMOV AX, 4CH \n";
						code += "\tINT 21H \n";
						code += "MAIN ENDP \n";
						code += "END MAIN \n \n";
					}
					else {
						code += funcName + " PROC\n";

						code += "\tPOP BP		; return pointer stored in BP\n";
						code += parameterCode;
						code += "\tPUSH BP		; return pointer retrieving from BP  \n";
						//cout << "In compd stmt::\n" << $7->getCode() << endl;
						code += $7->getCode();
						code += "\tPUSH BP \n";
						code += "\tRET \n";

						code += $2->getName() + " ENDP \n \n";
					}

	
	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ")" + $7->getName() + "\n", "func_definition");
	//declaredParamList.clear();
	$$->setCode(code);
	
	//cout<<code<<endl;
	logprint<<$$->getName()<<endl;
	logprint<<endl;
//	symtable.printAllScopeTable(logprint);
	//symtable.ExitScope();
}

|
type_specifier ID LPAREN parameter_list error RPAREN //to handle cases like:  void foo(int x-y){}
{
	//logprint<<"THEREFORE I AM"<<endl;
	string name= $2->getName();
	string ftype= $1->getType();
	funcReturnType=ftype;
	vector<parameter> ListofParamters;
	vector<string>  typeName;
	vector<string>  parlist;
	vector<string> params;
	string parName= $4->getName();
	int parNumber=1;
	for(int i=0; i<parName.size(); i++)
	{
		if(parName[i]==',')
			parNumber++;
	}
	//logprint<<parName<<endl;

	if(parNumber==1){ params.push_back(parName) ;}
		else{
	params = splitString(parName, ',');
	}
	string curParam;


	for (int i=0;i<params.size(); i++)
    {
		
		curParam= params[i];
		string ParType;
		string ParName;
		
		string str="";
		for(int i=0;i<curParam.size(); i++)
		{
			//cout<<curParam<<endl;
			if(curParam[i]== ' '){
				for(int j=i+1; j<curParam.size(); j++)
				{
					str+=curParam[j];
				}
			}
		}
       // cout<<str.size()<<endl;
		//cout<<typeName[0]<<endl;

		
		if(str.size()==0){
		count_error++;
		logprint<< "Error at line " << count_line <<" "<< i+1<<"th parameter's name not given in function definition of '" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " <<count_line <<" "<<i+1<< "th parameter's name not given in function definition of '" << $2->getName() << "'"<<endl;

			
			ParType= curParam;
			ParName="Dummy";
			ParName+=to_string(rand());
			
			typeName.push_back(ParType);
			typeName.push_back(ParName);
			//cout<<ParType<<" "<<ParName<<endl;
			//ListofParamters.push_back(parameter(typeName[1],typeName[0]));
			
		}

		else 
			typeName = splitString(curParam, ' ');
		//cout<<ParType<<" "<<ParName<<endl;
        ListofParamters.push_back(parameter(typeName[1],typeName[0]));
		typeName.clear();
    }
	
	
	SymbolInfo * dupID= symtable.Lookup( $2->getName());
	//cout<<"Hiii";


	if(dupID==nullptr) //isnt declared previously
	{
		SymbolInfo* temp= new SymbolInfo(name, "ID", ListofParamters,-1,true);
		
		
		symtable.InsertSI(temp);
		symtable.EnterScope();
		
		declaredSymbols.push_back(parameter(name,"function"));
		declaredFunctions.push_back(FunctionDef(name,ftype, ListofParamters));
		//cout<<"Hiii"<<endl;
		bool inserted = false;
		for (int i=0; i < ListofParamters.size(); i++)
		{
		inserted = symtable.Insert(ListofParamters[i].getName(), ListofParamters[i].getType());
		//cout<<ListofParamters[i].getName()<<" "<<ListofParamters[i].getType()<<endl;
		if (!inserted)
		{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Multiple declaration of '" <<ListofParamters[i].getName()<< "' parameter"<<endl;
			errorprint<< "Error at line " << count_line <<  " Multiple declaration of '" << ListofParamters[i].getName() << "' parameter"<<endl;
		}
								
		}
						

	}

	else{

		if(dupID->getSize()!=-1) //if not a Function
		{
		symtable.EnterScope();
		count_error++;
		logprint<< "Error at line " << count_line <<  " Multiple Declaration of'" << $2->getName() << "' Identifier"<<endl;
		errorprint<< "Error at line " << count_line<<  " Multiple Declaration of'" << $2->getName() << "' Identifier"<<endl;
		}

		else{ //if is a Function



		if(dupID->getIsDefined()==true) //a Function with declaration and definition
		{
		count_error++;
		logprint<< "Error at line " << count_line <<  "Re-definition of '" << $2->getName() << "' Function"<<endl;
		errorprint<< "Error at line " << count_line <<  "Re-definition of '" << $2->getName() << "' Function"<<endl;

		}
		else //Function declared but not defined
		{	
			FunctionDef cur;
			for(int i=0; i<declaredFunctions.size(); i++)
			{
				if(declaredFunctions[i].getName()==dupID->getName())
				{
					cur= declaredFunctions[i];
				};
			}
			string returnType= cur.getReturnType();

			int dupParamsize= dupID->getParameterSize();
			if(dupParamsize!= ListofParamters.size())// parameter numbers dont match
			{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Total number of arguments mismatch with declaration in '" << $2->getName() << "' Function"<<endl;
			errorprint<< "Error at line " << count_line <<  " Total number of arguments mismatch with declaration in '" << $2->getName() << "' Function"<<endl;

			}

			if(returnType!=ftype) //return type doesnt match with declaration and definition
			{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Return type mismatch with function declaration in function '" << $2->getName() << "' Function"<<endl;
			errorprint<< "Error at line " << count_line <<  " Return type mismatch with function declaration in function'" << $2->getName() << "' Function"<<endl;

			}
			if(dupParamsize!=0 &&(dupParamsize== ListofParamters.size())) //parameter types dont match
			{	
			vector<parameter> Params;
			Params= cur.getParList();
			bool ParamNameExists= cur.IsParNameExists();
			for(int i=0; i<Params.size(); i++)
			{
			//	cout<<Params[i].getName()<<" "<<Params[i].getType()<<" "<<ListofParamters[i].getName()<< " "<<ListofParamters[i].getType()<<endl;
				if(ParamNameExists){
				if(Params[i].getName()!=ListofParamters[i].getName()||Params[i].getType()!=ListofParamters[i].getType())
				{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Type mismatch of Function parameter '" << ListofParamters[i].getName() <<"'"<<endl;
				errorprint<< "Error at line " << count_line <<  " Type mismatch of Function parameter  '" << ListofParamters[i].getName() <<"'"<<endl;
				}
				}

				else
				{
					if(Params[i].getType()!=ListofParamters[i].getType())
				{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Type mismatch of Function parameter '" << ListofParamters[i].getName() <<"'"<<endl;
				errorprint<< "Error at line " << count_line <<  " Type mismatch of Function parameter  '" << ListofParamters[i].getName() <<"'"<<endl;
				}
				}
			}
		}
		}


			symtable.Remove(name);

			SymbolInfo* temp= new SymbolInfo( name, "ID", ListofParamters,-1, true);
			
			
			symtable.InsertSI(temp);
			symtable.EnterScope();	
			bool inserted = false;
			//cout<< ListofParamters.size()<<endl;
			for (int i=0; i < ListofParamters.size(); i++)
			{
			inserted = symtable.Insert(ListofParamters[i].getName(), ListofParamters[i].getType());
			//cout<<ListofParamters[i].getName()<<" "<<ListofParamters[i].getType()<<endl;
			if (!inserted)
			{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Multiple definition of '" << ListofParamters[i].getName() << "' parameter"<<endl;
				errorprint<< "Error at line " << count_line <<  " Multiple definition of '" << ListofParamters[i].getName() << "' parameter"<<endl;
			}
								
		}

	
		}
	}
}
	compound_statement{
	
	logprint << "Line " << count_line << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement";
	logprint<<endl;

	//logprint<<"HELLO"<<endl;

	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ")"  + $8->getName() + "\n", "func_definition");
	//declaredParamList.clear();
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
type_specifier ID LPAREN RPAREN
{


	string name= $2->getName();
	string ftype= $1->getType();
	funcReturnType=ftype;
	SymbolInfo * dupID= symtable.Lookup(name);

	if(dupID==nullptr) //isnt declared previously
	{
		vector<parameter> ListofParamters;
		SymbolInfo * temp= new SymbolInfo(name,"ID", ListofParamters,-1,true);
		declaredSymbols.push_back(parameter(name, "function"));
	
		declaredFunctions.push_back(FunctionDef(name, ftype,ListofParamters));
	
		symtable.InsertSI(temp);
		symtable.EnterScope();	
		
	}

	else{ //declared

		if(dupID->getSize()!=-1) //isnt Function
		{
		count_error++;
		logprint<< "Error at line " << count_line <<  " Identifier'" << $2->getName() << "'Not a Function"<<endl;
		errorprint<< "Error at line " << count_line <<  " Identifier '" << $2->getName() << "'Not a Function"<<endl;
		}

		else{



		if(dupID->getIsDefined()==true) //a Function with declaration and definition
		{
		count_error++;
		logprint<< "Error at line " << count_line <<  " Re-definition of '" << $2->getName() << "' Function"<<endl;
		errorprint<< "Error at line " << count_line <<  " Re-definition of '" << $2->getName() << "' Function"<<endl;

		}
		else //Function declared but not defined
		{
			string RealType;
			for(int i=0; i< declaredFunctions.size(); i++)
			{
				if(name==declaredFunctions[i].getName())
					RealType= declaredFunctions[i].getReturnType();
			}
			

			if(ftype!=RealType) //return type doesnt match with declaration and definition
			{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Function return type doesn't match with declaration of '" << $2->getName() << "' FunctionDef"<<endl;
			errorprint<< "Error at line " << count_line <<  " Function return type doesn't match with declaration of '" << $2->getName() << "' FunctionDef"<<endl;

			}


			symtable.Remove(name);

	
			vector<parameter> ListofParamters;
			SymbolInfo * temp= new SymbolInfo(name, "ID", ListofParamters,-1,true);
			
			
			
			symtable.InsertSI(temp);
			


	}
		}

		
symtable.EnterScope();	
	}
	
}

	compound_statement{
	
	
	logprint << "Line " << count_line << ": func_definition: type_specifier ID LPAREN RPAREN compound_statement";
	logprint<<endl;
	//cout<<$1->getName() + " " + $2->getName() + "()" + $6->getName() + "\n"<<endl;

//	cout<<$6->getName() <<endl;

	string codd = "";
					
	if ($2->getName() == "main") {
		codd += "MAIN PROC\n";
		codd += "\tMOV AX, @DATA\n";
		codd += "\tMOV DS, AX\n";

		codd += $6->getCode();
	//	cout << "In main \n" << $6->getCode() << endl;

		codd += "\tMOV AX, 4CH\n";
		codd += "\tINT 21H\n";
		codd += "MAIN ENDP\n";
		codd += "END MAIN\n\n";
		}
	else {
		//code+="CHALLENGE NIBINA SALA";
		codd += $2->getName() + " PROC\n";
					
		codd += "\tPOP BP		; storing the return pointer in BP\n";
		codd += $6->getCode();

		//cout<< $6->getCode()<<endl;
		codd += "\tPUSH BP		; retrieving the return pointer\n";
		//codd+=
		codd += "\tRET\n";
		
		codd += $2->getName() + " ENDP\n\n";
	}
	//code+= "bondhura elomelo";
	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "()" + $6->getName() + "\n", "func_definition");
	$$->setCode(codd);
	//cout<<codd<<endl;
	//cout<< $$->getCode()<<endl;
	logprint<<$$->getName()<<endl;
	logprint<<endl;

}

|

 type_specifier ID LPAREN error RPAREN {
	string name= $2->getName();
	string ftype= $1->getType();
	funcReturnType=ftype;
	SymbolInfo * dupID= symtable.Lookup(name);

	if(dupID==nullptr) //isnt declared previously
	{
		vector<parameter> ListofParamters;
		SymbolInfo * temp= new SymbolInfo(name,"ID", ListofParamters,-1,true);
		declaredSymbols.push_back(parameter(name, "function"));
	
		declaredFunctions.push_back(FunctionDef(name, ftype,ListofParamters));
	
		symtable.InsertSI(temp);
		symtable.EnterScope();	
		
	}

	else{ //declared

		if(dupID->getSize()!=-1) //isnt Function
		{
		count_error++;
		logprint<< "Error at line " << count_line <<  " Identifier'" << $2->getName() << "'Not a Function"<<endl;
		errorprint<< "Error at line " << count_line <<  " Identifier '" << $2->getName() << "'Not a Function"<<endl;
		}

		else{



		if(dupID->getIsDefined()==true) //a Function with declaration and definition
		{
		count_error++;
		logprint<< "Error at line " << count_line <<  " Re-definition of '" << $2->getName() << "' Function"<<endl;
		errorprint<< "Error at line " << count_line <<  " Re-definition of '" << $2->getName() << "' Function"<<endl;

		}
		else //Function declared but not defined
		{
			string RealType;
			for(int i=0; i< declaredFunctions.size(); i++)
			{
				if(name==declaredFunctions[i].getName())
					RealType= declaredFunctions[i].getReturnType();
			}
			

			if(ftype!=RealType) //return type doesnt match with declaration and definition
			{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Function return type doesn't match with declaration of '" << $2->getName() << "' FunctionDef"<<endl;
			errorprint<< "Error at line " << count_line <<  " Function return type doesn't match with declaration of '" << $2->getName() << "' FunctionDef"<<endl;

			}


			symtable.Remove(name);

	
			vector<parameter> ListofParamters;
			SymbolInfo * temp= new SymbolInfo(name, "ID", ListofParamters,-1,true);
			
			
			
			symtable.InsertSI(temp);
			


	}
		}

		
symtable.EnterScope();	
	}
 }
	compound_statement {

	logprint << "Line " << count_line << ": func_definition: type_specifier ID LPAREN RPAREN";
	logprint<<endl;
	

	
	$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "()" , "func_definition");

	logprint<<$$->getName()<<endl;
	logprint<<endl;

 }
;

parameter_list
:


parameter_list COMMA type_specifier ID
{
	logprint << "Line " << count_line << ": parameter_list :parameter_list COMMA type_specifier ID ";
	logprint<<endl;

	$$ = new SymbolInfo($1->getName() + "," + $3->getName() + " " + $4->getName(), "parameter_list");
	//declaredParamList.push_back(parameter($4->getName(), $3->getName()));
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|

  parameter_list error COMMA type_specifier ID //  To handle cases like:   void fun(int a-b,int c);
{

	logprint << "Line " << count_line << ": parameter_list :parameter_list COMMA type_specifier ID ";
	logprint<<endl;

	$$ = new SymbolInfo($1->getName() + "," + $4->getName() + " " + $5->getName(), "parameter_list");
	//declaredParamList.push_back(parameter($4->getName(), $3->getName()));
	logprint<<$$->getName()<<endl;
	logprint<<endl;
           
	
} 
|
parameter_list COMMA type_specifier 
{
	logprint << "Line " << count_line << ": parameter_list : parameter_list COMMA type_specifier ";
	logprint<<endl;

	$$ = new SymbolInfo($1->getName() + "," + $3->getName() , "parameter_list");
	
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
parameter_list error COMMA type_specifier  //to handle cases like void fun(int a-b, int)
{
	logprint << "Line " << count_line << ": parameter_list : parameter_list COMMA type_specifier ";
	logprint<<endl;

	$$ = new SymbolInfo($1->getName() + "," + $4->getName() , "parameter_list");
	
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
type_specifier ID
{
	logprint << "Line " << count_line << ": parameter_list : type_specifier ID ";
	logprint<<endl;

	//logprint<<$1->getName()<<endl;
	if($1->getName()=="void")
{
	count_error++;
	logprint<<"Error at line No "<<count_line<<" variable can't be of void type"<<endl;
	errorprint<<"Error at line No "<<count_line<<" variable can't be of void type"<<endl;
	
	
}



	$$ = new SymbolInfo($1->getName() + " " + $2->getName() , "parameter_list");
	//declaredParamList.push_back(parameter($2->getName(), $1->getName()));


logprint<<$$->getName()<<endl;
logprint<<endl;
}
|
type_specifier
{
	logprint << "Line " << count_line << ": parameter_list : type_specifier ";
	logprint<<endl;
	$$ = new SymbolInfo($1->getName() , "parameter_list");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}

;


compound_statement
:

LCURL statements  RCURL
{

	
	
	logprint << "Line " << count_line << ": compound_statement : LCURL statements RCURL";
	logprint<<endl;

	
	$$ = new SymbolInfo("{\n"+ $2->getName() + "\n}", "compound_statement");
	
	$$->setCode($2->getCode());
	logprint<<$$->getName()<<endl;
	logprint<<endl;
	symtable.printAllScopeTable(logprint);
	symtable.ExitScope();

}
|
/* LCURL statements error RCURL{

	
	logprint << "Line " << count_line << ": compound_statement : LCURL statements error RCURL ";
	logprint<<endl;

	
	$$ = new SymbolInfo("{\n"+ $2->getName() + "\n}", "compound_statement");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
	symtable.printAllScopeTable(logprint);
	symtable.ExitScope();

}
|
LCURL error statements RCURL{

	
	logprint << "Line " << count_line << ": compound_statement : LCURL error statements RCURL";
	logprint<<endl;

	
	$$ = new SymbolInfo("{\n"+ $3->getName() + "\n}", "compound_statement");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
	symtable.printAllScopeTable(logprint);
	symtable.ExitScope();

}
|
LCURL error RCURL{
	

	

	logprint << "Line " << count_line << ": compound_statement : LCURL RCURL ";
	logprint<<endl;
	$$ = new SymbolInfo("{\n}", "compound_statement");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
	symtable.printAllScopeTable(logprint);
	symtable.ExitScope();
	
}
| */
LCURL RCURL
{
	logprint << "Line " << count_line << ": compound_statement : LCURL RCURL";
	logprint<<endl;
	$$ = new SymbolInfo("{\n}", "compound_statement");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
	symtable.printAllScopeTable(logprint);
	symtable.ExitScope();
	
}
;


var_declaration
:
type_specifier declaration_list SEMICOLON
{
	logprint << "Line " << count_line << ": var_declaration : type_specifier declaration_list SEMICOLON";
	logprint<<endl;

	string name= $2->getName();
	string ftype= $1->getName();
	//cout<<name<<" "<<ftype<<endl;
	SymbolInfo* temp;

	if(ftype=="void")
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  " variable type cant be void of'" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  " variable type cant be void of'" << $2->getName() << "'"<<endl;

	}

	else
	{
		vector<string> ListString= splitString(name, ',');
		bool isArray =false;
		bool arrayNotclosed=false;

		for (string cur: ListString)
			{
				isArray=false;
				//cout<<cur<<endl;
				if ((cur.find("[") != string::npos) || (cur.find("]") != string::npos)) 
        			isArray=true;
				//else isArray=false;

				//cout<<isArray<<endl;

				if (isArray==false)
				{
				//	cout<<cur<<endl;
					temp= new SymbolInfo(cur, "ID");
					string global_name = getGlobalName(cur, symtable);
					declaredGlobalVars.push_back( {global_name, 0} );
					temp->setAsm(global_name);
					//$$= temp;
				//	logprint<<$$->getName()<<endl;
					//logprint<<endl;
					//declaredSymbols.push_back(parameter(cur,ftype)); 
				}
				else if(arrayNotclosed)
				{
					count_error++;
					logprint<<"Error at line No "<<count_line<<" expected ']' before ',' token"<<endl;
					errorprint<<"Error at line No "<<count_line<<" expected ']' before ',' token"<<endl;
				}

				else //if it is an array
				{
				   stringstream ss(cur);
				   string arrayname="";


					 string  t, sz;
					int i=0;
					while(cur[i]!='[')  //determining array name
					{
						arrayname+=cur[i];
						i++;
					}
  
					//cout<<arrayname<<endl;

   					 while (getline(ss, t, '[')) { }
					 stringstream ss2(t);
					 getline(ss2,sz,']');

					    


    				int arraysize= stoi(sz);//determining array size

    			//	cout<<arraysize<<endl;
				 	
					string global_name = getGlobalName(arrayname, symtable);
					declaredGlobalVars.push_back( {global_name, arraysize} );
					temp= new SymbolInfo(arrayname, "ID", arraysize);
					temp->setAsm(global_name);
				}

				bool flag= symtable.InsertSI(temp);
				 

				if ( !flag )
				{
				count_error++;
				logprint<< "Error at line " << count_line <<  " multiple declaration of'" << temp->getName() << "'"<<endl;
				errorprint<< "Error at line " << count_line <<  " multiple declaration of'" <<temp->getName() << "'"<<endl;

				} 
				else
				{
					if(isArray){
					declaredSymbols.push_back(parameter(temp->getName(),"Array"));
					declaredArrays.push_back(parameter(temp->getName(),ftype));
					
				}
					else
					{
					declaredSymbols.push_back(parameter(temp->getName(),ftype));
					}

				}
				

		}
					$$= new SymbolInfo( $1->getName() +" "+  $2->getName()+ ";" , "var_declaration");
					logprint<<$$->getName()<<endl;
					logprint<<endl;

	}
	

}
|
type_specifier declaration_list error SEMICOLON
{


	logprint << "Line " << count_line << ": var_declaration : type_specifier declaration_list semicolon";
	logprint<<endl;

	string name= $2->getName();
	string ftype= $1->getName();
	//cout<<name<<" "<<ftype<<endl;
	SymbolInfo* temp;

	if(ftype=="void")
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  " variable type cant be void of'" << $2->getName() << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  " variable type cant be void of'" << $2->getName() << "'"<<endl;

	}

	else
	{
		vector<string> ListString= splitString(name, ',');
		bool isArray =false;
		bool arrayNotclosed=false;

		for (string cur: ListString)
			{
				isArray=false;
				//cout<<cur<<endl;
				if ((cur.find("[") != string::npos) || (cur.find("]") != string::npos)) 
        			isArray=true;
				//else isArray=false;

				//cout<<isArray<<endl;

				if (isArray==false)
				{
				//	cout<<cur<<endl;
					temp= new SymbolInfo(cur, "ID");
					//$$= temp;
				//	logprint<<$$->getName()<<endl;
					//logprint<<endl;
					//declaredSymbols.push_back(parameter(cur,ftype)); 
				}
				else if(arrayNotclosed)
				{
					count_error++;
					logprint<<"Error at line No "<<count_line<<" expected ']' before ',' token"<<endl;
					errorprint<<"Error at line No "<<count_line<<" expected ']' before ',' token"<<endl;
				}

				else //if it is an array
				{
				   stringstream ss(cur);
				   string arrayname="";


					 string  t, sz;
					int i=0;
					while(cur[i]!='[')  //determining array name
					{
						arrayname+=cur[i];
						i++;
					}
  
					//cout<<arrayname<<endl;

   					 while (getline(ss, t, '[')) { }
					 stringstream ss2(t);
					 getline(ss2,sz,']');

					    


    				int arraysize= stoi(sz);//determining array size

    			//	cout<<arraysize<<endl;
				 	
    			
					temp= new SymbolInfo(arrayname, "ID", arraysize);
					
				}

				bool flag= symtable.InsertSI(temp);
				 

				if ( !flag )
				{
				count_error++;
				logprint<< "Error at line " << count_line <<  " multiple declaration of'" << temp->getName() << "'"<<endl;
				errorprint<< "Error at line " << count_line <<  " multiple declaration of'" <<temp->getName() << "'"<<endl;

				} 
				else
				{
					if(isArray){
					declaredSymbols.push_back(parameter(temp->getName(),"Array"));
					declaredArrays.push_back(parameter(temp->getName(),ftype));
					
				}
					else
					{
					declaredSymbols.push_back(parameter(temp->getName(),ftype));
					}
					$$= new SymbolInfo( $1->getName() +" "+  $2->getName()+ ";" , "var_declaration");
					logprint<<$$->getName()<<endl;
					logprint<<endl;
				}
				

		}

	}

}


;


type_specifier
:
INT
{
	logprint << "Line " << count_line << ": type_specifier :  int"<<endl;
	logprint<<endl;
	$$ = new SymbolInfo("int", "int");
	logprint << $$->getName() << endl;
	logprint<<endl;
	///type="int";

}
|
FLOAT
{
	logprint << "Line " << count_line << ": type_specifier :  FLOAT"<<endl;
	logprint<<endl;
	$$ = new SymbolInfo("float", "float");
	logprint << $$->getName() << endl;
	logprint<<endl;
	//type="float";

}
|
VOID
{
	logprint << "Line " << count_line << ": type_specifier :  VOID"<<endl;
	logprint<<endl;

	$$ = new SymbolInfo("void", "void");
	logprint << $$->getName() << endl;
	logprint<<endl;
//	cout<<"blood sweat tears"<<endl;
//	type="void";

}



;


declaration_list
:
declaration_list COMMA ID
{

	logprint << "Line " << count_line << ": declaration_list : declaration_list COMMA ID";
	logprint<<endl;

	$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "declaration_list");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
declaration_list error COMMA ID //to handle error like int a-b,c
{

	logprint << "Line " << count_line << ": declaration_list : declaration_list COMMA ID";
	logprint<<endl;

	$$ = new SymbolInfo($1->getName() + "," + $4->getName(), "declaration_list");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
{
	logprint << "Line " << count_line << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD";
	logprint<<endl;

	$$ = new SymbolInfo($1->getName() + "," + $3->getName() + "["+ $5->getName() + "]", "declaration_list");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
	//declaredSymbols.push_back(parameter($3->getName(),"array"));
}
|
declaration_list error COMMA ID LTHIRD CONST_INT RTHIRD 
{
	logprint << "Line " << count_line << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD";
	logprint<<endl;

	$$ = new SymbolInfo($1->getName() + "," + $4->getName() + "["+ $6->getName() + "]", "declaration_list");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
	//declaredSymbols.push_back(parameter($3->getName(),"array"));
}
|
ID
{
	logprint << "Line " << count_line << ": declaration_list : ID";
	logprint<<endl;


	$$ = $1;
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
ID LTHIRD CONST_INT RTHIRD
{
	logprint << "Line " << count_line << ": declaration_list : ID LTHIRD CONST_INT RTHIRD";
	logprint<<endl;


	$$ = new SymbolInfo($1->getName() + "["+ $3->getName() + "]", "declaration_list");
	logprint<<$$->getName()<<endl;
	logprint<<endl;

	//declaredSymbols.push_back(parameter($$->getName(),"array"));
}
|
ID LTHIRD CONST_FLOAT RTHIRD
{
	logprint<<"Warning: array index has been type casted to integer type"<<endl;
	logprint<<endl;
	logprint << "Line " << count_line << ": declaration_list : ID LTHIRD CONST_FLOAT RTHIRD";
	logprint<<endl;
	string name= $3->getName();
	string intVal="";
	for(int i=0; i<name.size(); i++)
	{
		if(name[i]=='.')
			break;
		intVal=+name[i];
	}


	$$ = new SymbolInfo($1->getName() + "["+ intVal + "]", "declaration_list");
	logprint<<$$->getName()<<endl;
	logprint<<endl;

	//declaredSymbols.push_back(parameter($$->getName(),"array"));
}
;

statements
:


statement
{

	
	logprint << "Line " << count_line << ": statements : statement";
	logprint<<endl;
	$$ = new SymbolInfo($1->getName() , "statements");
   $$->setCode($1->getCode());
  // cout<<$$->getCode()<<endl;
	logprint<<$$->getName()<<endl;
	logprint<<endl;

}
|
statements statement
{
	logprint << "Line " << count_line << ": statements : statements statement";
	logprint<<endl;

	
	$$ = new SymbolInfo($1->getName() + "\n" +  $2->getName() , "statements");
	$$->setCode($1->getCode() + $2->getCode());
	logprint<<$$->getName()<<endl;
	//cout<<"statements statement"<<endl;
	//cout<<$1->getCode()<<endl;
	//cout<<$2->getCode()<<endl;
//	cout<<$$->getCode()<<endl;
	logprint<<endl;

}
|
statements error statement
{
	logprint << "Line " << count_line << ": statements : statements statement";
	logprint<<endl;


	$$ = new SymbolInfo(  $1->getName() + "\n" + $3->getName() , "statements");
	$$->setCode($1->getCode() + $3->getCode());
	
	logprint<<$$->getName()<<endl;
	logprint<<endl;

}

/* |
func_declaration  error
{
	count_error++;
	logprint<< "Error at line " << count_line<<"Invalid Scoping Found"<<endl;
	errorprint<< "Error at line "<< count_line <<"Invalid Scoping Found"<<endl;

			
}
|
func_definition error

{
	count_error++;
	logprint<< "Error at line " << count_line<<"Invalid Scoping Found"<<endl;
	errorprint<< "Error at line "<< count_line <<"Invalid Scoping Found"<<endl;

			
} */

;


statement
:
/* func_declaration 
{
	logprint << "Line " << count_line << ": statements : statement";
	logprint<<endl;
	count_error++;
	logprint<<"Error at Line " << count_line << " invalid scoping found"<<endl;
	errorprint<<"Error at Line " << count_line << " invalid scoping found"<<endl;
	logprint<<endl;
	
	$$ = new SymbolInfo($1->getName() , "statements");

	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
func_definition 
{
	logprint << "Line " << count_line << ": statements : statement";
	logprint<<endl;
	count_error++;
	logprint<<"Error at Line " << count_line <<" invalid scoping found"<<endl;
	errorprint<<"Error at Line " << count_line <<" invalid scoping found"<<endl;
	logprint<<endl;
	$$ = new SymbolInfo($1->getName() , "statements");

	//logprint<<$$->getName()<<endl;
	//logprint<<endl;
}
| */
var_declaration
{
	logprint << "Line " << count_line << ": statement : var_declaration";
	logprint<<endl;

	
	$$ = new SymbolInfo($1->getName() , "statement");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
expression_statement
{
	
	logprint << "Line " << count_line << ": statement : expression_statement";
	logprint<<endl;
	$$ = new SymbolInfo($1->getName() , "statement");
	$$->setCode($1->getCode());
	$$->setAsm($1->getAsm());
	logprint<<$$->getName()<<endl;
	logprint<<endl;


}
| {symtable.EnterScope();}
compound_statement
{
	logprint << "Line " << count_line << ": statement : compound_statement";
	logprint<<endl;

	//$$ = new SymbolInfo($2->getName() , "statement");
	$$=$2;
	logprint<<$$->getName()<<endl;
	logprint<<endl;

}
|
FOR LPAREN expression_statement expression_statement expression RPAREN statement
{
	logprint << "Line " << count_line << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement";
	logprint<<endl;

	string code = "";
	string cond_asm = $4->getAsm();

	string init_code = $3->getCode();
	string cond_code = $4->getCode();
	string incr_code = $5->getCode();
	string body_code = $7->getCode();

	string first_statement = $3->getName();
	string second_statement = $4->getName();
	code += "; code segment for FOR loop rule \n";
	code += init_code;
	if (first_statement != ";" && second_statement != ";")
	{
		string label_1 = newLabel();
		string label_2 = newLabel();

		code += label_1 + ":\n";
		code += cond_code;
		code += "\tMOV AX, " + cond_asm + "\n";
		code += "\tCMP AX, 0\n";
		code += "\tJE " + label_2 + "\n";

		code += body_code;
		code += incr_code;
		code += "\tJMP " + label_1 + "\n";
		code += label_2 + ":\n";
				}
	$$ = new SymbolInfo("for("+ $3->getName() +$4->getName() +$5->getName() +  ")" + $7->getName(), "statement");
	$$->setCode(code);
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}

|
IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
{
	logprint << "Line " << count_line << ": statement : IF LPAREN expression RPAREN statement";
	logprint<<endl;

	

	
	string label = newLabel();

	string code = "";

	code += ";  IF rule code part\n";
	code +=  $3->getCode();
	code += "\tMOV AX, " +  $3->getAsm() + "\n";
	code += "\tCMP AX, 0\n";
	code += "\tJE " + label + "\n";
	code += $5->getCode();
	code += label + ":\n";


	$$ = new SymbolInfo("if("+ $3->getName() + ")" + $5->getName(),"statement");
	$$->setCode(code);
	//cout<<$$->getName()<<endl;
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
IF LPAREN expression RPAREN statement ELSE statement
{

	logprint << "Line " << count_line << ": statement : IF LPAREN expression RPAREN statement ELSE statement";
	logprint<<endl;

	

	

	string label_1 = newLabel();
	string label_2 = newLabel();

	string code = "";

	code += "; IF ELSE rcode part\n";

	code +=  $3->getCode();
	code += "\tMOV AX, " +  $3->getAsm() + "\n";
	code += "\tCMP AX, 0\n";
	code += "\tJE " + label_1 + "\n";
	code += $5->getCode();
	code += "\tJMP " + label_2 + "\n";
	code += label_1 + ":\n";
	code +=$7->getCode();
	code += label_2 + ":\n";
	$$ = new SymbolInfo("if("+$3->getName() + ")" +$5->getName() +"\n" +"else" +"\n" + $7->getName(),"statement");
	$$->setCode(code);
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
WHILE LPAREN expression RPAREN statement
{
	logprint << "Line " << count_line << ": statement : WHILE LPAREN expression RPAREN statement";
	logprint<<endl;

	

	string code = "";

	string label_1 = newLabel();
	string label_2 = newLabel();

	code += "; code segment for WHILE rule\n";

	code += label_1 + ":\n";
	code += $3->getCode();
	code += "\tMOV AX, " + $3->getAsm() + "\n";
	code += "\tCMP AX, 0\n";
	code += "\tJE " + label_2 + "\n";

	code +=  $5->getCode();
	code += "\tJMP " + label_1 + "\n";
	code += label_2 + ":\n";
	$$ = new SymbolInfo("while("+ $3->getName() + ")"+$5->getName()  , "statement");
	$$->setCode(code);
//	cout<<$$->getCode();
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
PRINTLN LPAREN ID RPAREN SEMICOLON
{
	logprint << "Line " << count_line << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON";
	logprint<<endl;

	string name= $3->getName();
	SymbolInfo* dupID= symtable.Lookup(name);

	if (dupID == nullptr)
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  " undeclared variable '" << name << "'"<<endl;
		errorprint<< "Error at line " << count_line <<  " undeclared variable '" << name << "'"<<endl;
	}
	else
		{

		if(!(dupID->getSize()==0))
		{
			count_error++;
			logprint<< "Error at line " << count_line <<  " A FunctionDefcan't be inside printf"  <<endl;
			errorprint<< "Error at line " << count_line <<  " A FunctionDefcan't be inside printf"  <<endl;
		}

		}
	string code = "";
	string cvar = dupID->getAsm();

	code += "\tMOV AX, " + cvar + "\n";
	code += "\tMOV varPrint, AX\n";
	code += "\tCALL PRINTLN\n";


				

	$$ = new SymbolInfo("printf(" + $3->getName() + ");",	"statement");
	$$->setCode(code);
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|

RETURN expression SEMICOLON
{
	logprint << "Line " << count_line << ": statement : RETURN expression SEMICOLON";
	logprint<<endl;


string asmasm= $2->getAsm();
//cout<<asmasm<<endl;
	//string ftype= $2->getType();
	//cout << $2 << endl;
	//logprint << funcReturnType << endl;
	string ftype= funcReturnType;
	string code = "";

	if(ftype=="void")
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  " A void type Function cannot have return type"  <<endl;
		errorprint<< "Error at line " << count_line <<   " A void type Function cannot have return type"   <<endl;
		
	}

	code += $2->getCode();

	code += "\tPOP BP\n";
	code += "\tPUSH " + $2->getAsm() + "\n";

	
//	cout<<"in return "<<  $2->getAsm()<<endl;
	$$ = new SymbolInfo("return " + $2->getName() + ";","statement");
	$$->setCode(code);

	logprint<<$$->getName()<<endl;
	logprint<<endl;


}

;

expression_statement
:
SEMICOLON
{
	logprint << "Line " << count_line << ": expression_statement : SEMICOLON";
	logprint<<endl;

	$$ = new SymbolInfo(";", "expression_statement");

	//logprint<<$$->getName()<<endl;
	//logprint<<endl;

}
|
expression SEMICOLON
{
	logprint << "Line " << count_line << ": expression_statement : expression SEMICOLON";
	logprint<<endl;

	$$ = new SymbolInfo($1->getName() + ";", "expression_statement");
	$$->setCode($1->getCode());
	//cout<<$1->getCode()<<endl;
	$$->setAsm($1->getAsm());
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}

;

variable
:

ID
{

	logprint << "Line " << count_line << ": variable: ID";
	logprint<<endl;

	string name= $1->getName();
	
	SymbolInfo* IdDup = symtable.Lookup(name);
	//cout<<declaredSymbols.size()<<endl;
	//cout<<declaredParamList.size()<<endl;

	//symtable.printAllScopeTable(logprint);
	bool isDeclaredParam=false;
	bool isDeclaredVar= false;
	string paramtype= "undeclared";
	string vartype ="undeclared";
	FunctionDef func;

	if(declaredFunctions.size()!=0)
		func= declaredFunctions[declaredFunctions.size()-1];

	vector <parameter> param= func.getParList();
	int siz= param.size();

	for(int i=0; i<siz; i++)
	{
		if(param[i].getName()==(name))
			{isDeclaredParam=true;
			paramtype= param[i].getType();
			}
	}

		for(int i=declaredSymbols.size()-1; i>=0; i--)
	{
		if(declaredSymbols[i].getName()==(name))
			{isDeclaredVar=true;
			vartype= declaredSymbols[i].getType();
			break;
			}
	}
	
	
	if(IdDup!=nullptr)
	{
		if(IdDup->getSize()>0)

		{	logprint << "Error at line " << count_line << ": Type mismatch, " << $1->getName() << " is an array"<<endl;
			errorprint << "Error at line " <<count_line << ": Type mismatch, " << $1->getName() << " is an array"<<endl;
			count_error++;
		}

		if(IdDup->getSize()==-1)

		{	logprint << "Error at line " << count_line << ": Type mismatch, " << $1->getName() << " is a Function"<<endl;
			errorprint << "Error at line " <<count_line << ": Type mismatch, " << $1->getName() << " is a Function"<<endl;
			count_error++;
		}
	$$= new SymbolInfo($1->getName(), IdDup->getType());
	$$->setAsm(IdDup->getAsm());
	//cout<<$$->getType()<<endl;
		logprint<<$$->getName()<<endl;
	logprint<<endl;

	}
	else if (isDeclaredVar) 
	{
		$$= new SymbolInfo($1->getName(), vartype);
			logprint<<$$->getName()<<endl;
	logprint<<endl;
	}


	else if (isDeclaredParam) 
	{
		$$= new SymbolInfo($1->getName(), paramtype);
			logprint<<$$->getName()<<endl;
	logprint<<endl;
	}

	else
	{
		count_error++;
		logprint<<" Error at line "<< count_line <<" Undeclared variable '" + $1->getName() + "' referred"<<endl;
		errorprint<<"Error at line "<< count_line <<" Undeclared variable '" + $1->getName() + "' referred"<<endl;
	
	}

	//cout<<"hi"<<endl;






}
|
ID LTHIRD expression RTHIRD
{
	logprint << "Line " << count_line << ": variable: ID LTHIRD expression RTHIRD";
	logprint<<endl;

	SymbolInfo* IdDup = symtable.Lookup($1->getName());
	string code = "";
	string temp = newTemp();

	string expr_code = $3->getCode();
	string expr_asm  = $3->getAsm();

	if (IdDup == nullptr)
	{
		count_error++;
		logprint<<"Error at line " << count_line <<" Undeclared variable '" << $1->getName() << "' referred";
		errorprint<<"Error at line " << count_line <<" Undeclared variable '" << $1->getName() << "' referred";
	}

	else

	{
		if(IdDup->getSize()>0)
		{
			int arraysize=IdDup->getSize();
			string global_name =IdDup->getAsm();

			code += expr_code;
			code += "\tMOV SI, " + expr_asm + "\n";
			code += "\tADD SI, SI\n";
			code += "\tMOV AX, " + global_name + "[SI]\n";
					//	code += "\tMOV " + temp + ", AX\n";
			temp = global_name + "[" + expr_asm + "]";
			
			int index = stoi($3->getName() );
			if($3->getType()!="int"&&$3->getType()!="CONST_INT")
			{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Expression inside third brackets not an integer in '" << $1->getName() << "'"<<endl;
				errorprint<< "Error at line " << count_line << " Expression inside third brackets not an integer in '" << $1->getName() << "'"<<endl;

			}

			
	
			else if(index>=arraysize)
			{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Array Index exceeded Array size."<<endl;
				errorprint<< "Error at line " << count_line << " Array Index exceeded Array size."<<endl;
			}

			else{
			
			SymbolInfo* s = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", IdDup->getType());
			$$=s;
			$$->setCode(code);
			$$->setAsm(temp);
			logprint <<$$->getName() << endl;
			logprint<<endl;
			}
			//declaredSymbols.push_back(parameter($1->getName(), "int"));

		}

		else

		{
			logprint << "Error at line " << count_line << ": Type mismatch, " << $1->getName() << " is not an array"<<endl;
			errorprint << "Error at line " <<count_line << ": Type mismatch, " << $1->getName() << " is not an array"<<endl;
			count_error++;
		}
	}

	



}
;

expression
:
logic_expression
{
	logprint << "Line " << count_line << ": expression: logic_expression";
	logprint<<endl;

	$$ = $1;
	$$->setCode($1->getCode());
	$$->setAsm($1->getAsm());
	//cout<<" logic ex"<< $1->getCode()<<endl;
	logprint <<$$->getName() << endl;
	logprint<<endl;
}
|
variable ASSIGNOP logic_expression
{
	logprint << "Line " << count_line << ": expression: variable ASSIGNOP logic_expression";
	logprint<<endl;

	string leftType= "undeclared";
	string RightType= "undeclared";
	string leftName= $1->getName();
	string rightName=$3->getName();
	//logprint<<leftName<<" "<<rightName<<endl;
	leftType=$1->getType();
	RightType= $3->getType();

	for(int i=0; i<declaredSymbols.size(); i++)
	{
		if(declaredSymbols[i].getName()==leftName)
			leftType=declaredSymbols[i].getType();

	}
	
		for(int i=declaredSymbols.size()-1; i>=0; i--)
	{
		if(declaredSymbols[i].getName()==rightName)
			RightType=declaredSymbols[i].getType();

	}

	if(leftType=="undeclared"||leftType=="ID"){
	for(int i=0; i<leftName.size(); i++)
{
	if(leftName[i]=='['&&leftName[leftName.size()-1]==']')
		leftType="Array";

}
	}
	
	if(RightType=="undeclared"||RightType=="ID"){
	for(int i=0; i<rightName.size(); i++)
{
	if(rightName[i]=='['&&rightName[rightName.size()-1]==']')
		RightType="Array";
}
	}


	//logprint<<leftType<< " "<<RightType<<endl;

	if(RightType=="function"){
		for(int i=declaredFunctions.size()-1; i>=0; i--)
	{
		//cout<<"hello"<<endl;
		if(declaredFunctions[i].getName()==rightName){
			RightType=declaredFunctions[i].getReturnType();
			//cout<<RightType<<endl;
		//	RightIsAFunction=true;
			break;
		}
	}
	}

		if(RightType=="Array"){
			
		    string arrayname1="";
			bool IndexExists=false;

			for(int z=0; z<rightName.size(); z++)
			{
				if(rightName[z]=='[')
					IndexExists=true;
			}
			int j=0;
			if(IndexExists){
			while(rightName[j]!='[')  //determining array name
					{
						arrayname1+=rightName[j];
						j++;
					}
			}
			else
			arrayname1=rightName;

		for(int i=declaredArrays.size()-1; i>=0; i--)
	{
		//cout<<"hello"<<endl;
		if(declaredArrays[i].getName()==arrayname1){
			RightType=declaredArrays[i].getType();
		
	
			break;
		}
	}
	//logprint<<arrayname1<<endl;
	}
	
	
		

		if(leftType=="function"){
		for(int i=declaredFunctions.size()-1; i>=0; i--)
	{
	
		if(declaredFunctions[i].getName()==leftName){
			leftType=declaredFunctions[i].getReturnType();
		
			break;
		}
	}
	}

		if(leftType=="Array"){
			
		    string arrayname2="";
		bool IndexExists=false;
		for(int z=0; z<leftName.size(); z++)
			{
				if(leftName[z]=='[')
					IndexExists=true;
			}
			
			int j=0;
			if(IndexExists){
			while(leftName[j]!='[')  //determining array name
					{
						arrayname2+=leftName[j];
						j++;
					}
			}
			else
			arrayname2=leftName;
		
		for(int i=declaredArrays.size()-1; i>=0; i--)
	{
		
		if(declaredArrays[i].getName()==arrayname2){
			leftType=declaredArrays[i].getType();
			
			break;
		}
	}


	}

	//cout<<RightIsAFunction<<endl;
	
	//logprint<<leftType<< " "<<RightType<<endl;

	if(leftType!=RightType)
	{
		if(RightType=="void"||leftType=="void")
		{
			count_error++;
				logprint<< "Error at line " << count_line <<  " Void function used in expression " <<endl;
				errorprint<< "Error at line " << count_line << " Void function used in expression " <<endl;
		}
		else if($1->getSize()>0)
			{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Type mismatch: left one is an array '" << $1->getName() << "'"<<endl;
				errorprint<< "Error at line " << count_line << " Type mismatch: left one is an array '" << $1->getName() << "'"<<endl;

			}
		else if($3->getSize()>0)
			{
				count_error++;
				logprint<< "Error at line " << count_line <<  " Type mismatch: right one is an array '" << $3->getName() << "'"<<endl;
				errorprint<< "Error at line " << count_line << " Type mismatch: right one is an array '" << $3->getName() << "'"<<endl;

			}

		else if((leftType=="int"&&RightType=="CONST_INT")||(leftType=="float"&&RightType=="CONST_FLOAT")||(leftType=="float"&&RightType=="CONST_INT")||(leftType=="float"&&RightType=="int"))
		{
				//do nothing
		}

		
		else{
			if(leftType=="ID"||RightType=="ID")
			{}
			else{	count_error++;
				logprint<< "Error at line " << count_line <<  " Type mismatch of variable '" << $1->getName() << "'"<<endl;
				errorprint<< "Error at line " << count_line << " Type mismatch of variable '" << $1->getName() << "'"<<endl;
			}
		}
	}


	
	

	string code = "";

	code += $1->getCode();
	code += $3->getCode();
	//cout<<code;
	code += "\tMOV AX, " + $3->getAsm() + "\n";
	code += "\tMOV " +  $1->getAsm() + ", AX\n";
	$$ = new SymbolInfo($1->getName() + "=" + $3->getName(), "expression");
	$$->setCode(code);
	$$->setAsm( $1->getAsm());	
	logprint <<$$->getName() << endl;

	logprint<<endl;

}
;

logic_expression
:
rel_expression
{
	logprint << "Line " << count_line << ": logic_expression: rel_expression";
	logprint<<endl;
	$$=$1;
	logprint <<$$->getName() << endl;
	//logprint <<$$->getType() << endl;
	logprint<<endl;

}
|
rel_expression LOGICOP rel_expression
{
	logprint << "Line " << count_line << ": logic_expression: rel_expression LOGICOP rel_expression";
	logprint<<endl;

	string leftType= $1->getType();
	string rightType= $3->getType();
	string opsymbol = $2->getName();


	for(int i=0; i<declaredSymbols.size();i++)
	{
		if(declaredSymbols[i].getName()==$1->getName())
			leftType=declaredSymbols[i].getType();
	}

		for(int i=0; i<declaredSymbols.size();i++)
	{
		if(declaredSymbols[i].getName()==$3->getName())
			rightType=declaredSymbols[i].getType();
	}
	//cout<<leftType<<" "<<rightType;

	if(leftType!="int"&&leftType!="CONST_INT"||rightType!="int"&&rightType!="CONST_INT")
	{
		count_error++;
		logprint<< "Error at line " << count_line <<  " Both operand should be integer type"<<endl;
		errorprint<< "Error at line " << count_line << " Both operand should be integer type"<<endl;
	}

	string left_asm = $1->getAsm();
	string right_asm = $3->getAsm();

	string left_code = $1->getCode();
	string right_code = $3->getCode();

	string code = "";
	string temp = newTemp();

	string return_0 = newLabel();
	string return_1 = newLabel();

	code += left_code;
	code += right_code;

	if (opsymbol == "&&")
	{	
		code += "\tMOV AX, " + left_asm + "\n";
		code += "\tCMP AX, 0\n";
		code += "\tJE " + return_0 + "\n";
		code += "\tMOV AX, " + right_asm + "\n";
		code += "\tCMP AX, 0\n";
		code += "\tJE " + return_0 + "\n";
		code += "\tMOV AX, 1\n";
		code += "\tMOV " + temp + ", AX\n";
		code += "\tJMP " + return_1 + "\n";
		code += return_0 + ":\n";
		code += "\tMOV AX, 0\n";
		code += "\tMOV " + temp + ", AX\n";
		code += return_1 + ":\n";
	}
	else
		{
		code += "\tMOV AX, " + left_asm + "\n";
		code += "\tCMP AX, 0\n";
		code += "\tJNE " + return_0 + "\n";
		code += "\tMOV AX, " + right_asm + "\n";
		code += "\tCMP AX, 0\n";
		code += "\tJNE " + return_0 + "\n";
		code += "\tMOV AX, 1\n";
		code += "\tMOV " + temp + ", AX\n";
		code += "\tJMP " + return_1 + "\n";
		code += return_0 + ":\n";
		code += "\tMOV AX, 0\n";
		code += "\tMOV " + temp + ", AX\n";
		code += return_1 + ":\n";
						}


	$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(),	"int");
	$$->setCode(code);
	$$->setAsm(temp);
	logprint <<$$->getName() << endl;
	logprint<<endl;


}
;

rel_expression
:
simple_expression
{
	logprint << "Line " << count_line << ": rel_expression: simple_expression";
	logprint<<endl;
	$$=$1;
	logprint <<$$->getName() << endl;
	//logprint <<$$->getType() << endl;
	logprint<<endl;

}
|
simple_expression RELOP simple_expression
{
	logprint << "Line " << count_line << ": rel_expression: simple_expression RELOP simple_expression";
	logprint<<endl;



	string left_asm  = $1->getAsm();
	string right_asm = $3->getAsm();

	string left_code  = $1->getCode();
	string right_code = $3->getCode();

	string code = "";
	string temp = newTemp();

	string return_0 = newLabel();
	string return_1 = newLabel();

	string symbol = $2->getName();

	code += left_code;
	code += right_code;

	code += "\tMOV AX, " + left_asm  + "\n";
	code += "\tCMP AX, " + right_asm + "\n";

	if (symbol == "<")
	{
		code += "\tJL " + return_1 + "\n";
		code += "\tMOV AX, 0\n";
		code += "\tMOV " + temp + ", AX\n";
		code += "\tJMP " + return_0 + "\n";
		code += return_1 + ":\n";
		code += "\tMOV AX, 1\n";
		code += "\tMOV " + temp + ", AX\n";
		code += return_0 + ":\n";
	}
	else if (symbol == ">")
{
		code += "\tJG " + return_1 + "\n";
		code += "\tMOV AX, 0\n";
		code += "\tMOV " + temp + ", AX\n";
		code += "\tJMP " + return_0 + "\n";
		code += return_1 + ":\n";
		code += "\tMOV AX, 1\n";
		code += "\tMOV " + temp + ", AX\n";
		code += return_0 + ":\n";
	}
else if (symbol == "<=")
					{
		code += "\tJLE " + return_1 + "\n";
		code += "\tMOV AX, 0\n";
		code += "\tMOV " + temp + ", AX\n";
		code += "\tJMP " + return_0 + "\n";
		code += return_1 + ":\n";
		code += "\tMOV AX, 1\n";
		code += "\tMOV " + temp + ", AX\n";
		code += return_0 + ":\n";
	}
	else if (symbol == ">=")
	{
		code += "\tJGE " + return_1 + "\n";
		code += "\tMOV AX, 0\n";
		code += "\tMOV " + temp + ", AX\n";
		code += "\tJMP " + return_0 + "\n";
		code += return_1 + ":\n";
		code += "\tMOV AX, 1\n";
		code += "\tMOV " + temp + ", AX\n";
		code += return_0 + ":\n";
	}
	else if (symbol == "==")
	{
		code += "\tJE " + return_1 + "\n";
		code += "\tMOV AX, 0\n";
		code += "\tMOV " + temp + ", AX\n";
		code += "\tJMP " + return_0 + "\n";
		code += return_1 + ":\n";
		code += "\tMOV AX, 1\n";
		code += "\tMOV " + temp + ", AX\n";
		code += return_0 + ":\n";
	}
	else
	{
		code += "\tJNE " + return_1 + "\n";
		code += "\tMOV AX, 0\n";
		code += "\tMOV " + temp + ", AX\n";
		code += "\tJMP " + return_0 + "\n";
		code += return_1 + ":\n";
		code += "\tMOV AX, 1\n";
		code += "\tMOV " + temp + ", AX\n";
		code += return_0 + ":\n";
	}
	




	$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(),	"int");
	$$->setCode(code);
	$$->setAsm(temp);
	logprint <<$$->getName() << endl;
	logprint<<endl;

}
;


simple_expression
:
term
{
	logprint << "Line " << count_line << ": simple_expression: term";
	logprint<<endl;
	$$=$1;
	
	logprint <<$$->getName() << endl;
	logprint<<endl;
}
|
simple_expression ADDOP term
{
	logprint << "Line " << count_line << ": simple_expression: simple_expression ADDOP term";
	logprint<<endl;

	string ftype = "int";
	
	if (($1->getType()=="FLOAT") || ($3->getType()=="FLOAT"))
		{
			ftype = "FLOAT";
		}

	string temp;
	string code = "";

	string left_code  = $1->getCode();
	string right_code = $3->getCode();

	string left_asm  = $1->getAsm();
	string right_asm = $3->getAsm();

	code += left_code;
	code += right_code;

	if ($2->getName() == "+") {
		// simple ADD operation

		code += "\tMOV AX, " + left_asm  + "\n";
		code += "\tADD AX, " + right_asm + "\n";
		temp = newTemp();
		code += "\tMOV " + temp + ", AX\n";

	}
	else {
		// simple SUB operation

		code += "\tMOV AX, " + left_asm  + "\n";
		code += "\tSUB AX, " + right_asm + "\n";
		temp = newTemp();
		code += "\tMOV "  + temp + ", AX\n";
	}
	$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), ftype);

	$$->setCode(code);
	$$->setAsm(temp);

	logprint <<$$->getName() << endl;


	logprint<<endl;			
}
;


term
:
unary_expression
{
	logprint << "Line " << count_line << ": term : uanry_expression";
	logprint<<endl;

	$$=$1;
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
term MULOP unary_expression
{
	logprint << "Line " << count_line << ": term : term MULOP unary_expression";
	logprint<<endl;

	string leftType= $1->getType();
	string rightType= $3->getType();
	string opsymbol= $2->getName();
	for(int i=declaredSymbols.size()-1; i>=0; i--)
	{
		if(declaredSymbols[i].getName()==$3->getName())
			rightType= declaredSymbols[i].getType();

	}

		for(int i=declaredSymbols.size()-1; i>=0; i--)
	{
		if(declaredSymbols[i].getName()==$1->getName())
			leftType= declaredSymbols[i].getType();

	}
//	cout<<"sukhe theko "<<leftType<< " "<<rightType<<endl;
	//string opsymbol = $2->getName();
	string ftype="undeclared";
	//logprint<<opsymbol<<endl;

	if(rightType=="void")
	{
		count_error++;
			logprint<< "Error at line " << count_line <<  " Void function used in expression"<<endl;
			errorprint<< "Error at line " << count_line << " Void function used in expression"<<endl;
	}

	else if(opsymbol=="%")
	{
		if((leftType!="int"&&leftType!="CONST_INT")||(rightType!="int"&&rightType!="CONST_INT"))
		{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Non-Integer operand on modulus operator"<<endl;
			errorprint<< "Error at line " << count_line << " Non-Integer operand on modulus operator"<<endl;
		}

		else if($3->getName()=="0")
		{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Modulus by zero"<<endl;
			errorprint<< "Error at line " << count_line << " Modulus by zero"<<endl;
		}
		else{ 
		ftype="int";

		


	
	}
	}

	else
	{
		// if(leftType=="float"||rightType=="CONST_FLOAT"||rightType!="float"||rightType!="CONST_FLOAT")
		// 	type="float";
		// else
			

		if(opsymbol=="/" && $3->getName()=="0")
			{
			count_error++;
			logprint<< "Error at line " << count_line <<  " Division by zero"<<endl;
			errorprint<< "Error at line " << count_line << " Division by zero"<<endl;
			}

		else{ 
		ftype="int";
		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), ftype);
		declaredSymbols.push_back(parameter($$->getName(),ftype));


	
	
	}
	}


	// Assembly code
		string code = "";
		string temp = newTemp();

		string left_asm  = $1->getAsm();
		string right_asm = $3->getAsm();

		string left_code  = $1->getCode();
		string right_code = $3->getCode();

		code += left_code;
		code += right_code;

		if (opsymbol == "*") {

			code += "\tMOV AX, " + left_asm + "\n";
			code += "\tMOV BX, " + right_asm + "\n";
			code += "\tIMUL BX\n";
			code += "\tMOV " + temp + ", AX\n";

		}
		else {

			code += "\tMOV AX, " + left_asm + "\n";
			code += "\tCWD\n";
			code += "\tMOV BX, " + right_asm + "\n";
			code += "\tIDIV BX\n";

			if (opsymbol == "/") {
				code += "\tMOV " + temp + ", AX\n";
			}
			else {
				code += "\tMOV " + temp + ", DX\n";
			}
		}

		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), ftype);
		declaredSymbols.push_back(parameter($$->getName(),ftype));

		$$->setCode(code);
		$$->setAsm(temp);

		logprint <<$$->getName() << endl;
		logprint<<endl;

	//cout<<temp;
	//cout<<"final "<<$$->getAsm()<<endl;

}
;


unary_expression
:
ADDOP unary_expression
{
	logprint << "Line " << count_line << ": unary_expression: ADDOP unary_expression";
	logprint<<endl;
	string ftype= "undeclared";
	string fname= $2->getName();
	for(int i=0 ;i< declaredSymbols.size(); i++)
	{
		if(declaredSymbols[i].getName()==fname)
			 ftype=declaredSymbols[i].getType();
	}

	for(int i=0 ;i<fname.size(); i++)
	{
		if((fname[i]=='[')&&(fname[fname.size()-1]==']'))
			 ftype="Array";
	}


	if(ftype=="Array")
	{
		stringstream ss(fname);
		string arrayname="";
		
		int j=0;
		while(fname[j]!='[')  //determining array name
		{
			arrayname+=fname[j];
			j++;
		}

		for(int z= declaredArrays.size()-1; z>=0; z--)
		{
			if(arrayname==declaredArrays[z].getName())
				ftype= declaredArrays[z].getType();
		}
  
	}



		string temp;
		string code = "";
		string sign = $1->getName();

		string right_asm  = $2->getAsm();
		string right_code = $2->getCode();

		if (sign == "-"){
			temp = newTemp();
			code += right_code;
			code += "\tMOV AX, " + right_asm + "\n";
			code += "\tMOV " + temp + ", AX\n";
			code += "\tNEG " + temp + "\n";
		}
		else {
			temp = right_asm;
			code = right_code;
		}


	$$= new SymbolInfo($1->getName()+ $2->getName(), ftype);
	$$->setCode(code);
	$$->setAsm(temp);
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
NOT unary_expression
{
	logprint << "Line " << count_line << ": unary_expression: NOT unary_expression";
	logprint<<endl;

	string temp;
	string code = "";
	string right_asm  = $2->getAsm();
	string right_code = $2->getCode();

	string return_0 = newLabel();
	string return_1 = newLabel();

	code += right_code;

	code += "\tMOV AX, " + right_asm + "\n";
	code += "\tCMP AX, 0\n";
	code += "\tJE " + return_1 + "\n";
	code += "\tMOV AX, 0\n";
	code += "\tMOV " +  temp + ", AX\n";
	code += "\tJMP " + return_0 + "\n";

	code += return_1 + ":\n";
	code += "\tMOV AX, 1\n";
	code += "\tMOV " + temp + ", AX\n";
	code += return_0 + ":\n";


	$$= new SymbolInfo("!"+ $2->getName(), $2->getType());

	$$->setCode(code);
	$$->setAsm(temp);
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
factor
{
	logprint << "Line " << count_line << ": unary_expression: factor";
	logprint<<endl;
	$$=$1;
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
;


factor
:
variable
{
	logprint << "Line " << count_line << ": factor: variable";
	logprint<<endl;

	$$=$1;
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
ID LPAREN argument_list RPAREN
{
	logprint << "Line " << count_line << ": factor: ID LPAREN argument_list RPAREN";
	logprint<<endl;
	string temp;
	string code = "";
	string returntype = "undeclared";
	SymbolInfo * IDdup = symtable.Lookup( $1->getName());
	string nam= $1->getName();
	//undeclared check
//for(int i=0; i<declaredSymbols.size(); i++)
	//cout<<declaredSymbols[i].getName()<<" "<<declaredSymbols[i].getType()<<endl;

	if(nam=="println")
	{

	}
	else if(IDdup==nullptr)
	{
		count_error++;
		logprint<<"Error at line " << count_line <<" Undeclared Function'" << $1->getName() << "' referred"<<endl;
		errorprint<<"Error at line " << count_line <<" Undeclared Function '" << $1->getName() << "' referred"<<endl;

	}

	else

	{	//Function kina check

		//logprint<<"hello"<<endl;
		//sob thik thak thakle
		if(IDdup->getSize()==-1)
		{

			string nameArgs= $3->getName();
			string typeArgs= $3->getType();
			string asmArgs = $3->getAsm();

		FunctionDef cur;
		//logprint<<"Mad at disney"<<endl;
		//logprint<<nameArgs<<" "<<typeArgs<<endl;
		for(int i=0; i<declaredFunctions.size(); i++)
		{
			if(IDdup->getName()==declaredFunctions[i].getName()){
				returntype= declaredFunctions[i].getReturnType();
				cur= declaredFunctions[i];
		}
		}
		returntype= cur.getReturnType();

		bool isArgOne=true;
		for(int i=0 ;i<nameArgs.size(); i++)
		{
			if(nameArgs[i]==',')
				isArgOne=false;
		}

		vector <string> nameInd ,typeInd, asmInd;
		
		if(isArgOne==false)
		{
		 nameInd = splitString(nameArgs, ',');

		typeInd = splitString(typeArgs, ',');

		asmInd = splitString(asmArgs, ',');
		}
		else
		{
			nameInd.push_back(nameArgs);
			typeInd.push_back(typeArgs);
			asmInd.push_back(asmArgs);
		}
		vector <parameter> parInd ;
		

	//	cout<<nameInd.size() << " "<< declaredSymbols.size()<<endl;
	//	logprint<<nameInd[0]<<endl;

		for(int m=0; m<typeInd.size(); m++)
		{	
			//string typ= typeInd[m];
			string nam= nameInd[m];
			//cout<<typ<<endl;
			bool isArray=false;

			for(int j=0; j<nam.size(); j++)
			{
				if(nam[j]=='[')
					isArray=true;
			}

			if(isArray==true)
			{
				string aName="";
				int i=0;
				while(nam[i]!='['){
					aName+=nam[i];
					i++;
				}

				for(int z=declaredArrays.size()-1; z>=0; z--)
				{
					if(declaredArrays[z].getName()==aName)
						typeInd[m]=declaredArrays[z].getType();
				}
			}
		//logprint<<isArray<<endl;
//			cout<<typeInd[m]<<endl;


		}

		// 	for(int m=0; m<typeInd.size(); m++)
		// {	
		// 		cout<<nameInd[m]<<" "<<typeInd[m]<<endl;
		// }
		for(int i=0; i<nameInd.size(); i++)
		{
			//cout<<nameInd[i]<<" "<<typeInd[i]<<endl;
			
			if(typeInd[i]!="ID")
			{
				parInd.push_back(parameter(nameInd[i],typeInd[i]));
					
			}
			else{
			for(int j=declaredSymbols.size()-1; j>=0; j--)
			{
				//logprint<<nameInd[i]<< " "<< declaredSymbols[j].getName()<<endl;
				if(nameInd[i]==declaredSymbols[j].getName()){
					//logprint<<nameInd[i]<< " "<< declaredSymbols[j].getType()<<endl;
					
					parInd.push_back(parameter(nameInd[i],declaredSymbols[j].getType() ));
					break;
				}

			}
			}
		}
	

			 if(IDdup->getParameterSize()!=nameInd.size())
			{
				if(IDdup->getParameterSize()==0){}

				else{

			count_error++;

			logprint<<"Error at line " << count_line <<" Total number of arguments mismatch in function '" << IDdup->getName() << "'"<<endl;
			errorprint<<"Error at line " << count_line <<" Total number of arguments mismatch in function '" << IDdup->getName() << "'"<<endl;
			}
			}

			else //arguments and parameters match
			{
				vector<parameter> pars =cur.getParList();
				for(int i=0; i<pars.size(); i++)
				{
					//logprint<<parInd[i].getType()<<endl;
					if(parInd[i].getType()!=pars[i].getType())
						{
						count_error++;
						logprint<<"Error at line " << count_line<<" " <<i+1<<"th argument"  << " mismatch on "<<IDdup->getName()<<" function"<<endl;
						errorprint<<"Error at line " << count_line<<" " <<i+1<<"th argument"  << " mismatch on "<<IDdup->getName()<<" function"<<endl;
					//	errorprint<<parInd[i].getType()<<" "<<pars[i].getType()<<endl;
						break;
						}
				}

						code += "\tPUSH AX\n";
						code += "\tPUSH BX\n";
						code += "\tPUSH CX\n";
						code += "\tPUSH DX\n";


						int count = asmInd.size();
						while(count--) {
							code += "\tPUSH " + asmInd[count] + "\n";
						}

						code += "\tCALL " + $1->getName() + "\n";
						temp = newTemp();
						code += "\tPOP " + temp + "\n";

						code += "\tPOP DX\n";
						code += "\tPOP CX\n";
						code += "\tPOP BX\n";
						code += "\tPOP AX\n";

			}

		}
		else
		{
		count_error++;
		
		logprint<<"Error at line " << count_line <<" Non Function Identifier '" << IDdup->getName() << "' accessed"<<endl;
		errorprint<<"Error at line " << count_line <<" Non Function Identifier '" << IDdup->getName() << "' accessed"<<endl;

		}

	}
			
			$$ = new SymbolInfo($1->getName() + "(" + $3->getName() + ")",	returntype);
			$$->setCode(code);
			$$->setAsm(temp);
			//cout<<"temp "<<temp;
			logprint<<$$->getName()<<endl;
			logprint<<endl;

}
|
LPAREN expression RPAREN
{
	logprint << "Line " << count_line << ": factor: LPAREN expression RPAREN";
	logprint<<endl;

	$$ = new SymbolInfo("(" + $2->getName() + ")",	$2->getType() );

	$$->setCode($2->getCode());
	$$->setAsm($2->getAsm());
	logprint<<$$->getName()<<endl;
	logprint<<endl;
	
}
|
CONST_INT
{
	logprint << "Line " << count_line << ": factor: CONST_INT"<<endl;
	logprint<<endl;

	$$=yylval.symbol;
	$$->setType("int");
	$$->setAsm(yylval.symbol->getName());
	logprint<<$$->getName()<<endl;
	logprint<<endl;


}
|
CONST_FLOAT
{
	logprint << "Line " << count_line << ": factor: CONST_FLOAT"<<endl;
	logprint<<endl;

	$$=yylval.symbol;
	$$->setType("float");
	$$->setAsm(yylval.symbol->getName());
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
variable INCOP
{
	logprint << "Line " << count_line << ": factor: variable INCOP";
	logprint<<endl;

	$$=new SymbolInfo($1->getName()+ "++" , $1->getType() );
	string code = "";
	string temp = newTemp();
	string var_code = $1->getCode();
	string var_asm = $1->getAsm();

	code += var_code;
	code += "\tMOV AX, " + var_asm + "\n";
	code += "\tMOV " + temp + ", AX\n";
	code += "\tINC " + var_asm + "\n";

	$$->setCode(code);
	$$->setAsm(temp);
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
variable DECOP
{
	logprint << "Line " << count_line << ": factor: variable DECOP";
	logprint<<endl;

	$$=new SymbolInfo($1->getName()+ "--" , $1->getType() );

	string code = "";
	string temp = newTemp();
	string var_code = $1->getCode();
	string var_asm = $1->getAsm();

	code += var_code;
	code += "\tMOV AX, " + var_asm + "\n";
	code += "\tMOV " + temp + ", AX\n";
	code += "\tDEC " + var_asm + "\n";

	$$->setCode(code);
	$$->setAsm(temp);


	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
;


argument_list
:
arguments
{
	logprint << "Line " << count_line << ": argument_list: arguments";
	logprint<<endl;

	$$=$1;
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}
|
{
	logprint << "Line " << count_line << ": argument_list: arguments";
	logprint<<endl;

	$$=new SymbolInfo("", "void");
	$$->setAsm("");
	logprint<<$$->getName()<<endl;
	logprint<<endl;
}


;

arguments
:
arguments COMMA logic_expression
{
	logprint << "Line " << count_line << ": arguments : arguments COMMA logic_expression";
	logprint<<endl;

	string names = $1->getName() + "," + $3->getName();
	string types = $1->getType() + "," + $3->getType();
	string asmNames = $1->getAsm()	+ "," + $3->getAsm();

	string code = $1->getCode() + $3->getCode();

	$$ = new SymbolInfo(names, types);
	$$->setCode(code);
	$$->setAsm(asmNames);
	

	logprint<<$$->getName()<<endl;
	logprint<<endl;

}
|
logic_expression
{
	logprint << "Line " << count_line << ": arguments :logic_expression";
	logprint<<endl;

	$$=$1;

	logprint<<$$->getName()<<endl;
	logprint<<endl;

}
;






%%


int main(int argc,char *argv[])
{
	if(argc!=2){
		cout << "Please provide input file name and try again\n";
		return 0;
	}

	infile=fopen(argv[1],"r");
	if(infile==NULL){
		cout << "Cannot open specified file\n";
		return 0;
	}

	logprint.open("log.txt");
	errorprint.open("error.txt");

	yyin=infile;
	yyparse();
	symtable.printAllScopeTable(logprint);

	/* for(int i=0; i<declaredSymbols.size(); i++)
	{
		cout<<declaredSymbols[i].getName()<< " "<<declaredSymbols[i].getType()<<endl;
	}
	cout<<"Func"<<endl;
	
	for(int i=0; i<declaredFunctions.size(); i++)
	{
		cout<<declaredFunctions[i].getName()<< " "<<declaredFunctions[i].getReturnType()<<endl;
	}
	cout<<"Array"<<endl;
	
	for(int i=0; i<declaredArrays.size(); i++)
	{
		cout<<declaredArrays[i].getName()<< " "<<declaredArrays[i].getType()<<endl;
	} */
	declaredFunctions.clear();
	declaredSymbols.clear();
	declaredArrays.clear();
	
	

	logprint << "Total lines: " << count_line << endl;
    logprint << "Total errors: " << count_error << endl;
	fclose(yyin);
	logprint.close();
	errorprint.close();


	return 0;
}
