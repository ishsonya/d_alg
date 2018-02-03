import std.stdio;
import std.algorithm;
import std.typecons;
import std.meta;
///
Tuple!(int, int) gcd(int a, int b) {
    // writeln(a, " ", b);
    // ka * a + kb * mod = 1;
    if (b == 0) {
        return tuple(1, 0);
    }
    int d = a % b;
    int c = a / b;
    int k1, k2;
    AliasSeq!(k1, k2) = gcd(b, d);
    return tuple(k2, (k1 - k2 * c));
}
///
struct ZMod(int mod){
    ///
    int x = 0;
    ///
    this(int a) {
        x = a % mod;
        x += mod;
        x %= mod;
    }
    ///
    typeof(this) opBinary(string op)(typeof(this) a) {
        mixin("return (this "~op~" a.x);");
    }
    ///
    typeof(this) opBinary(string op)(int a) {
        typeof(this) ans;
        static if (op == "+" || op == "-") {
            a %= mod;
            mixin("ans.x = x " ~ op ~ " a;");
            ans.x %= mod;
            ans.x += mod;
            ans.x %= mod;
        }
        else static if (op == "*") {
            a %= mod;
            const long temp = x * a;
            ans.x = temp % mod;
            ans.x += mod;
            ans.x %= mod;
        }
        else static if (op == "/") {
            int a_rev = gcd(a, mod)[0];
            a_rev %= mod;
            const long temp = x * a_rev;
            ans.x = temp % mod;
            ans.x += mod;
            ans.x %= mod;
        }
        else static assert(0, op~" is not supported for "~typeof(this));
        return ans;
    }
    ///
    void opOpAssign(string op)(typeof(this) a) {
        mixin("x "~op~"= a.x;");
    }
    ///
    void opOpAssign(string op)(int a) {
        mixin("this = this "~op~" a;");
    }
}
///
struct RootExt(Ring, int root) {
    Ring free_member;
    Ring root_member;

    typeof(this) opBinary(string op)(typeof(this) a) {
        typeof(this) ans;
        static if (op == "+" || op == "-") {
            mixin("ans.free_member = free_member "~op~" a.free_member;");
            mixin("ans.root_member = root_member "~op~" a.root_member;");
        }
        else static if (op == "*") {
            ans.free_member = root_member * a.root_member;
            ans.free_member *= root;
            ans.free_member += free_member * a.free_member;

            ans.root_member = free_member * a.root_member;
            ans.root_member += root_member * a.free_member;
        }
        else static assert(0, op~" is not supported for "~typeof(this));
        return ans;
    }

    typeof(this) opBinary(string op)(Ring a) {
        typeof(this) ans;
        mixin("ans = this "~op~" typeof(this)(a, 0);");
        return ans;
    }

    void opOpAssign(string op)(typeof(this) a) {
        mixin("this = this "~op~" a;");
    }
    ///
    void opOpAssign(string op)(Ring a) {
        mixin("this = this "~op~" a;");
    }
}
///
struct Matrix(Ring, size_t n) {
    ///
    Ring[n][n] matrix;
    ///
    typeof(this) opBinary(string op)(typeof(this) m) {
        typeof(this) ans;
        static if (op == "+" || op == "-") {
            foreach(int i; 0 .. n) {
                foreach(int j; 0 .. n) {
                    mixin("ans.matrix[i][j] = matrix[i][j] + m.matrix[i][j];");
                }
            }
        }
        else static if (op == "*") {
            foreach(int i; 0 .. n) {
                foreach(int r; 0 .. n) {
                    foreach(int j; 0 .. n) {
                        ans[i][j] += matrix[i][r] * m.matrix[r][j];
                    }
                }
            }
        }
        else static assert(0, op~" is not supported for "~typeof(this));
        return ans;
    }
    ///
    typeof(this) opBinary(string op)(Ring x) {
        typeof(this) ans;
        static if (op == "*") {
            foreach(int i; 0.. n) {
                foreach(int j; 0 .. n) {
                    ans.matrix[i][j] = matrix[i][j] * x;
                }
            }
        }
        else static assert(0, op~" is not supported for "~typeof(this));
        return ans;
    }
    ///
    void opOpAssign(string op)(typeof(this) m) {
        mixin("this = this "~op~"m;");
    }
    ///
    void opOpAssign(string op)(Ring x) {
        mixin("this = this * x;");
    }
}

Ring fast_exp(Ring)(Ring base, int pow) {
    if (pow == 1) {
        return base;
    }
    Ring ans = fast_exp(base, pow / 2);
    if (pow % 2 == 0) {
        return ans * ans;
    }
    else {
        return base * ans * ans;
    }
}

///solve
void solve() {
    auto a = RootExt!(int, -1)(2, 3);
    auto b = RootExt!(int, -1)(-1, 1);
    writeln(a + b);
    writeln(a - b);
    writeln(a * b);
    writeln(a + 3);
}
void main() {
    solve();
}
