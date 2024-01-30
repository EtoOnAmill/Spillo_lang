
#[derive(Debug)]
pub struct Position {
    pub line:usize,
    pub column:usize,
}
impl Position {
    pub fn advance(&self, amount:usize) -> Position {
        Position {
            line: self.line,
            column: self.column + amount,
        }
    }
}

pub trait Iter:Sized + Clone {
    type Val: Sized;

    fn next(&self) -> (Option<Self::Val>, Self)
    where
        Self: Sized;

    fn nth(&self, n: usize) -> (Option<Self::Val>, Self) {
        let mut new_iter = self.clone();
        let mut val = None;

        for _ in 0..n {
            (val, new_iter) = new_iter.next();
        }

        (val, new_iter)
    }

    fn skip(&self, n: usize) -> Self {
        self.nth(n).1
    }

    fn peek(&self, n: usize) -> Option<Self::Val> {
        self.nth(n).0
    }

    fn take_n(&self, n: usize) -> (Vec<Self::Val>, Self) {
        let mut ret = Vec::with_capacity(n);
        let mut next_iter = self.clone();

        for _ in 0..n {
            if let (Some(chr), next_i) = next_iter.next() {
                ret.push(chr);
                next_iter = next_i;
            } else {
                break;
            }
        }

        (ret, next_iter)
    }

    fn take_until(&self, f: impl Fn(&Self::Val) -> bool) -> (Vec<Self::Val>, Self) {
        let mut ret = Vec::new();

        let mut next_iter = self.clone();

        while let (Some(val), iter) = next_iter.next() {
            if f(&val) {
                break;
            }

            next_iter = iter;
            ret.push(val);
        }

        (ret, next_iter)
    }

    fn take_while(&self, f: impl Fn(&Self::Val) -> bool) -> (Vec<Self::Val>, Self) {
        let mut ret = Vec::new();

        let mut next_iter = self.clone();

        while let (Some(val), iter) = next_iter.next() {
            if !f(&val) {
                break;
            }

            next_iter = iter;
            ret.push(val);
        }

        (ret, next_iter)
    }
}



#[derive(Clone)]
pub struct CharIter<'a> {
    b: &'a str,
}

impl<'a> Iter for CharIter<'a> {
    type Val = char;

    fn next(&self) -> (Option<Self::Val>, Self) {
        let mut new_idx = if self.b.len() != 0 {
            1
        } else {
            return (None, self.clone());
        };

        while !self.b.is_char_boundary(new_idx) {
            new_idx += 1;
        }

        let chr = self.b[0..new_idx].parse::<char>().ok();

        (
            chr,
            CharIter {
                b: &self.b[new_idx..],
            },
        )
    }
}

impl<'a> CharIter<'a> {
    pub fn new(s: &'a str) -> CharIter<'a> {
        CharIter { b: s }
    }
}
