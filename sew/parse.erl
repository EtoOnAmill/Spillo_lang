-module(parse).
-export([parse/1]).

%% list tokens -> AST
parse(Tokens) -> parser.
 
%% element stack * State stack * list tokens -> {AST, list tokens}
%% token ::= {tokentype, pos, value}
%% tokentype ::= ignore | eof | word | string | number
%% State ::= [type, Id, Values...]
%% elementType ::= sort | fnBranch | guard | patt | multisort | multipatt
%% the state stack is built backward since lists have the head on the left

token_to_terminal({reserved, Pos, Value}) -> [reserved, list_to_atom(Value), Pos];
token_to_terminal({eof, Pos}) -> [eof, Pos];
token_to_terminal({Type, Pos, Value}) -> [Type, Pos, Value].
