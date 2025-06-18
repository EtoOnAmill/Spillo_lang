import std.stdio;
import std.range;
import std.array;
import std.algorithm;
import std.format;
import std.range.primitives;
import std.conv;

template GrammarT (GrammarItem = int, AstType) {

struct Grammar {
    GrammarItem[] intermediates;
    AstType[] production_names;
    GrammarItem[][] productions;

    GrammarItem root;
    GrammarItem eof;

    this(GrammarItem root, GrammarItem eof) {
        this.root = root;
        this.eof = eof;
    }

    Grammar add_production(GrammarItem interm, AstType ast_type, GrammarItem[] production) {
        this.intermediates ~= interm;
        this.productions ~= production;
        this.production_names ~= ast_type;

        return this;
    }

    Grammar add_many_productions(GrammarItem interm, AstType[] prod_names, GrammarItem[][] list_of_productions) {
        foreach(i, production; list_of_productions) {
            this.add_production(interm, prod_names[i], production);
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
        writeln(i, ' ', g.intermediates[i], " :: ", g.production_names[i], " = ", g.productions[i]);
    }
    writeln();
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
    GrammarItem[] extended_new_lookahead =
        g.productions[state_line.production_idx][state_line.progress..$]
        ~ state_line.lookahead;
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
    ParsingAction[] actions;

    ParsingAction default_action = ParsingAction(Action.REFUTE, 0);

    bool insert_action(GrammarItem expected_item, ParsingAction action) {
        if(this.expected_items.canFind(expected_item)) {
            return false;
        } else {
            this.expected_items ~= expected_item;
            this.actions ~= action;
            return true;
        }
    }

    ParsingAction get_action(GrammarItem item) {
        size_t idx = countUntil(this.expected_items, item);
        if(idx < this.actions.length) {
            return this.actions[idx];
        } else {
            return this.default_action;
        }
    }

    void print() {
        writeln("\t'DEFAULT' : ", this.default_action);
        for(int i = 0; i < this.actions.length; i++) {
            writeln("\t'", this.expected_items[i], "' : ", this.actions[i]);
        }
    }
}
alias ParsingTable = ParsingTableLine[];

struct StateLineMetadata{ Action action; GrammarItem expected_item; }
struct StateLine {
    size_t progress;
    size_t production_idx;
    GrammarItem[] lookahead;
}
struct State {
    StateLine[] productions;
    StateLineMetadata[] metadatas;

    void add_state_line(Grammar g, StateLine prod) {
        this.productions ~= prod;
        this.metadatas ~= calculate_metadata(g, prod);
    }
}


void print_state_line(Grammar g, StateLine line){
    string output = "\t";
    output ~= format("%s", g.intermediates[line.production_idx]);
    output ~= format(" -> ");
    output ~= format("%s", g.productions[line.production_idx][0..line.progress]);
    output ~= format(" . %s (%s)", g.productions[line.production_idx][line.progress..$], line.lookahead);
    writeln(output);
}

StateLineMetadata calculate_metadata(Grammar g, StateLine curr_line) {
    GrammarItem[] prod = g.productions[curr_line.production_idx];

    StateLineMetadata ret;
    if(curr_line.progress < prod.length) {
        ret.action = Action.SHIFT;
        ret.expected_item = prod[curr_line.progress];
    } else {
        ret.expected_item = curr_line.lookahead[0];

        if(curr_line.production_idx == g.productions.length-1) {
            ret.action = Action.ACCEPT;
        } else {
            ret.action = Action.REDUCE;
        }
    }

    return ret;
}


ParsingTable generate_parsing_table(Grammar g) {
    State[] generated_states = [
        State(
            [StateLine(0, g.productions.length, [ g.eof ] )],
            [StateLineMetadata(Action.SHIFT, g.root)])
    ];
    g.add_production(g.eof, AstType.ROOT, [g.root]);
    g.print_productions();

//---------------
    size_t state_to_shift_to(StateLine[] state_kernel) {
        size_t ret = 0;
        while(
        ret < generated_states.length
        && !generated_states[ret].productions.startsWith(state_kernel)) {
            ret++;
        }
        return ret;
    }

    State refine_tmp_state(Grammar g, State tmp_state) {
        State refined_state;

        size_t[] reduce_idxes;
        size_t[] shift_idxes;
        foreach(i, e; tmp_state.metadatas){
            final switch(e.action) {
                case Action.ACCEPT:
                    refined_state.productions ~= tmp_state.productions[i];
                    refined_state.metadatas ~= tmp_state.metadatas[i];
                    break;
                case Action.REDUCE: reduce_idxes ~= i; break;
                case Action.SHIFT: shift_idxes ~= i; break;
                case Action.REFUTE: assert(0, "Unreachable code, parse.d");
            }
        }

        if(
            reduce_idxes
            .map!(i => tmp_state.productions[i].production_idx)
            .uniq
            .walkLength == 1
        ) {
            auto prod = tmp_state.productions[0];
            StateLine simplified_line = StateLine(prod.progress, prod.production_idx, [GrammarItem.EOF]);
            refined_state.productions ~= simplified_line;
            refined_state.metadatas ~= calculate_metadata(g, simplified_line);
        } else {
            foreach(idx; reduce_idxes) {
                refined_state.productions ~= tmp_state.productions[idx];
                refined_state.metadatas ~= tmp_state.metadatas[idx];
            }
        }

        foreach(idx; shift_idxes) {
            refined_state.productions ~= tmp_state.productions[idx];
            refined_state.metadatas ~= tmp_state.metadatas[idx];
        }
        
        return refined_state;
    }
//---------------


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

    ParsingTable table;

    for(size_t curr_state_idx = 0; curr_state_idx < generated_states.length; curr_state_idx++) {
        writeln(curr_state_idx);
        State curr_state = generated_states[curr_state_idx];

        for(size_t idx = 0; idx < curr_state.metadatas.length; idx++) {
            StateLineMetadata metadata = curr_state.metadatas[idx];
            StateLine state_line = curr_state.productions[idx];

            size_t[] prod_idxes = g.productions_for_intermediate(metadata.expected_item);

            foreach(prod_idx; prod_idxes) {
                StateLine prod = StateLine(0, prod_idx, new_lookahead(g, state_line)); 
                if(!curr_state.productions.canFind(prod)) {
                    curr_state.productions ~= prod;
                    curr_state.metadatas ~= calculate_metadata(g, prod);
                }
            }
        }

        table ~= ParsingTableLine();

        size_t[] reduce_idxes;
        size_t[] shift_idxes;
        foreach(i, e; curr_state.metadatas){
            final switch(e.action) {
                case Action.ACCEPT:
                    table[curr_state_idx]
                    .insert_action(e.expected_item, ParsingAction(Action.ACCEPT, 0));
                    break;
                case Action.REDUCE: reduce_idxes ~= i; break;
                case Action.SHIFT: shift_idxes ~= i; break;
                case Action.REFUTE: assert(0, "Unreachable code, parse.d");
            }
        }

        foreach(reduce_idx; reduce_idxes) {
            auto r_metadata = curr_state.metadatas[reduce_idx];
            auto r_state_line = curr_state.productions[reduce_idx];
            ParsingAction action = {
                action : r_metadata.action,
                parameter : r_state_line.production_idx,
            };
            if(r_metadata.expected_item == GrammarItem.EOF) {
                table[curr_state_idx].default_action = action;
            } else {
                assert(table[curr_state_idx].insert_action(r_metadata.expected_item, action), "Reduce/Reduce Conflict");
            }
        }


        GrammarItem[] encountered;
        foreach(shift_idx; shift_idxes) {
            auto s_metadata = curr_state.metadatas[shift_idx];
            if(encountered.canFind(s_metadata.expected_item)) {
                continue;
            } else {
                encountered ~= s_metadata.expected_item;
            }
            State tmp_state =
                shift_idxes
                .filter!(i => curr_state.metadatas[i].expected_item == s_metadata.expected_item)
                .map!((i) {
                    StateLine curr_prod = curr_state.productions[i];
                    return StateLine(
                        curr_prod.progress+1,
                        curr_prod.production_idx,
                        curr_prod.lookahead);
                })
                .fold!((acc, prod) {
                    acc.add_state_line(g, prod);
                    return acc;
                })(State());
            State refined_state = refine_tmp_state(g, tmp_state);

            size_t shift_to_idx = state_to_shift_to(refined_state.productions);
            ParsingAction action = ParsingAction(Action.SHIFT, shift_to_idx);
            assert(table[curr_state_idx].insert_action(s_metadata.expected_item, action), "Shift/Reduce Conflict");

            if(shift_to_idx == generated_states.length) {
                generated_states ~= refined_state;
            }
        }

        foreach(curr_line; curr_state.productions) { g.print_state_line(curr_line); }
        table[curr_state_idx].print();
    }

    return table;
}


ParsingAction get_action(ParsingTable table, size_t state, GrammarItem lookahead) {
    ParsingAction action = table[state].get_action(lookahead);
    return action;
}


struct Ast_utils(AstNode, Token) {
    AstNode function(Token item) from_token;
    GrammarItem function(AstNode node) to_grammar_item;
    AstNode function(Grammar grammar, size_t prod_idx, AstNode[] items) reduce;
    @disable this();
}


AstNode[] parse(AstNode,Token)
( Grammar g
, Token[] input
, Ast_utils!(AstNode,Token) ast_u) {

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

        writeln
            ( map!(e =>
                ast_u.to_grammar_item(cast(AstNode)e).to!string
                ~ "::"
                ~ e.ast_type.to!string) (processed)
            , '.'
            , map!(e =>
                ast_u.to_grammar_item(cast(AstNode)e).to!string
                ~ "::"
                ~ e.ast_type.to!string) (right_of_cursor)
            , to_parse
            , '\t'
            , p_action
            , '\n', state_stack);

        writeln();

        final switch(p_action.action) {
            case Action.SHIFT:
                processed ~= next_item_processed;
                state_stack ~= p_action.parameter;
                if(r_o_c) right_of_cursor.popFront;
                else to_parse.popFront;
                break;

            case Action.REDUCE:
                size_t progress = g.productions[p_action.parameter].length;
                size_t p_length = processed.length-progress;
                AstNode[] items = processed[p_length..$];
                processed.popBackN(progress);
                state_stack.popBackN(progress);
                right_of_cursor = ast_u.reduce(g, p_action.parameter, items) ~ right_of_cursor;
                break;

            case Action.ACCEPT:
            case Action.REFUTE:
                break loop;
        }
    }

    return processed;
}
}


