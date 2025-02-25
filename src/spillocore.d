import std.stdio;
import std.file;
import lex;
import parse;

void main(){
    string source = readText("test.spll");
    Grammar!char g = new Grammar!char('S', '~');
    g.add_production('S', ['D']);
    g.add_production('S', ['a']);
    g.add_production('D', ['S','a']);

    Grammar!char.ParsingTable t = g.generate_parsing_table();
    //writeln(lex_spillo(source));
    writeln(t);

    Grammar!char gg = new Grammar!char('S', '~');
    gg.add_production('S', ['X', 'Y', 'a']);
    gg.add_production('S', ['Y', 'X', 'b']);
    gg.add_production('X', ['x']);
    gg.add_production('Y', ['x']);

    auto tt = gg.generate_parsing_table();
    writeln(tt);
}
