import std.stdio;
import std.traits;
import std.algorithm;
import std.array;
import std.file;
import lex;
import parse;
import parse_spillocore;

void main(){
    //writeln( GrammarTinstance.generate_parsing_table( parse_spillocore.spillocore));
    //string spillo = "a >b:B; b b / <!=:(_:(A A %)) 1 /";
    string spillo = "> 0 hd:t _:tt / /; hd \\ n:nat _:t tl:tt / /; n dec! tl / 0 ?<";
    writeln( lex.lex_spillo(spillo) );
    writeln();
    print_ast_node(
        GrammarTinstance.parse!(ParseAst)( parse_spillocore.spillocore, lex.lex_spillo(spillo), parse_spillocore.ast_u)[$-1]
        , 0)
    ;
    /*



    {
        mixin Boilerplateinator!("Test", "A", "EOF", "
            A : AA = a Y X .
            B : BB = X Y b .
            X : XB = B ;
                XY = Y Y ;
                XX = x n .

            Y : YA = A ;
                YX = X X ;
                YY = y .
        ");

        struct tree {
            GrammarItems type;
            AstType ast_type;
            tree[] items;
        }
        GrammarTinstance.Ast_utils!(tree, char) ast_u = {
            from_token : function tree(char token) {
                switch(token) {
                    case 'a': return tree(GrammarItems.a, AstType.TERMINAL, []);
                    case 'b': return tree(GrammarItems.b, AstType.TERMINAL, []);
                    case 'x': return tree(GrammarItems.x, AstType.TERMINAL, []);
                    case 'y': return tree(GrammarItems.y, AstType.TERMINAL, []);
                    default : assert(0);
                }
            },
            to_grammar_item : function GrammarItems(tree ast) { return ast.type; },
            reduce : function tree(GrammarTinstance.Grammar g, size_t prod_idx, tree[] items)  
            {
                GrammarItems intermediate = g.intermediates[prod_idx];
                AstType at = g.production_names[prod_idx];
                return tree(intermediate, at, items);
            },
        };
        writeln( GrammarTinstance.parse!(tree, char)(Test,cast(char[]) "aaxxyby", ast_u) );
    }
*/
}
