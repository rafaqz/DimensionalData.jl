# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DimensionalData.jl is a Julia package that provides tools and abstractions for working with datasets that have named dimensions and optionally lookup indices. It offers no-cost abstractions for named indexing and fast index lookups, similar to Python's xarray but designed for the Julia ecosystem.

## Development Commands

### Running Tests
```bash
# Run all tests
julia --project=. -e 'using Pkg; Pkg.test()'

# Run a single test file
julia --project=. test/runtests.jl
```

### Building Documentation
```bash
# Build documentation locally
julia --project=docs docs/make.jl

# The documentation uses DocumenterVitepress and will be built in docs/build/
```

### Package Management
```bash
# Install dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Update dependencies
julia --project=. -e 'using Pkg; Pkg.update()'

# Add a new dependency
julia --project=. -e 'using Pkg; Pkg.add("PackageName")'
```

## Architecture Overview

### Core Components

1. **Dimensions** (`src/Dimensions/`)
   - Base dimension types and interfaces
   - Dimension predicates, primitives, and formatting
   - Indexing operations on dimensions

2. **Lookups** (`src/Lookups/`)
   - Lookup arrays that provide the values for each dimension
   - Selectors for indexing (At, Near, Between, Contains, etc.)
   - Traits for lookup behavior (order, span, sampling, locus)

3. **Arrays** (`src/array/`)
   - `AbstractDimArray` and `DimArray` - the main array types
   - Specialized indexing, broadcasting, and matrix multiplication
   - Integration with the Julia array interface

4. **Stacks** (`src/stack/`)
   - `AbstractDimStack` and `DimStack` - collections of arrays sharing dimensions
   - Layer-based operations and indexing

5. **Extensions** (`ext/`)
   - Integration with plotting libraries (Makie, Plots via RecipesBase)
   - Support for categorical arrays, disk arrays, and statistical operations
   - Python interoperability via PythonCall

### Key Design Patterns

- **Traits System**: Uses traits for lookup behavior (Ordered/Unordered, Regular/Irregular, etc.)
- **Selector System**: Flexible indexing using selector types rather than raw values
- **Rebuild Pattern**: Consistent reconstruction of objects with modified properties
- **Extension Loading**: Optional features loaded via package extensions (Julia 1.9+)

### Testing Structure

Tests are organized using SafeTestsets for isolation:
- Each component has its own test file
- Tests use `@safetestset` to avoid namespace pollution
- Platform-specific tests (e.g., plotting) are conditionally run

## Important Notes

- The package uses `@assume_effects` for performance optimizations
- Many operations are type-stable and allocation-free
- The `@d` macro provides convenient dimension construction
- Package follows the DimArray convention where dimensions are always kept with the data