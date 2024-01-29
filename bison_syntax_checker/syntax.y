%{
    // prologue
%}

// declarations
%right '.'
%left '@'
%left ' '
%nonassoc '>' ';'
// rules
%%
expr:
    ident
    | '0' | '1' | '2' | '3' | '4' | '5'
    | '(' '>' patt ';' expr ')'
    | expr '>' patt ';' expr
    | expr ' ' expr | expr '.' expr
    | '(' expr '&' expr ')' | expr '@' expr
    | '(' "with" expr branch ')'
    | '(' "recur with" expr branch ')'
;
branch:
    | '|' '>' patt ';' expr branch
    | '|' '>' patt '&' '(' declaration ')' ';' expr branch
    | '|' expr
;
patt:
    '_'
    | '_' type
    | '`' ident
    | '`' patt ':' type
    | '`' ident "::" patt
    | '(' patt '%' patt ')'
    | '(' '(' patt ')' '.' patt ')'
;
type:
    '*'
    | '#'
;
ident:
    'a'
    | 'b'
    | 'c'
    | 'd'
    | 'e'
    | 'x'
    | 'y'
;
declaration:
    "recur" patt "<>" expr
    patt "<" expr
    expr ">" patt
;
%%

// epilogue
