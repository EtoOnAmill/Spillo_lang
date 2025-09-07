import lex;
import parse_spillocore;

SemanticAst convert(ParseAst parse_ast) {
    SemanticAst ret;
    final switch(parse_ast.ast_type){

        case AstType.TERMINAL: assert(0, "Unreachable code, converting terminal simbol to SemanticAst");
        case AstType.ROOT: ret = convert(parse_ast.ast.root.root); break;

        case AstType.LitteralWord: {
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.Word;
            ret.litteral.word = parse_ast.ast.litteralWord.value;
            break; }
        case AstType.LitteralString: {
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.String;
            ret.litteral.lstring = parse_ast.ast.litteralString.value;
            break; }
        case AstType.LitteralNumber: {
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.Number;
            ret.litteral.number = parse_ast.ast.litteralNumber.value;
            break; }
        case AstType.LitteralDecimal: {
            ret.tag = AstTag.Litteral;
            ret.litteral.tag = LitteralTag.Decimal;
            ret.litteral.whole = parse_ast.ast.litteralDecimal.whole;
            ret.litteral.decimal = parse_ast.ast.litteralDecimal.decimal;
            break; }

        case AstType.SortLitteral: {
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.Litteral;
            ret.sort.litteral = convert(parse_ast.ast.sortLitteral.value).litteral;
            break; }
        case AstType.SortUnitLitteral: {
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.Litteral;
            ret.sort.litteral = convert(parse_ast.ast.sortUnitLitteral.sort).litteral;
            break; }
        case AstType.SortUnitBounded: {
            ret = convert(parse_ast.ast.sortUnitBounded.sort);
            break; }
        case AstType.SortBinOp: {
            SortBinOp sbo = parse_ast.ast.sortBinOp;
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.BinOp;
            ret.sort.bin_op = new S_SortBinOp();
            ret.sort.bin_op.left = convert(sbo.left).sort;
            ret.sort.bin_op.right = convert(sbo.right).sort;
            switch( sbo.binOp.ast_type ) {
                case AstType.BinOpPair: {
                    ret.sort.bin_op.operator = SortBinOperator.Pair;
                    break; }
                case AstType.BinOpTuple: {
                    ret.sort.bin_op.operator = SortBinOperator.Tuple;
                    break; }
                case AstType.BinOpRecurse: {
                    ret.sort.bin_op.operator = SortBinOperator.Recurse;
                    break; }
                case AstType.BinOpApply: {
                    ret.sort.bin_op.operator = SortBinOperator.Apply;
                    break; }
                case AstType.BinOpFunction: {
                    ret.sort.bin_op.operator = SortBinOperator.Function;
                    break; }
                default : assert(0,"Binop type expected");
            }
            break; }
        case AstType.SortDepBind: {
            SortDepBind sdb = parse_ast.ast.sortDepBind;
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.DepBind;
            ret.sort.dep_bind = new S_PattSort();
            ret.sort.dep_bind.sort = convert(sdb.sort).sort;
            ret.sort.dep_bind.pattern = convert(sdb.pattern).pattern;
            break; }
        case AstType.SortLambda: {
            ret.tag = AstTag.Sort;
            ret.sort.tag = SortTag.Lambda;

            S_Branch[] branches = [];

            ParseAst curr_branch = parse_ast.ast.sortLambda.fnBranch;
            while( true ) {
                S_Guard[] or_guards = [];

                ParseAstData* tmp_guard = new ParseAstData();
                tmp_guard.orGuard = OrGuard(curr_branch.ast.fnBranch.guard);
                ParseAst curr_or_ast = ParseAst(GrammarItems.Orguard, AstType.OrGuard, tmp_guard);
                while( curr_or_ast.ast_type == AstType.OrGuard ) {
                    OrGuard curr_or = curr_or_ast.ast.orGuard;
                    Guard curr_guard = curr_or.guard.ast.guard;

                    S_PattSort[] and_guards = [];

                    ParseAst curr_and_ast = curr_guard.and;
                    while ( curr_and_ast.ast_type == AstType.AndGuard ) {
                        AndGuard curr_and = curr_and_ast.ast.andGuard;

                        S_Pattern and_patt = convert(curr_and.pattern).pattern;
                        S_Sort sort = convert(curr_and.sort).sort;

                        and_guards ~= S_PattSort(and_patt, sort);

                        curr_and_ast = curr_and.and_guard;
                    }

                    S_Pattern or_patt = convert(curr_guard.pattern).pattern;

                    or_guards ~= S_Guard(or_patt, and_guards);

                    // the ParseAst OrGuard is just a semantic separation of the base case (Patt And Or) and the looping (or Patt And Or)
                    curr_or_ast = curr_guard.or;
                }

                S_Sort branch_sort = convert(curr_branch.ast.fnBranch.sort).sort;

                branches ~= S_Branch(or_guards, branch_sort);

                if ( curr_branch.ast_type == AstType.FnBranch ) {
                    curr_branch = curr_branch.ast.fnBranch.branch;
                } else { break; }
            }

            ret.sort.lambda = new S_Lambda(branches);
            break; }

        case AstType.BinOpPair:
            assert(0, "BinOpPair conversion not to be implemented");
            break;
        case AstType.BinOpTuple:
            assert(0, "BinOpTuple conversion not to be implemented");
            break;
        case AstType.BinOpRecurse:
            assert(0, "BinOpRecurse conversion not to be implemented");
            break;
        case AstType.BinOpApply:
            assert(0, "BinOpApply conversion not to be implemented");
            break;
        case AstType.BinOpFunction:
            assert(0, "BinOpFunction conversion not to be implemented");
            break;

        case AstType.PattLitteral: {
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PatternTag.Litteral;
            ret.pattern.litteral = convert(parse_ast.ast.pattLitteral.value).litteral;
            break; }
        case AstType.PattUnitLitteral: {
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PatternTag.Litteral;
            ret.pattern.litteral = convert(parse_ast.ast.pattUnitLitteral.pattern).litteral;
            break; }
        case AstType.PattUnitBounded: {
            ret = convert(parse_ast.ast.pattUnitBounded.pattern);
            break; }
        case AstType.PattBinOp: {
            PattBinOp pbo = parse_ast.ast.pattBinOp;
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PatternTag.BinOp;
            ret.pattern.bin_op = new S_PatternBinOp;
            ret.pattern.bin_op.left = convert(pbo.left).pattern;
            ret.pattern.bin_op.right = convert(pbo.right).pattern;
            switch( pbo.binOp.ast_type ) {
                case AstType.BinOpPair: {
                    ret.pattern.bin_op.operator = PattBinOperator.Pair;
                    break; }
                default : assert(0,"Binop type expected");
            }
            break; }
        case AstType.PattEquality: {
            PattEquality peq = parse_ast.ast.pattEquality;
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PatternTag.BinOp;
            ret.pattern.bin_op = new S_PatternBinOp;
            ret.pattern.bin_op.left = convert(peq.pattern).pattern;
            ret.pattern.bin_op.right = convert(peq.pattern_unit).pattern;
            ret.pattern.bin_op.operator = PattBinOperator.Equality;
            break; }
        case AstType.PattAlternative: {
            ret.tag = AstTag.Pattern;
            ret.pattern.tag = PatternTag.Sort;
            ret.pattern.sort = convert(parse_ast.ast.pattAlternative.sort).sort;
            break; }
        case AstType.PattId: {
            ret.tag = AstTag.Pattern;
            ret.pattern.litteral = convert(parse_ast.ast.pattId.id).litteral;
            ret.pattern.type = new S_Sort;
            *ret.pattern.type = convert(parse_ast.ast.pattId.type).sort;
            break; }
        case AstType.PattTypeless: {
            // all three typeless pattern variants convert to a S_Pattern with a null type, this flattens the structure 
            ret = convert(parse_ast.ast.pattTypeless.patt);
            break; }

        case AstType.FnBranchLast: {
            assert(0, "FnBranchLast conversion not to be implemented");
            break; }
        case AstType.FnBranch: {
            assert(0, "FnBranch conversion not to be implemented");
            break; }
        case AstType.Guard: {
            assert(0, "Guard conversion not to be implemented");
            break; }
        case AstType.AndGuard: {
            assert(0, "AndGuard conversion not to be implemented");
            break; }
        case AstType.OrGuard: {
            assert(0, "OrGuard conversion not to be implemented");
            break; }
        case AstType.AndGuardEmpty: {
            assert(0, "AndGuardEmpty conversion not to be implemented");
            break; }
        case AstType.OrGuardEmpty: {
            assert(0, "OrGuardEmpty conversion not to be implemented");
            break; }
    }
    return ret;
}

