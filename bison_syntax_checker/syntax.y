%{
    // prologue
%}

// declarations
    // lower precedence
%precedence '|'
%precedence '&'
%right ' '
%precedence '/' '.' '%'
%left '@'
%right "::"
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

    | sort ' ' sort "."                     // type
    | '(' sort ' ' multisort ".." ')'       // type
    | '(' branch ')'                        // declaration
    | '(' sort ' ' multisort '!' ')'        // elimination // greedy proximity(first argument is closest to the function) application
    | '(' sort ' ' multisort '?' ')'        // elimination // greedy inverted(first argument is furthest to the left) application

    | sort ' ' sort "%"                     // type
    | '(' sort ' ' multisort "%%" ')'       // type
    | sort ' ' sort '/'                     // declaration
    | '(' sort ' ' multisort "//" ')'       // declaration
    | sort '@' sort                         // elimination

    | sort "::" '(' patt ')'                // for dependent type creation
    | "with " sort '(' branch ')'           // unnecessary but can make reading the code easier
    | "iterate " sort '(' branch ')'
;
branch: | '>' patt guard ';' sort branch;
guard:
    | '&' patt '<' sort guard
    | '|' patt guard
;
ident: 'a' | 'b' | 'c';
patt:
    '_'
    | ident
    | literal
    | '`' ident implicit_dec
    | patt ':' sort
    | patt "::" patt
    | patt ' ' patt '.'
    | patt ' ' patt '!' | patt ' ' patt '?'
    | patt ' ' patt '%'
    | patt ' ' patt '/'
;
multisort: | sort ' ' multisort;
implicit: '[' multisort ']';
multipatt: | patt ' ' multipatt;
implicit_dec: | '[' multipatt ']';
%%

// epilogue
