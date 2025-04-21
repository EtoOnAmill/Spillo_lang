import std.traits;
import std.conv;
import std.algorithm;
import std.format;
import std.array;
import parse;
import lex;


mixin template open(alias ENUM) {
    static foreach(alias element;EnumMembers!ENUM) {
        mixin(ENUM.stringof, ' ', element.stringof, '=', ENUM.stringof, '.', element.stringof, ';');
    }
}
/*
intermediate : prod_name = item item item ; prod_name = item item item .

white space before and after : = ; and .
every production must have a prod_name
the prod_name can be the same as intermediate
cannot start with RESRVED
*/
mixin template Boilerplateinator(alias elements) {
    mixin(make(elements));
}
string make(string elements) {

    string[] items;

    string curr_intermediate;
    string[] intermediates;
    string[] terminals;
    string[] prod_names;
    string[] curr_prod_item;
    string[][] prod_items;

    enum State { Intermediate, ProdName, ProdItems }
    State curr_state;

loop:
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
        "parse.GrammarT!GrammarItems.Grammar spillocore =
{ GrammarT!GrammarItems.Grammar g = GrammarT!GrammarItems.Grammar(GrammarItems.Sort, GrammarItems.EOF);\n";
    for(size_t idx = 0; idx < prod_items.length; idx++) {
        auto i = intermediates[idx];
        auto p = prod_items[idx];
        string formatted =
            "g.add_production(GrammarItems."
            ~ i
            ~ ",\n\t[ "
            ~ p.map!(e => "GrammarItems." ~ e).join(",")
            ~ " ]);\n";
        generate_grammar ~= formatted;
    }
    generate_grammar ~= "\treturn g; }();\n";


    string grammar_items_enum = "enum GrammarItems { EOF, Invalid\n\t, ";
    foreach(item; items) {
        grammar_items_enum ~= item ~ "\n\t, ";
    }
    grammar_items_enum ~= "}\n";


    string AstType = "enum AstType \n{ ";
    foreach(prod_name; prod_names) {
        AstType ~= prod_name ~ "\n\t, ";
    }
    AstType ~= "}\n";

    return
        grammar_items_enum ~ AstType ~ generate_grammar;
}

mixin Boilerplateinator!"
Sort :
    SortLitteral = Litteral ;
    SortLambda = With Fnbranch Done ;

    SortPair = Sort Sort Pair ;
    SortTuple = Sort Sort Tuple ;
    SortFunction = Sort Sort Function ;
    SortApply = Sort Sort Apply ;
    SortRecurse = Sort Sort Recurse ;

    SortDepTuple = Sort Of Of Pattunit Sort Tuple ;
    SortDepFunction = Sort Of Of Pattunit Sort Function ;

    SortDepPair = Sort Equal Of Pattunit Sort Pair .

Patt :
    Patt = Typelesspatt Of Sortunit .
Typelesspatt :
    PattLitteral = Litteral ;
    PattAlternative = Alt Sortunit ;
    PattEquality = Patt Equal Pattunit ;
    PattPair = Patt Patt Pair .

Fnbranch :
    FnBranchLast = Guard Do Sort ;
    FnBranch = Guard Do Sort When Fnbranch .

Guard :
    Guard = Patt Andguard Orguard .
Andguard :
    AndGuardEmpty = ;
    AndGuard = And Patt Of Equal Sort Andguard .
Orguard :
    OrGuardEmpty = ;
    OrGuard = Or Guard .

Litteral : 
    LitteralNumber = NUM ;
    LitteralDecimal = NUM Dot NUM ;
    LitteralWord = WORD ;
    LitteralString = STR .

Pattunit :
    PattUnitLitteral = Litteral ;
    PattUnitBounded = Lp Patt Rp .
Sortunit :
    SortUnitLitteral = Litteral ;
    SortUnitBounded = Lp Sort Rp .
";

GrammarItems token_to_grammar_item(Token t) {
    final switch(t.tt) {
        case TokenType.EOF: return GrammarItems.EOF;
        case TokenType.WORD: return GrammarItems.WORD;
        case TokenType.STRING: return GrammarItems.STR;
        case TokenType.NUMBER: return GrammarItems.NUM;
        case TokenType.RESERVED: return string_to_grammar_item(t.value);
        case TokenType.IGNORE: return GrammarItems.Invalid;
    }
}

GrammarItems string_to_grammar_item(string s) {
    switch(s) {
        case "!": case "apply":  return GrammarItems.Apply;
        case "?": case "recurse":  return GrammarItems.Recurse;
        case "^": case "function":  return GrammarItems.Function;
        case "%": case "tuple":  return GrammarItems.Tuple;
        case "/": case "pair":  return GrammarItems.Pair;
        case "(": case "lp":  return GrammarItems.Lp;
        case ")": case "rp":  return GrammarItems.Rp;
        case ":": case "of":  return GrammarItems.Of;
        case "=": case "equal":  return GrammarItems.Equal;
        case ">": case "with":  return GrammarItems.With;
        case ";": case "do":  return GrammarItems.Do;
        case "\\": case "when": return GrammarItems.When;
        case "<": case "done":  return GrammarItems.Done;
        case "&": case "and":  return GrammarItems.And;
        case "|": case "or":  return GrammarItems.Or;
        case "~": case "alt":  return GrammarItems.Alt;
        case ".": case "dot":  return GrammarItems.Dot;
        default: return GrammarItems.Invalid;
    }
}

struct AstNode {
    GrammarItems type;
    AstNode[] items;
}

GrammarT!GrammarItems.ast_utils!(AstNode, Token) ast_u = {

    from_token : function AstNode(Token token) { return AstNode(token_to_grammar_item(token), []); },

    to_grammar_item : function GrammarItems(AstNode node) { return node.type; },

    reduce : function AstNode(GrammarT!GrammarItems.Grammar grammar, size_t prod_idx, AstNode[] items) {
        GrammarItems intermediate = grammar.intermediates[prod_idx];
        size_t prod_length = grammar.productions[prod_idx].length;
        AstNode[] prod_items = items[0..prod_length];
        return AstNode(intermediate, prod_items);
    },
};
