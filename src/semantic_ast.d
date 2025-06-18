import parse_spillocore;

SemanticAst convert(ParseAst parse_ast) {
    SemanticAst ret;
    final switch(parse_ast.ast_type){

        case AstType.TERMINAL: assert(0, "Unreachable code, converting terminal simbol to SemanticAst");
        case AstType.ROOT: ret = convert(parse_ast.ast.root.root); break;

        case AstType.LitteralWord:
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.Word;
            ret.litteral.word = parse_ast.ast.litteralWord.value;
            break;
        case AstType.LitteralString:
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.String;
            ret.litteral.lstring = parse_ast.ast.litteralString.value;
            break;
        case AstType.LitteralNumber:
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.Number;
            ret.litteral.number = parse_ast.ast.litteralNumber.value;
            break;
        case AstType.LitteralDecimal:
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.Decimal;
            ret.litteral.whole = parse_ast.ast.litteralDecimal.whole;
            ret.litteral.decimal = parse_ast.ast.litteralDecimal.decimal;
            break;

        case AstType.SortLitteral:
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.Litteral;
            ret.sort.litteral = convert(parse_ast.ast.sortLitteral.value).litteral;
            break;
        case AstType.SortUnitLitteral: break;
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.Litteral;
            ret.sort.litteral = convert(parse_ast.ast.sortUnitLitteral.sort).litteral;
            break;
        case AstType.SortUnitBounded: break;
            ret = convert(parse_ast.ast.sortUnitBounded.sort);
            break;
        case AstType.SortLambda: break;
        case AstType.SortBinOp: break;
        case AstType.SortDepBind: break;
        case AstType.SortDepDecl: break;

        case AstType.BinOpPair: break;
        case AstType.BinOpTuple: break;
        case AstType.BinOpRecurse: break;
        case AstType.BinOpApply: break;
        case AstType.BinOpFunction: break;

        case AstType.PattLitteral:
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PatternTag.Litteral;
            ret.pattern.litteral = convert(parse_ast.ast.pattLitteral.value).litteral;
            break;
        case AstType.PattUnitLitteral: break;
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PatternTag.Litteral;
            ret.pattern.litteral = convert(parse_ast.ast.pattUnitLitteral.pattern).litteral;
            break;
        case AstType.PattUnitBounded: break;
            ret = convert(parse_ast.ast.pattUnitBounded.pattern);
            break;
        case AstType.PattTyped: break;
        case AstType.PattTypeless: break;
        case AstType.PattAlternative: break;
        case AstType.PattEquality: break;
        case AstType.PattBinOp: break;

        case AstType.FnBranchLast: break;
        case AstType.FnBranch: break;
        case AstType.Guard: break;
        case AstType.AndGuard: break;
        case AstType.OrGuard: break;
        case AstType.AndGuardEmpty: break;
        case AstType.OrGuardEmpty: break;
    }
    return ret;
}



enum AstTag { Sort, Pattern, Litteral, }
struct SemanticAst {
    AstTag tag;
    union {
        S_Sort sort;
        S_Pattern pattern;
        S_Litteral litteral;
    }
}



/*
Sort :
    SortLitteral = Litteral ;
    SortBinOp = Sort Sort BinOp EMPTY ;
    SortLambda = With Fnbranch Done ;
    SortDepBind = Sort Of Of Pattunit ;
    SortDepDecl = Sort Equal Of Pattunit .
*/
enum SortTag { Litteral, BinOp, DepBind, DepDecl, Lambda, }
struct S_Sort {
    SortTag tag;
    union {
        S_Litteral litteral;
        S_SortBinOp *binOp;
        S_PattSort *depBind;
        S_PattSort *depDecl;
        S_Lambda *lambda;
    }
    S_Sort *type;
}



/*
BinOp :
    BinOpPair = Pair ;
    BinOpTuple = Tuple ;
    BinOpFunction = Function ;
    BinOpApply = Apply ;
    BinOpRecurse = Recurse .
*/
enum SortBinOpOperator { Pair, Tuple, Function, Apply, Recurse, }
struct S_SortBinOp {
    SortBinOpOperator operator;
    S_Sort left;
    S_Sort right;
}
enum PatternBinOperator { Pair, Equality, }
struct S_PatternBinOp {
    PatternBinOperator tag;
    S_Pattern left;
    S_Pattern right;
}



/*
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
*/
struct S_Lambda {
    S_Branch[] branches;
}
struct S_Branch {
    S_Guard[] or_guards;
    S_Sort sort;
}
struct S_Guard {
    S_Pattern pattern;
    S_PattSort[] and_guards;
}



struct S_PattSort {
    S_Pattern pattern;
    S_Sort sort;
}



/*
Patt :
    PattTypeless = Typelesspatt ;
    PattTyped = Typelesspatt Of Sortunit .
Typelesspatt :
    PattLitteral = Litteral ;
    PattAlternative = Alt Sortunit ;
    PattEquality = Patt Equal Pattunit ;
    PattBinOp = Patt Patt BinOp EMPTY .
*/
enum PatternTag { Litteral, BinOp, Sort, }
struct S_Pattern {
    PatternTag tag;
    union {
        S_Litteral litteral;
        S_PatternBinOp *binOp;
        S_Sort alt_pattern;
    }
    S_Sort *type;
}



/*
Litteral : 
    LitteralNumber = NUM ;
    LitteralDecimal = NUM Dot NUM ;
    LitteralWord = WORD ;
    LitteralString = STR .
*/
enum LitteralTag { Word, String, Number, Decimal, }
struct S_Litteral {
    LitteralTag tag;
    union {
        string word;
        string lstring;
        string number;
        struct {
            string whole;
            string decimal;
        } 
    }
}
