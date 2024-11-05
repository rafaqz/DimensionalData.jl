const STRICT_MATMUL_CHECKS = Ref(true)
const STRICT_MATMUL_DOCS = """
With `strict=true` we check [`Lookup`](@ref) [`Order`](@ref) and values 
before attempting matrix multiplication, to ensure that dimensions match closely. 

We always check that dimension names match in matrix multiplication.
If you don't want this either, explicitly use `parent(A)` before
multiplying to remove the `AbstractDimArray` wrapper completely.
"""

"""
    strict_matmul()

Check if strickt broadcasting checks are active.

$STRICT_MATMUL_DOCS
"""
strict_matmul() = STRICT_MATMUL_CHECKS[]

"""
    strict_matmul!(x::Bool)

Set global matrix multiplication checks to `strict`, or not for all `AbstractDimArray`.

$STRICT_MATMUL_DOCS
"""
strict_matmul!(x::Bool) = STRICT_MATMUL_CHECKS[] = x
