import lex;



ParseItem[] parse(Token[] input) {
    return null;
}

struct ParseItem {
    Stype type;
    union {
    }
}

enum Stype {
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
