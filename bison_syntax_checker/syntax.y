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
    // higher precedence

// rules
%%
// can contain all types of declarations and must have at least one "def" declaration, otherwhise it is a set
// with this rule you'll have to put all your "def" decl at the start but this is just a limit of the LR parser of bison
// in reality i want it so you can put them anywhere in the module
module:
    "def" patt
    | "def" patt module
    | declarators patt ":=" sort module;
// like the module it contains all declaration but not "def" ones, every name must have a value attached to it
set: | declarators patt ":=" sort set;

// valid keywords for declarations
declarators: "let" | "rec" | "inf";

sort:
    litterals
    | '{' set '}' | '{' module '}'
    | sort '@' pattunit
    | '>' fnBranch '<'
    | sort '(' multisort ')'
    | sort sort binop
    | '[' sort ']'
    | '[' sort multisort multibinop
    | sort "::" pattunit sort typebinop
    | sort "=:" pattunit sort '/' ;

patt:
    litterals
    | '[' patt ']'
    | '[' patt multipatt multibinop
    | '{' set '}'
    | '~' sortunit // static sort pattern matching
    | patt ':' sortunit
    | patt '=' pattunit
    | patt patt '/' ;

fnBranch:
    multipatt guard ';' sort
    | multipatt guard ';' sort '?'
    | multipatt guard ';' sort '\\' fnBranch
    | multipatt guard ';' sort '?' '\\' fnBranch;

guard:
    | '&' patt ":=" sort guard
    | '|' patt guard;

litterals: 
    NUM
    | NUM '.' NUM
    | WORD
    | STR ;

binop: typebinop | sortbinop;
typebinop: '^' | '%';
sortbinop: '!' | '/';
multibinop: "^]" | "!]" | "/]" | "%]";

pattunit: litterals | '(' patt ')';
sortunit: litterals | '(' sort ')';
multipatt: patt | patt multipatt;
multisort: sort | sort multisort;
%%

// epilogue
