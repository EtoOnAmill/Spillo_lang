-module(parse).
-export([parse/1, safe_nth/2]).
-export_type([grammar/0,ast/0]). 

-type ast() :: {ProdId::atom(), Items::list()}.
-type grammar() :: #{ root := atom(), productions := #{ atom() => list(list(atom())) } }.

-spec parse(list(lex:token())) -> ast().
parse(Tokens) -> 
    Grammar = #{
        root => sort,
        productions => #{
            sort => [
                [litterals]
                , ['[',sort,']']
                , ['>',fnBranch,'<']
                , [sort,sort,binop]
                , [sort,'::',pattunit,sort,typebinop]
                , [sort,'=:',pattunit,sort,'/']
            ],

            patt => [
                [litterals]
                , ['[',patt,']']
                , ['~',sortunit]
                , [patt,':',sortunit]
                , [patt,'=',pattunit]
                , [patt,patt,'/']
            ],

            fnBranch => [
                [patt,guard,';',sort]
                , [patt,guard,';',sort,'?']
                , [patt,guard,';',sort,'\\',fnBranch]
                , [patt,guard,';',sort,'?','\\',fnBranch]
            ],

            guard => [ andguard,orguard ],
            orguard => [ [], ['|',patt,guard] ],
            andguard => [ [], ['&',patt,':=',sort,andguard] ],
            litterals => [  [num], [num,'.',num] , [word] , [str] ],

            binop => [ [typebinop], [sortbinop] ],
            typebinop => [ ['^'], ['%'] ],
            sortbinop => [ ['!'], ['/'] ],

            pattunit => [ [litterals], ['(',patt,')'] ],
            sortunit => [ [litterals], ['(',sort,')'] ]
        }% productions
        %% root : intermediate
        %% lookahead : nat
        %% productions : [ {intermediate, [[terminals/nonterminals],...]} ]
        %% intermediates are all atoms on the lhs in the productions
        %% terminals are all atom that show up only on the rhs of the productions
    },
    parse(Tokens, Grammar).

%-type state() :: {atom(), Progress::integer(), ProdId::integer()}.


-spec parse(list(lex:token()), grammar()) -> ast().
parse(Tokens, #{root := Root, productions := Productions}=Grammar) -> 
    SLOC = [],
    SROC = token_to_terminal(Tokens),
    StateStack = [ {root, 0, 0} | [] ],
    ExtendedProd = Productions#{root => [ [Root] ]},
    InputStream = spawn(parse, input_stream, [#{}, SLOC, SROC]),
    StateParserPID = spawn(parse, state_parser, [StateStack, ExtendedProd, InputStream]).

% input thread, holds all referenced state stacks and the SLOC with SROC
% can recive a remove to remove a state stack
% can recive a ready to know when a state stack is done doing it's calculations
% can recive a reduced to spawn a new input thread with the item on top of it's SROC and the appropriate Ss in it's pool
% sends the next input when all the Ss are ready
input_stream(StateParsers, SLOC, [{ Item, _ }|Tl]=SROC) -> 
    case maps:fold(fun(_,State,Acc) -> (State==ready) and Acc end, true, StateParsers) of
        false -> handle_responses(StateParsers, SLOC, SROC);
        true -> 
            maps:map((fun(Key,_) -> Key ! {inputItem, Item}, pending end), StateParsers),
            NewSLOC = [Item|SLOC],
            handle_responses(StateParsers, NewSLOC, Tl)
    end.

handle_responses(StateParsers, SLOC, SROC) -> 
    receive
        { remove, PID } -> input_stream(maps:remove(PID, StateParsers), SLOC, SROC);
        { reduce, PID, N, Prod } ->
            ReducedSLOC = lists:nthtail(N, SLOC),
            Item = {Prod, take(N, SLOC)},
            NewInputId = spawn(parse, input_stream, [#{PID => pending}, ReducedSLOC, [Item|SROC]]),
            PID ! { newInputStream, NewInputId },
            input_stream(maps:remove(PID, StateParsers), SLOC, SROC);
        { ready, PID } -> input_stream(StateParsers#{PID => ready}, SLOC, SROC)
    end.
% parsing thread, holds the state stack and SLOC
% can recive an input to push on the SLOC
% sends a remove if the input recived doesn't match the production next item
% sends a ready when it's completed it's computation
% sends a reduce when it reaches the end of the production
    % recieves the ID of the new input thread
state_parser([{Prod, Progress, ProdId}|_] = StateStack, Productions, InputID) -> 
    ExpectedItem = complete(StateStack, Productions, InputID),
    InputID ! {ready, self()},
    receive
        {inputItem, InputItem } -> 
            case ExpectedItem == InputItem of
                true ->  check_reduce(
                    [{Prod,Progress+1,ProdId}|StateStack],
                    Productions,
                    InputID);
                _ ->  InputID ! {remove, self()}
            end;
        eof -> eof
        % todo after logic
    end.

check_reduce([{Prod,Progress,ProdId}|_]=StateStack, Productions, InputID) -> 
    ProdRhs = maps:get(Prod, Productions),
    ItemList = safe_nth(ProdId, ProdRhs),
    case safe_nth(Progress, ItemList) of
        [] -> 
            ReducedStateStack = lists:nthtail(Progress, StateStack),
            InputID ! { reduce, self(), Progress, Prod },
            receive { newInputStream, NewInputId } -> 
                state_parser(
                    ReducedStateStack,
                    Productions,
                    NewInputId) 
            end;
        _ -> state_parser(StateStack, Productions, InputID)
    end.

complete([{Prod, Progress, ProdId}|_]=StateStack, Productions, InputID) ->
    ProdRhs = maps:get(Prod, Productions),
    ExpectedItem = lists:nth(Progress, ProdRhs),
    case maps:is_key(ExpectedItem, Productions) of
        true -> 
            Enumerated = lists:enumerate(ProdRhs),
            TopZeroStates = lists:takewhile(fun({_,0,_}) -> true; (_) -> false end, StateStack),
            Fun = fun({N, _}) -> 
                NewState = {Prod,0,N},
                case lists:member(NewState, TopZeroStates) of 
                    false ->
                        NewStateStack = [NewState|StateStack],
                        spawn(parse, state_parser, [NewStateStack, Productions, InputID]) 
                end
            end,
            lists:foreach(Fun, Enumerated);
        _ -> []
    end,
    ExpectedItem.

safe_nth(0, [Hd|_]) -> Hd;
safe_nth(_, []) -> [];
safe_nth(N, [_|Tl]) -> safe_nth(N - 1, Tl).

take(N, List) ->
    Take = fun
        TT(0, _, Acc) -> lists:reverse(Acc);
        TT(NN, [Hd|Tl], Acc) -> TT(NN-1, Tl, [Hd|Acc]);
        TT(_, _, Acc) -> lists:reverse(Acc)
    end,
    Take(N, List, []).
 
-spec token_to_terminal(lex:token()) -> ast().
token_to_terminal({reserved, Pos, Value}) -> {reserved, [Pos, list_to_atom(Value)]};
token_to_terminal({eof, Pos}) -> {eof, [Pos]};
token_to_terminal({Type, Pos, Value}) -> {Type, [Pos, Value]}.
