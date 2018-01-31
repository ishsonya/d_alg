import std.stdio;
import std.algorithm;
import std.random;


/*
1) Stat in root is alwaus correct
2) Methods are a monoid(group withoit reversed) acts on value,
    stats as described in their classes.
*/

///
const uint MY_RAND_MAX = 1 << 31;

/// stats dummy
struct MyStatType {
    ///
    int a;
    /// neutral constructor
    this(int v) {
        a = v;
    }
    /// accept methods
    void accept_method(ref MyMethodType method) {
        // Method_type monoid acts on stat_type as a trasformation
        // (map from stat_type into stat_type)
        // stats.accept(method) is:
        // 1) make a transformation from method
        // 2) apply this transformation to stat
        // in "stat.value += methods.to_add" transformation is (+= methods.to_add)
        a += method.to_add;
    }

    /// accept stats
    void accept_stats(ref MyStatType stats) {
        a = min(a, stats.a);
    }
}

///methods dummy
struct MyMethodType {
    ///
    int to_add;
    /// neutral constructor
    /// accept methods
    void accept_method(ref MyMethodType method) {
        // actually is composition of methods ( *= in methods monoid)
        to_add += method.to_add;
        method.to_add = 0;
    }
    // /// accept_value
    // void accept_value(ref ValueType value) {
    //     value += to_add;
    // }
    // ///accept stats
    // void accept_stats(ref StatType stats) {
    //     stats.a += to_add;
    // }
}

///decart tree, heap-tree, cartesian tree
// class InnerTreap(KeyType, ValueType, MethodType, StatType) {
struct InnerTreap(alias UltimateStruct) {
    alias KeyType = typeof(UltimateStruct.KeyType);
    alias ValueType = typeof(UltimateStruct.ValueType);
    alias StatType = typeof(UltimateStruct.StatType);
    alias MethodType = typeof(UltimateStruct.MethodType);
    ////
    InnerTreap!(UltimateStruct)* left;
    ////
    InnerTreap!(UltimateStruct)* right;
    ////
    KeyType key_tree;
    ////
    const int key_heap;
    ////
    ValueType value;
    ///stats
    StatType stats;
    /// methods
    MethodType methods;
    ///init
    this(KeyType key_tree_, ValueType value_) {
        left = null;
        right = null;
        value = value_;
        key_tree = key_tree_;
        key_heap = uniform(0, MY_RAND_MAX);
        stats = StatType(value_, key_tree_);
        methods = MethodType();
    }
    // InnerTreap* opCall() {
    //     return null;
    // }
    ///
    void push() {
        if (left != null) {
            left.value.accept_method(methods);
            left.stats.accept_method(methods);
            left.methods.accept_method(methods);
        }
        if (right != null) {
            right.value.accept_method(methods);
            right.stats.accept_method(methods);
            right.methods.accept_method(methods);
        }
        methods.flush();
    }
    ///
    void update() {
        StatType local_stat = StatType(value, key_tree);
        if (left != null) {
            stats = left.stats;
            stats.accept_stats(local_stat);
        }
        else {
            stats = local_stat;
        }
        if (right != null) {
            stats.accept_stats(right.stats);
        }
    }
}

///merge
InnerTreap* merge(InnerTreap)(InnerTreap* left_treap, InnerTreap* right_treap) {
    if (left_treap == null) {
        return right_treap;
    }
    if (right_treap == null) {
        return left_treap;
    }
    if (left_treap.key_heap < right_treap.key_heap) {
        right_treap.push();
        right_treap.left = merge!InnerTreap(left_treap, right_treap.left);
        right_treap.update();
        return right_treap;
    }
    else {
        left_treap.push();
        left_treap.right = merge!InnerTreap(left_treap.right, right_treap);
        left_treap.update();
        return left_treap;
    }
}

/// split
InnerTreap*[] split(InnerTreap, KeyType)(InnerTreap* treap, KeyType key_tree_) {
    if (treap == null) {
        return [treap, treap];
    }
    treap.push();
    InnerTreap* left;
    InnerTreap* right;
    InnerTreap* temp;
    if (key_tree_ > treap.key_tree) {
        // not sure if I can do this but I want to
        auto lexa = split(treap.right, key_tree_);
        temp = lexa[0]; right = lexa[1];
        left = treap;
        left.right = temp;
    }
    else {
        auto lexa = split(treap.left, key_tree_);
        left = lexa[0]; temp = lexa[1];
        right = treap;
        right.left = temp;
    }
    treap.update();
    return [left, right];
}

/// add elem
InnerTreap* radd_elem(InnerTreap, KeyType, ValueType)(KeyType key_tree, ValueType value, InnerTreap* treap) {
    InnerTreap* new_left;
    InnerTreap* new_right;
    auto lexa = split(treap, key_tree);
    new_left = lexa[0]; new_right = lexa[1];
    InnerTreap* new_treap = new InnerTreap(key_tree, value);
    return merge(merge(new_left, new_treap), new_right);
}

/// method on range
InnerTreap* rmethod_on_range(MethodType, KeyType, InnerTreap)(MethodType method, KeyType left_cl, KeyType right_op, InnerTreap* treap) {
    InnerTreap* left_cut;
    InnerTreap* right_cut;
    InnerTreap* target;
    auto obj = split(treap, left_cl);
    left_cut = obj[0];
    target = obj[1];
    obj = split(target, right_op);
    target = obj[0];
    right_cut = obj[1];
    target.methods.accept_method(method);
    target.value.accept_method(method);
    target.stats.accept_method(method);
    return merge(merge(left_cut, target), right_cut);
}

/// stats on range
StatType rstats_on_range(StatType, KeyType, InnerTreap)(KeyType left_cl, KeyType right_op, InnerTreap* treap) {
    InnerTreap* left_cut;
    InnerTreap* right_cut;
    InnerTreap* target;
    auto lexa = split(treap, left_cl);
    left_cut = lexa[0]; target = lexa[1];
    lexa = split(target, right_op);
    target = lexa[0]; right_cut = lexa[1];
    StatType stats = target.stats;
    treap = merge(merge(left_cut, target), right_cut);
    return stats;
}

/// treap wrapper
struct Treap(alias UltimateStruct) {
    alias KeyType = typeof(UltimateStruct.KeyType);
    alias ValueType = typeof(UltimateStruct.ValueType);
    alias StatType = typeof(UltimateStruct.StatType);
    alias MethodType = typeof(UltimateStruct.MethodType);
    /// ._.
    InnerTreap!(UltimateStruct)* treap;
    ///init
    this(KeyType key, ValueType value) {
        treap = new InnerTreap!(UltimateStruct)(key, value);
    }
    ///
    void add_elem(KeyType key_tree, ValueType value) {
        treap = radd_elem!(InnerTreap!(UltimateStruct), KeyType, ValueType)(key_tree, value, treap);
    }
    ///
    void method_on_range(MethodType method, KeyType left_cl, KeyType right_op) {
        treap = rmethod_on_range!(MethodType, KeyType, InnerTreap!(UltimateStruct))(method, left_cl, right_op, treap);
    }
    ///
    StatType stats_on_range(KeyType left_cl, KeyType right_op) {
        return rstats_on_range!(StatType, KeyType, InnerTreap!(UltimateStruct))(left_cl, right_op, treap);
    }
}
