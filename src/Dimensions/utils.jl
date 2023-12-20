for f in (:shiftlocus, :maybeshiftlocus)
    @eval begin
        function LookupArrays.$f(locus::Locus, x; dims=Dimensions.dims(x))
            newdims = map(Dimensions.dims(x, dims)) do d
                LookupArrays.$f(locus, d)
            end
            return setdims(x, newdims)
        end
        function LookupArrays.$f(locus::Locus, d::Dimension)
            rebuild(d, LookupArrays.$f(locus, lookup(d)))
        end
    end
end
