%{ /* -*- C++ -*- */
#include <cerrno>
#include <climits>
#include <cstdlib>
#include <string>

#include "Types.hpp"
#include "Driver.hpp"
#include "Context.hpp"
#include "Central.hpp"
#include "Function.hpp"
#include "Statement.hpp"
#include "Expression.hpp"

#undef yywrap
#define yywrap() 1

#if defined __GNUC__ && 7 <= __GNUC__
#pragma GCC diagnostic ignored "-Wnull-dereference"
#endif
%}

%option noyywrap nounput noinput debug batch

id    [a-zA-Z][a-zA-Z_0-9]*
int   [0-9]+
blank [ \t]

%{
    #define YY_USER_ACTION  loc.columns (yyleng);
%}

%%
    
%{
    yy::location& loc = drv.location;
    loc.step();
%}

{blank}+   loc.step();
[\n]+      loc.lines(yyleng); loc.step();


"--" { return yy::parser::make_MINUS_MINUS(loc); }
"++" { return yy::parser::make_PLUS_PLUS(loc); }

"-" { return yy::parser::make_MINUS(loc); }
"+" { return yy::parser::make_PLUS(loc); }

"|" { return yy::parser::make_BITOR(loc); }
"&" { return yy::parser::make_BITAND(loc); }
"^" { return yy::parser::make_BITXOR(loc); }

"<<" { return yy::parser::make_BITLSHIFT(loc); }
">>" { return yy::parser::make_BITRSHIFT(loc); }

"<" { return yy::parser::make_LESS(loc); }
">" { return yy::parser::make_GREATER(loc); }

"!=" { return yy::parser::make_NOT_EQ(loc); }
"==" { return yy::parser::make_IS_EQ(loc); }

";" { return yy::parser::make_SEMICOLON(loc); }
"," { return yy::parser::make_COMMA(loc); }
"=" { return yy::parser::make_EQ(loc); }

"(" { return yy::parser::make_LPAREN(loc); }
")" { return yy::parser::make_RPAREN(loc); }
"{" { return yy::parser::make_LBRACE(loc); }
"}" { return yy::parser::make_RBRACE(loc); }

"function" { return yy::parser::make_FUNCTION(loc); }
"proto"    { return yy::parser::make_PROTO(loc); }
"val"      { return yy::parser::make_VAL(loc); }
"void"     { return yy::parser::make_VOID(loc); }
"byte"     { return yy::parser::make_BYTE(loc); }
"bool"     { return yy::parser::make_BYTE(loc); }
"local"    { return yy::parser::make_LOCAL(loc); }
"global"   { return yy::parser::make_GLOBAL(loc); }
"if"       { return yy::parser::make_IF(loc); }
"while"    { return yy::parser::make_WHILE(loc); }
"return"   { return yy::parser::make_RETURN(loc); }


{int} {
    errno = 0;
    
    long n = std::strtol(yytext, NULL, 10);
    
    if (!(INT_MIN <= n && n <= INT_MAX && errno != ERANGE))
    {
        throw yy::parser::syntax_error (loc, "integer is out of range: " + std::string(yytext));
    }
    
    return yy::parser::make_NUMCONST(n, loc);
}

{id} { return yy::parser::make_IDENTIFIER(yytext, loc); }

.  throw yy::parser::syntax_error(loc, "invalid character: " + std::string(yytext));

<<EOF>> return yy::parser::make_END(loc);

(\/\/[^\r\n]*)                               { /* single line comment */ }
\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*+\/ { /*  multi line comment */ }

%%

void driver::scan_begin(void)
{
    yy_flex_debug = trace_scanning;
    
    if (file.empty () || file == "-")
    {
        yyin = stdin;
    }
    else if (!(yyin = fopen (file.c_str (), "r")))
    {
        std::cerr << "cannot open " << file << ": " << strerror(errno) << '\n';
        std::exit(EXIT_FAILURE);
    }
}

void driver::scan_end(void)
{
    fclose(yyin);
}