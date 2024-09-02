-module(lr).
-export([init/0, init/1]).


init() ->
    Grammar = #{
        root => sort,
        lookahead => 1,
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
                [patt,andguard,orguard,';',sort]
                , [patt,andguard,orguard,';',sort,'?']
                , [patt,andguard,orguard,';',sort,'\\',fnBranch]
                , [patt,andguard,orguard,';',sort,'?','\\',fnBranch]
            ],

            orguard => [ [], ['|',patt,andguard,orguard] ],
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
    ExtendedGrammar = #{
        %% terminals : [atoms]
        %% intermediates : [atoms]
        %% root : s0
        %% lookahead : nat
        %% action_table : #{ {state, lookahead} => {shift/reduce, action_argument } }
        % shift and goto are merged by reducing item to the top of the input instead of the stack
        % action arguments are 
% for shift, a state to add to the stack
    % move first element of input to the stack and add action_argument to stack
% for reduce, the amount of element to remove from the stack and the intermediate to add to the input
    % remove n element and states from the stack and add action_argument to the input
    }.

%% check root is a intermediate
%% check root is on the lhs of a production
%% check no terminal is in intermediate and vice versa
%% check every number in the productions is unique
%% generate the extended grammar
%% constuct the grammar states
%% check that Z Z0 Z1 ... Zs are disjoint sets
%% generate a action table from the generated states
%        for every state generate a new state such that 
%    { [q, 0; %] | exists [p, j; $] in P'
%        we aren't at the end of the `p`th production parsing
%    , 0 <eq j < np
%        the next item of the `p`th production equals the lhs of the `q`th production
%    , Xp(j+1) = Aq
%        the lookahead % is a T k-string
%        derivable from the remaining items of the `p`th production and it's lookahead
%    , and % in Hk(Xp(j+2) .. Xp(np) $) }d
% any state has a production number, an index for the progress into the production, 
% and a lookahead
% identify States by their first production
% start with the first production, add state { 0,0, ~^k } {prod number, index in production, lookahead
% for every state 

init(Grammar) -> Grammar.


accept([{0, 1, [eof]}]) -> accept;
accept(_) -> reject.
