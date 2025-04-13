import std.stdio;
import std.range;
import std.array;
import std.algorithm;
import std.format;
import std.range.primitives;

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

        Grammar add_many_productions(GrammarItem interm, GrammarItem[][] list_of_productions) {
            foreach(production; list_of_productions) {
                this.add_production(interm, production);
            }

            return this;
        }
    }



    bool is_intermediate(Grammar g, GrammarItem item) {
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

    struct ParsingTableLine {
        GrammarItem[] expected_items;
        ParsingAction[] relative_actions;
        ParsingAction default_action;

        bool insert_action(GrammarItem expected_item, ParsingAction action) {
            if(this.expected_items.canFind(expected_item)) {
                return false;
            } else {
                this.expected_items ~= expected_item;
                this.relative_actions ~= action;
                return true;
            }
        }

        ParsingAction get_action(GrammarItem item) {
            size_t idx = countUntil(this.expected_items, item);
            if(idx > 0) {
                return this.relative_actions[idx];
            } else {
                return this.default_action;
            }
        }
    }
    alias ParsingTable = ParsingTableLine[];

    struct StateLineMetadata{ Action action; GrammarItem expected_item; };
    struct StateLine {
        size_t progress;
        size_t production_idx;
        GrammarItem[] lookahead;
    };
    struct State {
        StateLine[] productions;
        StateLineMetadata[] metadata;
    }


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
            State([StateLine(0, g.productions.length, [ g.eof ] )], [StateLineMetadata(Action.SHIFT, g.root)])
        ];
        g.add_production(g.eof, [g.root]);
        g.print_productions();


        StateLineMetadata calculate_metadata(StateLine curr_line) {
            GrammarItem[] prod = g.productions[curr_line.production_idx];

            GrammarItem expected_item;
            if(curr_line.progress < prod.length) { expected_item = prod[curr_line.progress]; }
            else { expected_item = curr_line.lookahead[0]; }

            StateLineMetadata ret;
            ret.expected_item = expected_item;
            if(curr_line.progress < prod.length){
                ret.action = Action.SHIFT;
            } else if(curr_line.production_idx == g.productions.length-1) {
                ret.action = Action.ACCEPT;
            } else {
                ret.action = Action.REDUCE;
            }
            return ret;
        }


        ParsingTable table;

// -) For every state:
// for every state line
//     add to the state every state line derived from the productions of the expected item
//     calculat the added line action and add it to the state metadata
// for all the reduce action add a table entry
//     for the production that appears most add as default reduce action
// for all the acitons that are shift
//     group in TMP states by expected item
//     foreach TMP state
//         group reductions by the production
//         simplify one of the group to `prod` [eof] ; eof: R prod
//             prioritize either number of Intermediates in expected items
//             length of produciton
//             frequency of production in group
//         add TMP state to states and add shift action to current state 
        for(size_t curr_state_idx = 0; curr_state_idx < generated_states.length; curr_state_idx++) {
            writeln(curr_state_idx);
            State curr_state = generated_states[curr_state_idx];

            size_t state_to_shift_to(StateLine[] state_kernel) {
                size_t ret = 0;
                while(
                ret < generated_states.length
                && !generated_states[ret].productions.startsWith(state_kernel)) {
                    ret++;
                }
                return ret;
            }



            foreach(curr_line; curr_state.productions) { g.print_state_line(curr_line); }
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

    ParsingAction get_action(ParsingTable table, size_t state, GrammarItem lookahead) {
        ParsingAction action = table[state].get_action(lookahead);
        return action;
    }

    struct ast_utils(AstNode, Token) {
        AstNode function(Token item) from_token;
        GrammarItem function(AstNode node) to_grammar_item;
        AstNode function(Grammar grammar, size_t prod_idx, AstNode[] items) reduce;
        @disable this();
    };

    AstNode[] parse(AstNode,Token)
    ( Grammar g
    , Token[] input
    , ast_utils!(AstNode,Token) ast_u) {

        ParsingTable table = g.generate_parsing_table();
        Token[] to_parse = input;
        AstNode[] processed;
        AstNode[] right_of_cursor;
        size_t[] state_stack = [0];

loop:
        while(true) {
            bool r_o_c = right_of_cursor.length > 0;

            AstNode next_item_processed;
            if(r_o_c) {
                next_item_processed = cast(AstNode) right_of_cursor.front;
            } else {
                Token next_token = cast(Token) to_parse.front;
                next_item_processed = ast_u.from_token(next_token);
            }

            GrammarItem next_item = ast_u.to_grammar_item(next_item_processed);
            ParsingAction p_action = get_action(table, state_stack.back, next_item);

            writeln(map!(e => ast_u.to_grammar_item(cast(AstNode)e))(processed), '.', map!(e => ast_u.to_grammar_item(cast(AstNode)e))(right_of_cursor), to_parse, '\t', p_action, '\n', state_stack);

            final switch(p_action.action) {
                case Action.SHIFT:
                    processed ~= next_item_processed;
                    state_stack ~= p_action.parameter;
                    if(r_o_c) right_of_cursor.popFront;
                    else to_parse.popFront;
                    break;

                case Action.REDUCE:
                    size_t progress = g.productions[p_action.parameter].length;
                    GrammarItem intermediate = g.intermediates[p_action.parameter];
                    size_t p_length = processed.length-progress;
                    AstNode[] items = processed[p_length..$];
                    processed.popBackN(progress);
                    state_stack.popBackN(progress);
                    right_of_cursor = ast_u.reduce(g, p_action.parameter, items) ~ right_of_cursor;
                    break;

                case Action.ACCEPT:
                    break loop;

                case Action.REFUTE:
                    break loop;
            }
        }

        return processed;
    }
};


//    Grammar!int __ = new Grammar!int;
//    Grammar!long ___ = new Grammar!long;
//    Grammar!wchar ____ = new Grammar!wchar;
//    Grammar!float _____ = new Grammar!float;
