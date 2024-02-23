using DimensionalData
using DimensionalData: Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered,
    Sampled, Categorical, NoLookup, Transformed,
    Regular, Irregular, Explicit, Points, Intervals, Start, Center, End

using GLMakie: GLMakie as Mke

A1intervals = rand(X(1.0:10.0; sampling=Intervals(Start())); name=:test)

Mke.plot(set(A1intervals, X=>Points()))
Mke.plot(A1intervals)

A2intervals1 = rand(X(10:10:100; sampling=Intervals(Start())), Z(1:3))
Mke.plot(A2intervals1)
A2intervals2 = rand(X(10:10:100; sampling=Intervals(Start())), Z(1:3; sampling=Intervals(Start())))
Mke.plot(A2intervals2)

A3intervals1 = rand(X(10:1:15; sampling=Intervals(Start())), Y(1:3), Dim{:C}(10:15))
Mke.plot(A3intervals1; z=:C)
# broken
A3intervals2 = rand(X(10:1:15; sampling=Intervals(Start())), Y(1:3), Z(10:15; sampling=Intervals(Start())))
Mke.plot(A3intervals2)
A3intervals2a = rand(X(10:1:10; sampling=Intervals(Start())), Y(1:1; sampling=Intervals(Start())), Z(10:20))
Mke.plot(A3intervals2a)

a = rand(2,2,2)