// Written in the D programming language.
/**
1) Stat in root is alwaus correct
2) Methods are a monoid(group withoit reversed) acts on value,
stats as described in their classes.
*/

import std.stdio;
import std.algorithm;
import std.random;


///
const uint MY_RAND_MAX = 1 << 31;

//decart tree, heap-tree, cartesian tree
// class InnerTreap(KeyType, ValueType, MethodType, StatType) {
/// Internal struct for a node of a treap
struct InnerTreap(alias UltimateStruct) {
    alias KeyType = typeof(UltimateStruct.KeyType);
    alias ValueType = typeof(UltimateStruct.ValueType);
    alias StatType = typeof(UltimateStruct.StatType);
    alias MethodType = typeof(UltimateStruct.MethodType);
    /// pointers to children
    InnerTreap!(UltimateStruct)* left;
    InnerTreap!(UltimateStruct)* right; /// ditto
    /// keys
    KeyType key_tree;
    const int key_heap; /// ditto
    /// value
    ValueType value;
    /// statistics
    StatType stats;
    /// methods
    MethodType methods;

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
    /**
      pushes methods into the children.
      It is guaranteed that values and statistics in children are
      correct(reflect those of a node and subtree respectively) after push.
    */
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
    /**
      Updates statistics os subtree in a node. It is guaranteed that
      statistics in a node are correct if statistics of children were correct.
    */
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

///merges 2 rtrees into one
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

/**
Splits rtree into 2 by value.
Left tree is <=, right tree is >

Params:
treap = pointer to the root of a tree to split
key_tree_ = key to split by

Returns:
tuple of pointers: to left and to right
*/
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

/** adds elememt to a tree

Params:
key_tree = key of element to add
value = value of element
treap = pointer to the root of a tree in which element is added

Returns:
pointer to the root of new tree, with element added
*/
InnerTreap* radd_elem(InnerTreap, KeyType, ValueType)(KeyType key_tree, ValueType value, InnerTreap* treap) {
    InnerTreap* new_left;
    InnerTreap* new_right;
    auto lexa = split(treap, key_tree);
    new_left = lexa[0]; new_right = lexa[1];
    InnerTreap* new_treap = new InnerTreap(key_tree, value);
    return merge(merge(new_left, new_treap), new_right);
}

/**
applies method on range.

Params:
method = presentation of a method to be applied, element of MethodType monoid
left_cl = left closed border of a range on which method is applied
right_op = right opened border of a range on which method is applied
treap = pointer to the root of a tree to subsegment of which the method is applied

Returns:
Pointer to the root of a new treap with applied method
*/
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

/**
gets statistics on range

Params:
left_cl = left closed border of a range on which statistics are requested
right_op = right opened border of a range on which statistics are requested
treap = pointer to the root of a tree on subsegment of which statistics are requested
*/
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

/**
Treap type implements a multimap with statistics function and
modification methods on subsegment.
*/
struct Treap(alias UltimateStruct) {
    //types are unpacked from UltimateStruct
    alias KeyType = typeof(UltimateStruct.KeyType);
    alias ValueType = typeof(UltimateStruct.ValueType);
    alias StatType = typeof(UltimateStruct.StatType);
    alias MethodType = typeof(UltimateStruct.MethodType);
    /// pointer to the root of recursive treap
    InnerTreap!(UltimateStruct)* treap;
    /// constructor from one element
    this(KeyType key, ValueType value) {
        treap = new InnerTreap!(UltimateStruct)(key, value);
    }
    /// adds element into the Treap. O(log(n)) average case
    void add_elem(KeyType key_tree, ValueType value) {
        treap = radd_elem!(InnerTreap!(UltimateStruct), KeyType, ValueType)(key_tree, value, treap);
    }
    /// applys method on range. O(log(n)) average case
    void method_on_range(MethodType method, KeyType left_cl, KeyType right_op) {
        treap = rmethod_on_range!(MethodType, KeyType, InnerTreap!(UltimateStruct))(method, left_cl, right_op, treap);
    }
    /// gets statistics on range. O(log(n)) average case
    StatType stats_on_range(KeyType left_cl, KeyType right_op) {
        return rstats_on_range!(StatType, KeyType, InnerTreap!(UltimateStruct))(left_cl, right_op, treap);
    }
}
