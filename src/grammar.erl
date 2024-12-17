-module(grammar).

-export([production/2, expected_items/2, progress/1, is_intermediate/2]). 
-export_type([grammar/0, bare_state/0, state/0]). 


-opaque bare_state() :: {Intermediate::atom(), Progress::integer(), ProdId::integer(), Lookahead::list(atom())}.
-opaque state() :: {Id::atom(), State::bare_state()}.

-type grammar() :: #{ root := atom(), productions := #{ atom() => list(list(atom())) } }.

-spec is_intermediate(atom(), grammar()) -> boolean().
is_intermediate(ToCheck, Grammar) ->
    production(ToCheck, Grammar) =/= invalid.

-spec production(bare_state()|state(), grammar()) -> list(atom()) | invalid.
production({_, BareState}, Grammar) ->
    production(BareState, Grammar);
production({Intermediate, _, ID, _}, Grammar) ->
    case maps:find(Intermediate, Grammar) of
        {ok, Productions} -> lists:nth(ID, Productions);
        error -> invalid
    end. 

-spec expected_items(bare_state()|state(), grammar()) -> [atom] | invalid.
expected_items({_, BareState}, Grammar) ->
    expected_items(BareState, Grammar);
expected_items({_, Progress, _, Lookaheads}=BareState, Grammar) ->
    throw("TODO: reduce lookahead is expanded"),
    Production = production(BareState, Grammar),
    case length(Production) == Progress of
        true -> Lookaheads;
        false -> [lists:nth(Progress, Production)]
    end. 

-spec progress(bare_state()|state()) -> pos_integer().
progress({_, {_, Progress, _, _}}) ->
    Progress;
progress({_, Progress, _, _}) ->
    Progress.
