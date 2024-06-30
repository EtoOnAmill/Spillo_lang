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
        string ident;
        MultiSort multiSort;
        FnBranch fnLitteral;
        struct {
            Sort* left;
            Sort* right;
        }
        struct {
            Sort* dLeft;
            Pattern* dIdent;
            Sort* dRight;
        }
        struct {
            Sort* sValue;
            Pattern* pAlias;
        }
    }
}

enum Tsort {
    ident,
    litteral,

    fnType,
    pairType,
    pairLitteral,

    fnLitteral,
    application,

    pairTypeMulti,
    fnTypeMulti,
    pairLitteralMulti,
    applicationMulti,

    dependentFunctionType,
    dependentPairType,

    inlineDeclaration
}
