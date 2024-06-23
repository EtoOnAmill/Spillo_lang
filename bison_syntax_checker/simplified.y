
%{
    // prologue
%}

%token NUM
%token WORD
// declarations
    // lower precedence
%precedence '|'
%precedence '&'
%precedence '/' '%' '!' '^'
%left '@'
%right "::"
%precedence ':'
    // higher precedence

// rules
%%
// these are all expressions, called sorts because they can be at any level universe
sort:
    ident
    | literal
    | '(' sort ')'

    | sort sort '^' | '(' multisort "^)"
    | '(' fnBranch ')'

    | sort sort '%' | '(' multisort "%)"
    | sort sort '/' | '(' multisort "/)"

    | sort sort '!' | '(' multisort "!)"

    | sort '@' '(' patt ')' sort '%'
    | sort '@' '(' patt ')' sort '^'

    | sort "::" '(' patt ')'
;

number:
    NUM
    | NUM '.' NUM;
literal:
    number | "U" number;

fnBranch:
    '>' patt guard ';' sort
    | ">>" patt guard ';' sort fnBranch
    | '>' patt guard ';' sort fnBranch;

guard:
    | '&' patt '=' sort guard
    | '|' patt guard ;

ident: WORD;

patt:
    ident
    | '(' patt ')'
    | literal | '~' ident | '~' '(' sort ')' // constant sort pattern matching
    | '(' patt ':' sort ')'
    | patt "::" '(' patt ')'
    | patt patt '/' | '(' multipatt "/)";

multisort: sort sort | sort multisort;
multipatt: patt patt | patt multipatt;
%%

// epilogue
