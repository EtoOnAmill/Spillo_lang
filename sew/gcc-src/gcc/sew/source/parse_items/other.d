import parse_items;

enum Tmulti { pair, extended }

struct Ident {
    Locus position;
    string name;
}


struct Number {
    Locus position;
    string whole;
    string decimal;
}

enum Tlitteral { number, sstring }
struct Litteral {
    Tlitteral type;
    Locus position;
    union {
        Number number;
        string sstring;
    }
}


enum Tguard { and, or }
struct Guard {
    Tguard type;
    Locus position;
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
    Locus position;
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