template fold_ast(T) {
    struct Foldr_Ast_Utils {
        T function(SortTag, T[]) fold_sort;
        T function(PatternTag, T[]) fold_pattern;
        T function(S_Litteral) fold_litteral;
        T function(T[]) fold_branch;
        T function(T[]) fold_or_guard;
        T function(T[]) fold_and_guard;
        T function(PattBinOperator) fold_patt_bin_operator;
        T function(SortBinOperator) fold_sort_bin_operator;
    }

    T foldr_ast( SemanticAst ast, Foldr_Ast_Utils fau ) {
        final switch( ast.tag ) {
            case AstTag.Sort: return foldr_sort(ast.sort, fau );
            case AstTag.Pattern: return foldr_pattern(ast.pattern, fau );
            case AstTag.Litteral: return foldr_litteral(ast.litteral, fau);
        }
    }
    T foldr_sort( S_Sort sort, Foldr_Ast_Utils fau ) {
        T[] sub_acc;
        final switch( sort.tag ) {
            case SortTag.Litteral:
                return fau.fold_litteral(sort.litteral);
            case SortTag.BinOp:
                sub_acc ~= foldr_sort(sort.bin_op.left, fau);
                sub_acc ~= foldr_sort(sort.bin_op.right, fau);
                sub_acc ~= fau.fold_sort_bin_operator(sort.bin_op.operator);
                return fau.fold_sort(sort.tag, sub_acc);
            case SortTag.DepBind:
                sub_acc ~= foldr_sort(sort.dep_bind.sort, fau);
                sub_acc ~= foldr_pattern(sort.dep_bind.pattern, fau);
                return fau.fold_sort(sort.tag, sub_acc);
            case SortTag.Lambda:
                foreach(branch; sort.lambda.branches) {
                    T[] branch_acc;
                    foreach(or_branch; branch.or_guards) {
                        T[] or_acc;
                        or_acc ~= foldr_pattern(or_branch.pattern, fau);
                        foreach(and_branch; or_branch.and_guards) {
                            T[] and_acc;
                            and_acc ~= foldr_pattern(and_branch.pattern, fau);
                            and_acc ~= foldr_sort(and_branch.sort, fau);
                            or_acc ~= fau.fold_and_guard(and_acc);
                        }
                        branch_acc ~= fau.fold_or_guard(or_acc);
                    }
                    branch_acc ~= foldr_sort(branch.sort, fau);
                    sub_acc ~= fau.fold_branch(branch_acc);
                }
                return fau.fold_sort(sort.tag, sub_acc);
        }
    }
    T foldr_pattern( S_Pattern pattern, Foldr_Ast_Utils fau ) {
        T[] sub_acc;
        final switch( pattern.tag ) {
            case PatternTag.Litteral:
                sub_acc ~= fau.fold_litteral(pattern.litteral); 
                if(pattern.type != null) {
                    sub_acc ~= foldr_sort(*pattern.type, fau);
                }
                return fau.fold_pattern(pattern.tag, sub_acc);
            case PatternTag.BinOp:
                sub_acc ~= foldr_pattern(pattern.bin_op.left, fau);
                sub_acc ~= foldr_pattern(pattern.bin_op.right, fau);
                sub_acc ~= fau.fold_patt_bin_operator(pattern.bin_op.operator);
                return fau.fold_pattern(pattern.tag, sub_acc);
            case PatternTag.Sort:
                return fau.fold_pattern(
                    pattern.tag,
                    [foldr_sort(pattern.sort, fau)] );
        }
    }
    T foldr_litteral( S_Litteral litteral, Foldr_Ast_Utils fau ) {
        return fau.fold_litteral(litteral);
    }
}


