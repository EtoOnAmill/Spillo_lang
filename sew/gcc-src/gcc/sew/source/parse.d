import parse_items;
import lex;



ParseItem[] parse(Token[] input) {
    return null;
}

struct ParseItem {
    PItype type;
    Locus location;
    union {
        Ident ident;
        Sort sort;
        FnBranch fnBranch;
        Guard guard;
        Pattern patt;
        MultiSort multiSort;
        MultiPattern multiPattern;
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
