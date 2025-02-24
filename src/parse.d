class Grammar(GrammarItem = int) {
    void* function(size_t) allocator;

    GrammarItem[] intermediates;
    GrammarItem[][] productions;

    Grammar append_production(GrammarItem interm, GrammarItem[] items) {
        this.intermediates ~= interm;
        this.productions ~= items;

        return this;
    }

    bool is_intermediate(GrammarItem item) {
        foreach(GrammarItem intermediate; this.intermediates) {
            if(intermediate == item) { return true; }
        }
        return false;
    }



    struct ProdAndIdx {
        size_t production_idx;
        GrammarItem[] productions;
    }
    ProdAndIdx[] productions_for_intermediate(GrammarItem intermediate) {
        ProdAndIdx[] ret;

        for(size_t idx = 0; idx < this.intermediates.length; idx++) {
            if(this.intermediates[idx] == intermediate) {
                ProdAndIdx tmp = ProdAndIdx(idx, this.productions[idx]);
                ret ~= tmp;
            }
        }

        return ret;
    }

    GrammarItem[] refine_lookahead(GrammarItem[] lookahead) {
        size_t idx;

        // there should always be a terminal symbol before the end of the array
        for(idx = 0; is_intermediate(lookahead[idx]); idx++) { }

        return lookahead[0..(idx+1)];
    }

    GrammarItem root;
    GrammarItem eof;

    const enum Action { ACCEPT, SHIFT, REDUCE, REFUTE }
    struct ParsingAction {
        Action action;
        size_t parameter; // for reduce action is the intermediate and production index, for shift action is the state to add to state stack
    }

    alias ParsingTable = ParsingAction[GrammarItem][];

    struct StateLine {
        size_t progress;
        size_t production_idx;
        GrammarItem[] lookahead;
    };
    alias state = StateLine[];

    ParsingTable generate_parsing_table() {
// 0) Create the extended grammar like with canonical LR with root symbol S, and it's own symbol S' not in Intermediates nor Terminals set
        this.append_production(this.eof, [this.root]);
// 1) Let state `0` start with Production State `S' -> . S (~)`, where the dot represents the Progress in the production, '~' represents the Eof symbol, all comma separated lists of symbols in the parenthesis are the lookahead
        state[] generated_states = [
            [StateLine(0, this.productions.length, [ this.eof ] )]
        ];
        ParsingAction[GrammarItem][] table;

// -) For every state:
        for(size_t curr_state_idx = 0; curr_state_idx < generated_states.length; curr_state_idx++) {
            state curr_state = generated_states[curr_state_idx];

// -) For every state line:
            for(size_t curr_line_idx = 0; curr_line_idx < curr_state.length; curr_line_idx++) {
                StateLine curr_line = curr_state[curr_line_idx];
                GrammarItem[] prod = this.productions[curr_line.production_idx];

                GrammarItem expected_item;
                if(curr_line.progress < prod.length) { expected_item = prod[curr_line.progress]; }
                else { expected_item = curr_line.lookahead[0]; }


                GrammarItem[] extended_new_lookahead = prod[curr_line.progress..$] ~ curr_line.lookahead;
                GrammarItem[] new_lookahead = refine_lookahead(extended_new_lookahead);
// 2) If the item on the right of Progress is an intermediate, add all production(without creating duplicates) of that intermediate, with lookahead equal to all items right of Progress+1 and the production lookahead up to the first Terminal item; repeat for all Production States added
                foreach(ProdAndIdx bi; productions_for_intermediate(expected_item)) {
                    generated_states[curr_state_idx] ~= StateLine(0, bi.production_idx, new_lookahead);
                }

                if(curr_line.progress+1 < prod.length) {
// 4) If Progress+1 falls within the Production, if there isn't an action for the grammr item at Production[Progress+1] then create it with Shift(Tot_states+1); then add the Production with it's Progress increased by one to the state indicated by the action related to it's item
                    if(! expected_item in table[curr_state_idx]) {
                        table[curr_state_idx][expected_item] = ParsingAction(Action.SHIFT, generated_states.length);
                    }
                    generated_states ~= [StateLine(curr_line.progress+1, curr_line.production_idx, curr_line.lookahead)];
                } else {
// 3) If Progress+1 is greater than the numbers of items in the production, create a reduction rule of Reduce(Progress, Intermediate) on GrammarItem Lookahead[0]; if a reduce rule shares the grammar item with any other rule there is a conflict
                    if(expected_item in table[curr_state_idx]) {
                        table[curr_state_idx][expected_item] = ParsingAction(Action.REFUTE, 0);
                    } else {
                        table[curr_state_idx][expected_item] = ParsingAction(Action.REDUCE, curr_line.production_idx);
                    }
// 5) Once every production has an action in the state, go to Curr_state+1, repeat from step 2
                }
            }
// 6) Stop when Curr_state>Tot_states
        }

/*
The algorithm for generating a parsing table is as follow:
Example grammar 
    S ::= D
    S ::= a
    D ::= S a


    0) Create the extended grammar like with canonical LR with root symbol S, and it's own symbol S' not in Intermediates nor Terminals set
        S' ::= S
        S ::= D
        S ::= a
        D ::= S a
    1) Let state `0` start with Production State `S' -> . S (~)`, where the dot represents the Progress in the production, '~' represents the Eof symbol, all comma separated lists of symbols in the parenthesis are the lookahead
        0
            S' -> . S  (~)
    2) If the item on the right of Progress is an intermediate, add all production(without creating duplicates) of that intermediate, with lookahead equal to all items right of Progress+1 and the production lookahead up to the first Terminal item; repeat for all Production States added
        0
            S' -> . S  (~)
            S -> . D   (~)
            S -> . a   (~)
            D -> . S a (~)
            S -> . D   (a) # this doesn't create a duplicate because the lookahead is different
            S -> . a   (a)
            D -> . S a (a) # if we didn't stop at the first terminal symbol here we would start creating Production State with equal cores and increasingly more 'a's in the lookahead
    3) If Progress+1 is greater than the numbers of items in the production, create a reduction rule of Reduce(Progress, Intermediate) on GrammarItem Lookahead[0]; if a reduce rule shares the grammar item with any other rule there is a conflict
    4) If Progress+1 falls within the Production, if there isn't an action for the grammr item at Production[Progress+1] then create it with Shift(Tot_states+1); then add the Production with it's Progress increased by one to the state indicated by the action related to it's item
        0
            S' -> . S  (~) # Generate action for 'S' and state 1, add (S' -> S . (~)) to state 1
            S -> . D   (~) # Generate action for 'D' and state 2, add (S -> D . (~)) to state 2
            S -> . a   (~) # Generate action for 'a' and state 3, add (S -> a . (~)) to state 3
            D -> . S a (~) # Action for S already exist, append (D -> S . a (~)) to state 1
            S -> . D   (a) # Action for D already exist, append (S -> D . (a)) to state 2
            S -> . a   (a) # Action for a already exist, append (S -> a . (a)) to state 3
            D -> . S a (a) # Action for S already exist, append (D -> S . a (a)) to state 1
            S: s1
            D: s2
            a: s3
        1
            S' -> S .  (~)
            D -> S . a (~)
            D -> S . a (a)
        2
            S -> D .   (~)
            S -> D .   (a)
        3
            S -> a .   (~)
            S -> a .   (a)
    5) Once every production has an action in the state, go to Curr_state+1, repeat from step 2
    6) Stop when Curr_state>Tot_states
*/
        return table;
    }
};


const Grammar!char _ = new Grammar!char;
//    Grammar!int __ = new Grammar!int;
//    Grammar!long ___ = new Grammar!long;
//    Grammar!wchar ____ = new Grammar!wchar;
//    Grammar!float _____ = new Grammar!float;
