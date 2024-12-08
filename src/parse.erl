-module(parse).
-export([parse/1, state_parser/3, state_parser_setup/2, input_stream/3]).
-export_type([grammar/0,ast/0]). 

-type ast() :: {ProdId::atom(), Items::list()}.
-type grammar() :: #{ root := atom(), productions := #{ atom() => list(list(atom())) } }.

-define(GRAMMAR, #{
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
            litterals => [ [num], [num,'.',num] , [word] , [str] ],

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
    }). 

-spec parse(list(lex:token())) -> ast().
parse(Tokens) -> 
    Grammar = #{
        root => sort,
        productions => #{
            sort => [
                [litterals]
                , [sort,sort,binop]
                , [sort,'::',pattunit,sort,typebinop]
                , [sort,'=:',pattunit,sort,'/']
                , ['[',sort,']']
                , ['>',fnBranch,'<']
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
            litterals => [ [num], [num,'.',num] , [word] , [str] ],

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
%#{
%        root => s,
%        productions => #{
%            s => [ [d], [word] ],
%            d => [ [s,word] ]
%        }
%    },
    parse(Tokens, Grammar).

%-type state() :: {atom(), Progress::integer(), ProdId::integer()}.


-spec parse(list(lex:token()), grammar()) -> ast().
parse(Tokens, #{root := Root, productions := Productions}) -> 
    SLOC = [],
    SROC = lists:map(fun(T) -> token_to_terminal(T) end, Tokens),
    StateStack = [ {root, 0, 1} | [] ],
    ExtendedProd = Productions#{root => [ [Root, eof] ]},
    ParserPID=spawn(parse, state_parser_setup, [StateStack, ExtendedProd]),
    ParserPID ! { inputId, self() },
    input_stream(#{ParserPID => pending}, SLOC, SROC).

% input thread, holds all referenced state stacks and the SLOC with SROC
% can recive a remove to remove a state stack
% can recive a ready to know when a state stack is done doing it's calculations
% can recive a new for a new Ss to add to the pool
% can recive a reduced with an item
    % remove the id of the Ss from the pool
    % spawn a new input thread with the item on top of it's SROC 
    % and the id of the Ss in the pool

% parsing thread, holds the state stack and SLOC
% complete and sends a ready
% recive an input to push on the SLOC
    % sends a remove if the input recived doesn't match the production next item
        % terminates the thread
    % sends a reduce when it reaches the end of the production
        % remove Progress items from the Ss 
        % get the new Is id

input_stream(StateParsers, SLOC, []) -> 
    maps:foreach(fun(Key,_) -> Key ! { eof, SLOC, self() } end , StateParsers); 
input_stream(StateParsers, SLOC, [{ Item, _ }=Hd|Tl]=SROC) -> 
    case maps:size(StateParsers) == 0 of 
        false ->  
            case maps:fold(fun(_,State,Acc) -> (State==ready) and Acc end, true, StateParsers) of
                false -> handle_responses(StateParsers, SLOC, SROC);
                true -> 
                    NewParserStates = maps:map((fun(Key,_) -> Key ! {inputItem, Item}, pending end), StateParsers),
                    NewSLOC = [Hd|SLOC],
                    handle_responses(NewParserStates, NewSLOC, Tl)
            end;
        true -> []
    end.

handle_responses(StateParsers, SLOC, SROC) -> 
    receive
        { remove, PID } -> input_stream(maps:remove(PID, StateParsers), SLOC, SROC);
        { reduce, PID, Progress, Prod } ->
            io:fwrite("~p reduces ~p as ~p~n", [PID,Progress,Prod]), 
            ReducedSLOC = lists:nthtail(Progress, SLOC),
            Item = {Prod, take(Progress, SLOC)},
            NewSROC = [Item|SROC],
            InputPID = spawn(parse, input_stream, [#{PID => pending}, ReducedSLOC, NewSROC]),
            PID ! { inputId, InputPID },
            input_stream(maps:remove(PID, StateParsers), SLOC, SROC);
        { ready, PID } -> 
            input_stream(StateParsers#{PID => ready}, SLOC, SROC);
        { new, PID } -> input_stream(StateParsers#{PID => pending}, SLOC, SROC)
    end.


state_parser_setup(StateStack, Productions) ->
    receive 
        { inputId, InputPID } -> state_parser(StateStack, Productions, InputPID);
        { eof, SLOC, InputPID } -> io:fwrite("~pIs:~p ~p~nSs:~p ~p~n",[self(),InputPID,SLOC,InputPID,StateStack]);
        MSG -> io:fwrite("~nInvalid message ( ~p ) to parser_setup~n~n", [MSG]) 
    end.

state_parser([{Prod, Progress, ProdId}|_] = StateStack, Productions, InputPID) -> 
    ExpectedItem = complete(StateStack, Productions, InputPID),
    InputPID ! {ready, self()},
    receive
        { inputItem, InputItem } when ExpectedItem == InputItem -> 
            NewState = {Prod, Progress+1, ProdId},
            io:fwrite("~pshifting~p ~p~n", [self(),InputPID,NewState]), 
            NewStateStack = [NewState|StateStack],
            check_reduce(NewStateStack, Productions, InputPID);
        { inputItem, _ } -> InputPID ! {remove, self()};
        { eof, SLOC } -> io:fwrite("~pIs:~p ~p~nSs:~p ~p~n",[self(),InputPID,SLOC,InputPID,StateStack]);
        MSG -> io:fwrite("~nInvalid message ( ~p ) to parser~n~n", [MSG]) 
    end.

check_reduce([{Prod,Progress,ProdId}|_]=StateStack, Productions, InputPID) ->
    ProdRhs = maps:get(Prod, Productions),
    ItemList = lists:nth(ProdId, ProdRhs),
    case length(ItemList) == Progress of
        true -> 
            io:fwrite("~pReducing~p (~p)~p~n", [self(),InputPID,Progress,StateStack]), 
            ReducedStateStack = lists:nthtail(Progress+1, StateStack),
            InputPID ! { reduce, self(), Progress, Prod },
            % do completion for reduce here
            state_parser_setup(ReducedStateStack, Productions);
        false -> 
            % do completion for shift here
            state_parser(StateStack, Productions, InputPID)
    end.

complete([{Prod, Progress, ProdId}|_]=StateStack, Productions, InputPID) ->
    ProdRhs = maps:get(Prod, Productions),
    ExactProd = lists:nth(ProdId, ProdRhs), 
    ExpectedItem = safe_nth(Progress, ExactProd),
    case maps:is_key(ExpectedItem, Productions) of
        true -> 
            EItemProds = maps:get(ExpectedItem, Productions),
            Enumerated = lists:enumerate(EItemProds),
            Fun = fun({N, _}) -> 
                NewState = {ExpectedItem,0,N},
                TopZeroStates = lists:takewhile(fun({_,0,_}) -> true; (_) -> false end, StateStack),
                case lists:member(NewState, TopZeroStates) of 
                    false -> io:fwrite("~pcomplete~p ~p ~p~n", [self(),InputPID,NewState,StateStack]),
                        NewStateStack = [NewState|StateStack],
                        NewPID=spawn(parse, state_parser, [NewStateStack, Productions, InputPID]),
                        InputPID ! { new, NewPID };
                    true -> [] 
                end
            end,
            lists:foreach(Fun, Enumerated);
        false -> []%io:fwrite("~p isn't an intermediate~n", [ExpectedItem]) 
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
