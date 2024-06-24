for f in (:shiftlocus, :maybeshiftlocus)
    @eval begin
        function Lookups.$f(locus::Locus, x; dims=Dimensions.dims(x))
            newdims = map(Dimensions.dims(x, dims)) do d
                Lookups.$f(locus, d)
            end
            return setdims(x, newdims)
        end
        function Lookups.$f(locus::Locus, d::Dimension)
            rebuild(d, Lookups.$f(locus, lookup(d)))
        end
    end
end
