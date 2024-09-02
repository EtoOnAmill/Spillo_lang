-module(parse).
-export([parse/1]).

%% list tokens -> AST
parse(Tokens) -> 
    lr_parse(token_to_terminal(Tokens)).

lr_parse(Input) -> ok.
 

token_to_terminal({reserved, Pos, Value}) -> [reserved, list_to_atom(Value), Pos];
token_to_terminal({eof, Pos}) -> [eof, Pos];
token_to_terminal({Type, Pos, Value}) -> [Type, Pos, Value].
