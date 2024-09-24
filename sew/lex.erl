-module(lex).
-export([lex/1, lex_one/2]).
-export_type([token/0, ttype/0, pos/0]). 

-type ttype() :: ignore|eof|word|string|number|reserved.
-type pos() :: {integer(), integer()}.
-type token() :: {ttype(), pos(), string()}.

-spec lex(string()) -> list(token()).
lex(Str) -> lex(Str,{1,1}).

-spec lex(string(),pos()) -> list(token()).
lex([],Pos) -> [{eof,Pos} |[]];
lex(Str, Pos) ->
    case  lex_one(Str, Pos) of
        {ignore, _, NewPos, Rest} -> lex(Rest, NewPos);
        {Ttype, Token, NewPos, Rest} -> [{Ttype, Pos, Token}|lex(Rest, NewPos)]
    end.

-spec lex_one(string(), pos()) -> {ttype(), pos(), string(), Rest :: {pos(), string()}}.
lex_one([], Pos) -> {eof,Pos};
lex_one([Chr|Tail], {Line,Column}) ->
    WhiteSpace=[$\s,$\t,$\n,$\v,$\r],
    Reserved=[$^,$!,$%,$/,$|,$&,$:,${,$},$[,$],$(,$),$=,$>,$<,$;,$~,$`,$.,$,,$#|WhiteSpace],
    NewPosition = fun(Token) -> 
        LineSplit=string:split(Token, "\n", all),
        NewLine= Line + length(LineSplit) - 1, %% length returns 1 in case of no split 
        NewColumn = (if Line == NewLine -> Column; true -> 1 end) + string:length(lists:last(LineSplit)),
        {NewLine, NewColumn}
    end,

    case lists:member(Chr, WhiteSpace) of
        true -> {ignore, whiteSpace, NewPosition([Chr]), Tail};
        false ->
        (case Chr of
            N when N >= $0, N =< $9 %% the comma is the boolean and
            -> {Token, Rem} = take_number([Chr|Tail]),
                %
                {number, Token, NewPosition(Token), Rem};
            $` ->
                IsntBackTick = fun($`) -> false; (_) -> true end,
                {Token, Rem} = case take_while(IsntBackTick, Tail) of
                    {T, [$`|Rest]} -> {T, Rest};
                    _ -> throw("Unclosed delimiter, expected '`'")
                end,
                {NewLine, NewColumn} = NewPosition(Token),
                {string, Token, {NewLine, NewColumn + 2}, Rem};
            $# ->
                IsntOctothorp = fun($#) -> false; (_) -> true end,
                {Token, Rem, Delimited} = case take_while(IsntOctothorp, Tail) of
                    {T, [$#|Rest]} -> {T, Rest, true};
                    {T, []} -> {T, [], false};
                    _ -> throw("Unclosed delimiter, expected '#'")
                end,
                {NewLine, NewColumn} = NewPosition(Token),
                NewerColumn = NewColumn + (if Delimited -> 1; true -> 0 end),
                {ignore, Token, {NewLine, NewerColumn}, Rem};
            C  -> case lists:member(C, Reserved) of
                true -> case [Chr|Tail] of
                    [$:,$:|TTail] -> {reserved, "::", NewPosition(".."), TTail};
                    [$>,$>|TTail] -> {reserved, ">>", NewPosition(".."), TTail};
                    [$=,$:|TTail] -> {reserved, "=:", NewPosition(".."), TTail};
                    [$:,$=|TTail] -> {reserved, ":=", NewPosition(".."), TTail};
                    [$^,$]|TTail] -> {reserved, "^]", NewPosition(".."), TTail};
                    [$%,$]|TTail] -> {reserved, "%]", NewPosition(".."), TTail};
                    [$/,$]|TTail] -> {reserved, "/]", NewPosition(".."), TTail};
                    [$!,$]|TTail] -> {reserved, "!]", NewPosition(".."), TTail};
                    _ -> {reserved, [Chr], NewPosition("."), Tail}
                    end;
                false ->
                    IsntReserved = fun(CC) -> not lists:member(CC, Reserved) end,
                    {Word, Rest} = take_while(IsntReserved,  [Chr|Tail]),
                    {word, Word, NewPosition(Word), Rest}
                end
            end)
        end.


-spec take_while(fun((A) -> boolean()), list(A)) -> {Taken::list(A),Rest::list(A)}.
take_while(Fn, List) ->
    Helper = fun
        Hlp([], Acc) -> {lists:reverse(Acc),[]};
        Hlp([Chr|Rest]=Whole, Acc) -> case Fn(Chr) of
            true -> Hlp(Rest, [Chr|Acc]);
            false -> {lists:reverse(Acc), Whole} end
    end,
    Helper(List, []).


-spec take_number(string()) -> {string(),string()}.
take_number(Str) -> 
    Is_decimal = fun(N) when N >= $0, N =< $9 -> true; (_) -> false end,
    take_while( Is_decimal , Str).
