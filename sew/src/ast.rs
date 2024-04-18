use sew::Iter;
use crate::lexer::{ Token, TokenIter, Number };

type Context = Vec<Declaration>;

struct Declaration {
	binder: Patt,
	value: Sort,
}
enum Patt {
    CatchAll,
    Type {
        name: String,
        index: usize,
    },
    Constant(Box<Sort>),
    Ident(String),
    PattType {
        patt: Box<Patt>,
        type_: Box<Patt>,
    },
    WholeParts {
        whole: Box<Patt>,
        parts: Box<Patt>
    },
    Pair(Vec<Patt>),
    Inductive{
        param: Box<Patt>,
        function: Box<Patt>
    }
}
enum Sort {
    Const{
        value:Token,
    },
    Function{
        param: Patt,
        body: Box<Sort>
    },
    Application{
        func: Box<Sort>,
        param: Box<Sort>,
    },
    Pair(Vec<Sort>),
    Declaration(Box<Declaration>),
    With {
        match_expr: Option<Box<Sort>>,
        arms: Vec<Branch>,
    },
    RecurWith {
        match_expr: Option<Box<Sort>>,
        arms: Vec<Branch>,
    },
    Unit(usize),
}

struct Branch {
    matcher: Option<Patt>,
    guards: Vec<Declaration>,
    value: Box<Sort>,
}

fn build (tokens:TokenIter) -> Context {
	todo!()
}
