import std.stdio;
import std.file;
import lex;
import parse;

void main(){
    string source = readText("test.spll");
    GrammarT!char.Grammar g = GrammarT!char.Grammar('S', '~');
    g.add_production('S', ['D']);
    g.add_production('S', ['a']);
    g.add_production('D', ['S','a']);

    auto t = GrammarT!char.generate_parsing_table(g);
    //writeln(lex_spillo(source));
    writeln(t);

    GrammarT!char.Grammar gg = GrammarT!char.Grammar('S', '~');
    gg.add_production('S', ['X', 'Y', 'a']);
    gg.add_production('S', ['Y', 'X', 'b']);
    gg.add_production('X', ['x']);
    gg.add_production('Y', ['x']);

    auto tt = GrammarT!char.generate_parsing_table(gg);
    writeln(tt);


    GrammarT!char.Grammar ggg = GrammarT!char.Grammar('S', '~');
    ggg.add_production('S', ['E']);
    ggg.add_production('S', []);
    ggg.add_production('E', ['T', '+', 'E']);
    ggg.add_production('E', ['T']);
    ggg.add_production('T', ['[','E',']']);
    ggg.add_production('T', ['1']);

    auto ttt = GrammarT!char.generate_parsing_table(ggg);
    writeln(ttt);
}
