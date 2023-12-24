using Test, DimensionalData, Dates

using DimensionalData.LookupArrays, DimensionalData.Dimensions
const DD = DimensionalData

A = rand(X(10:20), Y(10:20))
@test DD.issampled(A) == true
@test DD.iscategorical(A) == false
@test DD.iscyclic(A) == false
@test DD.isordered(A) == true
@test DD.isforward(A) == true
@test DD.isreverse(A) == false
@test DD.isregular(A) == true
@test DD.isexplicit(A) == false
@test DD.ispoints(A) == true
@test DD.isintervals(A) == false
@test DD.isstart(A) == false
@test DD.iscenter(A) == true
@test DD.isend(A) == false

ds = X(10:20), 
     Ti(Cyclic([DateTime(2001), DateTime(2002), DateTime(2003)]; order=ForwardOrdered(), cycle=Year(3), sampling=Intervals(Start()))), 
     Y(20:-1:10; sampling=Intervals(End())), 
     Dim{:cat}(["a", "z", "b"])
A = rand(ds)
@test DD.issampled(A) == false
@test DD.iscategorical(A) == false
@test DD.iscyclic(A) == false
@test DD.isordered(A) == false
@test DD.isforward(A) == false
@test DD.isreverse(A) == false
@test DD.isregular(A) == false
@test DD.isexplicit(A) == false
@test DD.ispoints(A) == false
@test DD.isintervals(A) == false
@test DD.isstart(A) == false
@test DD.iscenter(A) == false
@test DD.isend(A) == false

@test DD.issampled(A, (X, Y, Ti)) == true
@test DD.iscategorical(A, :cat) == true
@test DD.iscyclic(A, Ti) == true
@test DD.isordered(A, (X, Y, Ti)) == true
@test DD.isforward(A, (X, Ti)) == true
@test DD.isreverse(A, Y) == true
@test DD.isregular(A, (X, Y)) == true
@test DD.ispoints(A, X) == true
@test DD.isintervals(A, (Ti, Y)) == true
@test DD.isstart(A, Ti) == true
@test DD.iscenter(A, X) == true
@test DD.isend(A, Y) == true
