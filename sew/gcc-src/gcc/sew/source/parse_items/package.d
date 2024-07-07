public import sort;
public import patt;
public import lex : size;

enum Tmulti { pair, extended }

struct Locus {
    size line_start;
    size column_start;
    size line_end;
    size column_end;
}
