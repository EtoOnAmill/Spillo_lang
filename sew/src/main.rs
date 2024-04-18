mod lexer;
mod ast;

//use ast2str::AstToStr;
use lexer::lex;
use lexer::TokenIter;
use sew::Iter;

//use crate::ast::build_ast;

fn main() {
    let pseudo_program =
    "main::{
    let`number<657.791,
    let`Fib:(Nat.Nat)<
    (>`n;
    recur with (n & Sub n 1)
        | > `acc & (`next).Succ ; Mul acc next & next),
    let`fib3 < Fib 3
    }";

    let mut token_iter = lex(pseudo_program);

    while let (Some(token), next_iter) = token_iter.next() {
        token_iter = next_iter;
        print!("{} ", token);
    }
    println!("");

    //let ast = build_ast(token_vec.as_slice()).unwrap().1;
    //println!("{}", ast.ast_to_str());
    // println!("{:#?}", ast);
}
