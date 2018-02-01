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
// class TreapNode(KeyType, ValueType, MethodType, StatType) {
/// Internal struct for a node of a treap
struct TreapNode(alias TreapTypeCollection) {
    alias KeyType = TreapTypeCollection.KeyType;
    alias ValueType = TreapTypeCollection.ValueType;
    alias StatType = TreapTypeCollection.StatType;
    alias MethodType = TreapTypeCollection.MethodType;
    /// pointers to children
    TreapNode!(TreapTypeCollection)* left;
    /// ditto
    TreapNode!(TreapTypeCollection)* right;
    /// keys
    KeyType key_tree;
    /// ditto
    const int key_heap;
    /// value
    ValueType value;
    /// statistics
    StatType stats;
    /// methods
    MethodType methods;
    /// init
    this(KeyType key_tree_, ValueType value_) {
        left = null;
        right = null;
        value = value_;
        key_tree = key_tree_;
        key_heap = uniform(0, MY_RAND_MAX);
        stats = StatType(value_, key_tree_);
        methods = MethodType();
        methods.flush();
    }
    // TreapNode* opCall() {
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
TreapNode* merge(TreapNode)(TreapNode* left_treap, TreapNode* right_treap) {
    if (left_treap == null) {
        return right_treap;
    }
    if (right_treap == null) {
        return left_treap;
    }
    if (left_treap.key_heap < right_treap.key_heap) {
        right_treap.push();
        right_treap.left = merge!TreapNode(left_treap, right_treap.left);
        right_treap.update();
        return right_treap;
    }
    else {
        left_treap.push();
        left_treap.right = merge!TreapNode(left_treap.right, right_treap);
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
TreapNode*[] split(TreapNode)(TreapNode* treap, TreapNode.KeyType key_tree_) {
    if (treap == null) {
        return [treap, treap];
    }
    treap.push();
    TreapNode* left;
    TreapNode* right;
    TreapNode* temp;
    if (key_tree_ > treap.key_tree) {
        // not sure if I can do this but I want to
        auto lexa = split!(TreapNode)(treap.right, key_tree_);
        temp = lexa[0]; right = lexa[1];
        left = treap;
        left.right = temp;
    }
    else {
        auto lexa = split!(TreapNode)(treap.left, key_tree_);
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
TreapNode* radd_elem(TreapNode)(TreapNode.KeyType key_tree, TreapNode.ValueType value, TreapNode* treap) {
    TreapNode* new_left;
    TreapNode* new_right;
    auto lexa = split!(TreapNode)(treap, key_tree);
    new_left = lexa[0]; new_right = lexa[1];
    TreapNode* new_treap = new TreapNode(key_tree, value);
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
TreapNode* rmethod_on_range(TreapNode)(TreapNode.MethodType method, TreapNode.KeyType left_cl, TreapNode.KeyType right_op, TreapNode* treap) {
    TreapNode* left_cut;
    TreapNode* right_cut;
    TreapNode* target;
    auto obj = split!(TreapNode)(treap, left_cl);
    left_cut = obj[0];
    target = obj[1];
    obj = split!(TreapNode)(target, right_op);
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
//HOW THE FUCK IS THIS EVEN LEGAL?!
TreapNode.StatType rstats_on_range(TreapNode)(TreapNode.KeyType left_cl, TreapNode.KeyType right_op, TreapNode* treap) {
    TreapNode* left_cut;
    TreapNode* right_cut;
    TreapNode* target;
    auto lexa = split!(TreapNode)(treap, left_cl);
    left_cut = lexa[0]; target = lexa[1];
    lexa = split!(TreapNode)(target, right_op);
    target = lexa[0]; right_cut = lexa[1];
    TreapNode.StatType stats = target.stats;
    treap = merge(merge(left_cut, target), right_cut);
    return stats;
}

/**
Treap type implements a multimap with statistics function and
modification methods on subsegment.
*/
struct Treap(alias TreapTypeCollection) {
    //types are unpacked from TreapTypeCollection
    alias KeyType = TreapTypeCollection.KeyType;
    alias ValueType = TreapTypeCollection.ValueType;
    alias StatType = TreapTypeCollection.StatType;
    alias MethodType = TreapTypeCollection.MethodType;
    
    alias NodeType = TreapNode!(TreapTypeCollection);
    /// pointer to the root of recursive treap
    NodeType* root;
    /// constructor from one element
    this(KeyType key, ValueType value) {
        root = new NodeType(key, value);
    }
    /// adds element into the Treap. O(log(n)) average case
    void add_elem(KeyType key_tree, ValueType value) {
        root = radd_elem!NodeType(key_tree, value, root);
    }
    /// applys method on range. O(log(n)) average case
    void method_on_range(MethodType method, KeyType left_cl, KeyType right_op) {
        root = rmethod_on_range!NodeType(method, left_cl, right_op, root);
    }
    /// gets statistics on range. O(log(n)) average case
    StatType stats_on_range(KeyType left_cl, KeyType right_op) {
        return rstats_on_range!NodeType(left_cl, right_op, root);
    }
}


struct Method {
    ///
    int to_add;
    ///init full
    this(int t_a) {
        to_add = t_a;
    }
    /// push
    void accept_method(ref Method method) {
        to_add += method.to_add;
    }
    /// clean up
    void flush() {
        to_add = 0;
    }
}

struct Value {
    int value;
    this(int a) {
        value = a;
    }
    void accept_method(ref Method method) {
        value += method.to_add;
    }
}

///stats
struct Stat {
    ///
    int max_;
    ///
    int min_;
    ///
    int elems_nr_;
    ///
    int min_idx_;
    ///
    int sum_;
    /// init
    this(Value val, int key_tree) {
        max_ = val.value;
        min_ = val.value;
        min_idx_ = key_tree;
        elems_nr_ = 1;
        sum_ = val.value;
    }
    /// update
    void accept_stats(ref Stat stats) {
        max_ = max(max_, stats.max_);
        min_ = min(min_, stats.min_);
        elems_nr_ += stats.elems_nr_;
        sum_ += stats.sum_;
    }
    /// push
    void accept_method(ref Method method) {
        max_ += method.to_add;
        min_ += method.to_add;
        sum_ += method.to_add * elems_nr_;
    }
}

struct TreapTypeCollection {
    alias KeyType = int;
    alias ValueType = Value;
    alias StatType = Stat;
    alias MethodType = Method;
}
unittest {
    int[] idx___value = [3, 5, 6, 24, 63, 2, 5, -8, 35, 12, 4, 6, 67];
    // InnerTreap!(TreapTypeCollection)* t = new InnerTreap!(TreapTypeCollection)(0, Value(0));
    Treap!(TreapTypeCollection) t = Treap!(TreapTypeCollection)(0, Value(0));
    foreach(idx; 0 .. idx___value.length) {
        pragma(msg, typeof(t));
        t.add_elem(idx + 1, Value(idx___value[idx]));
        // add_elem!(InnerTreap!(TreapTypeCollection), int, Value)(idx + 1, Value(idx___value[idx]), t);
    }
    idx___value = [0] ~ idx___value;
    Stat all_stats = t.stats_on_range(-1, 100);
    assert(idx___value.length == all_stats.elems_nr_);
    int curr_sum = idx___value.sum;
    assert(curr_sum == all_stats.sum_);
    assert(idx___value.minElement == all_stats.min_);
    assert(idx___value.maxElement == all_stats.max_);
    Method meth = Method(3);
    foreach (ref elem; idx___value) {
        elem += 3;
    }
    t.method_on_range(meth, -1, 100);
    all_stats = t.stats_on_range(-1, 100);
    assert(idx___value.length == all_stats.elems_nr_);
    curr_sum = idx___value.sum;
    writeln(idx___value.sum, " ", all_stats.sum_);
    assert(curr_sum == all_stats.sum_);
    assert(idx___value.minElement == all_stats.min_);
    assert(idx___value.maxElement == all_stats.max_);
    // t.method_on_range(meth, -1, 100);
    // assert(1 == 's');
    all_stats = t.stats_on_range(3, 7);
    assert(all_stats.elems_nr_ == 4);
    curr_sum = idx___value[3 .. 7].sum;
    writeln(curr_sum, " ", all_stats.sum_);
    assert(curr_sum == all_stats.sum_);
    assert(all_stats.min_ == idx___value[3 .. 7].minElement);
    assert(all_stats.max_ == idx___value[3 .. 7].maxElement);
    meth = Method(-3);
    foreach (ref elem; idx___value) {
        elem -= 3;
    }
    t.method_on_range(meth, 3, 7);
    all_stats = t.stats_on_range(3, 7);
    assert(all_stats.elems_nr_ == 4);
    curr_sum = idx___value[3 .. 7].sum;
    assert(curr_sum == all_stats.sum_);
    assert(all_stats.min_ == idx___value[3 .. 7].minElement);
    assert(all_stats.max_ == idx___value[3 .. 7].maxElement);
    writeln("Happy line :)");
}

void main() {
    // writeln("why so serious?");
}
