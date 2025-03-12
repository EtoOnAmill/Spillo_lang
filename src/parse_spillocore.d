import std.traits;
import std.format;
import parse;
import lex;

mixin template open(alias ENUM) {
    static foreach(alias element;EnumMembers!ENUM) {
        mixin(ENUM.stringof, ' ', element.stringof, '=', ENUM.stringof, '.', element.stringof, ';');
    }
}

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
        [Litteral],
        [With, Fnbranch, Done],
        [Sort, Sort, Pair],
        [Sort, Sort, Apply],
        [Sort, Sort, Recurse],
        [Sort, Of, Of, Pattunit, Sort, Function],
        [Sort, Of, Of, Pattunit, Sort, Tuple],
        [Sort, Equals, Of, Pattunit, Sort, Pair]
        ]);

    g.add_many_productions(GrammarItems.Patt, [
        [Typelesspatt, Of, Sortunit]
        ]);

    g.add_many_productions(GrammarItems.Typelesspatt, [
        [Litteral],
        [Alt, Sortunit], // static sort pattern matching
        [Patt, Equals, Pattunit],
        [Patt, Patt, Pair]
        ]);

    g.add_many_productions(GrammarItems.Fnbranch, [
        [Patt, Guard, Do, Sort],
        [Patt, Guard, Do, Sort, When, Fnbranch]
        ]);

    g.add_many_productions(GrammarItems.Guard, [
        [Andguard, Orguard]
        ]);

    g.add_many_productions(GrammarItems.Orguard, [
        [Or, Patt, Guard]
        [],
        ]);

    g.add_many_productions(GrammarItems.Andguard, [
        [And, Patt, Of, Equals, Sort, Andguard],
        []
        ]);

    g.add_many_productions(GrammarItems.Litteral, [
        [NUM],
        [NUM, Dot, NUM],
        [WORD],
        [STR]
        ]);

    g.add_many_productions(GrammarItems.Pattunit, [
        [Litteral],
        [Lp, Patt, Rp]
        ]);

    g.add_many_productions(GrammarItems.Sortunit, [
        [Litteral],
        [Lp, Sort, Rp]
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
        case "%": case "couple":  return GrammarItems.Tuple;
        case "/": case "pair":  return GrammarItems.Pair;
        case "(": case "begin":  return GrammarItems.Lp;
        case ")": case "end":  return GrammarItems.Rp;
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
//    Sort:
//        litterals
    SortLitteral,
//        | '>' fnBranch '<'
    SortLambda,
//        | sort sort binop
    SortBinop,
//        | sort ':' ':' pattunit sort typebinop
    SortDepType,
//        | sort '=' ':' pattunit sort '/' ;
    SortDepExpr,

//    Patt: typeless_patt ':' sortunit
    TypedPatt,
//    Typeless_patt:
//        litterals
    PattLitteral,
//        | '~' sortunit // static sort pattern matching
    PattSort,
//        | patt '=' pattunit
    PattEquality,
//        | patt patt '/' ;
    PattPair,

//    Fnbranch:
//        patt guard ';' sort
    FnBranchLast,
//        | patt guard ';' sort '\\' fnBranch;
    Fnbranch,

//    Guard: andguard orguard;
    Guard,
//    Orguard:
//        | '|' patt guard;
    GuardOr,
    GuardOrEmpty,
//    Andguard:
//        | '&' patt ':' '=' sort andguard;
    GuardAnd,
    GuardAndEmpty,

//    Litterals: 
//        NUM
    LitteralNum,
//        | NUM '.' NUM
    LitteralDecimalNum,
//        | WORD
    LitteralWord,
//        | STR ;
    LitteralString,

//    Binop: typebinop | sortbinop;
    BinopType,
    BinopSort,

//    Typebinop: '^' | '%';
    BinopTypePair,
    BinopTypeFunction,

//    Sortbinop: '!' | '/' | '?';
    BinopSortApplication,
    BinopSortPair,
    BinopSortRecApplication,

//    Pattunit: litterals | '(' patt ')';
    PattUnitLitteral,
    PattUnitBounded,
//    Sortunit: litterals | '(' sort ')';
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
