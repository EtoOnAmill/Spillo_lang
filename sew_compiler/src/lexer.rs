use core::fmt;
use sew::CharIter;
use sew::Iter;
use sew::Position;

type TokenGroup<'a> = (Token, CharIter<'a>, Position);

#[derive(Debug)]
pub enum Token {
    Word(String, Position),
    Number{ int: usize, dec: usize, pos:Position },
    Symbol(Symbol, Position),
    Keyword(Keyword, Position),
    Illegal(String, Position),
}

impl Token {
    pub fn to_string(&self) -> String {
        match self {
            Token::Word(w,_) => w.clone(),
            Token::Number { int, dec, .. } => format!("{}.{}", int, dec),
            Token::Symbol(s,_) => s.to_string(),
            Token::Keyword(k,_) => k.to_string(),
            Token::Illegal(i,_) => i.clone(),
        }
    }
}
impl fmt::Display for Token {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f,"{}", self.to_string())
    }
}

pub fn lex(s: &str) -> Vec<Token> {
    let mut ret = Vec::new();
    let mut i = CharIter::new(s);
    let mut cursor = Position { line: 0, column: 0 };

    while let (Some(chr), iter) = i.next() {
        if chr.is_alphabetic() {
            let token;
            (token, i, cursor) = tokenize_word(i, cursor);
            ret.push(token);
        } else if chr.is_numeric() {
            let token;
            (token, i, cursor) = tokenize_number(i, cursor);
            ret.push(token);
        } else if !chr.is_whitespace() {
            let token;
            (token, i, cursor) = tokenize_symbol(i, cursor);
            ret.push(token);
        } else {
            if chr == '\n' {
                cursor = Position {
                    line: cursor.line + 1,
                    column: 0
                }
            }
            i = iter;
        }
    }

    ret
}

fn tokenize_number(i: CharIter, cursor: Position) -> TokenGroup {
    let (vec, iter) = i.take_while(|e| e.is_numeric());
    let new_cursor = cursor.advance(vec.len());
    let int = vec
        .into_iter()
        .collect::<String>()
        .parse()
        .expect("Error while parsing number");

    if let (Some('.'), decimals) = iter.next() {
        let (vec, rest) = decimals.take_while(|e| e.is_numeric());
        let dec: usize = vec
            .into_iter()
            .collect::<String>()
            .parse()
            .expect("Error while parsing decimal digits");

        (Token::Number { int, dec, pos: cursor }, rest, new_cursor)
    } else {
        (Token::Number { int, dec: 0, pos: cursor }, iter, new_cursor)
    }
}

#[derive(Debug)]
pub enum Symbol {
    Semicolon,  // ;
    Colon,      // :
    DubleColon, // ::
    RightDecl,    // >
    SelfRef,    // <>
    LeftDecl,       // <
    Return,     // >>
    OpenCurly,  // {
    CloseCurly, // }
    OpenBrakets, // [
    ClosedBrakets, // ]
    OpenParen, // (
    ClosedParen, // )
    Escape,     // \
    Comma, // ,
    Ampersand, // &
    Type, // *
    SetOfAll, // #
    Percent, // %
    Arrow, // ->
    Dot, // .
    Backtick // `
}

impl Symbol {
    pub fn to_string(&self) -> String {
        match self {
            Symbol::Semicolon => ";".to_owned(),
            Symbol::Colon => ":".to_owned(),
            Symbol::DubleColon => "::".to_owned(),
            Symbol::LeftDecl => "<".to_owned(),
            Symbol::SelfRef => "<>".to_owned(),
            Symbol::RightDecl => ">".to_owned(),
            Symbol::Return => ">>".to_owned(),
            Symbol::OpenCurly => "{".to_owned(),
            Symbol::CloseCurly => "}".to_owned(),
            Symbol::OpenBrakets => "[".to_owned(),
            Symbol::ClosedBrakets => "]".to_owned(),
            Symbol::OpenParen => "(".to_owned(),
            Symbol::ClosedParen => ")".to_owned(),
            Symbol::Escape => "\\".to_owned(),
            Symbol::Comma => ",".to_owned(),
            Symbol::Ampersand => "&".to_owned(),
            Symbol::Percent => "%".to_owned(),
            Symbol::Arrow => "->".to_owned(),
            Symbol::Dot => ".".to_owned(),
            Symbol::Backtick => "`".to_owned(),
            Symbol::Type => "*".to_owned(),
            Symbol::SetOfAll => "#".to_owned(),
        }
    }
}

