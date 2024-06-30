import lex;
import parse_items;


enum Tpattern {
    ident,
    constexpr,
    typed,
    extended,
    pair,
    pairMulti
}

struct Pattern {
    Tpattern type;
    Locus position;
    union {
        string ident;
        Sort* constexpr;
        struct {
            Pattern* patt;
            Sort* ptype;
        }
        struct {
            Pattern* whole;
            Pattern* exploded;
        }
        struct {
            Pattern* left;
            Pattern* right;
        }
        MultiPattern multiPair;
    }
}

struct MultiPattern {
    Tmulti type;
    Locus position;
    Pattern* left;
    MultiPattern* right;
}
