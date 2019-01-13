%{
	#include <stdio.h>
     #include <string.h>

	int yylex();
	int yyerror(const char *msg);
	int first_line;
	int first_column;

     int EsteCorecta = 1;
	char msg[500];

	class TVAR
	{
	     char* nume;
	     int valoare;
	     bool init;
	     TVAR* next;
	  
	  public:
	     static TVAR* head;
	     static TVAR* tail;

	     TVAR(char* n, int v = -1, bool init = false);
	     TVAR();
	     int exists(char* n);
             void add(char* n, int v = -1, bool init = false);
             int getValue(char* n);
	     void setValue(char* n, int v, bool init);
	     bool initializedVar(char* n);
	     void showTable();
	};

	TVAR* TVAR::head;
	TVAR* TVAR::tail;

	TVAR::TVAR(char* n, int v, bool init)
	{
	 this->nume = new char[strlen(n)+1];
	 strcpy(this->nume,n);
	 this->valoare = v;
	 this->init = init;
	 this->next = NULL;
	}

	TVAR::TVAR()
	{
	  TVAR::head = NULL;
	  TVAR::tail = NULL;
	}

	int TVAR::exists(char* n)
	{
	  TVAR* tmp = TVAR::head;
	  while(tmp != NULL)
	  {
	    if(strcmp(tmp->nume,n) == 0)
	      return 1;
            tmp = tmp->next;
	  }
	  return 0;
	 }

         void TVAR::add(char* n, int v, bool init)
	 {
	   TVAR* elem = new TVAR(n, v, init);
	   if(head == NULL)
	   {
	     TVAR::head = TVAR::tail = elem;
	   }
	   else
	   {
	     TVAR::tail->next = elem;
	     TVAR::tail = elem;
	   }
	 }

         int TVAR::getValue(char* n)
	 {
	   TVAR* tmp = TVAR::head;
	   while(tmp != NULL)
	   {
	     if(strcmp(tmp->nume,n) == 0)
	      return tmp->valoare;
	     tmp = tmp->next;
	   }
	   return -1;
	  }

	  void TVAR::setValue(char* n, int v, bool init)
	  {
	    TVAR* tmp = TVAR::head;
	    while(tmp != NULL)
	    {
	      if(strcmp(tmp->nume,n) == 0)
	      {
		tmp->valoare = v;
		tmp->init = init;
	      }
	      tmp = tmp->next;
	    }
	  }
	
	bool TVAR::initializedVar(char* n){
		
		TVAR* tmp = TVAR::head;
		while(tmp != NULL){
			if(strcmp(tmp->nume,n) == 0) return tmp->init;
			tmp = tmp->next;
		}
		return false;
	}
	void TVAR::showTable(){
		TVAR*tmp = TVAR::head;
		while(tmp != NULL){
			printf("%s %d\n",tmp->nume,tmp->valoare);
			tmp = tmp->next;
		}
	}

	TVAR* ts = NULL;
%}


%union { char* id; int val; }

%token TOK_PROGRAM TOK_VAR TOK_BEGIN TOK_END TOK_DOT TOK_COMMA TOK_COL TOK_SEMICOL TOK_PLUS TOK_MINUS TOK_MUL TOK_DIV TOK_LEFT TOK_RIGHT TOK_ASSIGN TOK_READ TOK_WRITE TOK_FOR TOK_TO TOK_DO TOK_ERROR
%token <id> TOK_ID TOK_INTEGER
%token <val> TOK_NO
%type <id> idlist

%locations


%start prog

%left TOK_PLUS TOK_MINUS
%left TOK_MULTIPLY TOK_DIVIDE

%%

prog : 	
	|
	TOK_PROGRAM progname TOK_VAR declist TOK_BEGIN stmtlist TOK_END TOK_DOT
	{
		//ts->showTable();
		//afisez tabela de simboli
	}
	|
	error ';' prog 
	;

