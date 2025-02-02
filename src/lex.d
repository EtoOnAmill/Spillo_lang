import std.string;
import std.algorithm;
import std.stdio;
import std.array;

const char[] whitespace = [' ', '\t', '\n', '\v', '\r'];
const char[] binOps = ['^', '!', '%', '/'];
const char[] delimeters = ['{', '}', '[', ']', '(', ')', '>', '<', '`', '#'];
const char[] functions = ['?', '&', '|', ';', '\\'];
const char[] other = ['=', ':', '~'];
const char[] reserved = whitespace ~ binOps ~ delimeters ~ functions ~ other;

extern(C) enum TokenType {
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
        if(tt == TokenType.STRING) {
            return value.length + 2;
        }
        return value.length;
    }

    Position new_position() {
        string[] lines = splitter(value,"\n").array;
        lines.length ? (lines=lines) : (lines=[""]);
        string lastLine = lines[$-1];
        size_t newLine = pos.line + lines.length - 1; // -1 in case of no split

        size_t columnOffset = newLine==pos.line ? pos.column : 1;
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

        idx += lexed.offset();
    }

    return ret;
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



/* bison */

Token[] yylex_tokens;
size_t yylex_idx = 0;

void yylex_init(string input) {
    yylex_tokens = lex_spillo(input);
    yylex_idx = 0;
}

extern(C) int yylex() {
    Token current_token = yylex_tokens[yylex_idx];
    int ret;

    final switch (current_token.tt) {
        case TokenType.WORD:
            ret = TokenType.WORD;
            break;
        case TokenType.STRING:
            ret = TokenType.STRING;
            break;
        case TokenType.NUMBER:
            ret = TokenType.NUMBER;
            break;
        case TokenType.RESERVED:
            ret = current_token.value[0];
            break;
        case TokenType.IGNORE:
            yylex_idx += 1;
            ret = yylex();
            break;
        case TokenType.EOF:
            ret = 0;
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
