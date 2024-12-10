-module(parse).
-export([parse_spillo/1, state_parser/3, state_parser_setup/2, input_stream/3]).
-export_type([ast/0]). 

-type ast() :: {Intermediate::atom(), Items::list()}.

-spec parse_spillo(list(lex:token())) -> ast().
parse_spillo(Tokens) -> 
    Grammar = #{
        root => sort,
        productions => #{
            sort => 
                [ [litterals]
                , [sort,sort,binop]
                , [sort,'::',pattunit,sort,typebinop]
                , [sort,'=:',pattunit,sort,'/']
                , ['[',sort,']']
                , ['>',fnBranch,'<']
            ],

            patt => 
                [ [litterals]
                , ['[',patt,']']
                , ['~',sortunit]
                , [patt,':',sortunit]
                , [patt,'=',pattunit]
                , [patt,patt,'/']
            ],

            fnBranch =>
                [ [patt,guard,';',sort]
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




-type state_stack() :: list(list(grammar:state())).
-type input_stack() :: {LOC::list(ast()), ROC::list(ast())}.

-spec parse_action(InputData::input_stack(), State::state_stack(), Grammar::grammar:grammar()) -> {input_stack(), state_stack()}.
parse_action(InputData, State, Grammar) -> 
    { }.

-spec get_action(Lookahead::ast(), BareState::grammar:bare_state(), Grammar::grammar:grammar()) -> reduce | shift | reject | accept.
get_action(Lookahead, BareState, Grammar) -> 
    StateProd = grammar:production(BareState, Grammar),
    ExpectedItems = grammar:expected_items(BareState, Grammar),
    Progress = grammar:progress(BareState),
    {Intermediate, _} = Lookahead,
    case { length(StateProd), lists:member(Intermediate, ExpectedItems) } of
        {N, true} when N == Progress -> reduce;
        {_, true} -> shift;
        {_, false} when Intermediate == root -> accept;
        {_, false} -> reject
    end.

% start with [ [{root, 0, x, [~]}] ]
% for every state on top of SS for which the lookahead is a intermediate 
    % add {i,0,x,[lookahead]} to top of SS or expand the existing state with the parent state lookahead
% if on top of stack tere is only one state terminating
    % if lookahead matches then reduce
    % else do a temporary shift
% if on top of stack tere is one state terminating
    % if lookahead matches then reduce
    % else shift
% else shift

% shift
    % for evry state on top of SS where expected_item == input_item
    % add to SS {intermediate, progress+1, prod_id, [lookahead]}

% reduce
    % remove progress elements off SS
    % if top element is temporary state remove that too
    % add intermediate to top of IS


-spec parse(list(lex:token()), grammar:grammar()) -> ast().
parse(Tokens, #{root := Root, productions := Productions}) -> 
    InputStack = lists:map(fun(T) -> token_to_ast(T) end, Tokens),
    StateStack = [ {root, 0, 1, [eof]} | [] ],
    ExtendedProd = Productions#{root => [ [Root, eof] ]}.
    % todo connect to parsing fucntion

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

take(N, List) when N >= 0 ->
    Take = fun
        TT(0, _, Acc) -> lists:reverse(Acc);
        TT(NN, [Hd|Tl], Acc) -> TT(NN-1, Tl, [Hd|Acc]);
        TT(_, [], Acc) -> lists:reverse(Acc)
    end,
    Take(N, List, []);
take(_, _) -> [].
 
-spec token_to_ast(lex:token()) -> ast().
token_to_ast({reserved, Pos, Value}) -> {reserved, [Pos, list_to_atom(Value)]};
token_to_ast({eof, Pos}) -> {eof, [Pos]};
token_to_ast({Type, Pos, Value}) -> {Type, [Pos, Value]}.
