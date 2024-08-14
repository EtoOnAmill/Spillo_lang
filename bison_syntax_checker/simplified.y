
%{
    // prologue
%}

%token NUM
%token WORD
%token STR
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
    | WORD
    | STR
    | '[' sort ']'

    | '>' fnBranch '<' | sort '(' multisort ')'

    | sort sort binop
    | '[' sort multisort multibinop

    | sort "::" '(' patt ')'
    | sort "=:" '(' patt ')'
;

binop: '^' | '!' | '%' | '/';
multibinop: "^]" | "!]" | "%]" | "/]";

fnBranch:
    patt guard ';' sort
    | patt guard ';' sort '?'
    | patt guard ';' sort '\\' fnBranch
    | patt guard ';' sort '?' '\\' fnBranch
    | patt guard ';' sort '?' fnBranch;

guard:
    | '&' patt ":=" sort guard
    | '|' patt guard;

patt:
    WORD
    | STR
    | NUM
    | NUM '.' NUM
    | '[' patt ']'
    | '~' WORD | '~' '[' sort ']' // static sort pattern matching
    | patt ':' WORD
    | patt ':' '[' sort ']'
    | patt '=' WORD
    | patt '=' '[' patt ']'
    | patt patt '/' | '[' patt multipatt "/]";

multisort: sort | sort multisort;
multipatt: patt | patt multipatt;
%%

// epilogue
