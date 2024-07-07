import parse_items;
import lex;

ParseItem[] parse(Token[] input) {
    ParseItem[] ret = convert(input);

    return ret;
}

ParseItem[] convert(Token[] input) {
    ParseItem[] ret = [];

    ParseItem to_append;
    foreach(token; input) {

        Locus locus = {
            column_end : token.column_end,
            column_start : token.column_start,
            line_end : token.line_end,
            line_start : token.line_start,
        };
        to_append.position = locus;
        final switch(token.ttype) {
            case Ttype.litStr:
                to_append.type = PItype.sort;
                to_append.sort.type = Tsort.strLitteral;
                to_append.sort.strLitteral = token.value;
                break;
            case Ttype.number:
                to_append.type = PItype.sort;
                to_append.sort.type = Tsort.numLitteral;
                to_append.sort.numLitteral = token.value;
                break;
            case Ttype.word:
                to_append.type = PItype.ident;
                to_append.ident = token.value;
                break;
            case Ttype.reserved:
                to_append.type = PItype.terminal;
                to_append.terminal = token.value;
                break;
        }
        ret ~= to_append;
    }

    return ret;
}

struct ParseItem {
    PItype type;
    Locus position;
    union {
        string terminal;
        string ident;
        Sort sort;
        FnBranch fnBranch;
        Guard guard;
        Pattern patt;
        MultiSort multiSort;
        MultiPattern multiPattern;
    }
}

enum PItype {
    terminal,
    ident,
    sort,
    fnBranch,
    guard,
    patt,
    multiSort,
    multiPatt,
}
