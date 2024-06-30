import parse_items;

struct MultiSort {
    Tmulti type;
    Locus position;
    Sort* left;
    MultiSort* right;
}

struct Sort {
    Tsort type;
    Locus position;
    union {

    }
}

enum Tsort {
    ident,
    litteral,

    fnType,
    fnTypeMulti,
    fnLitteral,

    pairType,
    pairTypeMulti,
    pairLitteral,
    pairLitteralMulti,

    application,
    applicationMulti,

    dependentFunctionType,
    dependentPairType,

    inlineDeclaration
}
