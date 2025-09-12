import std.string;
import std.algorithm;
import std.stdio;
import std.array;

enum TokenSymbol : char {
    Function = '^',
    Apply = '!',
    Recurse = '?',
    Tuple = '%',
    Pair = '/',

    Lbr = '{',
    Rbr = '}',
    Lsq= '[',
    Rsq= ']',
    Lp= '(',
    Rp= ')',
    With = '>',
    Done = '<',
    String = '`',
    Comment = '#',

    And = '&',
    Or = '|',
    Do = ';',
    When = '\\',

    Eq = '=',
    Of = ':',
    Alt = '~',

}
string to_string(TokenSymbol ts) {
    return "" ~ ts;
}

const char[] whitespace = [' ', '\t', '\n', '\v', '\r'];
const char[] binOps = ['^', '!', '%', '/', '?'];
const char[] delimeters = ['{', '}', '[', ']', '(', ')', '>', '<', '`', '#'];
const char[] functions = ['&', '|', ';', '\\'];
const char[] other = ['=', ':', '~'];
const char[] reserved = whitespace ~ binOps ~ delimeters ~ functions ~ other;

enum TokenType {
    EOF = 0,
    WORD,
    STRING,
    NUMBER,
    RESERVED,
    IGNORE,
}

struct Position {
    size_t line = 1;
    size_t column = 1;

    this(size_t line, size_t column) {
        this.line=line;
        this.column=column;
    }
}

struct Token {
    TokenType tt;
    Position pos;
    string value;

    this(Position pos) {
        this.pos = pos;
    }

    Position set_position(Position pos) {
        this.pos = pos;
        return this.new_position();
    }

    size_t offset() {
        if(this.tt == TokenType.STRING) {
            return this.value.length + 2;
        }
        return this.value.length;
    }

    Position new_position() {
        string[] lines = splitter(this.value,"\n").array;
        lines.length ? (lines=lines) : (lines=[""]);
        string lastLine = lines[$-1];
        size_t newLine = this.pos.line + lines.length - 1; // -1 in case of no split

        size_t columnOffset = newLine==this.pos.line ? this.pos.column : 1;
        size_t newColumn = columnOffset + lastLine.length;
        size_t delimeterOffset = {
            switch ( this.tt ) {
                case TokenType.STRING:
                    if(lines.length > 1){
                        return 1;
                    } else {
                        return 2;
                    }
                default:
                    return 0;
            }
        }();

        return Position(newLine, newColumn + delimeterOffset);
    }
}

Token[] lex_spillo(string input) {
    Token[] ret;
    Position position;

    size_t idx = 0;
    while( idx < input.length ) {
        Token lexed = lex_one(input[idx..$]);

        position = lexed.set_position(position);

        if( lexed.tt != TokenType.IGNORE ){
            ret ~= lexed;
            writeln(lexed);
        }

        if( binOps.canFind(lexed.value) ) {
            Token empty = Token(lexed.pos);
            empty.tt = TokenType.RESERVED;
            ret ~= empty;
        }

        idx += lexed.offset();
    }

    Token eof = Token();
    eof.tt = TokenType.EOF;
    return ret ~ eof;
}


Token lex_one(string input) {
    Token ret;

    switch(char first = input[0]){
        case '0': .. case '9':
            bool is_number(char c) { return '0' <= c && c <= '9'; }
            ret.tt = TokenType.NUMBER;
            ret.value = take_while(&is_number, input).idup;
            break;

        case '`':
            bool isnt_backtick(char c) { return c != '`'; }
            ret.tt = TokenType.STRING;
            ret.value = take_while(&isnt_backtick, input[1..$]).idup; // we skip the first character that is a backtic
            break;

        case '#':
            bool isnt_octothorp(char c) { return c != '#'; }
            ret.tt = TokenType.IGNORE;
            ret.value = ("#" ~ take_while(&isnt_octothorp, input[1..$]) ~ "#" ).idup;
            break;

        default:
            if( whitespace.canFind(first) ){
                ret.tt = TokenType.IGNORE;
                ret.value = [first];
                break;
            }

            if( reserved.canFind(first) ){
                ret.tt = TokenType.RESERVED;
                ret.value = [first];
                break;
            }

            bool isnt_reserved(char c) { return ! reserved.canFind(c); }
            ret.tt = TokenType.WORD;
            ret.value = take_while!(char)(&isnt_reserved, input).idup;

            break;
        }
    return ret;
}

T[] take_while(T)(bool delegate(T) f, immutable(T)[] arr) {
    size_t idx;
    T[] ret;

    for(idx = 0; idx < arr.length; idx++) {
        if (f(arr[idx])) {
            ret ~= arr[idx];
        } else {
            break;
        }
    }

    return ret;
}
