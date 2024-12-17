-module(parse).
-export([parse_spillo/1]).
-export_type([ast/0]). 

-type ast() :: {Intermediate::atom(), ID::atom() | Pos::lex:pos(), Items::list()}.

-spec parse_spillo(list(lex:token())) -> ast().
parse_spillo(Tokens) -> 
    throw("unimplemented"),
    Grammar = 
%#{
%        root => sort,
%        productions => #{
%            sort => 
%                [ [litterals]
%                , [sort,sort,binop]
%                , [sort,'::',pattunit,sort,typebinop]
%                , [sort,'=:',pattunit,sort,'/']
%                , ['[',sort,']']
%                , ['>',fnBranch,'<']
%            ],
%
%            patt => 
%                [ [litterals]
%                , ['[',patt,']']
%                , ['~',sortunit]
%                , [patt,':',sortunit]
%                , [patt,'=',pattunit]
%                , [patt,patt,'/']
%            ],
%
%            fnBranch =>
%                [ [patt,guard,';',sort]
%                , [patt,guard,';',sort,'?']
%                , [patt,guard,';',sort,'\\',fnBranch]
%                , [patt,guard,';',sort,'?','\\',fnBranch]
%            ],
%
%            guard => [ andguard,orguard ],
%            orguard => [ [], ['|',patt,guard] ],
%            andguard => [ [], ['&',patt,':=',sort,andguard] ],
%            litterals => [ [num], [num,'.',num] , [word] , [str] ],
%
%            binop => [ [typebinop], [sortbinop] ],
%            typebinop => [ ['^'], ['%'] ],
%            sortbinop => [ ['!'], ['/'] ],
%
%            pattunit => [ [litterals], ['(',patt,')'] ],
%            sortunit => [ [litterals], ['(',sort,')'] ]
%        }% productions
%        %% root : intermediate
%        %% lookahead : nat
%        %% productions : [ {intermediate, [[terminals/nonterminals],...]} ]
%        %% intermediates are all atoms on the lhs in the productions
%        %% terminals are all atom that show up only on the rhs of the productions
%    },
#{
        root => s,
        productions => #{
            s => [ [d], [word] ],
            d => [ [s,word] ]
        }
    },
    parse(Tokens, Grammar).




-type state_stack() :: list(list(grammar:state())).
-type input_stack() :: {LOC::list(ast()), ROC::list(ast())}.

-spec parse_action(InputData::input_stack(), State::state_stack(), grammar:grammar()) -> {input_stack(), state_stack()}.
parse_action(InputData, State, Grammar) -> 
    throw("unimplemented"),
    { }.

-spec get_action(Lookahead::ast(), grammar:bare_state(), grammar:grammar()) -> reduce | shift | reject | accept.
get_action(Lookahead, BareState, Grammar) -> 
    StateProd = grammar:production(BareState, Grammar),
    ExpectedItems = grammar:expected_items(BareState, Grammar),
    Progress = grammar:progress(BareState),
    {Intermediate, _, _} = Lookahead,
    case { length(StateProd), lists:member(Intermediate, ExpectedItems) } of
        {N, true} when N == Progress -> reduce;
        {_, true} -> shift;
        {_, false} when Intermediate == root -> accept;
        {_, false} -> reject
    end.


-spec generate_state_items(grammar:bare_state()|grammar:state(), grammar:grammar()) -> list(grammar:bare_state()).
generate_state_items({_, BareState}, Grammar) ->
    generate_state_items(BareState, Grammar);
generate_state_items({_, Progress, _, _}=BareState, Grammar) ->
    throw("unimplemented"),
    ExpectedItems = grammar:expected_items(BareState, Grammar),
    OnlyIntermediate = lists:filter(fun(X) -> grammar:is_intermediate(X,Grammar) end, ExpectedItems), 
    AdvancedState = setelement(2, BareState, Progress+1), % tuples are 1 indexed
    IntermediateToState = fun (I) -> 
        LaHeads = grammar:expected_items(AdvancedState, Grammar), 
        {I, 0, x, LaHeads} % to avoid overcrowding the 0th states don't have a specified ProdID
    end,
    lists:map(IntermediateToState, OnlyIntermediate) .
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
    throw("Unimplemented"),
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
token_to_ast({reserved, Pos, Value}) -> {reserved, Pos, [list_to_atom(Value)]};
token_to_ast({eof, Pos}) -> {eof, [Pos], []};
token_to_ast({Type, Pos, Value}) -> {Type, Pos, [Value]}.
