import std.traits;
import std.conv;
import std.algorithm;
import std.format;
import std.array;
import std.stdio;
import parse;
import lex;

mixin Boilerplateinator!("spillocore", "Sort", "EOF", "
Sort :
    SortLitteral = Litteral ;
    SortBinOp = Sort Sort BinOp EMPTY ;
    SortLambda = With Fnbranch Done ;
    SortDepBind = Sort Of Of Pattunit .

BinOp :
    BinOpPair = Pair ;
    BinOpTuple = Tuple ;
    BinOpFunction = Function ;
    BinOpApply = Apply ;
    BinOpRecurse = Recurse .

Patt :
    PattTypeless = Typelesspatt ;
    PattId = WORD Of Sortunit .
Typelesspatt :
    PattLitteral = Litteral ;
    PattAlternative = Alt Sortunit ;
    PattEquality = Patt Equal Pattunit ;
    PattBinOp = Patt Patt BinOp EMPTY .

Fnbranch :
    FnBranchLast = Guard Do Sort ;
    FnBranch = Guard Do Sort When Fnbranch .

Guard :
    Guard = Patt ;
    GuardAnd = Patt And Patt Of Equal Sort .

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
//        case "|": case "or":  return GrammarItems.Or;
        case "~": case "alt":  return GrammarItems.Alt;
        case ".": case "dot":  return GrammarItems.Dot;
        case "": case "EMPTY":  return GrammarItems.EMPTY;
        default: return GrammarItems.Invalid;
    }
}

struct ParseAst {
    GrammarItems type;
    AstType ast_type;
    ParseAstData *ast;
}

GrammarTinstance.Ast_utils!(ParseAst, Token) ast_u = {

    from_token : &from_token,

    to_grammar_item : function GrammarItems(ParseAst node) { return node.type; },

    reduce : &reduce,
};

ParseAst from_token(Token token) {
    ParseAst ret = ParseAst(token_to_grammar_item(token));
    ret.ast = new ParseAstData();
    final switch(token.tt) {
    case TokenType.WORD:
        ret.ast.litteralWord.value = token.value.dup;
        ret.ast_type = AstType.LitteralWord;
        break;
    case TokenType.STRING:
        ret.ast.litteralString.value = token.value.dup;
        ret.ast_type = AstType.LitteralString;
        break;
    case TokenType.NUMBER:
        ret.ast.litteralNumber.value = token.value.dup;
        ret.ast_type = AstType.LitteralNumber;
        break;

    case TokenType.EOF: case TokenType.RESERVED: case TokenType.IGNORE:
        ret.ast_type = AstType.TERMINAL;
        ret.ast.items = [];
    }
    return ret;
}

ParseAst reduce(GrammarTinstance.Grammar grammar, size_t prod_idx, ParseAst[] items) {
    GrammarItems intermediate = grammar.intermediates[prod_idx];
    AstType ast_type = grammar.production_names[prod_idx];

    ParseAst ret;
    ret.type = intermediate;
    ret.ast_type = ast_type;

    ret.ast = new ParseAstData();
    final switch(ast_type) {
    case AstType.TERMINAL: assert(0, "illegal reduction: AstType.TERMINAL  in src/parse_spillocore.d");
    case AstType.ROOT: assert(0, "illegal reduction: AstType.ROOT  in src/parse_spillocore.d");

    case AstType.LitteralWord:
    case AstType.LitteralString:
    case AstType.LitteralNumber:
        ret.ast = items[0].ast; break;
    case AstType.LitteralDecimal:
        ret.ast.litteralDecimal = LitteralDecimal(
            items[0].ast
            ? items[0].ast.litteralNumber.value
            : "NUM",
            items[2].ast
            ? items[2].ast.litteralNumber.value
            : "NUM",
        );
        break;

    case AstType.PattLitteral: ret.ast.pattLitteral = PattLitteral(items[0]); break;
    case AstType.SortLitteral: ret.ast.sortLitteral = SortLitteral(items[0]); break;
    case AstType.PattUnitLitteral: ret.ast.pattUnitLitteral = PattUnitLitteral(items[0]); break;
    case AstType.PattUnitBounded: ret.ast.pattUnitBounded = PattUnitBounded(items[1]); break;
    case AstType.SortUnitLitteral: ret.ast.sortUnitLitteral = SortUnitLitteral(items[0]); break;
    case AstType.SortUnitBounded: ret.ast.sortUnitBounded = SortUnitBounded(items[1]); break;

    case AstType.SortLambda: ret.ast.sortLambda = SortLambda(items[1]); break;
    case AstType.SortBinOp: ret.ast.sortBinOp = SortBinOp(items[0], items[1], items[2]); break;
    case AstType.BinOpPair: ret.ast.binOpPair = BinOpPair(items[0]); break;
    case AstType.BinOpTuple: ret.ast.binOpTuple = BinOpTuple(items[0]); break;
    case AstType.BinOpRecurse: ret.ast.binOpRecurse = BinOpRecurse(items[0]); break;
    case AstType.BinOpApply: ret.ast.binOpApply = BinOpApply(items[0]); break;
    case AstType.BinOpFunction: ret.ast.binOpFunction = BinOpFunction(items[0]); break;

    case AstType.SortDepBind: ret.ast.sortDepBind = SortDepBind(items[0], items[3]); break;

    case AstType.PattId: ret.ast.pattId = PattId(items[0], items[2]); break;
    case AstType.PattTypeless: ret.ast.pattTypeless = PattTypeless(items[0]); break;
    case AstType.PattAlternative: ret.ast.pattAlternative = PattAlternative(items[1]); break;
    case AstType.PattEquality: ret.ast.pattEquality = PattEquality(items[0], items[2]); break;
    case AstType.PattBinOp: ret.ast.pattBinOp = PattBinOp(items[0], items[1], items[2]); break;

    case AstType.FnBranchLast: ret.ast.fnBranchLast = FnBranchLast(items[0], items[2]); break;
    case AstType.FnBranch: ret.ast.fnBranch = FnBranch(items[0], items[2], items[4]); break;

    case AstType.Guard: ret.ast.guard = Guard(items[0]); break;
    case AstType.GuardAnd: ret.ast.guardAnd = GuardAnd(items[0], items[2], items[5]); break;
    }

    return ret;
}


