import std.conv;
import std.algorithm;
import std.array;
import std.stdio;
import lex;
import parse;
import parse_spillocore;
import semantic_ast;

alias to_string = fold_ast!string;

to_string.Foldr_Ast_Utils fold_utils_s = to_string.Foldr_Ast_Utils(
    &fold_sort_s,
    &fold_pattern_s,
    &fold_litteral_s,
    &fold_branch_s,
    &fold_patt_bin_operator_s,
    &fold_sort_bin_operator_s);

string fold_sort_s(SortTag tag, string[] leaf_fold) {
    final switch( tag ) {
        case SortTag.Incomplete:
            return " Sort";
        case SortTag.Litteral:
            return leaf_fold[0];
        case SortTag.BinOp:
            return leaf_fold[0] ~ " " ~ leaf_fold[1] ~  " " ~ leaf_fold[2];
        case SortTag.DepBind:
            return leaf_fold[0] ~ "::(" ~ leaf_fold[1] ~ ")";
        case SortTag.Lambda:
            return ">" ~ leaf_fold.join(" \\ ") ~ "<";
    }
}
string fold_pattern_s(PatternTag tag, string[] leaf_fold) {
    final switch ( tag ) {
        case PatternTag.Incomplete:
            return " Pattern";
        case PatternTag.Litteral:
            return leaf_fold.join(":");
        case PatternTag.BinOp:
            if( leaf_fold[2] == lex.to_string(TokenSymbol.Eq) ) {
                return leaf_fold[0] ~ TokenSymbol.Eq ~ leaf_fold[1];
            } else if ( leaf_fold[2] == lex.to_string(TokenSymbol.Pair) ) {
                return leaf_fold[0] ~ " " ~ leaf_fold[1] ~ " " ~ TokenSymbol.Pair;
            } else if ( leaf_fold[2] == "*" ) {
                return leaf_fold[0] ~ " " ~ leaf_fold[1] ~ " " ~ "*";
            } else { assert(0, "Invalid fold state"); }
        case PatternTag.Sort:
            return TokenSymbol.Alt ~ leaf_fold[0];
    }
}
string fold_litteral_s(S_Litteral litteral) {
    final switch( litteral.tag ) {
        case LitteralTag.Incomplete:
            return "Litteral";
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
string fold_branch_s(string[] leaf_fold) {
    if( leaf_fold.length == 0 ) { return "Fnbranch"; }
    return leaf_fold[0..$-1].join ~ "; " ~ leaf_fold[$-1];
}

string fold_patt_bin_operator_s(PattBinOperator op) {
    return "" ~ op;
}
string fold_sort_bin_operator_s(SortBinOperator op) {
    return "" ~ op;
}



alias to_GrammarItems = fold_ast!(GrammarItems[]);

to_GrammarItems.Foldr_Ast_Utils fold_utils_g = to_GrammarItems.Foldr_Ast_Utils(
        &fold_sort_g,
        &fold_pattern_g,
        &fold_litteral_g,
        &fold_branch_g,
        &fold_patt_bin_operator_g,
        &fold_sort_bin_operator_g);

GrammarItems[] fold_sort_g(SortTag tag, GrammarItems[][] leaf_fold) {
    final switch( tag ) {
        case SortTag.Incomplete:
            return [GrammarItems.Sort];
        case SortTag.Litteral:
            return leaf_fold[0];
        case SortTag.BinOp:
            return [leaf_fold[0], leaf_fold[1], leaf_fold[2]].join;
        case SortTag.DepBind:
            return [leaf_fold[0], [GrammarItems.Of,GrammarItems.Of,GrammarItems.Lp], leaf_fold[1], [GrammarItems.Rp]].join;
        case SortTag.Lambda:
            return [[GrammarItems.With], leaf_fold.join([GrammarItems.When]), [GrammarItems.Done]].join;
    }
}
GrammarItems[] fold_pattern_g(PatternTag tag, GrammarItems[][] leaf_fold) {
    final switch ( tag ) {
        case PatternTag.Incomplete:
            return [GrammarItems.Patt];
        case PatternTag.Litteral:
            return leaf_fold.join(GrammarItems.Of);
        case PatternTag.BinOp:
            if( leaf_fold[2][0] == GrammarItems.Equal ) {
                return [leaf_fold[0], [GrammarItems.Equal,GrammarItems.Lp], leaf_fold[1], [GrammarItems.Rp]].join;
            } else if ( leaf_fold[2][0] == GrammarItems.Pair ) {
                return [leaf_fold[0], leaf_fold[1],  [GrammarItems.Pair]].join;
            } else if ( leaf_fold[2][0] == GrammarItems.BinOp ) {
                return [leaf_fold[0], leaf_fold[1],  [GrammarItems.BinOp]].join;
            } else { assert(0, "Invalid fold state"); }
        case PatternTag.Sort:
            return [[GrammarItems.Alt], leaf_fold[0]].join;
    }
}
GrammarItems[] fold_litteral_g(S_Litteral litteral) {
    final switch( litteral.tag ) {
        case LitteralTag.Incomplete:
            return [GrammarItems.Litteral];
        case LitteralTag.Word:
            return [GrammarItems.WORD];
        case LitteralTag.String:
            return [GrammarItems.STR];
        case LitteralTag.Number:
            return [GrammarItems.NUM];
        case LitteralTag.Decimal :
            return [GrammarItems.NUM, GrammarItems.Dot, GrammarItems.NUM];
    }
}
GrammarItems[] fold_branch_g(GrammarItems[][] leaf_fold) {
    if(leaf_fold.length == 0) return [GrammarItems.Fnbranch];
    if(leaf_fold.length > 3)
        return [leaf_fold[0], [GrammarItems.And], leaf_fold[1], [GrammarItems.Of, GrammarItems.Equal], leaf_fold[2], [GrammarItems.Do], leaf_fold[$-1]].join;
    else
        return [leaf_fold[0], [GrammarItems.Do], leaf_fold[$-1]].join;
}


GrammarItems[] fold_patt_bin_operator_g(PattBinOperator op) {
    final switch (op) {
        case PattBinOperator.PatternBinOp:
            return [GrammarItems.BinOp];
        case PattBinOperator.Pair:
            return [GrammarItems.Pair];
        case PattBinOperator.Eq:
            return [GrammarItems.Equal];
    }
}
GrammarItems[] fold_sort_bin_operator_g(SortBinOperator op) {
    final switch (op) {
        case SortBinOperator.SortBinOp:
            return [GrammarItems.BinOp];
        case SortBinOperator.Pair:
            return [GrammarItems.Pair];
        case SortBinOperator.Tuple:
            return [GrammarItems.Tuple];
        case SortBinOperator.Function:
            return [GrammarItems.Function];
        case SortBinOperator.Apply:
            return [GrammarItems.Apply];
        case SortBinOperator.Recurse:
            return [GrammarItems.Recurse];
    }
}

GrammarTinstance.Ast_utils!(ParseAst, GrammarItems) u = {
    from_token : function ParseAst(GrammarItems i) {
        return ParseAst(i, AstType.TERMINAL, null);
    },
    to_grammar_item : function GrammarItems(ParseAst ast) { return ast.type; },
    reduce : &parse_spillocore.reduce,

};



void main() {
    string spillo = "> 0 hd:t _:tt / /; hd \\ n:nat _:t tl:tt / /; n dec! tl / 0 ?<";
    ParseAst ast = GrammarTinstance.parse!(ParseAst)(
        parse_spillocore.spillocore,
        lex.lex_spillo(spillo),
        parse_spillocore.ast_u)[$-1];
    print_ast_node( ast, 0 );

    SemanticAst sem_ast = convert(ast);

    writeln( to_string.foldr_ast(sem_ast, fold_utils_s) );

    foreach(depth; 0..10) {
        GrammarItems[] generated = parse_spillocore.spillocore.generate_string(depth, GrammarItems.Sort) ~ GrammarItems.EOF;
        ParseAst parsed = GrammarTinstance.parse!(ParseAst)(
            parse_spillocore.spillocore,
            generated,
            u )[$-1];
        SemanticAst converted = convert(parsed);
        GrammarItems[] folded = to_GrammarItems.foldr_ast(converted, fold_utils_g);

        GrammarItems[] ed = generated
        .filter!(e => e != GrammarItems.EMPTY)
        .map!(function(e){
            switch(e) {
                case GrammarItems.Typelesspatt:
                    return [GrammarItems.Patt];
                case GrammarItems.Sortunit:
                    return [GrammarItems.Lp, GrammarItems.Sort, GrammarItems.Rp];
                case GrammarItems.Pattunit:
                    return [GrammarItems.Lp, GrammarItems.Patt, GrammarItems.Rp];
                default: return [e];
            }
        })
        .join;

        writeln();
        writeln( generated );
        writeln(to_string.foldr_ast(converted, fold_utils_s));
        writeln( folded );
        writeln( ed );
        writeln( loose_cmp(ed, folded));
        print_ast_node( parsed, 0 );
        writeln();
    }
    GrammarItems[] test = [GrammarItems.With, GrammarItems.Typelesspatt, GrammarItems.And, GrammarItems.Typelesspatt, GrammarItems.Of, GrammarItems.Equal, GrammarItems.Sort, GrammarItems.Sort, GrammarItems.BinOp, GrammarItems.EMPTY, GrammarItems.Do, GrammarItems.With, GrammarItems.Guard, GrammarItems.Do, GrammarItems.Sort, GrammarItems.Done, GrammarItems.Done, GrammarItems.With, GrammarItems.WORD, GrammarItems.Of, GrammarItems.Sortunit, GrammarItems.Do, GrammarItems.Litteral, GrammarItems.With, GrammarItems.Fnbranch, GrammarItems.Done, GrammarItems.Recurse, GrammarItems.EMPTY, GrammarItems.When, GrammarItems.Patt, GrammarItems.And, GrammarItems.Patt, GrammarItems.Of, GrammarItems.Equal, GrammarItems.Sort, GrammarItems.Do, GrammarItems.Sort, GrammarItems.Of, GrammarItems.Of, GrammarItems.Pattunit, GrammarItems.Done, GrammarItems.Recurse, GrammarItems.EMPTY, GrammarItems.EOF];
        writeln( test );
    ParseAst parsed = GrammarTinstance.parse!(ParseAst)(
        parse_spillocore.spillocore,
        test,
        u )[$-1];
    SemanticAst converted = convert(parsed);
    GrammarItems[] folded = to_GrammarItems.foldr_ast(converted, fold_utils_g);
    writeln( folded );
    print_ast_node( parsed, 0 );
    writeln();
}

bool loose_cmp(GrammarItems[] a, GrammarItems[] b) {
    size_t a_i = 0;
    size_t b_i = 0;
    while( a_i < a.length && b_i < b.length ) {
        if(a[a_i] == b[b_i]){
            a_i++;
            b_i++;
            continue;
        }

        if(a[a_i] == GrammarItems.Lp && b[b_i] != GrammarItems.Lp) {
            a_i++;
            continue;
        }
        if(a[a_i] == GrammarItems.Rp && b[b_i] != GrammarItems.Rp) {
            a_i++;
            continue;
        }
        if(b[b_i] == GrammarItems.Lp && a[a_i] != GrammarItems.Lp) {
            b_i++;
            continue;
        }
        if(b[b_i] == GrammarItems.Rp && a[a_i] != GrammarItems.Rp) {
            b_i++;
            continue;
        }

        if(a[a_i] == GrammarItems.Guard && b[b_i] == GrammarItems.Patt) {
            a_i++;
            b_i++;
            continue;
        }

        return false;
    }
    return true;
}
