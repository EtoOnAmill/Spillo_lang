%{
    // prologue
%}

// declarations
    // lower precedence
%precedence '|'
%precedence '&'
%right ' '
%precedence '/' '%' '?' '!' '^'
%left '@'
%right "::"
%precedence ':'
%precedence '[' '_'
    // higher precedence

// rules
%%
// can contain all types of declarations and must have at least one "def" declaration, otherwhise it is a set
// with this rule you'll have to put all your "def" decl at the start but this is just a limit of the LR parser of bison
// in reality i want it so you can put them anywhere in the module
module:
    "def" patt set
    | "def" patt module;
// like the module it contains all declaration but not "def" ones, every name must have a value attached to it
set:
    | "let" patt '=' sort set
    | "rec" patt '=' sort set
    | "inf" patt '=' sort set;
// numbers tokens
digit: '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | '0';
wholenum:
    digit
    | digit wholenum;
number:
    wholenum
    | wholenum '.' wholenum;
// litteral expression
literal:
    number | "type" | "kind" | "set" | "module" | "sort";
// these are all expressions, called sorts because they can be at any level universe
sort:
    ident
// sets like modules are first class citizens of the language
    | '{' set '}' | '{' module '}'
    | literal
// parenthesis shouldn't be needed for the compiler to understand but they are helpful to the programmer so here they are
    | '(' sort ')'
// when the compiler can't figure out implicit arguments
    | sort implicit
// lazy expression, if on an application, it delays the evaluation of parameters as well
    | sort '?'

// functions
// type, always takes 2 sorts and doesn't curry
    | sort ' ' sort '^'
// declaration, there are two types of function, more is explained at the fnBranch declaration
    | '(' fnBranch ')'

// pairs
// type, like functions they always take 2 sort and can't curry
    | sort ' ' sort '%'
// declaration, like the type
    | sort ' ' sort '/'

// elimination, application, with RPN rules, fn on the right parameters on the left
// for function is simple application, for pairs the first sort must be a positive whole number n
// it returns the nth element of the tuple
// as it is rn the order of parameter in declaration and application is inverted
// still don't know how and if i want to change it
    | sort ' ' sort '!'

// the parenthesis are just to help bison out
// realistically they are only needed when the pattern is more than one token
// for dependent type creation, it's the same as "patt : sort"
    | sort '@' 'E' '(' patt ')' ' ' sort '%'
    | sort '@' 'A' '(' patt ')' ' ' sort '^' 
// works like "patt = sort" without the need to break apart the expression
    | sort "::" '(' patt ')'

// transform a module into a set
// in the brackets all "def" present in the module must be given a "let" or "rec" declaration with the same name and type
    | sort "::" '{' set '}'
// this represents the type of a set where there are at least the element indicated in the brackets
    | "set::" '{' multipatt '}'
// sort must be a set and ident must be declared inside, this expression has the type and value of the ident inside the set
    | sort '@' ident

// unnecessary but can make reading the code easier
    | "with " sort '(' fnBranch ')'
    | "iterate " sort '(' fnBranch ')';

// if any fnBranch contains the duble greater (>>)
// then the function is iterative and the expression in the (>) branches gets used as parameters for the next iteration
// untill it breaks when it matches on a branch with the (>>)
// otherwhise it acts as a simple function
// iterative functions only work if the expression after the matched parameter isn't a function as you can't pattern match on functions
fnBranch:
    | ">>" patt guard ';' sort fnBranch
    | '>' patt guard ';' sort fnBranch;

// extra patterns to match
// & guards have more precedence than | guards
guard:
// & guards require both the left and right side to match in order to pass the pattern matching
    | '&' patt '=' sort guard
// | guards require the left side to fail and the right side to succed in order to pattern match
// plus they need every pattern that binds to a variable to have the same name and type on the left and right pattern
    | '|' patt guard ;

// identifiers can use any character that isn't a symbol already present in the grammar and can't be equal to keywords
letter: 'a' | 'b' | 'c' | 'd' | 'e' | 'f' | 'g' | 'h' | 'i' | 'j' | 'k' | 'l' | 'm' | 'n' | 'o' | 'p' | 'q' | 'r' | 's' | 't' | 'u' | 'v' | 'w' | 'x' | 'y' | 'z';
ident: letter | letter ident;

// the bread and butter of pattern matching
patt:
// match anything and bind to the identifier
    '_' | ident
// same as the "(sort)" here to help the programmer not the compiler
    | '(' patt ')'
// match with a constant expression
    | literal | '~' ident | '~' '(' sort ')' // constant sort pattern matching
// match with explicit implicit arguments
// in declarations it can be used to bring into context sorts without having to pass them explicitly every time the patt is used in the program
    | patt implicit_dec
// classic element type relationship
    | patt ':' sort
// when you need to match the internal of something but you also need the whole
    | patt "::" patt
// to match the inner element of a set
    | '{' set '}'
// match on a ?????? in here only if in the future i can make inductive types work well enough
    | patt ' ' patt '!'
// match on a pair
    | patt ' ' patt '/' ;

multisort: | sort ' ' multisort;
implicit: '[' multisort ']';
multipatt: | patt ' ' multipatt;
implicit_dec: '[' multipatt ']';
%%

// epilogue
