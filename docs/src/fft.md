# Fast Fourier Transform (FFT)
`DimensionalData.jl` implements the Fast Fourier Transform (FFT) for `DimensionalArray` objects, allowing users to perform frequency domain analysis while preserving dimensional metadata.

It uses lookups to scale the forward and inverse transforms to remain physically meaningful. As such, it implements the following conventions. If we denote a signal as a function of time ``a(x)`` sampled at discrete intervals ``dx``, the discrete Fourier transform (DFT) is defined as:
```math
\operatorname{DFT}(A)[k] =
\sum_{n=1}^{\operatorname{length}(A)} \exp\left(i2π x[n]f[k] \right) A[n] dx.
```
The inverse discrete Fourier transform (IDFT) is defined as:
```math
\operatorname{IDFT}(A)[n] =
\sum_{k=1}^{\operatorname{length}(A)} \exp\left(-i2π x[n]f[k] \right) A[k] df.
```

These conventions ensure that the transforms are unitary, meaning that applying the DFT followed by the IDFT returns the original signal without any additional scaling factors. The scaling factors applied to the forward and inverse transforms are different from the "standard" discrete Fourier transform definitions, which typically does not scale the forward transform, and includes a normalization factor of `1/N` in the inverse transform.

## API

The following functions are provided for performing FFTs on `DimensionalArray` objects:

TODO
