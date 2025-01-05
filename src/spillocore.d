import std.stdio;
import std.file;
import lex;

void main(){

    string source = readText("test.spll");
    writeln(lex_spillo(source));
}