pub fn tokenize_symbol(i: CharIter, cursor: Position) -> TokenGroup {
    let (vec, iter) = i.take_until(|c| c.is_whitespace());
    let adv = cursor.advance(1);

    match vec[0..] {
        ['-', '>', ..] => (Token::Symbol(Symbol::Arrow, cursor), i.skip(2), adv.advance(1)),
        ['>', '>', ..] => (Token::Symbol(Symbol::Return, cursor), i.skip(2), adv.advance(1)),
        [';', ..] => (Token::Symbol(Symbol::Semicolon, cursor), i.skip(1), adv),
        [',', ..] => (Token::Symbol(Symbol::Comma, cursor), i.skip(1), adv),
        [':', ':', ..] => (Token::Symbol(Symbol::DubleColon, cursor), i.skip(2), adv.advance(1)),
        [':', ..] => (Token::Symbol(Symbol::Colon, cursor), i.skip(1), adv),
        ['.', ..] => (Token::Symbol(Symbol::Dot, cursor), i.skip(1), adv),
        ['`', ..] => (Token::Symbol(Symbol::Backtick, cursor), i.skip(1), adv),
        ['&', ..] => (Token::Symbol(Symbol::Ampersand, cursor), i.skip(1), adv),
        ['{', ..] => (Token::Symbol(Symbol::OpenCurly, cursor), i.skip(1), adv),
        ['}', ..] => (Token::Symbol(Symbol::CloseCurly, cursor), i.skip(1), adv),
        ['[', ..] => (Token::Symbol(Symbol::OpenBrakets, cursor), i.skip(1), adv),
        [']', ..] => (Token::Symbol(Symbol::ClosedBrakets, cursor), i.skip(1), adv),
        ['(', ..] => (Token::Symbol(Symbol::OpenParen, cursor), i.skip(1), adv),
        [')', ..] => (Token::Symbol(Symbol::ClosedParen, cursor), i.skip(1), adv),
        ['\\', ..] => (Token::Symbol(Symbol::Escape, cursor), i.skip(1), adv),
        ['#', ..] => (Token::Symbol(Symbol::SetOfAll, cursor), i.skip(1), adv),
        ['*', ..] => (Token::Symbol(Symbol::Type, cursor), i.skip(1), adv),
        ['%', ..] => (Token::Symbol(Symbol::Percent, cursor), i.skip(1), adv),
        ['>', ..] => (Token::Symbol(Symbol::RightDecl, cursor), i.skip(1), adv),
        ['<', '>', ..] => (Token::Symbol(Symbol::SelfRef, cursor), i.skip(2), adv.advance(1)),
        ['<', ..] => (Token::Symbol(Symbol::LeftDecl, cursor), i.skip(1), adv),
        [i, ..] => (Token::Illegal(i.to_string(), cursor), iter, adv),
        [] => panic!("Expected symbol found nothing")
    }
}

#[derive(Debug)]
pub enum Keyword {
    Let,
    Recur,
    Inf,
    With,
    Where
}

impl Keyword {
    pub fn to_string(&self) -> String {
        match self {
            Keyword::Let => "let".to_owned(),
            Keyword::Recur => "recur".to_owned(),
            Keyword::Inf => "inf".to_owned(),
            Keyword::With => "with".to_owned(),
            Keyword::Where => "where".to_owned(),
        }
    }
}
pub fn tokenize_word(i: CharIter, cursor:Position) -> TokenGroup {
    let (vec, iter) = i.take_while(|c| c.is_alphabetic() || *c == '_');
    let new_cursor = cursor.advance(vec.len());
    let word: String = vec.into_iter().collect();

    match word.as_str() {
        "let" => (Token::Keyword(Keyword::Let, cursor), iter, new_cursor),
        "recur" => (Token::Keyword(Keyword::Recur, cursor), iter, new_cursor),
        "inf" => (Token::Keyword(Keyword::Inf, cursor), iter, new_cursor),
        "with" => (Token::Keyword(Keyword::With, cursor), iter, new_cursor),
        "where" => (Token::Keyword(Keyword::Where, cursor), iter, new_cursor),
        _ => (Token::Word(word, cursor), iter, new_cursor),
    }
}