alias debug_template = fold_ast!bool;

enum AstTag : short { Sort, Pattern, Litteral, }
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
enum SortTag : short { Litteral, BinOp, DepBind, Lambda, }
struct S_Sort {
    SortTag tag;
    union {
        S_Litteral litteral;
        S_SortBinOp *bin_op;
        S_PattSort *dep_bind;
        S_Lambda *lambda;
    }
    S_Sort *type;
}


/*
Patt :
    PattTypeless = Typelesspatt : 
    PattId = WORD Of Sortunit .
Typelesspatt :
    PattLitteral = Litteral ;
    PattAlternative = Alt Sortunit ;
    PattEquality = Patt Equal Pattunit ;
    PattBinOp = Patt Patt BinOp EMPTY .
*/
enum PatternTag : short { Litteral, BinOp, Sort, }
struct S_Pattern {
    PatternTag tag;
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
enum LitteralTag : short { Word, String, Number, Decimal }
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

/*
BinOp :
    BinOpPair = Pair ;
    BinOpTuple = Tuple ;
    BinOpFunction = Function ;
    BinOpApply = Apply ;
    BinOpRecurse = Recurse .
*/
enum SortBinOperator : char {
    Pair = TokenSymbol.Pair,
    Tuple = TokenSymbol.Tuple,
    Function = TokenSymbol.Function,
    Apply = TokenSymbol.Apply,
    Recurse = TokenSymbol.Recurse, }
struct S_SortBinOp {
    SortBinOperator operator;
    S_Sort left;
    S_Sort right;
}
enum PattBinOperator : char { Pair = TokenSymbol.Pair, Equality = TokenSymbol.Eq, }
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

        case PatternTag.Litteral:
            return format_semantic_litteral(pattern.litteral);
        case PatternTag.BinOp:
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
        case PatternTag.Sort:
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
    }
}

