%{
    // prologue
%}

// declarations
%right '.' '%' "::"
%left ' ' '@'

// rules
%%
sort:
    '1' | '2' | '3' | ident

    | "||" patt '.' sort
    | '(' '>' patt ';' sort ')'
    | sort ' ' sort | sort '.' sort

    | "^^" patt '%' sort
    | sort '%' sort
    | sort '@' sort

    | '(' "with" sort branch ')'
    | '(' "iterate" sort branch ')'
;
branch:
    | '|' '>' patt guard ';' sort branch
;
guard:
    | '&' patt '>' sort guard
;
ident:
    'a' | 'b' | 'c'
patt:
    '_'
    | '_' ident
    | '`' ident
    | '(' patt ':' sort ')' 
    | patt "::" patt
    | patt '.' patt
    | patt '%' patt
%%

// epilogue
