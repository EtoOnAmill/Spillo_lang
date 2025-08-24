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
        case AstType.SortUnitLitteral:
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.Litteral;
            ret.sort.litteral = convert(parse_ast.ast.sortUnitLitteral.sort).litteral;
            break;
        case AstType.SortUnitBounded:
            ret = convert(parse_ast.ast.sortUnitBounded.sort);
            break;
        case AstType.SortBinOp:
            SortBinOp sbo = parse_ast.ast.sortBinOp;
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.BinOp;
            ret.sort.bin_op.left = convert(sbo.left).sort;
            ret.sort.bin_op.right = convert(sbo.right).sort;
            ret.sort.bin_op.operator = convert(sbo.binOp).litteral.sort_bin_op;
            break;
        case AstType.SortDepBind:
            SortDepBind sdb = parse_ast.ast.sortDepBind;
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.BinOp;
            ret.sort.depBind.sort = convert(sdb.sort).sort;
            ret.sort.depBind.pattern = convert(sdb.pattern).pattern;
            break;
        case AstType.SortLambda:
            assert(0, "Lambdas not yet implemented");
            break;

        case AstType.BinOpPair:
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.BinOp;
            ret.litteral.sort_bin_op = SortBinOperator.Pair;
            break;
        case AstType.BinOpTuple:
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.BinOp;
            ret.litteral.sort_bin_op = SortBinOperator.Tuple;
            break;
        case AstType.BinOpRecurse:
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.BinOp;
            ret.litteral.sort_bin_op = SortBinOperator.Recurse;
            break;
        case AstType.BinOpApply:
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.BinOp;
            ret.litteral.sort_bin_op = SortBinOperator.Apply;
            break;
        case AstType.BinOpFunction:
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.BinOp;
            ret.litteral.sort_bin_op = SortBinOperator.Function;
            break;

        case AstType.PattLitteral:
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PattTag.Litteral;
            ret.pattern.litteral = convert(parse_ast.ast.pattLitteral.value).litteral;
            break;
        case AstType.PattUnitLitteral:
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PattTag.Litteral;
            ret.pattern.litteral = convert(parse_ast.ast.pattUnitLitteral.pattern).litteral;
            break;
        case AstType.PattUnitBounded:
            ret = convert(parse_ast.ast.pattUnitBounded.pattern);
            break;
        case AstType.PattBinOp:
            PattBinOp pbo = parse_ast.ast.pattBinOp;
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PattTag.BinOp;
            ret.pattern.bin_op = new S_PatternBinOp;
            ret.pattern.bin_op.left = convert(pbo.left).pattern;
            ret.pattern.bin_op.right = convert(pbo.right).pattern;
            ret.pattern.bin_op.operator = convert(pbo.binOp).litteral.patt_bin_op;
            break;
        case AstType.PattEquality:
            PattEquality peq = parse_ast.ast.pattEquality;
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PattTag.BinOp;
            ret.pattern.bin_op = new S_PatternBinOp;
            ret.pattern.bin_op.left = convert(peq.pattern).pattern;
            ret.pattern.bin_op.right = convert(peq.pattern_unit).pattern;
            ret.pattern.bin_op.operator = PattBinOperator.Equality;
            break;
        case AstType.PattAlternative:
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PattTag.Sort;
            ret.pattern.sort = convert(parse_ast.ast.pattAlternative.sort).sort;
            assert(0, "PattAlternative not yet implemented");
            break;
        case AstType.PattTyped:
            // all three typeless pattern variants convert to a S_Pattern with a null type, this flattens the structure 
            ret.pattern = convert(parse_ast.ast.patt.typeless).pattern;
            ret.pattern.type = new S_Sort;
            *ret.pattern.type = convert(parse_ast.ast.patt.type).sort;
            break;

        case AstType.FnBranchLast:
            assert(0, "FnBranchLast not yet implemented");
            break;
        case AstType.FnBranch:
            assert(0, "FnBranch not yet implemented");
            break;
        case AstType.Guard:
            assert(0, "Guard not yet implemented");
            break;
        case AstType.AndGuard:
            assert(0, "AndGuard not yet implemented");
            break;
        case AstType.OrGuard:
            assert(0, "OrGuard not yet implemented");
            break;
        case AstType.AndGuardEmpty:
            assert(0, "AndGuardEmpty not yet implemented");
            break;
        case AstType.OrGuardEmpty:
            assert(0, "OrGuardEmpty not yet implemented");
            break;
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
*/
enum SortTag { Litteral, BinOp, DepBind, Lambda, }
struct S_Sort {
    SortTag tag;
    union {
        S_Litteral litteral;
        S_SortBinOp *bin_op;
        S_PattSort *depBind;
        S_Lambda *lambda;
    }
    S_Sort *type;
}


/*
Patt :
    PattTyped = Typelesspatt Of Sortunit .
Typelesspatt :
    PattLitteral = Litteral ;
    PattAlternative = Alt Sortunit ;
    PattEquality = Patt Equal Pattunit ;
    PattBinOp = Patt Patt BinOp EMPTY .
*/
enum PattTag { Litteral, BinOp, Sort, }
struct S_Pattern {
    PattTag tag;
    union {
        S_Litteral litteral;
        S_PatternBinOp *bin_op;
        S_Sort sort;
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
enum LitteralTag { Word, String, Number, Decimal, BinOp }
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
        SortBinOperator sort_bin_op;
        PattBinOperator patt_bin_op;
    }
}

/*
BinOp :
    BinOpPair = Pair ;
    BinOpTuple = Tuple ;
    BinOpFunction = Function ;
    BinOpApply = Apply ;
    BinOpRecurse = Recurse .
*/
enum SortBinOperator { Pair, Tuple, Function, Apply, Recurse, }
struct S_SortBinOp {
    SortBinOperator operator;
    S_Sort left;
    S_Sort right;
}
enum PattBinOperator { Pair, Equality, }
struct S_PatternBinOp {
    PattBinOperator operator;
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




string format_semantic_ast(SemanticAst ast) {
    string ret;
    return ret;
}
string format_semantic_sort(S_Sort sort) {
    string ret;
    return ret;
}
string format_semantic_pattern(S_Pattern pattern) {
    string ret;
    final switch(pattern.tag) {

        case PattTag.Litteral:
            return format_semantic_litteral(pattern.litteral);
        case PattTag.BinOp:
            final switch(pattern.bin_op.operator) {
                case PattBinOperator.Pair:
                    ret = format_semantic_pattern(pattern.bin_op.left);
                    ret ~= ' ';
                    ret ~= format_semantic_pattern(pattern.bin_op.right);
                    ret ~= '/';
                    break;
                case PattBinOperator.Equality:
                    ret = format_semantic_pattern(pattern.bin_op.left);
                    ret ~= "=(";
                    ret ~= format_semantic_pattern(pattern.bin_op.right);
                    ret ~= ')';
                    break;
            }
            break;
        case PattTag.Sort:
            ret = "~(";
            ret ~= format_semantic_sort(pattern.sort);
            ret ~= ')';
            break;
    }
    return ret;
}
string format_semantic_litteral(S_Litteral litteral) {
    final switch(litteral.tag) {
        case LitteralTag.Word:
            return litteral.word;
        case LitteralTag.String:
            return litteral.lstring;
        case LitteralTag.Number:
            return litteral.number;
        case LitteralTag.Decimal:
            return litteral.whole ~ '.' ~  litteral.decimal;
        case LitteralTag.BinOp: assert(0, "Imposssible to print litteral binop: lacking context (pattern|sort)");
    }
}

