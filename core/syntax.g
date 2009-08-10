#
# syntax.g
# Potion tokens and grammar
#
# (c) 2009 _why
#

%{
#include <stdio.h>
#include <stdlib.h>
#include "potion.h"
#include "internal.h"
#include "pn-ast.h"

int pos = 0;
PN input = PN_NIL;
Potion *P = 0;

#define YY_INPUT(buf, result, max) { \
  if (pos < PN_STR_LEN(input)) { \
    result = max; \
    if (pos + max > PN_STR_LEN(input)) \
      result = (PN_STR_LEN(input) - pos); \
    PN_MEMCPY_N(buf, PN_STR_PTR(input) + pos, char, result + 1); \
    pos += max; \
  } else { \
    result = 0; \
  } \
}

#define YYSTYPE PN

%}

potion = - s:statements sep? end-of-file { $$ = P->source = PN_AST(CODE, s); }

statements = s1:stmt { $$ = s1 = PN_TUP(s1); }
        (sep s2:stmt { $$ = s1 = PN_PUSH(s1, s2); })*
     | ''            { $$ = PN_NIL; }

stmt = e:expr        { e = PN_AST(EXPR, e); }
       ( assign s:stmt { $$ = PN_AST2(ASSIGN, e, s); }
       | or assign s:stmt    { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_OR, e, s)); }
       | or s:stmt     { $$ = PN_OP(AST_OR, e, s); }
       | and assign s:stmt   { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_OR, e, s)); }
       | and s:stmt          { $$ = PN_OP(AST_AND, e, s); }
       | cmp s:stmt          { $$ = PN_OP(AST_CMP, e, s); }
       | eq s:stmt           { $$ = PN_OP(AST_EQ, e, s); }
       | neq s:stmt          { $$ = PN_OP(AST_NEQ, e, s); }
       | gte s:stmt          { $$ = PN_OP(AST_GTE, e, s); }
       | gt s:stmt           { $$ = PN_OP(AST_GT, e, s); }
       | lte s:stmt          { $$ = PN_OP(AST_LTE, e, s); }
       | lt s:stmt           { $$ = PN_OP(AST_LT, e, s); }
       | pipe assign s:stmt  { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_PIPE, e, s)); }
       | pipe s:stmt         { $$ = PN_OP(AST_PIPE, e, s); }
       | caret assign s:stmt { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_CARET, e, s)); }
       | caret s:stmt        { $$ = PN_OP(AST_CARET, e, s); }
       | amp assign s:stmt   { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_AMP, e, s)); }
       | amp s:stmt          { $$ = PN_OP(AST_AMP, e, s); }
       | bitl assign s:stmt  { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_BITL, e, s)); }
       | bitl s:stmt         { $$ = PN_OP(AST_BITL, e, s); }
       | bitr assign s:stmt  { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_BITR, e, s)); }
       | bitr s:stmt         { $$ = PN_OP(AST_BITR, e, s); }
       | plus assign s:stmt  { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_PLUS, e, s)); }
       | plus s:stmt         { $$ = PN_OP(AST_PLUS, e, s); }
       | minus assign s:stmt { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_MINUS, e, s)); }
       | minus s:stmt        { $$ = PN_OP(AST_MINUS, e, s); }
       | times assign s:stmt { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_TIMES, e, s)); }
       | times s:stmt        { $$ = PN_OP(AST_TIMES, e, s); }
       | div assign s:stmt   { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_DIV, e, s)); }
       | div s:stmt          { $$ = PN_OP(AST_DIV, e, s); }
       | rem assign s:stmt   { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_REM, e, s)); }
       | rem s:stmt          { $$ = PN_OP(AST_REM, e, s); }
       | pow assign s:stmt   { $$ = PN_AST2(ASSIGN, e, PN_OP(AST_POW, e, s)); }
       | pow s:stmt          { $$ = PN_OP(AST_POW, e, s); }
       | ''                  { $$ = e; })

expr = mminus a:atom  { $$ = PN_OP(AST_INC, a, PN_NUM(-1) ^ 1); }
     | pplus a:atom   { $$ = PN_OP(AST_INC, a, PN_NUM(1) ^ 1); }
     | minus a:atom   { $$ = PN_OP(AST_MINUS, PN_AST(VALUE, PN_ZERO), a); }
     | plus a:atom    { $$ = PN_OP(AST_PLUS, PN_AST(VALUE, PN_ZERO), a); }
     | not a:atom     { $$ = PN_AST(NOT, PN_TUP(a)); }
     | wavy a:atom    { $$ = PN_AST(WAVY, PN_TUP(a)); }
     | a:atom (pplus  { $$ = PN_OP(AST_INC, a, PN_NUM(1)); }
             | mminus { $$ = PN_OP(AST_INC, a, PN_NUM(-1)); })?

atom = (e:value | e:closure | e:table | e:call)   { $$ = e = PN_TUP(e); }
       (c:call { $$ = e = PN_PUSH(e, c) })*

call = (n:name { v = PN_NIL; b = PN_NIL; } (v:value | v:table)? |
       (v:value | v:table) { n = PN_AST(MESSAGE, PN_NIL); b = PN_NIL; })
         b:block? { $$ = n; PN_S(n, 1) = v; PN_S(n, 2) = b; }

