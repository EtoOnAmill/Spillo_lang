Nonterminals sort fnBranch guard patt multisort multipatt.
Terminals string word num '!' '%' '&' '(' ')' '.' '/' ':' ';' '=' '>' '[' ']' '^' '{' '|' '}' '~' '::' '=:' ':=' '^]' '!]' '%]' '/]' '>>'.

Expect 0.
Rootsymbol sort.
Endsymbol eof.

sort -> num : {wholeNumber, '$1'}.
sort -> num '.' num : {fraction, '$1', '$3'}.
sort -> string.
sort -> word : {identifier, '$1'}.
sort -> '[' sort ']' : {sort, '$2'}.
sort -> '{' fnBranch '}': {lambda, '$2'}.
sort -> sort '(' multisort ')' : {application, '$1', '$3'}.
sort -> sort sort '^' : {functionType, {'$1','$2'}}.
sort -> sort sort '!' : {application, {'$2','$1'}}.
sort -> sort sort '%' : {pairType, {'$1','$2'}}.
sort -> sort sort '/' : {pairConstructor, {'$1','$2'}}.
sort -> '[' sort multisort '^]' : {multiFunctionType, ['$2'|'$3']}.
sort -> '[' sort multisort '!]' : {multiApplication, lists:reverse(['$2'|'$3'])}.
sort -> '[' sort multisort '%]' : {multiPairType, ['$2'|'$3']}.
sort -> '[' sort multisort '/]' : {multiPairConstructor, ['$2'|'$3']}.
sort -> sort '::' word : {downPattern, '$1', '$3'}.
sort -> sort '::' '(' patt ')' : {downPattern, '$1', '$4'}.
sort -> sort '=:' word : {levelPattern, '$1', '$3'}.
sort -> sort '=:' '(' patt ')' : {levelPattern, '$1', '$4'}.

fnBranch -> '>' multipatt guard ';' sort : [{functionBranchFinal, '$2', '$3', '$5'}].
fnBranch -> '>>' multipatt guard ';' sort : [{recursiveFunctionBranchFinal, '$2', '$3', '$5'}].
fnBranch -> '>' multipatt guard ';' sort fnBranch : [{functionBranch, '$2', '$3', '$5'}|'$6'].
fnBranch -> '>>' multipatt guard ';' sort fnBranch : [{recursiveFunctionBranch, '$2', '$3', '$5'}|'$6'].

guard -> '$empty' : nil.
guard -> '&' patt ':=' sort guard : {andGuard, '$2', '$4', '$5'}.
guard -> '|' patt guard : {orGuard, '$2', '$3'}.

patt -> word : {identifierIntro, '$1'}.
patt -> string.
patt -> '~' word : {staticIdentMatch, '$1'}.
patt -> '~' '[' sort ']' : {staticSortMatch, '$3'}.
patt -> patt ':' word : {typedPattern, '$1', '$3'}.
patt -> patt ':' '[' sort ']' : {typedPattern, '$1', '$4'}.
patt -> patt '=' word : {patternExtension, '$1', '$3'}.
patt -> patt '=' '[' sort ']' : {patternExtension, '$1', '$4'}.
patt -> patt patt '/' : {pairPattern, {'$1', '$2'}}.
patt -> '[' patt multipatt '/]' : {multiPairPattern, ['$2'|'$3']}.

multisort -> sort : ['$1'].
multisort -> sort multisort : ['$1'|'$2'].
multipatt -> patt : ['$1'].
multipatt -> patt multipatt : ['$1'|'$2'].
