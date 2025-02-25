import std.stdio;
import std.algorithm;
import std.format;
import core.thread.osthread;
import core.time;
class Grammar(GrammarItem = int) {
    GrammarItem[] intermediates;
    GrammarItem[][] productions;


    this(GrammarItem root, GrammarItem eof) {
        this.root = root;
        this.eof = eof;
    }

    Grammar add_production(GrammarItem interm, GrammarItem[] items) {
        this.intermediates ~= interm;
        this.productions ~= items;

        return this;
    }

    bool is_intermediate(GrammarItem item) {
        if(item == this.eof) return false;
        foreach(GrammarItem intermediate; this.intermediates) {
            if(intermediate != this.eof && intermediate == item) { return true; }
        }
        return false;
    }

    void print_productions() {
        for(size_t i = 0; i < this.intermediates.length; i++){
            writeln(i, ' ', this.intermediates[i], " ::= ", this.productions[i]);
        }
        writeln();
    }

    GrammarItem find_root() {
        GrammarItem ret;
        while(is_intermediate(ret)) {ret++;}
        return ret;
    }

    size_t[] productions_for_intermediate(GrammarItem intermediate) {
        size_t[] ret;
        if(!is_intermediate(intermediate)) return ret;

        for(size_t idx = 0; idx < this.intermediates.length; idx++) {
            if(this.intermediates[idx] == intermediate) {
                ret ~= idx;
            }
        }

        return ret;
    }

    GrammarItem[] refine_lookahead(GrammarItem[] lookahead) {
        size_t idx;

        // there should always be a terminal symbol before the end of the array
        for(idx = 0;is_intermediate(lookahead[idx]); idx++) { }

        return lookahead[1..(idx+1)];
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
    void print_state_line(StateLine line){
        string output = "\t";
        output ~= format("%s", this.intermediates[line.production_idx]);
        output ~= format(" -> ");
        output ~= format("%s",this.productions[line.production_idx][0..line.progress]);
        output ~= format(" . %s (%s)", this.productions[line.production_idx][line.progress..$], line.lookahead);
        writeln(output);
    }

    ParsingTable generate_parsing_table() {
        GrammarItem root_prime = this.find_root();
// 0) Create the extended grammar like with canonical LR with root symbol S, and it's own symbol S' not in Intermediates nor Terminals set
// 1) Let state `0` start with Production State `S' -> . S (~)`, where the dot represents the Progress in the production, '~' represents the Eof symbol, all comma separated lists of symbols in the parenthesis are the lookahead
        state[] generated_states = [
            [StateLine(0, this.productions.length, [ this.eof ] )]
        ];
        this.add_production(this.eof, [this.root]);
        this.print_productions();

        ParsingAction[GrammarItem][] table;

// -) For every state:
        for(size_t curr_state_idx = 0; curr_state_idx < generated_states.length; curr_state_idx++) {
            writeln(curr_state_idx);
            table ~= null;
            ref state curr_state = generated_states[curr_state_idx];
        //foreach(state curr_state; generated_states) {

// -) For every state line:
            for(size_t curr_line_idx = 0; curr_line_idx < curr_state.length; curr_line_idx++) {
                StateLine curr_line = curr_state[curr_line_idx];
                this.print_state_line(curr_line);
                Thread.sleep(dur!"seconds"(1));
            //foreach(StateLine curr_line; curr_state) {
                GrammarItem[] prod = this.productions[curr_line.production_idx];

                GrammarItem expected_item;
                if(curr_line.progress < prod.length) { expected_item = prod[curr_line.progress]; }
                else { expected_item = curr_line.lookahead[0]; }


                GrammarItem[] extended_new_lookahead = prod[curr_line.progress..$] ~ curr_line.lookahead;
                GrammarItem[] new_lookahead = refine_lookahead(extended_new_lookahead);
// 2) If the item on the right of Progress is an intermediate, add all production(without creating duplicates) of that intermediate, with lookahead equal to all items right of Progress+1 and the production lookahead up to the first Terminal item; repeat for all Production States added
                foreach(size_t prod_idx; productions_for_intermediate(expected_item)) {
                    StateLine new_state_line = StateLine(0, prod_idx, new_lookahead);
                    if(!curr_state.canFind(new_state_line))
                        curr_state ~= new_state_line;
                }

                if(curr_line.progress < prod.length) {
// 4) If Progress+1 falls within the Production, if there isn't an action for the grammr item at Production[Progress+1] then create it with Shift(Tot_states+1); then add the Production with it's Progress increased by one to the state indicated by the action related to it's item
                    StateLine new_state_line = StateLine(curr_line.progress+1, curr_line.production_idx, curr_line.lookahead);
                    if(expected_item in table[curr_state_idx]) {
                        ref ParsingAction existing_action = table[curr_state_idx][expected_item];
                        if(existing_action.action == Action.SHIFT) {
                            generated_states[existing_action.parameter] ~= new_state_line;
                        } else if(!existing_action.action == Action.SHIFT){
                            existing_action.action = Action.REFUTE;
                        }
                    } else {
                        table[curr_state_idx][expected_item] = ParsingAction(Action.SHIFT, generated_states.length);
                        generated_states ~= [new_state_line];
                    }
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
};


//    Grammar!int __ = new Grammar!int;
//    Grammar!long ___ = new Grammar!long;
//    Grammar!wchar ____ = new Grammar!wchar;
//    Grammar!float _____ = new Grammar!float;
