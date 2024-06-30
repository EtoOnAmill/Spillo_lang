import parse_items;
import lex;



ParseItem[] parse(Token[] input) {
    return null;
}

struct ParseItem {
    PItype type;
    Locus location;
    union {
    }
}

enum PItype {
    litteral,
    number,
    ident,
    sort,
    fnBranch,
    guard,
    patt,
    multiSort,
    multiPatt,
}
