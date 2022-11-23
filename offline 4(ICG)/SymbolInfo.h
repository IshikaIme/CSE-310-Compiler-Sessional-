#include <bits/stdc++.h>
using namespace std;

class gVar
{
    private:
        string name;
        int size;
    public:
        gVar(string n, int s)
        {
            name=n;
            size=s;
        }

        string getName()
        {
            return this->name;
        }
        int getSize()
        {
            return this->size;
        }

};

class parameter
{
        private:
            string name, type;
        public:
            parameter(string n, string t)
            {
                name= n;
                type=t;
            }

            string getType()
            {
                return this->type;
            }
            string getName()
            {
                return this->name;
            }
};

class FunctionDef
{
    private:
        string name,returntype;
        vector<parameter> paramlist;
        bool ParamNameExists;
    public:
        FunctionDef()
        {

        }
        FunctionDef(string na, string ty, vector<parameter> parlist)
        {

            name=na;
            returntype=ty;
            paramlist= parlist;
            ParamNameExists=true;
        }

           FunctionDef(string na, string ty, vector<parameter> parlist,bool Par)
        {

            name=na;
            returntype=ty;
            paramlist= parlist;
            ParamNameExists=Par;
        }

    vector<parameter> getParList()
    {
        return paramlist;
    }

   string getReturnType()
    {
        return returntype;
    }
   string getName()
    {
        return name;
    }

 

      bool IsParNameExists()
    {
       return this->ParamNameExists;
    }
};


class SymbolInfo{
    private:
        string name;
        string type;
        string code, asmName;
        SymbolInfo* SymbolNextInChain;
        bool isDefined;
        vector<parameter> parameter_type;
        int size;
    public:

        

         SymbolInfo(string name, string type,vector<parameter> parameter_type, int size, bool defined ) {
            this->name = name;
            this->type = type;
            this->parameter_type= parameter_type;
            this->isDefined = false;
            this->size=-1;
            this->isDefined= defined;
            this->code = "";
            this->asmName = "";
        }

        
        SymbolInfo(string name, string type,int size) {
            this->name = name;
            this->type = type;
            this->SymbolNextInChain = nullptr;
            this->isDefined = false;
            this->size=size;
        }

        SymbolInfo(string name, string type) {
            this->name = name;
            this->type = type;
            this->SymbolNextInChain = nullptr;
            this->isDefined = false;
            this->size=0;
        }

        SymbolInfo(const SymbolInfo &si)
        {
            this->name = si.name;
            this->type = si.type;
            this->size = si.size;
            this->SymbolNextInChain = si.SymbolNextInChain;
            this->parameter_type= si.parameter_type;
            this->isDefined = si.isDefined;
            this->asmName = si.asmName;
        }

        
         SymbolInfo()
        {
            //constructor
            this->name = "";
            this->type = "";
            this->SymbolNextInChain = nullptr;
            this->isDefined = false;
            this->size=0;
        }



        void setName(string name)
        {
            this->name=name;
        };
        string getName()
        {
            return this->name;
        };
        
        void setCode(string _code)
        {
             this->code = _code;
        }

        string getCode()
        {
           return this->code;
        }

        void setType(string type)
        {
             this->type=type;
        }
        
        string getType()
        {
             return this->type;
        }

        void setAsm(string asmName)
        {
            this->asmName = asmName;
        }

        string getAsm()
        {
           return this->asmName;
        }

        void setSymbolNextInChain(SymbolInfo* nextSymbol)
        {
            this->SymbolNextInChain= nextSymbol;
        }

        void setIsDefined(bool flag)
        {
            this->isDefined=flag;
        }

        bool getIsDefined()
        {
            return this->isDefined;
        }

        void setParameterType(parameter param_type)
        {
            this->parameter_type.push_back(param_type);
        }

        parameter getParameter(int i){
            return this->parameter_type.at(i);
        }

        vector <parameter> getParameterList(){
            return this->parameter_type;
        }


        int getParameterSize(){
            return parameter_type.size();
        }


        SymbolInfo* getSymbolNextInChain()
        {
            return this->SymbolNextInChain;
        }

          ~SymbolInfo()
        {
            //destructor
          //  delete SymbolNextInChain;
        }

        int getSize()
        {
            return this->size;
        }

};
