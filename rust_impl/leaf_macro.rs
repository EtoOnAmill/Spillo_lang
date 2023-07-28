macro_rules! leaf{
    {$($toparse:tt),*;} => {
        {
            $(leaf![$toparse])*
        }
    };
    [$($param:ident)+ $func:ident] => {
        $func($($param)+);
    };
    [$var_name:ident = $type:ty : $value: expr] => {
        let $var_name: $type = $value;
    };
    [$var_name:ident : $value: expr] => {
        let $var_name = $value;
    };
}

fn main() {
    leaf!{
        a : 4
        ,b : 3
        ,a b +;
    };
}