/*
intermediate : prod_name = item item item ; prod_name = item item item .

white space before and after : = ; and .
every production must have a prod_name
the prod_name can be the same as intermediate
cannot start with RESERVED
*/
mixin template Boilerplateinator(alias grammar_name, alias root_symbol, alias eof_symbol, alias elements) {
    mixin(make(elements, grammar_name, root_symbol, eof_symbol));
}
string make(string elements, string grammar_name, string root_symbol, string eof_symbol) {

    string[] items;

    string curr_intermediate;
    string[] intermediates;
    string[] terminals;
    string[] prod_names;
    string[] curr_prod_item;
    string[][] prod_items;

    enum State { Intermediate, ProdName, ProdItems }
    State curr_state;

    foreach(word; split(elements)) {
        final switch (curr_state) {
            case State.Intermediate:
                if(word == ":"){ curr_state = State.ProdName; }
                else {
                    curr_intermediate = word;
                    if(!items.canFind(word)) { items ~= word; }
                }
                break;
            case State.ProdName:
                if(word == "="){ curr_state = State.ProdItems; }
                else { prod_names ~= word; intermediates ~= curr_intermediate; }
                break;
            case State.ProdItems:
                if(word == ".") { prod_items ~= curr_prod_item; curr_prod_item = []; curr_state = State.Intermediate; }
                else if(word == ";") { prod_items ~= curr_prod_item; curr_prod_item = []; curr_state = State.ProdName; }
                else {
                    curr_prod_item ~= word;
                    if(!items.canFind(word)) { items ~= word; }
                }
                break;
        }
    }

    terminals = filter!(e => !intermediates.canFind(e))(items).array;

    string generate_grammar =
        "alias GrammarTinstance = GrammarT!(GrammarItems, AstType);\n"
        ~ "GrammarTinstance.Grammar "
        ~ grammar_name
        ~ " = { GrammarTinstance.Grammar g = GrammarTinstance.Grammar(GrammarItems."
        ~ root_symbol
        ~ ", GrammarItems."
        ~ eof_symbol
        ~ ");\n";
    for(size_t idx = 0; idx < prod_items.length; idx++) {
        auto i = intermediates[idx];
        auto p = prod_items[idx];
        string formatted =
            "g.add_production(GrammarItems."
            ~ i
            ~ ", AstType."
            ~ prod_names[idx]
            ~ ",\n\t[ "
            ~ p.map!(e => "GrammarItems." ~ e).join(",")
            ~ " ]);\n";
        generate_grammar ~= formatted;
    }
    generate_grammar ~= "\treturn g; }();\n";


    string grammar_items_enum = "enum GrammarItems : uint { EOF, Invalid\n\t, ";
    foreach(item; items) {
        grammar_items_enum ~= item ~ "\n\t, ";
    }
    grammar_items_enum ~= "}\n";


    string AstType = "enum AstType : uint \n{ ROOT, TERMINAL, ";
    foreach(prod_name; prod_names) {
        AstType ~= prod_name ~ "\n\t, ";
    }
    AstType ~= "}\n";

    return
        grammar_items_enum ~ AstType ~ generate_grammar;
}
