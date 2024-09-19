
%{
    // prologue
%}

%define lr.type ielr

%token NUM
%token WORD
%token STR
// declarations
    // lower precedence
%precedence '|'
%precedence '&'
    // higher precedence

// rules
%%
// these are all expressions, called sorts because they can be at any level universe
sort:
    litterals
    | '[' sort ']'
    | '>' fnBranch '<'
    | sort sort binop
    | sort "::" pattunit sort typebinop
    | sort "=:" pattunit sort '/' ;

patt:
    litterals
    | '[' patt ']'
    | '~' sortunit // static sort pattern matching
    | patt ':' sortunit
    | patt '=' pattunit
    | patt patt '/' ;

fnBranch:
    patt guard ';' sort
    | patt guard ';' sort '?'
    | patt guard ';' sort '\\' fnBranch
    | patt guard ';' sort '?' '\\' fnBranch;

guard: andguard orguard;
orguard:
    | '|' patt guard;
andguard:
    | '&' patt ":=" sort andguard;

litterals: 
    NUM
    | NUM '.' NUM
    | WORD
    | STR ;

binop: typebinop | sortbinop;
typebinop: '^' | '%';
sortbinop: '!' | '/';

pattunit: litterals | '(' patt ')';
sortunit: litterals | '(' sort ')';

%%

// epilogue
