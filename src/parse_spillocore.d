import parse;
import lex;

enum GrammarItems {
// Terminals
    Comment, // '#'
    Apply, // '!'
    Couple, // '%'
    And, // '&'
    Begin, // '('
    End, // ')'
    Dot, // '.'
    Pair, // '/'
    Of, // ':'
    Do, // ';'
    Done, // '<'
    Equals, // '='
    With, // '>'
    Recurse, // '?'
    When, // '\\'
    Function, // '^'
    Or, // '|'
    Not, // '~'
    NUM, // \d+
    WORD, // [^Terminal].+?\s
    STR, // `.*?`
// Intermediates
    Sort,
    Typedpatt,
    Patt,
    FnBranch,
    Guard,
    Orguard,
    Andguard,
    Litterals,
    Binop,
    Typebinop,
    Sortbinop,
    Pattunit,
    Sortunit,
};
enum AstType {
    SortLitteral,
    SortLambda,
    SortBinop,
    SortDepType,
    SortDepExpr,
//    Sort:
//        litterals
//        | '>' fnBranch '<'
//        | sort sort binop
//        | sort ':' ':' pattunit sort typebinop
//        | sort '=' ':' pattunit sort '/' ;

    TypedPatt,
    PattLitteral,
    PattSort,
    PattEquality,
    PattPair,
//    Patt:
//        typeless_patt ':' sortunit
//    Typeless_patt:
//        litterals
//        | '~' sortunit // static sort pattern matching
//        | patt '=' pattunit
//        | patt patt '/' ;

    FnBranchLast,
    FnBranch,
//    FnBranch:
//        patt guard ';' sort
//        | patt guard ';' sort '\\' fnBranch;

    Guard,
    GuardOr,
    GuardOrEmpty,
    GuardAnd,
    GuardAndEmpty,
//    Guard: andguard orguard;
//    Orguard:
//        | '|' patt guard;
//    Andguard:
//        | '&' patt ':' '=' sort andguard;

    LitteralNum,
    LitteralDecimalNum,
    LitteralWord,
    LitteralString,
//    Litterals: 
//        NUM
//        | NUM '.' NUM
//        | WORD
//        | STR ;

    BinopType,
    BinopTypePair,
    BinopTypeFunction,

    BinopSort,
    BinopSortPair,
    BinopSortApplication,
    BinopSortRecApplication,
//    Binop: typebinop | sortbinop;
//    Typebinop: '^' | '%';
//    Sortbinop: '!' | '/' | '?';

    PattUnitLitteral,
    PattUnitBounded,
    SortUnitLitteral,
    SortUnitBounded,
//    Pattunit: litterals | '(' patt ')';
//    Sortunit: litterals | '(' sort ')';

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
