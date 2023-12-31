%{
#include "postgres.h"

#include "utils/builtins.h"
#include "parser/scansup.h"

#include "statistics/statistics.h"
#include "statistics_gram.h"

/* Handle to the buffer that the lexer uses internally */
static YY_BUFFER_STATE scanbufhandle;

void statistic_scanner_finish(void);
void statistic_scanner_init(const char *str);
void statistic_yyerror(const char *message);
%}


%option noinput
%option nounput
%option noyywrap
%option prefix="statistic_yy"

digit			[0-9]+
double			[0-9.]

%%

[ \t\n]		;
"{"			{ return '{'; }
"}"			{ return '}'; }
","			{ return ','; }
"\""			{ return '"'; }
":"			{ return ':'; }
"=>"			{ return ARROW; }

{digit}+		{
				statistic_yylval.uintval = strtoul(yytext, NULL, 10);
				return UCONST;
			}
{double}+		{
				statistic_yylval.doubleval = strtod(yytext, NULL);
				return DOUBLE;
			}

%%

void
statistic_yyerror(const char *message)
{
	if (*yytext == YY_END_OF_BUFFER_CHAR)
	{
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
			errmsg("invalid input syntax for extended stats type"),
			errdetail("%s at end of input", message)));
	}
	else
	{
		ereport(ERROR,
			(errcode(ERRCODE_SYNTAX_ERROR),
			errmsg("invalid input syntax for extended stats type"),
			errdetail("%s at or near \"%s\"", message, yytext)));
	}
}

void
statistic_scanner_init(const char *str)
{
	Size		slen = strlen(str);
	char	   *scanbuf;

	/*
	 * Might be left over after ereport()
	 */
	if (YY_CURRENT_BUFFER)
		yy_delete_buffer(YY_CURRENT_BUFFER);

	/*
	 * Make a scan buffer with special termination needed by flex.
	 */
	scanbuf = (char *) palloc(slen + 2);
	memcpy(scanbuf, str, slen);
	scanbuf[slen] = scanbuf[slen + 1] = YY_END_OF_BUFFER_CHAR;
	scanbufhandle = yy_scan_buffer(scanbuf, slen + 2);
}

void
statistic_scanner_finish(void)
{
	yy_delete_buffer(scanbufhandle);
	scanbufhandle = NULL;
}
