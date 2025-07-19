using DimensionalData, FFTW, Test, LinearAlgebra, Unitful


@testset "FFT freqs" begin
    ext = Base.get_extension(DimensionalData, :DimensionalDataAbstractFFTsExt)

    # Test with even length
    x = dims(rand(X(-5:4)), 1)
    fx = ext._fftfreq(x)
    @test ext._ifftfreq(fx) == x
    
    # Test with odd length
    x = dims(rand(X(-5:5)), 1)
    fx = ext._fftfreq(x)
    @test ext._ifftfreq(fx) == x
    
    x = dims(rand(X(-5:5)), 1)
    fx = ext._rfftfreq(x)
    @test ext._irfftfreq(fx, length(x)) == x
    
    x = dims(rand(X(-5:4)), 1)
    fx = ext._rfftfreq(x)
    @test ext._irfftfreq(fx, length(x)) == x
end


@testset "1D FFT" begin
    gauss(x, a, x0) = exp(-a * (x - x0)^2)
    fourier_gauss(k, a, x0) = √(π / a) * exp(-π^2 * k^2 / a - 2π * im * x0 * k) # Fourier transform of a Gaussian
    
    unit_x = u"m"
    unit_y = u"g"
    unit = unit_x * unit_y
    
    x = range(-5, 5, length = 1000) .* unit_x
    y = gauss.(X(x), 5 / unit_x^2, 1 .* unit_x) .* unit_y
    
    fft_y = fft(y)
    ref_values = fourier_gauss.(dims(fft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y
    
    @test all(isapprox.(fft_y, fourier_gauss.(dims(fft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y, atol = 1E-9 * unit))
    shift_fft_y = fftshift(fft_y)
    @test all(isapprox.(shift_fft_y, fourier_gauss.(dims(shift_fft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y, atol = 1E-9 * unit))
    shift_shift_fft_y = fftshift(shift_fft_y)
    @test all(isapprox.(shift_shift_fft_y, fft_y, atol = 1E-5 * unit))
    
    ifft_y = ifft(fft_y)
    @test all(isapprox.(ifft_y, gauss.(lookup(ifft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y, atol = 1E-9 * unit_y))
    @test all(isapprox.(lookup(ifft(fft_y), 1) |> parent |> step, step(x), atol = 1E-9 * unit_x))
    
    # Double test to ensure that the plan uses correctly the temporary arrays used to avoid allocations
    p = plan_fft(y)
    @test all(isapprox.(mul!(fft_y, p, complex.(y)), ref_values, atol = 1E-9 * unit))
    @test all(isapprox.(mul!(fft_y, p, complex.(y)), ref_values, atol = 1E-9 * unit))
    pinv = plan_ifft(fft_y)
    @test all(isapprox.(mul!(ifft_y, pinv, fft_y), gauss.(lookup(ifft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y, atol = 1E-9 * unit_y))
    @test all(isapprox.(mul!(ifft_y, pinv, fft_y), gauss.(lookup(ifft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y, atol = 1E-9 * unit_y))
    
    
    fft_y = rfft(y)
    ref_values = fourier_gauss.(dims(fft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y
    
    @test all(isapprox.(fft_y, fourier_gauss.(dims(fft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y, atol = 1E-9 * unit))
    
    ifft_y = irfft(fft_y, length(y))
    @test all(isapprox.(ifft_y, gauss.(lookup(ifft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y, atol = 1E-9 * unit_y))
    @test all(isapprox.(lookup(ifft_y, 1) |> parent |> step, step(x), atol = 1E-9 * unit_x))
    
    # Double test to ensure that the plan uses correctly the temporary arrays used to avoid allocations
    p = plan_rfft(y)
    @test all(isapprox.(mul!(fft_y, p, y), ref_values, atol = 1E-9 * unit))
    @test all(isapprox.(mul!(fft_y, p, y), ref_values, atol = 1E-9 * unit))
    @test all(isapprox.(mul!(rand(typeof((1.0 .+ im)*u"kg*m"), dims(fft_y, X)), p, y), ref_values, atol = 1E-9 * unit)) # Check output with different unit works correctly

    @test_throws Unitful.DimensionError mul!(rand(typeof((1.0 .+ im)u"V"), dims(fft_y, X)), p, y)
    @test_throws ArgumentError mul!(rand(typeof(fft_y[1]), X(x)), p, y)


    pinv = plan_irfft(fft_y, length(y))
    ifft_refvalues = gauss.(lookup(ifft_y, 1), 5 / unit_x^2, 1 * unit_x) * unit_y
    @test all(isapprox.(mul!(ifft_y, pinv, fft_y), ifft_refvalues, atol = 1E-9 * unit_y))
    @test all(isapprox.(mul!(ifft_y, pinv, fft_y), ifft_refvalues, atol = 1E-9 * unit_y))
    @test all(isapprox.(mul!(rand(typeof((1.0)*u"kg"), dims(ifft_y, X)), pinv, fft_y), ifft_refvalues, atol = 1E-9 * unit_y)) # Check output with different unit works correctly
    @test_throws Unitful.DimensionError mul!(rand(typeof((1.0)*u"V"), dims(ifft_y, X)), pinv, fft_y)
    @test_throws ArgumentError mul!(rand(typeof(ifft_y[1]), X(x)), pinv, fft_y)
end


@testset "2D FFT" begin

    gauss(x, y, σx, σy) = exp(-(x^2 / (2σx^2) + y^2 / (2σy^2)))

    fourier_gauss(kx, ky, σx, σy) = complex(2π * σx * σy * exp(-2π^2 * (σx^2 * kx^2 + σy^2 * ky^2)))


    unit_x = u"m"
    unit_y = u"g"
    unit_z = u"F"
    unit = unit_x * unit_y * unit_z
    
    x = range(-5, 5, length = 1000) .* unit_x
    y = range(-10, 10, length = 2000) .* unit_y
    z = @d gauss.(X(x), Y(y), .5 * unit_x, 2 * unit_y) .* unit_z
    
    fft_z = fft(z)
    ref_values = @d fourier_gauss.(dims(fft_z, X), dims(fft_z, Y), .5 * unit_x, 2 * unit_y) .* unit_z
    
    @test all(isapprox.(fft_z, ref_values, atol = 1E-5 * unit))
    shift_fft_z = fftshift(fft_z)
    @test all(isapprox.(shift_fft_z, (@d fourier_gauss.(dims(shift_fft_z, X), dims(shift_fft_z, Y), .5 * unit_x, 2 * unit_y)) * unit_z, atol = 1E-5 * unit))
    shift_shift_fft_z = fftshift(shift_fft_z)
    @test all(isapprox.(shift_shift_fft_z, fft_z, atol = 1E-5 * unit))

    ifft_z = ifft(fft_z)
    @test all(isapprox.(ifft_z, (@d gauss.(dims(ifft_z, X), dims(ifft_z, Y), .5 * unit_x, 2 * unit_y)) * unit_z, atol = 1E-5 * unit_z))
    @test all(isapprox.(lookup(ifft_z, X) |> parent |> step, step(x), atol = 1E-9 * unit_x))
    @test all(isapprox.(lookup(ifft_z, Y) |> parent |> step, step(y), atol = 1E-9 * unit_y))

    p = plan_fft(z)
    @test all(isapprox.(mul!(fft_z, p, complex.(z)), ref_values, atol = 1E-5 * unit))
    @test all(isapprox.(mul!(fft_z, p, complex.(z)), ref_values, atol = 1E-5 * unit))
    pinv = plan_ifft(fft_z)

    ifft_refvalues = (@d gauss.(dims(ifft_z, X), dims(ifft_z, Y), .5 * unit_x, 2 * unit_y)) * unit_z
    @test all(isapprox.(mul!(ifft_z, pinv, fft_z), ifft_refvalues, atol = 1E-5 * unit_z))
    @test all(isapprox.(mul!(ifft_z, pinv, fft_z), ifft_refvalues, atol = 1E-5 * unit_z))

    fft_z = rfft(z)
    ref_values = @d fourier_gauss.(dims(fft_z, X), dims(fft_z, Y), .5 * unit_x, 2 * unit_y) .* unit_z
    
    @test all(isapprox.(fft_z, ref_values, atol = 1E-5 * unit))
    
    ifft_z = irfft(fft_z, size(z, X))
    ifft_refvalues = @d gauss.(dims(ifft_z, X), dims(ifft_z, Y), .5 * unit_x, 2 * unit_y) .* unit_z
    @test all(isapprox.(ifft_z, ifft_refvalues, atol = 1E-5 * unit_z))
    @test all(isapprox.(lookup(ifft_z, X) |> parent |> step, step(x), atol = 1E-9 * unit_x))
    @test all(isapprox.(lookup(ifft_z, Y) |> parent |> step, step(y), atol = 1E-9 * unit_y))
    
    # Double test to ensure that the plan uses correctly the temporary arrays used to avoid allocations
    p = plan_rfft(z)
    @test all(isapprox.(mul!(fft_z, p, z), ref_values, atol = 1E-5 * unit))
    @test all(isapprox.(mul!(fft_z, p, z), ref_values, atol = 1E-5 * unit))
    pinv = plan_irfft(fft_z, size(z, X))
    @test all(isapprox.(mul!(ifft_z, pinv, fft_z), ifft_refvalues, atol = 1E-5 * unit_z))
    @test all(isapprox.(mul!(ifft_z, pinv, fft_z), ifft_refvalues, atol = 1E-5 * unit_z))
end

@testset "Single dimension on multidimensional array" begin
    gauss(x, a, x0) = exp(-a * (x - x0)^2)
    fourier_gauss(k, a, x0) = √(π / a) * exp(-π^2 * k^2 / a - 2π * im * x0 * k) # Fourier transform of a Gaussian
    
    unit_x = u"m"
    unit_z = u"g"
    unit = unit_x * unit_z
    
    x = range(-5, 5, length = 1000) .* unit_x
    y = range(0, 3, length = 5) .* unit_x
    z = @d gauss.(X(x), 5 / unit_x^2, Y(y)) .* unit_z
    
    fft_z = fft(z, X)
    @test fft_z == fft(z, 1)
    ref_values = @d fourier_gauss.(dims(fft_z, X), 5 / unit_x^2, Y(y)) .* unit_z

    @test all(isapprox.(fft_z, ref_values, atol = 1E-9 * unit))
    shift_fft_z = fftshift(fft_z, X)
    @test all(isapprox.(shift_fft_z, (@d fourier_gauss.(dims(shift_fft_z, X), 5 / unit_x^2, Y(y))) .* unit_z, atol = 1E-9 * unit))
    shift_shift_fft_z = fftshift(shift_fft_z, X)
    @test all(isapprox.(shift_shift_fft_z, fft_z, atol = 1E-9 * unit))

    ifft_z = ifft(fft_z, X)
    @test ifft_z == ifft(fft_z, 1)
    ifft_refvalues = @d gauss.(dims(ifft_z, X), 5 / unit_x^2, Y(y)) .* unit_z
    @test all(isapprox.(ifft_z, ifft_refvalues, atol = 1E-9 * unit_z))

    @test all(isapprox.(lookup(ifft_z, X) |> parent |> step, step(x), atol = 1E-9 * unit_x))
    @test all(isapprox.(lookup(ifft_z, Y) |> parent, y, atol = 1E-9 * unit_x))

    p = plan_fft(z, X)
    @test plan_fft(z, 1) isa Any
    @test all(isapprox.(mul!(fft_z, p, complex.(z)), ref_values, atol = 1E-9 * unit))
    @test all(isapprox.(mul!(fft_z, p, complex.(z)), ref_values, atol = 1E-9 * unit))
    pinv = plan_ifft(fft_z, X)
    @test plan_ifft(fft_z, 1) isa Any
    @test all(isapprox.(mul!(ifft_z, pinv, fft_z), ifft_refvalues, atol = 1E-9 * unit_z))
    @test all(isapprox.(mul!(ifft_z, pinv, fft_z), ifft_refvalues, atol = 1E-9 * unit_z))

    fft_z = rfft(z, X)
    @test fft_z == rfft(z, 1)
    ref_values = @d fourier_gauss.(dims(fft_z, X), 5 / unit_x^2, Y(y)) .* unit_z
    @test all(isapprox.(fft_z, ref_values, atol = 1E-9 * unit))

    ifft_z = irfft(fft_z, size(z, X), X)
    @test ifft_z == irfft(fft_z, size(z, X), X)
    ifft_refvalues = @d gauss.(dims(ifft_z, X), 5 / unit_x^2, Y(y)) .* unit_z
    @test all(isapprox.(ifft_z, ifft_refvalues, atol = 1E-9 * unit_z))
    @test all(isapprox.(lookup(ifft_z, X) |> parent |> step, step(x), atol = 1E-9 * unit_x))
    @test all(isapprox.(lookup(ifft_z, Y) |> parent, y, atol = 1E-9 * unit_x))

    # Double test to ensure that the plan uses correctly the temporary arrays used to avoid allocations
    p = plan_rfft(z, X)
    @test plan_rfft(z, 1) isa Any
    @test all(isapprox.(mul!(fft_z, p, z), ref_values, atol = 1E-9 * unit))
    @test all(isapprox.(mul!(fft_z, p, z), ref_values, atol = 1E-9 * unit))
    @test all(isapprox.(mul!(rand(typeof((1.0 .+ im)*u"kg*m"), dims(fft_z, X), dims(fft_z, Y)), p, z), ref_values, atol = 1E-9 * unit)) # Check output with different unit works correctly
    @test_throws Unitful.DimensionError mul!(rand(typeof((1.0 .+ im)u"kg"), dims(fft_z, X), dims(fft_z, Y)), p, z)
    @test_throws ArgumentError mul!(rand(typeof(fft_z[1]), X(x), Y(y)), p, z)

    pinv = plan_irfft(fft_z, size(z, X), X)
    @test plan_irfft(fft_z, size(z, X), 1) isa Any
    @test all(isapprox.(mul!(ifft_z, pinv, fft_z), ifft_refvalues, atol = 1E-9 * unit_z))
    @test all(isapprox.(mul!(ifft_z, pinv, fft_z), ifft_refvalues, atol = 1E-9 * unit_z))
    @test all(isapprox.(mul!(rand(typeof((1.0)*u"kg"), dims(ifft_z, X), dims(ifft_z, Y)), pinv, fft_z), ifft_refvalues, atol = 1E-9 * unit_z)) # Check output with different unit works correctly
    @test_throws Unitful.DimensionError mul!(rand(typeof((1.0)*u"kg * m"), dims(ifft_z, X), dims(ifft_z, Y)), pinv, fft_z)
    @test_throws ArgumentError mul!(rand(typeof(ifft_z[1]), X(x), Y(y)), pinv, fft_z)
end

