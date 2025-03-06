import std.stdio;
import std.file;
import lex;
import parse;

void main(){
    struct Node {
        char val;
        Node[] prod;
    }
    class Utils : GrammarT!char.ast_utils!Node {
        GrammarT!char.Grammar grammar;

        void init_grammar(GrammarT!char.Grammar g) { this.grammar = g; }

        Node from_grammar_item(char grammar_item) {
            return Node(grammar_item, []);
        }

        Node reduce(size_t prod_idx, Node[] items) {
            return Node(this.grammar.intermediates[prod_idx], items);
        }

        char to_grammar_item(Node ast) { return ast.val; }
    }

    Utils utils = new Utils();
    
    string source = readText("test.spll");
    GrammarT!char.Grammar g = GrammarT!char.Grammar('S', '~');
    g.add_production('S', ['D']);
    g.add_production('S', ['a']);
    g.add_production('D', ['S','a']);

    //auto t = GrammarT!char.generate_parsing_table(g);
    writeln(GrammarT!char.parse(g, ['a', 'a', 'a', 'a'], utils));
    //writeln(lex_spillo(source));
    //writeln(t);

    GrammarT!char.Grammar gg = GrammarT!char.Grammar('S', '~');
    gg.add_production('S', ['X', 'Y', 'a']);
    gg.add_production('S', ['Y', 'X', 'b']);
    gg.add_production('X', ['x']);
    gg.add_production('Y', ['x']);

    auto tt = GrammarT!char.generate_parsing_table(gg);
    writeln(GrammarT!char.parse(gg, cast(char[]) "xxa", utils));
    writeln();
    writeln(GrammarT!char.parse(gg, cast(char[]) "xxb", utils));
    writeln();
    writeln(GrammarT!char.parse(gg, cast(char[]) "xxx", utils));
    //writeln(tt);
    /**/


    /*
    GrammarT!char.Grammar ggg = GrammarT!char.Grammar('S', '~');
    ggg.add_production('S', ['E']);
    ggg.add_production('S', []);
    ggg.add_production('E', ['T', '+', 'E']);
    ggg.add_production('E', ['T']);
    ggg.add_production('T', ['[','E',']']);
    ggg.add_production('T', ['1']);

    //auto ttt = GrammarT!char.generate_parsing_table(ggg);
    GrammarT!char.parse(ggg, cast(char[]) "[1+1+1+1]+1+1");
    //writeln(ttt);
    */
}
