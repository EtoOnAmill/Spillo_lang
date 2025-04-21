import std.traits;
import std.conv;
import std.algorithm;
import std.format;
import std.array;
import parse;
import lex;

mixin Boilerplateinator!("spillocore", "Sort", "EOF", "
Sort :
    SortLitteral = Litteral ;
    SortLambda = With Fnbranch Done ;

    SortPair = Sort Sort Pair ;
    SortTuple = Sort Sort Tuple ;

    SortApply = Sort Sort Apply ;
    SortRecurse = Sort Sort Recurse ;
    SortFunction = Sort Sort Function ;

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
");

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
