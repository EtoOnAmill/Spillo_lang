import parse_items;

struct MultiSort {
    Tmulti type;
    Locus position;
    Sort* left;
    MultiSort* right;
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
