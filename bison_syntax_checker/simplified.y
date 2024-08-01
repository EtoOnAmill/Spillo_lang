
%{
    // prologue
%}

%token NUM
%token WORD
// declarations
    // lower precedence
%precedence '|'
%precedence '&'
%precedence ':'
    // higher precedence

// rules
%%
// these are all expressions, called sorts because they can be at any level universe
sort:
    NUM
    | NUM '.' NUM
    | ident
    | '(' sort ')'

    | sort sort '^' | '(' multisort "^)"
    | '(' fnBranch ')'

    | sort sort '%' | '(' multisort "%)"
    | sort sort '/' | '(' multisort "/)"

    | sort sort '!' | '(' multisort "!)"

    | sort "::" '(' patt ')'
    | sort '=' '(' patt ')'
;

fnBranch:
    '>' patt guard ';' sort
    | ">>" patt guard ';' sort fnBranch
    | '>' patt guard ';' sort fnBranch;

guard:
    | '&' patt ":=" sort guard
    | '|' patt guard ;

ident: WORD;

patt:
    ident
    | '(' patt ')'
    | '~' ident | '~' '(' sort ')' // static sort pattern matching
    | '(' patt ':' sort ')'
    | patt '=' '(' patt ')'
    | patt patt '/' | '(' multipatt "/)";

multisort: sort sort | sort multisort;
multipatt: patt patt | patt multipatt;
%%

// epilogue
