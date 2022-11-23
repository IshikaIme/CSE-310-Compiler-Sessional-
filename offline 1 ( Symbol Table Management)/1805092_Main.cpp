#include<bits/stdc++.h>
#include"1805092_ScopeTable.h"
#include"1805092_SymbolInfo.h"
#include"1805092_SymbolTable.h"
#include <fstream>
using namespace std;
int main()
{
    //string line;

    //ifstream Inputfile ("input.txt");
   
    //fstream Inputfile;
	//Inputfile.open("Input.txt", ios::in);
    freopen("input.txt", "r", stdin);
    char ch;
    int numOfBuckets;
    cin>>numOfBuckets;
    SymbolTable ST(numOfBuckets);
    while(cin>>ch){

        if(ch == 'I'){
            string name,type;
            cin>>name>>type;

            if(ST.getCurrentScopeTable()==nullptr)
                cout<<"No scope to insert";
            bool insertFlag= ST.Insert(name, type);

            

            cout<<endl;
       
       }

        else if(ch=='P') {
           char ch2;
           cin>>ch2;
           if(ch2=='A')
                ST.printAllScopeTable();
           else if(ch2=='C')
                ST.printCurrentScopeTable();

            cout<<endl;
       }

        else if(ch=='S') {
           
            ST.EnterScope();
            //cout<<endl;
       }

        else if(ch=='L') {
            string str;
            cin>>str;
            SymbolInfo* LNode= ST.Lookup(str);
           // cout<<"Lookup";
           // if(LNode==nullptr)
             //   cout<<str<<" is not found"<<endl;
            cout<<endl;
       }

        else if(ch=='D') {
            string str;
            cin>>str;
           // SymbolInfo* LNode= ST.Lookup(str);
           //  if(LNode!=nullptr)
                //cout<<"Found it"<<endl;
                
            bool deleteFlag= ST.Remove(str);
            cout<<endl;
       }

        else if(ch=='E')
        {
            ST.ExitScope();
            cout<<endl;
        }
        else
        {
            cout<<"Operation not found"<<endl;
        }
    
    }
     


}
