import std.stdio;
import std.traits;
import std.algorithm;
import std.array;
import std.file;
import lex;
import parse;
import parse_spillocore;

void main(){
    alias Grammar = GrammarT!(parse_spillocore.GrammarItems);
    writeln( Grammar.generate_parsing_table( parse_spillocore.spillocore));
    string spillo = "a >b:B; b b / <!=:(_:(A A %)) 1 /";
    writeln( lex.lex_spillo(spillo) );
    writeln();
    writeln( Grammar.parse!(AstNode)( parse_spillocore.spillocore, lex.lex_spillo(spillo), parse_spillocore.ast_u));
}
