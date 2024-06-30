import std.stdio;
import lex;
import multi_switch;

void main()
{

    string dummy = ">aslkdi/\n)fh a sdf?;\n swoeiru fh>>sa`lkjh(?;:_  kash\ndfi/`)?; <::0'6jshdofiuweoiu\n\\987+ 65[84^)";
    auto tokenized = tokenize(dummy);
    foreach(tt ; tokenized) {
    	writeln(tt);
    }

	writeln("compiled");
}
