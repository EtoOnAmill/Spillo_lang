//mod ast;
mod lexer;

//use ast2str::AstToStr;
use lexer::lex;

//use crate::ast::build_ast;

fn main() {
    let pseudo_program = 
    "main::{
    recur`fib:(Nat -> Nat)<>
    (>`n >>
    recur with (n & Sub n 1)
        | > (`acc, (`next).Succ) >> (Mul acc next & next))";
    let token_vec = lex(pseudo_program);

    println!("{:?}", token_vec);
    for token in &token_vec {
        print!("{} ", token);
    }
    println!("");

    //let ast = build_ast(token_vec.as_slice()).unwrap().1;
    //println!("{}", ast.ast_to_str());
    // println!("{:#?}", ast);
}
