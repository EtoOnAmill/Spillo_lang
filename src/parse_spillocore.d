import std.traits;
import std.conv;
import std.algorithm;
import std.format;
import std.array;
import parse;
import lex;

/*
intermediate : prod_name = item item item ; prod_name = item item item ; .
*/
mixin template Boilerplateinator(alias elements) {
    mixin(make(elements));
}
string make(string elements) {

    string[] items;

    string curr_intermediate;
    string[] intermediates;
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

    string generate_grammar =
        "parse.GrammarT!GrammarItems.Grammar spillocore =
            { GrammarT!GrammarItems.Grammar g = GrammarT!GrammarItems.Grammar(GrammarItems.S, GrammarItems.EOF);";
    for(size_t idx = 0; idx < prod_items.length; idx++) {
        auto i = intermediates[idx];
        auto p = prod_items[idx];
        string formatted =
            "g.add_production(GrammarItems."
            ~ i
            ~ ",["
            ~ p.map!(e => "GrammarItems." ~ e).join(",")
            ~ "]);";
        generate_grammar ~= formatted;
    }
    generate_grammar ~= "return g; }();";


    string grammar_items_enum = "enum GrammarItems { EOF, ";
    foreach(item; items) {
        grammar_items_enum ~= item ~ ",";
    }
    grammar_items_enum ~= "}";

    return
        grammar_items_enum ~ generate_grammar;
}

mixin Boilerplateinator!"
S :
    S_a = a ;
    S_D = D .
D :
    D_D = S a .";

mixin template open(alias ENUM) {
    static foreach(alias element;EnumMembers!ENUM) {
        mixin(ENUM.stringof, ' ', element.stringof, '=', ENUM.stringof, '.', element.stringof, ';');
    }
}
/*
enum GrammarItems {
// Terminals
    Invalid,
    EOF,
    Comment, // '#'
    Apply, // '!'
    Recurse, // '?'
    Function, // '^'
    Pair, // '/'
    Tuple, // '%'
    Lp, // '('
    Rp, // ')'
    Of, // ':'
    Equals, // '='
    With, // '>'
    Do, // ';'
    When, // '\\'
    Done, // '<'
    And, // '&'
    Or, // '|'
    Alt, // '~'
    Dot, // '.'
    NUM, // \d+
    WORD, // [^Terminal].+?\s
    STR, // `.*?`
// Intermediates
    Sort,
    Patt,
    Typelesspatt,
    Fnbranch,
    Guard,
    Orguard,
    Andguard,
    Litteral,
    Binop,
    Typebinop,
    Sortbinop,
    Pattunit,
    Sortunit,
};

GrammarT!GrammarItems.Grammar spillocore =
{
    mixin open!(GrammarItems);
    auto g = GrammarT!GrammarItems.Grammar(GrammarItems.Sort, GrammarItems.EOF);

    g.add_many_productions(GrammarItems.Sort, [
        [Litteral], // SortLitteral
        [With, Fnbranch, Done], // SortLambda
        [Sort, Sort, Pair], // SortPair
        [Sort, Sort, Apply], // SortApply
        [Sort, Sort, Recurse], // SortRecurse
        [Sort, Of, Of, Pattunit, Sort, Tuple], // SortDepTuple
        [Sort, Of, Of, Pattunit, Sort, Function], // SortDepFunction
        [Sort, Equals, Of, Pattunit, Sort, Pair] // SortDepPair
        ]);
    g.add_many_productions(GrammarItems.Patt, [
        [Typelesspatt, Of, Sortunit] // Patt
        ]);
    g.add_many_productions(GrammarItems.Typelesspatt, [
        [Litteral], // PattLitteral
        [Alt, Sortunit], // PattAlt ; static sort pattern matching
        [Patt, Equals, Pattunit], // PattEquality
        [Patt, Patt, Pair] // PattPair
        ]);
    g.add_many_productions(GrammarItems.Fnbranch, [
        [Guard, Do, Sort], // FnBranchLast
        [Guard, Do, Sort, When, Fnbranch] // FnBranch
        ]);
    g.add_many_productions(GrammarItems.Guard, [
        [Patt, Andguard, Orguard] // Guard
        ]);
    g.add_many_productions(GrammarItems.Andguard, [
        [And, Patt, Of, Equals, Sort, Andguard], // AndGuard
        [] // AndGuardEmpty
        ]);
    g.add_many_productions(GrammarItems.Orguard, [
        [Or, Guard], // OrGuard
        [] // OrGuardEmpty
        ]);
    g.add_many_productions(GrammarItems.Typebinop, [
        [Function], // TypeBinOpFunction
        [Pair] // TypeBinOpPair
        ]);
    g.add_many_productions(GrammarItems.Litteral, [
        [NUM], // LitteralNum
        [NUM, Dot, NUM], // LitteralDecimalNum
        [WORD], // LitteralWord
        [STR] // LitteralString
        ]);
    g.add_many_productions(GrammarItems.Pattunit, [
        [Litteral], // PattUnitLitteral
        [Lp, Patt, Rp] // PattUnitBounded
        ]);
    g.add_many_productions(GrammarItems.Sortunit, [
        [Litteral], // SortUnitLitteral
        [Lp, Sort, Rp] // SortUnitBounded
        ]);

    return g;
}();

//GrammarT!GrammarItems.ParsingTable spillocore_parsing_table = GrammarT!GrammarItems.generate_parsing_table(spillocore);

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
        case "#": return GrammarItems.Comment;
        case "!": case "apply":  return GrammarItems.Apply;
        case "?": case "recurse":  return GrammarItems.Recurse;
        case "^": case "function":  return GrammarItems.Function;
        case "%": case "tuple":  return GrammarItems.Tuple;
        case "/": case "pair":  return GrammarItems.Pair;
        case "(": case "lp":  return GrammarItems.Lp;
        case ")": case "rp":  return GrammarItems.Rp;
        case ":": case "of":  return GrammarItems.Of;
        case "=": case "equal":  return GrammarItems.Equals;
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

enum AstType {
    SortLitteral,
    SortLambda,
    SortPair,
    SortApply,
    SortRecurse,
    SortDepTuple,
    SortDepFunction,
    SortDepPair,

    Patt,
    PattLitteral,
    PattAlt,
    PattEquality,
    PattPair,

    FnBranchLast,
    FnBranch,

    Guard,

    AndGuard,
    AndGuardEmpty,

    OrGuard,
    OrGuardEmpty,

    TypeBinOpFunction,
    TypeBinOpPair,

    LitteralNum,
    LitteralDecimalNum,
    LitteralWord,
    LitteralString,

    PattUnitLitteral,
    PattUnitBounded,

    SortUnitLitteral,
    SortUnitBounded,
}
struct AstNode {
    AstType type;
    AstNode[] items;
}

/*
GrammarT!GrammarItem.token_utils!Token token_u = {
    GrammarItem function(Token val) to_grammar_item;
    Token function(GrammarItem val) from_grammar_item;
};

GrammarT!GrammarItem.ast_utils!(AstNode, Token) ast_u = {
    AstNode function(Token item) from_token;
    Token function(AstNode node) to_token;
    GrammarItem function(AstNode node) to_grammar_item;
    AstNode function(Grammar grammar, size_t prod_idx, AstNode[] items) reduce;
};
*/
