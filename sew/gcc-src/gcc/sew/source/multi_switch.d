import std.stdio : writeln;

struct any {}
bool is_any(any t) {return true;}
bool is_any(T)(T t) {return false;}

auto match(exprT...)(exprT ee) {
    return matchS!(ee)(false);
}

struct matchS(expr...) {
    alias exprT = typeof(expr);
    alias ms = matchS!(expr);

    bool matched = false;
    this(bool b) {this.matched = b;}

    auto to(options...)(void delegate(exprT) f){
        if (this.matched) return ms(true);

        bool matches = true;
        static foreach(i ; 0..expr.length) {
            static if (!is_any(options[i]))
                matches = matches && (expr[i] == options[i]);
        }

        if (matches) {
            f(expr);
            return ms(true);
        } else {
            return ms(false);
        }
    }
}
