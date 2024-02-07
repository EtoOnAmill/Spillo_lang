use core::fmt;
use sew::CharIter;
use sew::Iter;
use sew::Position;

type TokenGroup<'a> = (Token, CharIter<'a>, Position);

#[derive(Debug)]
pub enum Token {
    Word(String, Position),
    Number(Number, Position ),
    Symbol(Symbol, Position),
    Keyword(Keyword, Position),
    Illegal(String, Position),
    EOF,
}

impl Token {
    pub fn to_string(&self) -> String {
        match self {
            Token::Word(w,_) => w.clone(),
            Token::Number(Number{int,dec}, .. ) => format!("{}.{}", int, dec),
            Token::Symbol(s,_) => s.to_string(),
            Token::Keyword(k,_) => k.to_string(),
            Token::Illegal(i,_) => i.clone(),
            Token::EOF => "\n".to_owned()
        }
    }
}
impl fmt::Display for Token {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f,"{}", self.to_string())
    }
}

#[derive(Clone)]
pub struct TokenIter<'a> {
    source: CharIter<'a>,
    cursor: Position,
}
impl<'a> TokenIter<'a> {
    pub fn new(s:&'a str) -> Self {
        Self {
            source: CharIter::new(s),
            cursor: Position{ line:0, column: 0 }
        }
    }
    fn from(source:CharIter<'a>, cursor: Position) -> Self {
        Self {
            source,
            cursor
        }
    }
}
impl Iter for TokenIter<'_> {
    type Val = Token;
    fn next(&self) -> (Option<<Self as Iter>::Val>, Self) {
        let mut cursor = self.cursor.clone();
        
        let (Some(chr), mut next_iter) = self.source.next() else { return (None, self.clone()); };

        if chr.is_alphabetic() || chr == '_' {
            let token;
            (token, next_iter, cursor) = tokenize_word(self.source.clone(), cursor);
            (Some(token), TokenIter::from(next_iter, cursor))
        } else if chr.is_numeric() {
            let token;
            (token, next_iter, cursor) = tokenize_number(self.source.clone(), cursor);
            (Some(token), TokenIter::from(next_iter, cursor))
        } else if !chr.is_whitespace() {
            let token;
            (token, next_iter, cursor) = tokenize_symbol(self.source.clone(), cursor);
            (Some(token), TokenIter::from(next_iter, cursor))
        } else {
            if chr == '\n' {
                cursor = Position {
                    line: cursor.line + 1,
                    column: 0
                }
            }
            TokenIter::from(next_iter, cursor).next()
        }
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
    ret.push(Token::EOF);

    ret
}

fn tokenize_number<'a>(i: CharIter<'a>, cursor: Position) -> TokenGroup<'a> {
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

        (Token::Number( Number{int, dec}, cursor ), rest, new_cursor)
    } else {
        (Token::Number( Number{int, dec: 0}, cursor), iter, new_cursor)
    }
}

#[derive(Debug)]
pub struct Number {
    int: usize,
    dec: usize,
}

#[derive(Debug)]
pub enum Symbol {
    Semicolon,  // ;
    Colon,      // :
    DubleColon, // ::
    RightDecl,    // >
    SelfRef,    // <>
    LeftDecl,       // <
    PipeInto,     // >.
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
    Pipe, // |
    Dot, // .
    Backtick, // `
    DepPair, // ^^
    DepFunc, // ||
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
            Symbol::PipeInto => ">.".to_owned(),
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
            Symbol::Pipe => "|".to_owned(),
            Symbol::Dot => ".".to_owned(),
            Symbol::Backtick => "`".to_owned(),
            Symbol::Type => "*".to_owned(),
            Symbol::SetOfAll => "#".to_owned(),
            Symbol::DepPair => "^^".to_owned(), // ^^
            Symbol::DepFunc => "||".to_owned(), // ||
        }
    }
}

pub fn tokenize_symbol<'a>(i: CharIter<'a>, cursor: Position) -> TokenGroup<'a> {
    let (vec, iter) = i.take_until(|c| c.is_whitespace());
    let adv = cursor.advance(1);

    match vec[0..] {
        ['|', ..] => (Token::Symbol(Symbol::Pipe, cursor), i.skip(1), adv),
        ['>', '.', ..] => (Token::Symbol(Symbol::PipeInto, cursor), i.skip(2), adv.advance(1)),
        [';', ..] => (Token::Symbol(Symbol::Semicolon, cursor), i.skip(1), adv),
        [',', ..] => (Token::Symbol(Symbol::Comma, cursor), i.skip(1), adv),
        [':', ':', ..] => (Token::Symbol(Symbol::DubleColon, cursor), i.skip(2), adv.advance(1)),
        ['|', '|', ..] => (Token::Symbol(Symbol::DepFunc, cursor), i.skip(2), adv.advance(1)),
        ['^', '^', ..] => (Token::Symbol(Symbol::DepPair, cursor), i.skip(2), adv.advance(1)),
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
        [] => panic!("Expected symbol found nothing at {:?}", cursor)
    }
}

#[derive(Debug)]
pub enum Keyword {
    Let,
    Mut,
    Recur,
    Inf,
    With,
    Where
}

impl Keyword {
    pub fn to_string(&self) -> String {
        match self {
            Keyword::Let => "let".to_owned(),
            Keyword::Mut => "mut".to_owned(),
            Keyword::Recur => "recur".to_owned(),
            Keyword::Inf => "inf".to_owned(),
            Keyword::With => "with".to_owned(),
            Keyword::Where => "where".to_owned(),
        }
    }
}
pub fn tokenize_word<'a>(i: CharIter<'a>, cursor:Position) -> TokenGroup<'a> {
    let (vec, iter) = i.take_while(|c| c.is_alphanumeric() || *c == '_');
    let new_cursor = cursor.advance(vec.len());
    let word: String = vec.into_iter().collect();

    match word.as_str() {
        "let" => (Token::Keyword(Keyword::Let, cursor), iter, new_cursor),
        "mut" => (Token::Keyword(Keyword::Mut, cursor), iter, new_cursor),
        "recur" => (Token::Keyword(Keyword::Recur, cursor), iter, new_cursor),
        "inf" => (Token::Keyword(Keyword::Inf, cursor), iter, new_cursor),
        "with" => (Token::Keyword(Keyword::With, cursor), iter, new_cursor),
        "where" => (Token::Keyword(Keyword::Where, cursor), iter, new_cursor),
        _ => (Token::Word(word, cursor), iter, new_cursor),
    }
}
