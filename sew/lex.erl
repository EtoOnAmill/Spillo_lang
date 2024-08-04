-module(lex).
-export([lex/1, lex_one/1]).

%% string -> list tokens
lex([]) -> [];
lex(Str) ->
    case  lex_one(Str) of
        {ignore, _, Rest} -> lex(Rest);
        {Ttype, Token, Rest} -> [{Ttype,Token}|lex(Rest)]
    end.

%% string * string -> {token , string}
lex_one([]) -> {"", []};
lex_one([Chr|Tail]) ->
    WhiteSpace=[$\s,$\t,$\n,$\v,$\r],
    Reserved=[$^,$!,$%,$/,$|,$&,$:,$[,$],$=,$>,$;,$~,$`,$.,$,,$#|WhiteSpace],

    case lists:member(Chr, WhiteSpace) of
        true -> {ignore, whiteSpace, Tail};
        false ->
        (case Chr of
            $` ->
                IsntBackTick = fun($`) -> false; (_) -> true end,
                {Token, Rem} = case take_while(IsntBackTick, Tail) of
                    {T, [$`|Rest]} -> {T, Rest};
                    _ -> throw("Unclosed delimiter, expected '`'")
                end,
                {string, Token, Rem};
            $# ->
                IsntOctothorp = fun($#) -> false; (_) -> true end,
                {Token, Rem} = case take_while(IsntOctothorp, Tail) of
                    {T, [$#|Rest]} -> {T, Rest};
                    {T, []} -> {T, []};
                    _ -> throw("Unclosed delimiter, expected '#'")
                end,
                {ignore, Token, Rem};
            C  -> case lists:member(C, Reserved) of
                true -> case [Chr|Tail] of
                    [$:,$:|TTail] -> {reserved, "::", TTail};
                    [$>,$>|TTail] -> {reserved, ">>", TTail};
                    [$=,$:|TTail] -> {reserved, "=:", TTail};
                    [$:,$=|TTail] -> {reserved, ":=", TTail};
                    [$^,$]|TTail] -> {reserved, "^]", TTail};
                    [$%,$]|TTail] -> {reserved, "%]", TTail};
                    [$/,$]|TTail] -> {reserved, "/]", TTail};
                    [$!,$]|TTail] -> {reserved, "!]", TTail};
                    _ -> {reserved, [C], Tail}
                    end;
                false ->
                    IsntReserved = fun(CC) -> not lists:member(CC, Reserved) end,
                    erlang:insert_element(1, take_while(IsntReserved,  [Chr|Tail]), word) 
                end
            end)
        end.

%% (a -> bool) -> list a -> {list a, list a}
take_while(Fn, List) ->
    Helper = fun
        Hlp([], Acc) -> {lists:reverse(Acc),[]};
        Hlp([Chr|Rest]=Whole, Acc) -> case Fn(Chr) of
            true -> Hlp(Rest, [Chr|Acc]);
            false -> {lists:reverse(Acc), Whole} end
    end,
    Helper(List, []).
