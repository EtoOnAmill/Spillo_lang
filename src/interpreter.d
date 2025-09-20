import semantic_ast;

/*
    convert to debruijn indexes:
        > a; a <     =    > ~0 <
        > a b /; a b / <    =    > ~0 pr1! ~0 pr2! / <
        > a b c //; a c / <    =    > ~0 pr1! ~0 pr3! / <
        > a 3 c //; a c / <    =    > ~0 pr1! ~0 pr3! / <
*/



struct Binding {
    string name;
    S_Sort value;
}

struct Context {
    Binding[] hd;
    Context* tl;
}

S_Litteral index_from_int( size_t index ) {
    return S_Litteral( LitteralTag.Number
}
