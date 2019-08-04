
abstract type AbstractSelectionMode end

struct Nearest <: AbstractSelectionMode end
struct Contained <: AbstractSelectionMode end
struct Exact <: AbstractSelectionMode end
struct Interpolated <: AbstractSelectionMode end
