using DimensionalData, AbstractFFTs, FFTW, Test, LinearAlgebra

gauss(x, a, x0) = exp(-a * (x - x0)^2)
fourier_gauss(k, a, x0) = √(π / a) * exp(-π^2 * k^2 / a + 2π * im * x0 * k) # Fourier transform of a Gaussian

x = range(-5, 5, length = 1000)
y = gauss.(X(x), 5, 0)

fft_y = fft(y)
ref_values = fourier_gauss.(dims(fft_y, 1), 5, 0)

@test all(isapprox.(fft_y, fourier_gauss.(dims(fft_y, 1), 5, 0), atol = 1E-9))
shift_fft_y = fftshift(fft_y)
@test all(isapprox.(shift_fft_y, fourier_gauss.(dims(shift_fft_y, 1), 5, 0), atol = 1E-9))
shift_shift_fft_y = fftshift(shift_fft_y)
@test all(isapprox.(shift_shift_fft_y, fft_y, atol = 1E-5))

ifft_y = ifft(fft_y)
@test all(isapprox.(ifft_y, gauss.(lookup(ifft_y, 1), 5, 0), atol = 1E-9))
@test all(isapprox.(lookup(ifft(fft_y), 1) |> parent |> step, step(x), atol = 1E-9))

# Double test to ensure that the plan uses correctly the temporary arrays used to avoid allocations
p = plan_fft(y)
@test all(isapprox.(mul!(fft_y, p, complex.(y)), ref_values, atol = 1E-9))
@test all(isapprox.(mul!(fft_y, p, complex.(y)), ref_values, atol = 1E-9))
pinv = plan_ifft(fft_y)
@test all(isapprox.(mul!(ifft_y, pinv, fft_y), gauss.(lookup(ifft_y, 1), 5, 0), atol = 1E-9))
@test all(isapprox.(mul!(ifft_y, pinv, fft_y), gauss.(lookup(ifft_y, 1), 5, 0), atol = 1E-9))



