%{
    // prologue
%}

// declarations
%right '.' "::"
%left '@' ':' ">." ','
%left ' '
%nonassoc '>' ';' '_'
// rules
%%
sort:
    ident
    | '0' | '1' | '2' | '3' | '4' | '5'

    | '(' '>' patt ';' sort ')'
    | sort ' ' sort | '(' sort '.' sort ')'
    | sort ">." sort

    | '(' sort '%' sort ')' | sort '@' sort

    | declaration
    | sort ',' sort

    | '(' "iterate" sort branch ')'
    | '(' "with" sort branch ')'
    | '(' "||" patt '.' sort ')'
    | '(' "^^" patt '%' sort ')'
;
branch:
    | '|' '>' patt ';' sort branch
    | '|' '>' patt '&' declaration ';' sort branch
    | '|' sort
;
patt:
    '_'
    | '_' ident
    | '`' ident
    | patt ':' sort
    | patt "::" patt
    | '(' patt '%' patt ')'
    | '(' patt '.' patt ')'
;
ident:
    'a'
    | 'b'
    | 'x'
    | 'y'
;
declaration:
    | "(recur" patt "<>" sort ")" declaration
    | "(inf" patt "<>" sort ")" declaration
    | "(" patt "<" sort ")" declaration
    | "(" sort ">" patt ")" declaration
;
%%

// epilogue
