%skeleton "lalr1.cc" /* -*- C++ -*- */
%require "3.8.2"
%defines

%define api.token.constructor
%define api.value.type variant
%define parse.assert

%code requires {
#include <string>
#include <vector>
#include <cstdint>
#include <cstdlib>
  class driver;

#include "Types.hpp"
//#include "Driver.hpp"
#include "Context.hpp"
#include "Central.hpp"
#include "Function.hpp"
#include "Statement.hpp"
#include "Expression.hpp"
#include <cstdint>
#include <cstdlib>
}

// The parsing context.
%param { driver& drv }

%locations

%define parse.trace
%define parse.error verbose
//%define parse.lac full

%code {
#include "Types.hpp"
#include "Driver.hpp"
#include "Context.hpp"
#include "Central.hpp"
#include "Function.hpp"
#include "Statement.hpp"
#include "Expression.hpp"
}

%define api.token.prefix {T_}
%token
    END 0 "end of file"
    
    MINUS_MINUS "--"
    PLUS_PLUS "++"

    MINUS "-"
    PLUS "+"

    BITOR "|"
    BITAND "&"
    BITXOR "^"

    BITLSHIFT "<<"
    BITRSHIFT ">>"

    LESS "<"
    GREATER ">"

    NOT_EQ "!="
    IS_EQ "=="

    SEMICOLON ";"
    COMMA ","
    EQ "="
    LPAREN "("
    RPAREN ")"
    LBRACE "{"
    RBRACE "}"


    FUNCTION "function"
    PROTO "proto"
    VAL "val"
    VOID "void"
    BYTE "byte"
    LOCAL "local"
    GLOBAL "global"
    IF "if"
    WHILE "while"
    RETURN "return"
;

%left ","
%right "?" ":" "="

%left "==" "!="
%left ">" "<"
%left "|"
%left "&"
%left "^"

%left ">>" "<<"
%left "+" "-"

%right "++" "--"

%left "("



%token<std::string> IDENTIFIER

%token<std::string> STRINGCONST
%token<std::uint8_t> NUMCONST

%type<ti::Expression*> expression expression_opt
%type<ti::Statement*> statement
%type<std::vector<ti::Variable*>> variable_declarator variable_declarator_i

%type<ti::TypeVisibility> type_visibility
%type<ti::TypeSpecifier> type_specifier
%type<ti::TypeQualifier> type_qualifier
%type<ti::CompleteType> complete_type


%type<std::vector<ti::Statement*>> statements statements_opt

%type<ti::Function> definition function_declarator function_header

%type<std::vector<ti::Function>> definitions definitions_opt

%type<std::vector<ti::Argument>> fdecl_args fdecl_args_opt

%type<std::vector<ti::Expression*>> fcall_args fcall_args_opt

%%
    
%start translation_unit;

translation_unit
: definitions_opt END
;

// definitions
definitions_opt
: %empty      { $$ = {}; }
| definitions { $$ = $1; }
;

definitions
: definitions definition
{
    drv.definition_queue.emplace_back($2);
    $$ = drv.definition_queue;
}
| definition
{
    drv.definition_queue.emplace_back($1);
    $$ = drv.definition_queue;
}
;

definition
: function_declarator { $$ = $1; }
;
// /definitions


// types
type_specifier
: "byte" { $$ = ti::TypeSpecifier::BYTE; }
| "void" { $$ = ti::TypeSpecifier::VOID; }
;

type_qualifier
: "val" { $$ = ti::TypeQualifier::VAL; }
;

type_visibility
: "local"  { $$ = ti::TypeVisibility::LOCAL; }
| "global" { $$ = ti::TypeVisibility::GLOBAL; }
;

complete_type
: type_specifier type_qualifier { $$ = ti::CompleteType{ $1, $2 }; }
;
// /types


// functions
function_declarator
: "proto" function_header ";" { $$ = $2; }
| function_header statement   { auto a = $1; a.body = $2; $$ = a; }
;

function_header
: "function" complete_type IDENTIFIER "=" "(" fdecl_args_opt ")" { $$ = ti::Function{ $3, $2, $6, NULL }; }
;

    // function definition args
    fdecl_args_opt
    : %empty     { $$ = {}; }
    | fdecl_args { $$ = $1; }
    ;
    
    fdecl_args
    : complete_type IDENTIFIER
    {
        drv.fdecl_args_queue.emplace_back(ti::Argument{ $2, $1 });
        $$ = drv.fdecl_args_queue;
    }
    | fdecl_args "," complete_type IDENTIFIER
    {
        drv.fdecl_args_queue.emplace_back(ti::Argument{ $4, $3 });
        $$ = drv.fdecl_args_queue;
    }
    ;
    // /function definition args
    
    // function call args
    fcall_args_opt
    : %empty     { $$ = {}; }
    | fcall_args { $$ = $1; }
    ;
    
    fcall_args
    : expression
    {
        drv.fcall_args_queue.emplace_back($1);
        $$ = drv.fcall_args_queue;
    }
    | fcall_args "," expression
    {
        drv.fcall_args_queue.emplace_back($3);
        $$ = drv.fcall_args_queue;
    }
    ;
    // /function call args
    
