-module(grammar).

-export([production/2, expected_items/2, progress/1]). 
-export_type([grammar/0, bare_state/0, state/0]). 


-opaque bare_state() :: {Intermediate::atom(), Progress::integer(), ProdId::integer(), Lookahead::list(atom())}.
-opaque state() :: {Id::atom(), State::bare_state()}.

-type grammar() :: #{ root := atom(), productions := #{ atom() => list(list(atom())) } }.

-spec production(bare_state(), grammar()) -> list(atom()) | invalid.
production({Intermediate, _, ID, _}, Grammar) ->
    case maps:find(Intermediate, Grammar) of
        {ok, Productions} -> lists:nth(ID, Productions);
        error -> invalid
    end. 

-spec expected_items(bare_state(), grammar()) -> [atom] | invalid.
expected_items({_, Progress, _, Lookaheads}=BareState, Grammar) ->
    Production = production(BareState, Grammar),
    case length(Production) == Progress of
        true -> Lookaheads;
        false -> [lists:nth(Progress, Production)]
    end. 

-spec progress(bare_state()) -> pos_integer().
progress({_, Progress, _, _}) ->
    Progress.
