import lex;
import parse_items;

struct Pattern {
    Tpattern type;
    Locus position;
    union {
        string ident;
        
    }
}

enum Tpattern {
    ident,
    litteral,
    typed,
    extended,
    pair,
    pairMulti
}