union ParseAstData {
    ParseAst[] items;

    SortLitteral sortLitteral;
    SortLambda sortLambda;
    SortBinOp sortBinOp;
    SortDepBind sortDepBind;

    BinOpPair binOpPair;
    BinOpTuple binOpTuple;
    BinOpFunction binOpFunction;
    BinOpApply binOpApply;
    BinOpRecurse binOpRecurse;

    PattId pattId;
    PattTypeless pattTypeless;
    PattLitteral pattLitteral;
    PattAlternative pattAlternative;
    PattEquality pattEquality;
    PattBinOp pattBinOp;

    FnBranchLast fnBranchLast;
    FnBranch fnBranch;

    Guard guard;
    GuardAnd guardAnd;

    LitteralNumber litteralNumber;
    LitteralDecimal litteralDecimal;
    LitteralWord litteralWord;
    LitteralString litteralString;

    PattUnitLitteral pattUnitLitteral;
    PattUnitBounded pattUnitBounded;

    SortUnitLitteral sortUnitLitteral;
    SortUnitBounded sortUnitBounded;

    ROOT root;
    TERMINAL terminal;

}

struct SortLitteral { ParseAst value; }
struct SortLambda { ParseAst fnBranch; }
struct SortBinOp { ParseAst left; ParseAst right; ParseAst binOp; } 
struct SortDepBind { ParseAst sort; ParseAst pattern; }

struct BinOpPair { ParseAst value; }
struct BinOpTuple { ParseAst value; }
struct BinOpFunction { ParseAst value; }
struct BinOpApply { ParseAst value; }
struct BinOpRecurse { ParseAst value; }

struct PattId { ParseAst id; ParseAst type; }
struct PattTypeless { ParseAst patt; }
struct PattLitteral { ParseAst value; }
struct PattAlternative { ParseAst sort; }
struct PattEquality { ParseAst pattern; ParseAst pattern_unit; }
struct PattBinOp { ParseAst left; ParseAst right; ParseAst binOp; }

struct FnBranchLast { ParseAst guard; ParseAst sort; }
struct FnBranch { ParseAst guard; ParseAst sort; ParseAst branch; }

struct Guard { ParseAst pattern; }
struct GuardAnd { ParseAst pattern; ParseAst and_pattern; ParseAst and_sort; }

struct LitteralNumber { string value; }
struct LitteralDecimal { string whole; string decimal; }
struct LitteralWord { string value; }
struct LitteralString { string value; }

struct PattUnitLitteral { ParseAst pattern; }
struct PattUnitBounded { ParseAst pattern; }

struct SortUnitLitteral { ParseAst sort; }
struct SortUnitBounded { ParseAst sort; }

struct ROOT { ParseAst root; }
struct TERMINAL {}


void write_indent(size_t indentation) {
    foreach(_;0..indentation) write("| ");
}
void print_ast_node(ParseAst node, size_t indentation, string title) {
    write_indent(indentation);
    writeln(title);
    print_ast_node(node, indentation+1);
}