name = m:message     { $$ = PN_AST(MESSAGE, m); }
     | q:query       { $$ = PN_AST(QUERY, q); }
     | p:path        { $$ = PN_AST(PATH, p); }
     | pq:path-query { $$ = PN_AST(PATHQ, pq); }

lick-items = i1:lick-item     { $$ = i1 = PN_TUP(i1); }
            (sep i2:lick-item { $$ = i1 = PN_PUSH(i1, i2); })*
           | ''               { $$ = PN_NIL; }

lick-item = m:message t:table v:loose { $$ = PN_AST3(LICK, m, v, t); }
          | m:message t:table { $$ = PN_AST3(LICK, m, PN_NIL, t); }
          | m:message v:loose t:table { $$ = PN_AST3(LICK, m, v, t); }
          | m:message v:loose { $$ = PN_AST2(LICK, m, v); }
          | m:message         { $$ = PN_AST(LICK, m); }

loose = value
      | v:unquoted - { $$ = PN_AST(VALUE, v); }

closure = t:table? b:block { $$ = PN_AST2(PROTO, t, b); }
table = table-start s:statements table-end { $$ = PN_AST(TABLE, s); }
block = block-start s:statements block-end { $$ = PN_AST(BLOCK, s); }
lick = lick-start i:lick-items lick-end { $$ = PN_AST(TABLE, i); }

message = < utfw+ > -        { $$ = potion_str2(P, yytext, yyleng); }
query = quiz message         { $$ = potion_str2(P, yytext, yyleng); }
path = < '/' ('/' | utfw)+ > { $$ = potion_str2(P, yytext, yyleng); }
path-query = quiz path       { $$ = potion_str2(P, yytext, yyleng); }

value = i:immed - { $$ = PN_AST(VALUE, i); }
      | lick

immed = nil   { $$ = PN_NIL; }
      | true  { $$ = PN_TRUE; }
      | false { $$ = PN_FALSE; }
      | hex   { $$ = PN_NUM(PN_ATOI(yytext, yyleng, 16)); }
      | dec   { $$ = potion_decimal(P, yytext, yyleng); }
      | int   { $$ = PN_NUM(PN_ATOI(yytext, yyleng, 10)); }
      | str1 | str2

utfw = [A-Za-z0-9_$@;`{}]
     | '\304' [\250-\277]
     | [\305-\337] [\200-\277]
     | [\340-\357] [\200-\277] [\200-\277]
     | [\360-\364] [\200-\277] [\200-\277] [\200-\277]
utf8 = [\t\n\r\40-\176]
     | [\302-\337] [\200-\277]
     | [\340-\357] [\200-\277] [\200-\277]
     | [\360-\364] [\200-\277] [\200-\277] [\200-\277]

comma = ',' -
block-start = ':' -
block-end = '.' -
table-start = '(' -
table-end = ')' -
lick-start = '[' -
lick-end = ']' -
quiz = '?' -
assign = '=' -
pplus = "++" -
mminus = "--" -
minus = '-' -
plus = '+' -
wavy = '~' -
times = '*' -
div = '/' -
rem = '%' -
pow = "**" -
bitl = "<<" -
bitr = ">>" -
amp = '&' -
caret = '^' -
pipe = '|' -
lt = '<' -
lte = "<=" -
gt = '>' -
gte = ">=" -
neq = "!=" -
eq = "==" -
cmp = "<=>" -
and = ("&&" | "and") -
or = ("||" | "or") -
not = ("!" | "not") -


nil = "nil"
true = "true"
false = "false"
int = < [0-9]+ >
hexl = [0-9A-Fa-f]
hex = '0x' < hexl+ >
dec = < ('0' | [1-9][0-9]*)
      '.' [0-9]+ ('e' [-+] [0-9]+)? >

q1 = [']
c1 = (!q1 utf8)+
str1 = q1 < (q1 q1 | c1)* >
       q1 { $$ = potion_str2(P, yytext, yyleng); }

escc        = '\\' q2 | '\\' '\\' | '\\' '/'
escn        = '\\' 'n'
escb        = '\\' 'b'
escf        = '\\' 'f'
escr        = '\\' 'r'
esct        = '\\' 't'
escu        = '\\' 'u' hexl hexl hexl hexl

q2 = ["]
e2 = '\\' ["]
c2 = (!q2 utf8)+
str2 = q2 < (e2 | escc | escn | escb | escf | escr | esct | escu | c2)* >
       q2 { $$ = potion_str2(P, yytext, yyleng); }

unquoted = < (!sep !lick-end utf8)+ > { $$ = potion_str2(P, yytext, yyleng); }

- = (space | comment)*
sep = (end-of-line | comma) (space | comment | end-of-line | comma)*
comment	= '#' (!end-of-line utf8)*
space = ' ' | '\f' | '\v' | '\t'
end-of-line = '\r\n' | '\n' | '\r'
end-of-file = !.

%%

PN potion_greg_parse(Potion *PP, PN code) {
  P = PP;
  pos = 0;
  input = code;
  if (!yyparse())
    printf("** Syntax error!\n");
  return P->source;
}