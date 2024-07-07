import parse_items;

enum Tmulti { pair, extended }

struct Ident {
    string name;
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