void print_ast_node(ParseAst node, size_t indentation) {

    write_indent(indentation);
    write(node.type.to!string);
    write("::");
    write(node.ast_type.to!string);
    write("\n");
    


    size_t new_indent = indentation + 1;

    if( node.ast == null ) { return; }
    final switch(node.ast_type) {
        case AstType.SortLitteral:
            print_ast_node(node.ast.sortLitteral.value, new_indent);
            break;
        case AstType.SortLambda:
            print_ast_node(node.ast.sortLambda.fnBranch, new_indent);
            break;
        case AstType.SortBinOp:
            print_ast_node(node.ast.sortBinOp.binOp, new_indent, "BinOp:");
            print_ast_node(node.ast.sortBinOp.left, new_indent, "Left:");
            print_ast_node(node.ast.sortBinOp.right, new_indent, "Right:");
            break;
        case AstType.BinOpPair:
            write_indent(new_indent);
            write("Op: Pair\n");
            break;
        case AstType.BinOpTuple:
            write_indent(new_indent);
            write("Op: Tuple\n");
            break;
        case AstType.BinOpRecurse:
            write_indent(new_indent);
            write("Op: Recurse\n");
            break;
        case AstType.BinOpApply:
            write_indent(new_indent);
            write("Op: Apply\n");
            break;
        case AstType.BinOpFunction:
            write_indent(new_indent);
            write("Op: Function\n");
            break;
        case AstType.SortDepBind:
            print_ast_node(node.ast.sortDepBind.sort, new_indent, "Sort:");
            print_ast_node(node.ast.sortDepBind.pattern, new_indent, "Pattern:");
            break;
        case AstType.PattId:
            print_ast_node(node.ast.pattId.id, new_indent, "Id:");
            print_ast_node(node.ast.pattId.type, new_indent, "Type:");
            break;
        case AstType.PattTypeless:
            print_ast_node(node.ast.pattTypeless.patt, new_indent, "Patt: ");
            break;
        case AstType.PattLitteral:
            print_ast_node(node.ast.pattLitteral.value, new_indent);
            break;
        case AstType.PattAlternative:
            print_ast_node(node.ast.pattAlternative.sort, new_indent);
            break;
        case AstType.PattEquality:
            print_ast_node(node.ast.pattEquality.pattern, new_indent, "Left:");
            print_ast_node(node.ast.pattEquality.pattern_unit, new_indent, "Right:");
            break;
        case AstType.PattBinOp:
            print_ast_node(node.ast.pattBinOp.binOp, new_indent, "BinOp:");
            print_ast_node(node.ast.pattBinOp.left, new_indent, "Left:");
            print_ast_node(node.ast.pattBinOp.right, new_indent, "Right:");
            break;
        case AstType.FnBranchLast:
            print_ast_node(node.ast.fnBranchLast.guard, new_indent, "Guard:");
            print_ast_node(node.ast.fnBranchLast.sort, new_indent, "Sort:");
            break;
        case AstType.FnBranch:
            print_ast_node(node.ast.fnBranch.guard, new_indent, "Guard:");
            print_ast_node(node.ast.fnBranch.sort, new_indent, "Sort:");
            print_ast_node(node.ast.fnBranch.branch, new_indent, "Branch:");
            break;
        case AstType.Guard:
            print_ast_node(node.ast.guard.pattern, new_indent);
            break;
        case AstType.GuardAnd:
            print_ast_node(node.ast.guardAnd.pattern, new_indent);
            print_ast_node(node.ast.guardAnd.and_pattern, new_indent);
            print_ast_node(node.ast.guardAnd.and_sort, new_indent);
            break;
        case AstType.LitteralNumber:
            write_indent(new_indent);
            write("Litteral Number : ");
            write(node.ast.litteralNumber.value);
            write("\n");
            break;
        case AstType.LitteralWord:
            write_indent(new_indent);
            write("Litteral Word : ");
            write(node.ast.litteralWord.value);
            write("\n");
            break;
        case AstType.LitteralString:
            write_indent(new_indent);
            write("Litteral String : ");
            write(node.ast.litteralString.value);
            write("\n");
            break;
        case AstType.LitteralDecimal:
            write_indent(new_indent);
            write("Litteral Decimal : ");
            write(node.ast.litteralDecimal.whole);
            write(".");
            write(node.ast.litteralDecimal.decimal);
            write("\n");
            break;
        case AstType.PattUnitLitteral:
            print_ast_node(node.ast.pattUnitLitteral.pattern, new_indent);
            break;
        case AstType.PattUnitBounded:
            print_ast_node(node.ast.pattUnitBounded.pattern, new_indent);
            break;
        case AstType.SortUnitLitteral:
            print_ast_node(node.ast.sortUnitLitteral.sort, new_indent);
            break;
        case AstType.SortUnitBounded:
            print_ast_node(node.ast.sortUnitBounded.sort, new_indent);
            break;
        case AstType.ROOT:
            print_ast_node(node.ast.root.root, new_indent);
            break;
        case AstType.TERMINAL: break;
    }
}
