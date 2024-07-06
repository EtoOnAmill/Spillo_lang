import multi_switch;

alias size = size_t;


Token[] tokenize(string input) {
    Token[] ret;
    
    size line_start = 1;
    size column_start = 1;
    size line_end = 1;
    size column_end = 1;

    string token;

    void whitespace_logic(char curr_char) {
        if (curr_char == '\n'){
            column_start = 1;
            column_end = 1;

            line_start += 1;
            line_end += 1;
        } else {
            column_end += 1;
            column_start = column_end;

//            import std.stdio : writeln;
//            writeln("igonoring : ", curr_char, " -- c/l=(", column_start, ",", column_end, ")(", line_start, ",", line_end, ")");
        }
    }
    auto extendToken = (char c) {
//        import std.stdio : writeln;
//        writeln("extending : ", token, " ", c, " -- c/l=(", column_start, ",", column_end, ")(", line_start, ",", line_end, ")");
        token ~= c;

        if (c == '\n') {
            column_end = 1;
            line_end += 1;
        } else {
            column_end += 1;
        }
    };
    void pushToTokenList () {
        if(token.length == 0) { return; }
//        import std.stdio : writeln;
//        writeln("pushing : ", token, " -- c/l=(", column_start, ",", column_end, ")(", line_start, ",", line_end, ")");

        Token newToken = {
            column_start : column_start,
            column_end : column_end,
            line_start : line_start,
            line_end : line_end,
            value : token,
            ttype : identify(token[0]),
        };

        column_start = column_end;
        line_start = line_end;

        ret ~= newToken;

        token = "";
    }
    auto push_multichar_reserved = (string _, char c) {
        extendToken(c);
        pushToTokenList();
    };

    if (input.length == 0) { return ret; }

    foreach(char curr_char; input){

        import std.stdio : writeln;
        writeln("current token " ~ token ~ " and current char " ~ curr_char);

        if(token.length == 0) {
            if(char_type(curr_char) != ChrType.white_s) {
                column_start = column_end;
                extendToken(curr_char);
            } else {
//                import std.stdio : writeln;
//                writeln("igonoring : ", curr_char, " -- c/l=(", column_start, ",", column_end, ")(", line_start, ",", line_end, ")");
                whitespace_logic(curr_char);
            }
            continue;
        }

       
        Ttype token_type = identify(token[0]);
        ChrType curr_char_type = char_type(curr_char);


        match(token_type, curr_char_type)
        .to!(Ttype.litStr, ChrType.strDelimiter) ((tt,ct) {
            extendToken(curr_char);
            pushToTokenList();
        })
        .to!(any(), ChrType.strDelimiter) ((tt,ct) {
            pushToTokenList();
            extendToken(curr_char);
        })
        .to!(Ttype.litStr, any()) ((tt,ct) {
            extendToken(curr_char);
        })
        .to!(any(), ChrType.white_s) ((tt,ct) {
            pushToTokenList();
            whitespace_logic(curr_char);
        })
    // if tok is numb, if char is numb extendToken else pushToTokenList
        .to!(Ttype.number, ChrType.number) ((tt,ct) {
            extendToken(curr_char);
        })
        .to!(Ttype.number, any()) ((tt,ct) {
            pushToTokenList();
            extendToken(curr_char);
        })
    // if tok is litteral, check if char can forms multi_char litteral 
        .to!(Ttype.reserved, any()) ((tt,ct) {
            match(token, curr_char)
            .to!(">", '>') (push_multichar_reserved)
            .to!(":", ':') (push_multichar_reserved)
            .to!("/", ')') (push_multichar_reserved)
            .to!("%", ')') (push_multichar_reserved)
            .to!("^", ')') (push_multichar_reserved)
            .to!("!", ')') (push_multichar_reserved)
            .to!(any(), any()) ((_,c) {
                pushToTokenList();
                extendToken(curr_char);
            });
        })
    // if tok is word, if char is reserved or whitespace pushToTokenList else extendToken
        .to!(Ttype.word, ChrType.reserved) ((tt,ct) {
             pushToTokenList();
             extendToken(curr_char);
        })
        .to!(Ttype.word, ChrType.white_s) ((tt,ct) {
             pushToTokenList();
             extendToken(curr_char);
        })
        .to!(Ttype.word, any()) ((tt,ct) {
            extendToken(curr_char);
        }) ;

    }

    pushToTokenList();

    return join_multi_char_reserved(ret);
}

Token[] join_multi_char_reserved(Token[] tokens) {
    Token[] ret;

    int i;
    for(i = 0; i + 1 < tokens.length; i++){
        Token curr_token = tokens[i];
        Token next_token = tokens[i + 1];
        string curr = curr_token.value;
        string next = next_token.value;

        Token newToken = curr_token;

        switch(curr){
            case ">":
            case ":":
                if(next == curr){
                    newToken.value = curr ~ next;
                    newToken.column_end = next_token.column_end;
                    newToken.line_end = next_token.line_end;
                    i += 1;
                }
                ret ~= newToken;
                break;
            case "/":
            case "%":
            case "^":
            case "!":
                if(next == ")"){
                    newToken.value = curr ~ next;
                    newToken.column_end = next_token.column_end;
                    newToken.line_end = next_token.line_end;
                    i += 1;
                }
                ret ~= newToken;
                break;
            default:
                ret ~= newToken;
                break;
        }
    }
    return ret;
}



struct Token {
    Ttype ttype;
    string value;

    size line_start;
    size column_start;
    size line_end;
    size column_end;
}

enum Ttype {
    reserved,
    word,
    number,
    litStr,
}

enum ChrType {
    reserved,
    word,
    number,
    strDelimiter,
    white_s
}

static assert(cast(ChrType) Ttype.number == ChrType.number);
static assert(cast(ChrType) Ttype.word == ChrType.word);
static assert(cast(ChrType) Ttype.reserved == ChrType.reserved);

ChrType char_type(char cc) {
    switch (cc) {
        case ' ': case '\t': case '\n': return ChrType.white_s;
        case '`': return ChrType.strDelimiter;
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
            return Ttype.reserved;
        case '`':
            return Ttype.litStr;
        default:
            return Ttype.word;
    }
}