// /functions


// variables
variable_declarator
: type_visibility complete_type variable_declarator_i
{
    drv.active_visibility = $1;
    drv.active_type = $2;
    $$ = $3;
}
| variable_declarator "," variable_declarator_i
{
    $$ = $3;
}
;

variable_declarator_i
: IDENTIFIER "=" expression
{
    drv.var_decl_queue.emplace_back(new ti::Variable{ drv.active_visibility, drv.active_type, $1, $3 });
    $$ = drv.var_decl_queue;
}
| IDENTIFIER
{
    drv.var_decl_queue.emplace_back(new ti::Variable{ drv.active_visibility, drv.active_type, $1, NULL });
    $$ = drv.var_decl_queue;
}
;
// /variables


// errors
expect_semicolon
: error { /*Meaningful error message*/ }
| ";"
;

expect_rparen
: error { /*Meaningful error message*/ }
| ")"
;

expect_rbrace
: error { /*Meaningful error message*/ }
| "}"
;
// /errors


// statements
statement
: "{" statements_opt "}"               { $$ = new ti::stmt::Block{ $2 }; }
| "if" "(" expression ")" statement    { $$ = new ti::stmt::If{ $3, $5 }; }
| "while" "(" expression ")" statement { $$ = new ti::stmt::While{ $3, $5 }; }
| "return" expression_opt ";"          { $$ = new ti::stmt::Return{ $2 }; }
| ";"                                  { $$ = new ti::stmt::Null{}; }
| variable_declarator ";"              { $$ = new ti::stmt::Variable{ $1 }; }
;

statements
: statements statement { drv.statement_queue.emplace_back($2); $$ = drv.statement_queue; }
| statement            { drv.statement_queue.emplace_back($1); $$ = drv.statement_queue; }
;

statements_opt
: %empty     { $$ = {}; }
| statements { $$ = $1; }
;
// /statements


// expressions
expression
: "(" expression ")"                        { $$ = $2; }
| NUMCONST                                  { $$ = new ti::expr::Numconst{ $1 }; }
| STRINGCONST                               { $$ = new ti::expr::Stringconst{ $1 }; }
| IDENTIFIER                                { $$ = new ti::expr::Identifier{ $1 }; }
| IDENTIFIER "("  fcall_args_opt ")"        { $$ = new ti::expr::FCall{ new ti::expr::Identifier{ $1 }, $3 }; }
| IDENTIFIER "="  expression                { $$ = new ti::expr::binary::Equals{ new ti::expr::Identifier{ $1 }, $3 }; }
| expression "+"  expression                { $$ = new ti::expr::binary::Plus{ $1, $3 }; }
| expression "-"  expression %prec "+"      { $$ = new ti::expr::binary::Minus{ $1, $3 }; }
| expression "<<" expression                { $$ = new ti::expr::binary::LeftShift{ $1, $3 }; }
| expression ">>" expression %prec "<<"     { $$ = new ti::expr::binary::RightShift{ $1, $3 }; }
| expression "^"  expression                { $$ = new ti::expr::binary::BitXor{ $1, $3 }; }
| expression "&"  expression                { $$ = new ti::expr::binary::BitAnd{ $1, $3 }; }
| expression "|"  expression                { $$ = new ti::expr::binary::BitOr{ $1, $3 }; }
| expression "++"                           { $$ = new ti::expr::unary::PlusPlus{ $1 }; }
| expression "--"            %prec "++"     { $$ = new ti::expr::unary::MinusMinus{ $1 }; }
| expression "==" expression                { $$ = new ti::expr::binary::EqualsEquals{ $1, $3 }; }
| expression "!=" expression %prec "=="     { $$ = new ti::expr::binary::NotEquals{ $1, $3 }; }
|            "+"  expression                { $$ = new ti::expr::unary::Positive{ $2 }; }
|            "-"  expression %prec "+"      { $$ = new ti::expr::unary::Negative{ $2 }; }
| expression "?"  expression ":" expression { $$ = new ti::expr::Ternary{ $1, $3, $5 }; }
| expression "<"  expression                { $$ = new ti::expr::binary::Less{ $1, $3 }; }
| expression ">"  expression                { $$ = new ti::expr::binary::Greater{ $1, $3 }; }
;

expression_opt
: %empty     { $$ = NULL; }
| expression { $$ = $1; }
;
// /expressions


/*
 exp:
 ;  exp "+" exp   { $$ = $1 + $3; }
 | exp "-" exp   { $$ = $1 - $3; }
 | exp "*" exp   { $$ = $1 * $3; }
 | exp "/" exp   { $$ = $1 / $3; }
 | "(" exp ")"   { std::swap ($$, $2); }
 | "identifier"  { $$ = drv.variables[$1]; }
 | "number"      { std::swap ($$, $1); };
 */

%%

void yy::parser::error(const location_type& l, const std::string& m)
{
    std::cerr << l << ": " << m << '\n';
}