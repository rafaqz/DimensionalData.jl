"""
Trait container for dimension and array ordering

The default is `Forward()`, `Forward()`
"""
struct Order{D,A} 
    dim::D
    array::A
end
Order() = Order(Forward(), Forward())

dimorder(order::Order) = order.dim
arrayorder(order::Order) = order.array

"""
Trait indicating that the array or dimension is in the normal forward order. 
"""
struct Forward end

"""
Trait indicating that the array or dimension is in the reverse order. 
Selector lookup or plotting will be reversed.
"""
struct Reverse end

Base.reverse(::Reverse) = Forward()
Base.reverse(::Forward) = Reverse()
Base.reverse(o::Order) = Order(revese(dimorder(o)), revese(arrayorder(o)))
