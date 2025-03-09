import std.stdio;
import std.algorithm;
import std.array;
import std.file;
import lex;
import parse;

void main(){
    struct Node {
        char val;
        Node[] prod;
    };
    alias BuilderType = GrammarT!char.ast_utils!(Node, char);
    BuilderType ast_u = {

        from_token: function(char grammar_item){ return Node(grammar_item, []); },

        reduce: function(GrammarT!char.Grammar grammar, size_t prod_idx, Node[] items) {
            return Node(grammar.intermediates[prod_idx], items);
        },

        to_grammar_item: function(Node ast) { return ast.val; },
        to_token: function(Node ast) { return ast.val; }
    };
    GrammarT!char.token_utils!char token_u = {
        to_grammar_item: function(char item) { return item; },
        from_grammar_item: function(char item) { return item; },
    };

   
    string source = readText("test.spll");
    GrammarT!char.Grammar g = GrammarT!char.Grammar('S', '~');
    g.add_production('S', ['D']);
    g.add_production('S', ['a']);
    g.add_production('D', ['S','a']);

    //auto t = GrammarT!char.generate_parsing_table(g);
    writeln(GrammarT!char.parse!(Node,char)(g, ['a', 'a', 'a'], ast_u, token_u));
    //writeln(lex_spillo(source));
    //writeln(t);

    GrammarT!char.Grammar gg = GrammarT!char.Grammar('S', '~');
    gg.add_production('S', ['X', 'Y', 'a']);
    gg.add_production('S', ['Y', 'X', 'b']);
    gg.add_production('X', ['x']);
    gg.add_production('Y', ['x']);

    //auto tt = GrammarT!char.generate_parsing_table(gg);
    struct AChar { char val; }
    GrammarT!char.token_utils!AChar a_char_utils = {
        to_grammar_item: function(AChar item) { return item.val; },
        from_grammar_item: function(char item) { return AChar(item); },
    };

    GrammarT!char.ast_utils!(Node, AChar) a_char_ast = {

        from_token: function(AChar token){ return Node(token.val, []); },

        reduce: function(GrammarT!char.Grammar grammar, size_t prod_idx, Node[] items) {
            return Node(grammar.intermediates[prod_idx], items);
        },

        to_grammar_item: function(Node ast) { return ast.val; },
        to_token: function(Node ast) { return AChar(ast.val); }
    };
    writeln(GrammarT!char.parse!(Node,char)(gg, cast(char[]) "xxa", ast_u, token_u));
    writeln();
    writeln(GrammarT!char.parse!(Node,AChar)(gg, [AChar('x'), AChar('x'), AChar('b')], a_char_ast, a_char_utils));
    writeln();
    writeln(GrammarT!char.parse!(Node,char)(gg, cast(char[]) "xxx", ast_u, token_u));
    //writeln(tt);
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
