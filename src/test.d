import std.conv;
import std.array;
import std.stdio;
import lex;
import parse;
import parse_spillocore;
import semantic_ast;

alias to_string = fold_ast!string;

to_string.Foldr_Ast_Utils fold_utils = to_string.Foldr_Ast_Utils(
    &fold_sort,
    &fold_pattern,
    &fold_litteral,
    &fold_branch,
    &fold_or_guard,
    &fold_and_guard,
    &fold_patt_bin_operator,
    &fold_sort_bin_operator);


string fold_sort(SortTag tag, string[] leaf_fold) {
    final switch( tag ) {
        case SortTag.Litteral:
            return leaf_fold[0];
        case SortTag.BinOp:
            return leaf_fold[0] ~ " " ~ leaf_fold[1] ~  " " ~ leaf_fold[2];
        case SortTag.DepBind:
            return leaf_fold[0] ~ "::(" ~ leaf_fold[1] ~ ")";
        case SortTag.Lambda:
            return ">" ~ leaf_fold.join(" \\ ") ~ " <";
    }
}
string fold_pattern(PatternTag tag, string[] leaf_fold) {
    final switch ( tag ) {
        case PatternTag.Litteral:
            return leaf_fold.join(":");
        case PatternTag.BinOp:
            if( leaf_fold[2] == lex.to_string(TokenSymbol.Eq) ) {
                return leaf_fold[0] ~ TokenSymbol.Eq ~ leaf_fold[1];
            } else if ( leaf_fold[2] == lex.to_string(TokenSymbol.Pair) ) {
                return leaf_fold[0] ~ " " ~ leaf_fold[1] ~ " " ~ TokenSymbol.Pair;
            } else { assert(0, "Invalid fold state"); }
        case PatternTag.Sort:
            return TokenSymbol.Alt ~ leaf_fold[0];
    }
}
string fold_litteral(S_Litteral litteral) {
    final switch( litteral.tag ) {
        case LitteralTag.Word:
            return litteral.word;
        case LitteralTag.String:
            return "`" ~ litteral.lstring ~ "`";
        case LitteralTag.Number:
            return litteral.number;
        case LitteralTag.Decimal :
            return litteral.whole ~ "." ~ litteral.decimal;
    }
}
string fold_branch(string[] leaf_fold) {
    return leaf_fold[0..$-1].join() ~ "; " ~ leaf_fold[$-1];
}
string fold_or_guard(string[] leaf_fold) {
    return " | " ~ leaf_fold.join();
}
string fold_and_guard(string[] leaf_fold) {
    return " & " ~ leaf_fold[0] ~ "=" ~ leaf_fold[1];
}

string fold_patt_bin_operator(PattBinOperator op) {
    return "" ~ op;
}
string fold_sort_bin_operator(SortBinOperator op) {
    return "" ~ op;
}

void main() {
    string spillo = "> 0 hd:t _:tt / /; hd \\ n:nat _:t tl:tt / /; n dec! tl / 0 ?<";
    ParseAst ast = GrammarTinstance.parse!(ParseAst)(
        parse_spillocore.spillocore,
        lex.lex_spillo(spillo),
        parse_spillocore.ast_u)[$-1];
    print_ast_node( ast, 0 );

    SemanticAst sem_ast = convert(ast);

    writeln( to_string.foldr_ast(sem_ast, fold_utils) ); 
}
