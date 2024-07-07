import parse_items;


enum Tsort {
    ident,
    strLitteral,
    numLitteral,
    numDecimals,

    // <bin_op>
    pairType,
    pairLitteral,
    application,
    fnType,

    fnLitteral,

    // ( <mutlisort> <bin_op> )
    pairTypeMulti,
    fnTypeMulti,
    pairLitteralMulti,
    applicationMulti,

    dependentFunctionType,
    dependentPairType,

    // <sort> :: <patt>
    inlineDeclaration
}

struct Sort {
    Tsort type;
    union {
        string ident;
        string strLitteral;
        string numLitteral;
        // all binary operator in a "( <multisort> <bin_op>)" situation
        MultiSort multiSort;
        // function declaration
        FnBranch fnLitteral;
        // all binary operators
        struct {
            Sort* left;
            Sort* right;
        }
        // dependent types
        struct {
            Sort* dLeft;
            Pattern* dIdent;
            Sort* dRight;
        }
        // sort :: patt
        struct {
            Sort* sValue;
            Pattern* pAlias;
        }
        // number decimals
        struct {
            string whole;
            string decimal;
        }
    }
}


struct MultiSort {
    Tmulti type;
    Locus position;
    Sort* left;
    MultiSort* right;
}

enum Tguard { and, or }
struct Guard {
    Tguard type;
    union {
        struct And {
            Pattern patt;
            Sort sort;
            Guard* next;
        }
        struct Or {
            Pattern patt;
            Sort sort;
        }
    }
}

enum TfnBranch {
    required, // `>`
    extended, // `>`
    extendedIterate, // `>>`
}
struct FnBranch {
    TfnBranch type;
    union {
        struct Required {
            Pattern patt;
            Guard guard;
            Sort sort;
        }
        struct Extended {
            Pattern patt;
            Guard guard;
            Sort sort;
            FnBranch* next;
        }
        struct ExtendedIterate {
            Pattern patt;
            Guard guard;
            Sort sort;
            FnBranch* next;
        }
    }
}
