%{
    // prologue
%}

// declarations
    // lower precedence
%precedence '|'
%precedence '&'
%right '.' ".."
%right'%' "%%"
%left ' '
%left '@'
%left "::"
%precedence ':'
%precedence '[' '_' 
    // higher precedence

// rules
%%
declaration:
    | "let" patt bind sort declaration
    | "const" patt bind sort declaration
    | "inf" patt bind sort declaration;
bind: "<" | "<>";
literal:
    '1' | '2' | '3' | '*'
;
sort:
    ident
    | literal
    | '(' sort ')'
    | sort implicit

    | "||" patt ".." sort
    | "||" patt '.' sort
    | '(' paramatch ')'
    | sort ' ' sort | sort '.' sort

    | "^^" patt "%%" sort
    | "^^" patt '%' sort
    | sort '%' sort
    | sort '@' sort

    | '{' '%' element '}'
    | '{' rule '}'

    | '(' "with" sort branch ')'
    | '(' "iterate" sort branch ')'
;
paramatch: | '>' patt guard ';' sort paramatch ;
branch: | '|' patt guard ';' sort branch | '|' ';' sort;
guard:
    | '&' patt '<' sort guard
    | '|' patt guard
;
multipatt: | patt ',' multipatt;
multisort: | sort ',' multisort;
rule: | multipatt ';' multisort;
element: | patt '<' sort ',' element;
ident: 'a' | 'b' | 'c';
patt:
    '_'
    | '_' literal
    | '`' ident implicit
    | patt ':' sort
    | patt "::" patt
    | patt '.' patt
    | patt '%' patt
;
implicit: '[' multisort ']';
%%

// epilogue
