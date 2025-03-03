import std.stdio;
import std.array;
import std.algorithm;
import std.format;

template GrammarT (GrammarItem = int) {

    struct Grammar {
        GrammarItem[] intermediates;
        GrammarItem[][] productions;

        GrammarItem root;
        GrammarItem eof;

        this(GrammarItem root, GrammarItem eof) {
            this.root = root;
            this.eof = eof;
        }

        Grammar add_production(GrammarItem interm, GrammarItem[] production) {
            this.intermediates ~= interm;
            this.productions ~= production;

            return this;
        }

        Grammar add_many_production(GrammarItem interm, GrammarItem[][] list_of_productions) {
            foreach(production; list_of_productions) {
                this.add_production(interm, production);
            }

            return this;
        }
    }



    bool is_intermediate(Grammar g,GrammarItem item) {
        if(item == g.eof) return false;
        foreach(GrammarItem intermediate; g.intermediates) {
            if(intermediate != g.eof && intermediate == item) { return true; }
        }
        return false;
    }

    void print_productions(Grammar g) {
        for(size_t i = 0; i < g.intermediates.length; i++){
            writeln(i, ' ', g.intermediates[i], " ::= ", g.productions[i]);
        }
        writeln();
    }

    GrammarItem find_root(Grammar g) {
        GrammarItem ret;
        while(g.is_intermediate(ret) && ret != GrammarItem.max) {ret++;}
        return ret;
    }

    size_t[] productions_for_intermediate(Grammar g, GrammarItem intermediate) {
        size_t[] ret;
        if(!g.is_intermediate(intermediate)) return ret;

        for(size_t idx = 0; idx < g.intermediates.length; idx++) {
            if(g.intermediates[idx] == intermediate) {
                ret ~= idx;
            }
        }

        return ret;
    }

    GrammarItem[] new_lookahead(Grammar g, StateLine state_line) {
        GrammarItem[] extended_new_lookahead = g.productions[state_line.production_idx][state_line.progress..$] ~ state_line.lookahead;
        return g.refine_lookahead(extended_new_lookahead);
    }

    GrammarItem[] refine_lookahead(Grammar g,GrammarItem[] lookahead) {
        size_t idx = 1;

        // there should always be a terminal symbol before the end of the array
        while(g.is_intermediate(lookahead[idx])) { idx++; }

        return lookahead[1..(idx+1)];
    }



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
    alias State = StateLine[];
    void print_state_line(Grammar g, StateLine line){
        string output = "\t";
        output ~= format("%s", g.intermediates[line.production_idx]);
        output ~= format(" -> ");
        output ~= format("%s",g.productions[line.production_idx][0..line.progress]);
        output ~= format(" . %s (%s)", g.productions[line.production_idx][line.progress..$], line.lookahead);
        writeln(output);
    }

    ParsingTable generate_parsing_table(Grammar g) {
        GrammarItem root_prime = g.find_root();
// 0) Create the extended grammar like with canonical LR with root symbol S, and it's own symbol S' not in Intermediates nor Terminals set
// 1) Let state `0` start with Production State `S' -> . S (~)`, where the dot represents the Progress in the production, '~' represents the Eof symbol, all comma separated lists of symbols in the parenthesis are the lookahead
        State[] generated_states = [
            [StateLine(0, g.productions.length, [ g.eof ] )]
        ];
        g.add_production(g.eof, [g.root]);
        g.print_productions();

        ParsingAction[GrammarItem][] table;

// -) For every state:
        for(size_t curr_state_idx = 0; curr_state_idx < generated_states.length; curr_state_idx++) {
            writeln(curr_state_idx);
            table ~= null;
            ref State curr_state = generated_states[curr_state_idx];

            struct StateLineMetadata{ Action action; GrammarItem expected_item; };
            StateLineMetadata[] metadatas;

// -) For every state line:
            for(size_t curr_line_idx = 0; curr_line_idx < curr_state.length; curr_line_idx++) {
                StateLine curr_line = curr_state[curr_line_idx];
                g.print_state_line(curr_line);

                GrammarItem[] prod = g.productions[curr_line.production_idx];

                GrammarItem expected_item;
                if(curr_line.progress < prod.length) { expected_item = prod[curr_line.progress]; }
                else { expected_item = curr_line.lookahead[0]; }


// 2) If the item on the right of Progress is an intermediate, add all production(without creating duplicates) of that intermediate, with lookahead equal to all items right of Progress+1 and the production lookahead up to the first Terminal item; repeat for all Production States added
                foreach(size_t prod_idx; g.productions_for_intermediate(expected_item)) {
                    StateLine new_state_line = StateLine(0, prod_idx, g.new_lookahead(curr_line));
                    if(!curr_state.canFind(new_state_line))
                        curr_state ~= new_state_line;
                }

// 4) If Progress+1 falls within the Production, if there isn't an action for the grammr item at Production[Progress+1] then create it with Shift(Tot_states+1); then add the Production with it's Progress increased by one to the state indicated by the action related to it's item
// 3) If Progress+1 is greater than the numbers of items in the production, create a reduction rule of Reduce(Progress, Intermediate) on GrammarItem Lookahead[0]; if a reduce rule shares the grammar item with any other rule there is a conflict
                StateLineMetadata current;
                current.expected_item = expected_item;
                if(curr_line.progress < prod.length){
                    current.action = Action.SHIFT;
                } else if(curr_line.production_idx == (g.productions.length-1)) {
                    current.action = Action.ACCEPT;
                } else {
                    current.action = Action.REDUCE;
                }
                metadatas ~= current;
// 5) Once every production has an action in the state, go to Curr_state+1, repeat from step 2
            }

            for(size_t idx=0; idx < curr_state.length; idx++) {
                StateLineMetadata metadata = metadatas[idx];
                StateLine curr_line = curr_state[idx];

                if(!(metadata.expected_item in table[curr_state_idx])) {
                    if(metadata.action == Action.ACCEPT) {

                        table[curr_state_idx][metadata.expected_item] = ParsingAction(Action.ACCEPT, curr_line.production_idx);

                    } else if(metadata.action == Action.REDUCE) {

                        table[curr_state_idx][metadata.expected_item] = ParsingAction(Action.REDUCE, curr_line.production_idx);

                    } else {

                        StateLine[] new_same_expected_item = [
                            StateLine(
                                curr_line.progress+1,
                                curr_line.production_idx,
                                curr_line.lookahead)];

                        for(size_t state_line_idx=0; state_line_idx < metadatas.length; state_line_idx++) {
                            if( idx != state_line_idx && metadatas[state_line_idx].expected_item == metadata.expected_item ) {
                                StateLine same_expected_item_line = curr_state[state_line_idx];

                                if(metadatas[state_line_idx].action != Action.SHIFT)
                                    writeln("ERROR! Conflict with state_line(", same_expected_item_line, ")");
                                else
                                    new_same_expected_item ~= StateLine(
                                        same_expected_item_line.progress+1,
                                        same_expected_item_line.production_idx,
                                        same_expected_item_line.lookahead);
                            }
                        }


                        size_t state_to_shift_to = 0;
                        while(
                        state_to_shift_to < generated_states.length
                        && !generated_states[state_to_shift_to].startsWith(new_same_expected_item)) {
                            state_to_shift_to++;
                        }

                        table[curr_state_idx][metadata.expected_item] = ParsingAction(Action.SHIFT, state_to_shift_to);
                        if(state_to_shift_to == generated_states.length) {
                            generated_states ~= new_same_expected_item;
                        }
                    }
                }
            }
            writeln("\t", table[curr_state_idx]);
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

    bool parse(Grammar g, GrammarItem[] input) {

        return true;
    }
};


//    Grammar!int __ = new Grammar!int;
//    Grammar!long ___ = new Grammar!long;
//    Grammar!wchar ____ = new Grammar!wchar;
//    Grammar!float _____ = new Grammar!float;
