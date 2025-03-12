import std.stdio;
import std.algorithm;
import std.array;
import std.file;
import lex;
import parse;
import parse_spillocore;

void main(){
    writeln(
        GrammarT!(parse_spillocore.GrammarItems).generate_parsing_table(
            parse_spillocore.spillocore));
}