progname : TOK_ID ;

declist : dec
	|
	declist TOK_SEMICOL dec 
	;
dec : idlist TOK_COL type {
	
	char* token = strtok($1, " ,:");

	while (token != NULL) {
		if(ts != NULL){
			if(!ts->exists(token)){
				ts->add(token,-1,false);
			}
			else{
			    sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, token);
			    yyerror(msg);
			    YYERROR;
			}
		}
		else
  		{
			  ts = new TVAR();
			  ts->add(token,-1,false);
		}		
		token = strtok(NULL, " ,:INTEGER;");
	}
	}
	;
type : TOK_INTEGER
	;
idlist : TOK_ID 
	|
	idlist TOK_COMMA TOK_ID { strcat($1,","); strcat($1,$3); }
	;
stmtlist : stmt 
	   |
	   stmtlist TOK_SEMICOL stmt
	   ;
stmt : assign
	 |
	 read
	 |
         write
	 |
	 for
	 ;
assign : TOK_ID TOK_ASSIGN exp //verific daca ID este declarat, daca da, ii dau valoare si il initializez, daca nu, eroare
	{
		if(ts != NULL){
			if(ts->exists($1)){
				ts->setValue($1,1,true);
			}
			
			else
	  		{	
			    sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $1);
			    yyerror(msg);
			    YYERROR;
			}
		}
		else{
			
	  		sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $1);
	  		yyerror(msg);
	  		YYERROR;
		}
	}
	;
exp : term
	|
	exp TOK_PLUS term
	|
	exp TOK_MINUS term
	;
term : factor
   	 |
	 term TOK_MUL factor
	 |
	 term TOK_DIV factor
	 ;
factor : TOK_ID
	   |
	   TOK_NO
	   |
	   TOK_LEFT exp TOK_RIGHT
	   ;
read : TOK_READ TOK_LEFT idlist TOK_RIGHT
	{
	
	char* token = strtok($3, " ,:");

	while (token != NULL) {
		if(ts != NULL){
			if(!ts->exists(token)){	
	  			sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $3);
	  			yyerror(msg);
	  			YYERROR;
			}
			else{
				ts->setValue(token,1,true);
			}
		}
		else
  		{
			sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $3);
  			yyerror(msg);
  			YYERROR;
		}		
		token = strtok(NULL, " ,:;");
	}
	}
	 ;
write : TOK_WRITE TOK_LEFT idlist TOK_RIGHT
	{
	
	char* token = strtok($3, " ,:");

	while (token != NULL) {
		if(ts != NULL){
			if(!ts->exists(token)){	
	  			sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $3);
	  			yyerror(msg);
	  			YYERROR;
			}
			else if(!ts->initializedVar(token)){
	  			sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost initializata!", @1.first_line, @1.first_column, $3);
	  			yyerror(msg);
	  			YYERROR;
				
			}
		}
		else
  		{
			sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $3);
  			yyerror(msg);
  			YYERROR;
		}		
		token = strtok(NULL, " ,:;");
	}
	}
	  ;
for : TOK_FOR indexexp TOK_DO body
	;
indexexp : TOK_ID TOK_ASSIGN exp TOK_TO exp
	{
		if(ts != NULL){
			if(!ts->exists($1)){	
	  			sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $1);
	  			yyerror(msg);
	  			YYERROR;
			}
			else{
				ts->setValue($1,1,true);
			}
		}
		else
  		{
			sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $1);
  			yyerror(msg);
  			YYERROR;
		}



	}
	      ;
body : stmt 
	 |
	 TOK_BEGIN stmtlist TOK_END
	 ;

%%

int main()
{
	yyparse();	

	if(EsteCorecta == 1)
	{
		printf("CORECTA\n");		
	}
	else printf("GRESITA\n");

       return 0;
}

int yyerror(const char *msg)
{
	EsteCorecta = 0;
	printf("Error: %s\n", msg);
	return 1;
}
