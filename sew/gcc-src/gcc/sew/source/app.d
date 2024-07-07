import std.stdio;
import lex;
import parse;
import multi_switch;

void main()
{

//    string dummy = ">aslkdi/\n)fh a sdf?;\n swoeiru fh>>sa`lkjh(?;:_  kash\ndfi/`)?; <::0'6jshdofiuweoiu\n\\987+ 65[84^)";
    string dummy = "(> a; > b ; b a /)";
    auto tokenized = tokenize(dummy);
    auto converted = convert(tokenized); 
    foreach(tt ; tokenized) {
        writeln(tt);
    }
    foreach(pi ; converted) {
    	write(pi.type);
    	write(" ");
    	writeln(pi.position);
    }

	writeln("compiled");
}
