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
    `number<657.791,
    `Fib:(Nat.Nat)<
    (>`n;
    recur with (n & Sub n 1)
        | > `acc & (`next).Succ ; Mul acc next & next),
    `fib3< Fib 3
    }";

    let token_vec = lex(pseudo_program);
    let mut token_iter = TokenIter::new(pseudo_program);

    /*
    for token in &token_vec {
        println!("{:?}", token);
    }
    */
    for token in &token_vec {
        print!("{} ", token);
    }
    println!("");
    while let (Some(token), next_iter) = token_iter.next() {
        token_iter = next_iter;
        print!("{} ", token);
    }
    println!("");

    //let ast = build_ast(token_vec.as_slice()).unwrap().1;
    //println!("{}", ast.ast_to_str());
    // println!("{:#?}", ast);
}
