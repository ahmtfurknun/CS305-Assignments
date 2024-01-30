%{
#include <stdio.h>
void yyerror (const char *s)
{;}

%}

%token tMAIL tENDMAIL tSCHEDULE tENDSCHEDULE tSEND tSET tTO tFROM tAT tCOMMA tCOLON tLPR tRPR tLBR tRBR tIDENT tSTRING tADDRESS tDATE tTIME
%%

program	: components
	    | 
;

components	: mail_block
            | set
            | mail_block components
            | set components
            
;

mail_block	: tMAIL tFROM tADDRESS tCOLON tENDMAIL
	        | tMAIL tFROM tADDRESS tCOLON statements tENDMAIL
;

statements	: set
            | send
            | schedule
            | set statements
            | send statements
            | schedule statements
;

set	: tSET tIDENT tLPR tSTRING tRPR
;

send	: tSEND tLBR tIDENT tRBR tTO recipient_list
		| tSEND tLBR tSTRING tRBR tTO recipient_list
;

schedule	: tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON send_list tENDSCHEDULE
;

send_list	: send 
		    | send send_list
;

recipient_list	: tLBR recipients tRBR
;

recipients	: tLPR tADDRESS tRPR
            | tLPR tIDENT tCOMMA tADDRESS tRPR
            | tLPR tSTRING tCOMMA tADDRESS tRPR
            | tLPR tADDRESS tRPR tCOMMA recipients
            | tLPR tIDENT tCOMMA tADDRESS tRPR tCOMMA recipients
            | tLPR tSTRING tCOMMA tADDRESS tRPR tCOMMA recipients
;

%%

int main ()
{
	if (yyparse())
	{
		// parse error
		printf("ERROR\n");
		return 1;
	}
	else
	{
		// successful parsing
		printf("OK\n");
		return 0;
	}
}