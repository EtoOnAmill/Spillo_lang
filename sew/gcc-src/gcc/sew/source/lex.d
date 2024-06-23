import multi_switch;

alias size = size_t;

Token[] tokenize(string input) {
    Token[] ret;
    
    size line = 0;
    size column = 0;

    string token;

    auto extendToken = (char c) {token ~= c;};
    void pushToTokenList (string value, size column_start, size line) {
        if(token.length == 0) { return; }
// (TODO) make it so it counts fucking graphemes instead of bytes
        column += token.length;

        Token newToken = {
            column_start : column_start,
            line : line,
            value : value,
            ttype : identify(value[0]),
        };

        token = "";

        ret ~= newToken;
    }
    auto push_multichar_reserved = (string _, char c) {
        extendToken(c);
        pushToTokenList(token, column, line);
    };

    if (input.length == 0) { return ret; }

    foreach( char curr_char; input){

        if(token.length == 0) {
            if(char_type(curr_char) != ChrType.white_s) 
                extendToken(curr_char);
            continue;
        }
        
        Ttype token_type = identify(token[0]);
        ChrType curr_char_type = char_type(curr_char);


        match(token_type, curr_char_type)
        .to!(any(), ChrType.white_s) ((tt,ct) {
            pushToTokenList(token, column, line);

            if(curr_char == '\n') {
                column = 0;
                line += 1;
            } else {
                column += 1;
            }
        })
    // if tok is numb, if char is numb extendToken else pushToTokenList
        .to!(Ttype.number, ChrType.number) ((tt,ct) { extendToken(curr_char); })
        .to!(Ttype.number, any()) ((tt,ct) {
            pushToTokenList(token,column,line);
            extendToken(curr_char);
        })
    // if tok is litteral, check if char can forms multi_char litteral 
        .to!(Ttype.litteral, any()) ((tt,ct) {
            match(token, curr_char)
            .to!(">", '>') (push_multichar_reserved)
            .to!(":", ':') (push_multichar_reserved)
            .to!("/", ')') (push_multichar_reserved)
            .to!("%", ')') (push_multichar_reserved)
            .to!("^", ')') (push_multichar_reserved)
            .to!("!", ')') (push_multichar_reserved)
            .to!(any(), any()) ((_,c) {
                pushToTokenList(token, column, line);
                extendToken(c);
            });
        })
    // if tok is word, if char is reserved or whitespace pushToTokenList else extendToken
        .to!(Ttype.word, ChrType.reserved) ((tt,ct) {
             pushToTokenList(token, column, line);
             extendToken(curr_char);
        })
        .to!(Ttype.word, any()) ((tt,ct) { extendToken(curr_char); })
        ;
    }

    pushToTokenList(token, column, line);

    return ret;
}

struct Token {
    Ttype ttype;
    string value;

    size line;
    size column_start;
    size column_end() => column_start + value.length;
}

enum Ttype {
    litteral,
    word,
    number,
}

enum ChrType {
    reserved,
    word,
    number,
    white_s
}

static assert(cast(ChrType) Ttype.number == ChrType.number);
static assert(cast(ChrType) Ttype.word == ChrType.word);
static assert(cast(ChrType) Ttype.litteral== ChrType.reserved);

ChrType char_type(char cc) {
    switch (cc) {
        case ' ': case '\t': case '\n': return ChrType.white_s;
        default: return cast(ChrType) identify(cc);
    }
}

Ttype identify(char string_start){
    switch(string_start){
        case '0': .. case '9':
            return Ttype.number;
        case '(':
        case ')':
        case '.':
        case ':':
        case '@':
        case '!':
        case ';':
        case '>':
        case '^':
        case '%':
        case '/':
        case '=':
        case '&':
        case '|':
        case '~':
            return Ttype.litteral;
        default:
            return Ttype.word;
    }
}
