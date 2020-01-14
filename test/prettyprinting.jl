using Dates, DimensionalData
using DimensionalData: Time, X
timespan = DateTime(2001):Month(1):DateTime(2001,12)
t = Time(timespan)
x = X(Vector(10:10:500))
A = DimensionalArray(rand(12,length(x)), (t, x))
