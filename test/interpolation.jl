using DimensionalData
using DataInterpolations
using Test

x_vec = [0.0, 62.25, 109.66, 162.66, 205.8, 252.3]

x_vec_dense = range(extrema(x_vec)..., 123)

x_vec_wider = [
    minimum(x_vec) - 100 : 50 : maximum(x_vec) + 100
    extrema(x_vec)...
] |> unique! |> sort!

x_vec_left = filter(≤(x_vec |> maximum), x_vec_wider)

x_vec_right = filter(≥(x_vec |> minimum), x_vec_wider)

A_vec = [14.7, 11.51, 10.41, 14.95, 12.24, 11.22]

dA_vec = [-0.047, -0.058, 0.054, 0.012, -0.068, 0.0011]

ddA_vec = [0.0, -0.00033, 0.0051, -0.0067, 0.0029, 0.0]

A_dimvec = DimArray(A_vec, X(x_vec))

reproducers = [
    LinearInterpolation
    QuadraticInterpolation
    LagrangeInterpolation
    AkimaInterpolation
    ConstantInterpolation
    QuadraticSpline
    CubicSpline
    BSplineInterpolation
    CubicHermiteSpline
    PCHIPInterpolation
    QuinticHermiteSpline
]

interpolators = [
    reproducers...
    SmoothedConstantInterpolation
]

extrapolators = [
    ExtrapolationType.Constant
    ExtrapolationType.Linear
    ExtrapolationType.Extension
    ExtrapolationType.Periodic
    ExtrapolationType.Reflective
]

@testset "Reproduces Data" begin
    @testset "`$Itp`" for Itp in reproducers
        itp = if Itp == BSplineInterpolation
            BSplineInterpolation(A_dimvec, 3, :ArcLen, :Average)
        elseif Itp == CubicHermiteSpline
            CubicHermiteSpline(dA_vec, A_dimvec)
        elseif Itp == QuinticHermiteSpline
            QuinticHermiteSpline(ddA_vec, dA_vec, A_dimvec)
        else
            Itp(A_dimvec)
        end

        if Itp in [CubicSpline, QuinticHermiteSpline, BSplineInterpolation]
            @testset "$x" for x in x_vec
                @test isapprox(
                    A_dimvec[X = At(x)],
                    itp(x);
                    atol = 1e-14
                )
            end

            @test isapprox(
                A_dimvec |> parent,
                itp(x_vec)
            )
        else
            @testset "$x" for x in x_vec
                @test isequal(
                    A_dimvec[X = At(x)],
                    itp(x)
                )
            end

            @test isequal(
                A_dimvec |> parent,
                itp(x_vec)
            )
        end
    end

    @testset "Backward `QuadraticInterpolation`" begin
        itp = QuadraticInterpolation(A_dimvec, :Backward)
        @testset "$x" for x in x_vec
            @test isequal(
                A_dimvec[X = At(x)],
                itp(x)
            )
            @test isequal(
                A_vec,
                itp(x_vec)
            )
        end
    end

    @testset "Right `ConstantInterpolation`" begin
        itp = ConstantInterpolation(A_dimvec; dir = :Right)
        @testset "$x" for x in x_vec
            @test isequal(
                A_dimvec[X = At(x)],
                itp(x)
            )
            @test isequal(
                A_vec,
                itp(x_vec)
            )
        end
    end
end

@testset "Preserves Interpolation" begin
    @testset "$Itp" for Itp in interpolators
        (; itp_raw, itp_dim) = if Itp == BSplineInterpolation
            itp_raw = BSplineInterpolation(A_vec, x_vec, 3, :ArcLen, :Average)
            itp_dim = BSplineInterpolation(A_dimvec, 3, :ArcLen, :Average)
            (; itp_raw, itp_dim)
        elseif Itp == CubicHermiteSpline
            itp_raw = CubicHermiteSpline(dA_vec, A_vec, x_vec)
            itp_dim = CubicHermiteSpline(dA_vec, A_dimvec)
            (; itp_raw, itp_dim)
        elseif Itp == QuinticHermiteSpline
            itp_raw = QuinticHermiteSpline(ddA_vec, dA_vec, A_vec, x_vec)
            itp_dim = QuinticHermiteSpline(ddA_vec, dA_vec, A_dimvec)
            (; itp_raw, itp_dim)
        else
            itp_raw = Itp(A_vec, x_vec)
            itp_dim = Itp(A_dimvec)
            (; itp_raw, itp_dim)
        end

        @testset "$x" for x in x_vec_dense
            @test isequal(
                itp_raw(x),
                itp_dim(x)
            )
        end

        @testset "Vector Input" begin
            @test isequal(
                itp_raw(x_vec),
                itp_dim(x_vec)
            )
            @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x_vec_wider)
            @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x_vec_left)
            @test_throws DataInterpolations.RightExtrapolationError itp_dim(x_vec_right)
        end
    end

    @testset "Backward `QuadraticInterpolation`" begin
        itp_raw = QuadraticInterpolation(A_vec, x_vec, :Backward)
        itp_dim = QuadraticInterpolation(A_dimvec, :Backward)
        @testset "$x" for x in x_vec
            @test isequal(
                itp_raw(x),
                itp_dim(x)
            )
        end

        @testset "Vector Input" begin
            @test isequal(
                itp_raw(x_vec),
                itp_dim(x_vec)
            )
            @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x_vec_wider)
            @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x_vec_left)
            @test_throws DataInterpolations.RightExtrapolationError itp_dim(x_vec_right)
        end
    end

    @testset "Right `ConstantInterpolation`" begin
        itp_raw = ConstantInterpolation(A_vec, x_vec; dir = :Right)
        itp_dim = ConstantInterpolation(A_dimvec; dir = :Right)
        @testset "$x" for x in x_vec
            @test isequal(
                itp_raw(x),
                itp_dim(x)
            )
        end

        @testset "Vector Input" begin
            @test isequal(
                itp_raw(x_vec),
                itp_dim(x_vec)
            )
            @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x_vec_wider)
            @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x_vec_left)
            @test_throws DataInterpolations.RightExtrapolationError itp_dim(x_vec_right)
        end
    end
end

@testset "Preserves Extrapolation" begin
    @testset "$Xtp" for Xtp in extrapolators
        @testset "$Itp" for Itp in interpolators

            (; itp_raw, itp_dim) = if Itp == BSplineInterpolation
                itp_raw = BSplineInterpolation(
                    A_vec, x_vec, 3, :ArcLen, :Average;
                    extrapolation = Xtp
                )
                itp_dim = BSplineInterpolation(
                    A_dimvec, 3, :ArcLen, :Average;
                    extrapolation = Xtp
                )
                (; itp_raw, itp_dim)

            elseif Itp == CubicHermiteSpline
                itp_raw = CubicHermiteSpline(
                    dA_vec, A_vec, x_vec;
                    extrapolation = Xtp
                )
                itp_dim = CubicHermiteSpline(
                    dA_vec, A_dimvec;
                    extrapolation = Xtp
                )
                (; itp_raw, itp_dim)

            elseif Itp == QuinticHermiteSpline
                itp_raw = QuinticHermiteSpline(
                    ddA_vec, dA_vec, A_vec, x_vec;
                    extrapolation = Xtp
                )
                itp_dim = QuinticHermiteSpline(
                    ddA_vec, dA_vec, A_dimvec;
                    extrapolation = Xtp
                )
                (; itp_raw, itp_dim)

            else
                itp_raw = Itp(
                    A_vec, x_vec;
                    extrapolation = Xtp
                )
                itp_dim = Itp(
                    A_dimvec;
                    extrapolation = Xtp
                )
                (; itp_raw, itp_dim)
            end

            if (Itp, Xtp) == (
                SmoothedConstantInterpolation,
                ExtrapolationType.Linear
            )
                @testset "$x" for x in x_vec_wider
                   if x > maximum(x_vec)
                        @test_broken isequal(
                            itp_raw(x),
                            itp_dim(x)
                        )
                   else
                        @test isequal(
                            itp_raw(x),
                            itp_dim(x)
                        )
                   end

                   @testset "Vector Input" begin
                       @test_broken isequal(
                           itp_raw(x_vec_wider),
                           itp_dim(x_vec_wider)
                       )
                       @test isequal(
                           itp_raw(x_vec_left),
                           itp_dim(x_vec_left)
                       )
                   end
                end

            else
                @testset "$x" for x in x_vec_wider
                    @test isequal(
                        itp_raw(x),
                        itp_dim(x)
                    )
                end

                @testset "Vector Input" begin
                    @test isequal(
                        itp_raw(x_vec_wider),
                        itp_dim(x_vec_wider)
                    )
                end
            end
        end

        @testset "Backward `QuadraticInterpolation`" begin
            itp_raw = QuadraticInterpolation(
                A_vec, x_vec, :Backward;
                extrapolation = Xtp
            )
            itp_dim = QuadraticInterpolation(
                A_dimvec, :Backward;
                extrapolation = Xtp
            )

            @testset "$x" for x in x_vec_wider
                @test isequal(
                    itp_raw(x),
                    itp_dim(x)
                )
            end

            @testset "Vector Inputs" begin
                @test isequal(
                    itp_raw(x_vec_wider),
                    itp_dim(x_vec_wider)
                )
            end
        end

        @testset "Right `ConstantInterpolation`" begin
            itp_raw = ConstantInterpolation(
                A_vec, x_vec; dir = :Right,
                extrapolation = Xtp
            )
            itp_dim = ConstantInterpolation(
                A_dimvec; dir = :Right,
                extrapolation = Xtp
            )

            @testset "$x" for x in x_vec_wider
                @test isequal(
                    itp_raw(x),
                    itp_dim(x)
                )
            end

            @testset "Vector Inputs" begin
                @test isequal(
                    itp_raw(x_vec_wider),
                    itp_dim(x_vec_wider)
                )
            end
        end
    end
end

@testset "Preserves Left Extrapolation" begin
    @testset "$Ext" for Ext in extrapolators
        @testset "$Itp" for Itp in interpolators

            (; itp_raw, itp_dim) = if Itp == BSplineInterpolation
                itp_raw = BSplineInterpolation(
                    A_vec, x_vec, 3, :ArcLen, :Average;
                    extrapolation_left = Ext
                )
                itp_dim = BSplineInterpolation(
                    A_dimvec, 3, :ArcLen, :Average;
                    extrapolation_left = Ext
                )
                (; itp_raw, itp_dim)

            elseif Itp == CubicHermiteSpline
                itp_raw = CubicHermiteSpline(
                    dA_vec, A_vec, x_vec;
                    extrapolation_left = Ext
                )
                itp_dim = CubicHermiteSpline(
                    dA_vec, A_dimvec;
                    extrapolation_left = Ext
                )
                (; itp_raw, itp_dim)

            elseif Itp == QuinticHermiteSpline
                itp_raw = QuinticHermiteSpline(
                    ddA_vec, dA_vec, A_vec, x_vec;
                    extrapolation_left = Ext
                )
                itp_dim = QuinticHermiteSpline(
                    ddA_vec, dA_vec, A_dimvec;
                    extrapolation_left = Ext
                )
                (; itp_raw, itp_dim)

            else
                itp_raw = Itp(
                    A_vec, x_vec;
                    extrapolation_left = Ext
                )
                itp_dim = Itp(
                    A_dimvec;
                    extrapolation_left = Ext
                )
                (; itp_raw, itp_dim)
            end

            @testset "$x" for x in x_vec_wider
                if x > maximum(x_vec)
                    @test_throws DataInterpolations.RightExtrapolationError itp_dim(x)
                else
                    @test isequal(
                        itp_raw(x),
                        itp_dim(x)
                    )
                end
            end

            @testset "Vector Input" begin
                @test_throws DataInterpolations.RightExtrapolationError itp_dim(x_vec_wider)

                @test isequal(
                    itp_raw(x_vec_left),
                    itp_dim(x_vec_left)
                )
            end
        end

        @testset "Backward `QuadraticInterpolation`" begin
            itp_raw = QuadraticInterpolation(
                A_vec, x_vec, :Backward;
                    extrapolation_left = Ext
            )
            itp_dim = QuadraticInterpolation(
                A_dimvec, :Backward;
                    extrapolation_left = Ext
            )

            @testset "$x" for x in x_vec_wider
                if x > maximum(x_vec)
                    @test_throws DataInterpolations.RightExtrapolationError itp_dim(x)
                else
                    @test isequal(
                        itp_raw(x),
                        itp_dim(x)
                    )
                end
            end

            @testset "Vector Input" begin
                @test_throws DataInterpolations.RightExtrapolationError itp_dim(x_vec_wider)

                @test isequal(
                    itp_raw(x_vec_left),
                    itp_dim(x_vec_left)
                )
            end
        end

        @testset "Right `ConstantInterpolation`" begin
            itp_raw = ConstantInterpolation(
                A_vec, x_vec; dir = :Right,
                extrapolation_left = Ext
            )
            itp_dim = ConstantInterpolation(
                A_dimvec; dir = :Right,
                extrapolation_left = Ext
            )

            @testset "$x" for x in x_vec_wider
                if x > maximum(x_vec)
                    @test_throws DataInterpolations.RightExtrapolationError itp_dim(x)
                else
                    @test isequal(
                        itp_raw(x),
                        itp_dim(x)
                    )
                end
            end

            @testset "Vector Input" begin
                @test_throws DataInterpolations.RightExtrapolationError itp_dim(x_vec_wider)

                @test isequal(
                    itp_raw(x_vec_left),
                    itp_dim(x_vec_left)
                )
            end
        end
    end
end

@testset "Preserves Right Extrapolation" begin
    @testset "$Xtp" for Xtp in extrapolators
        @testset "$Itp" for Itp in interpolators

            (; itp_raw, itp_dim) = if Itp == BSplineInterpolation
                itp_raw = BSplineInterpolation(
                    A_vec, x_vec, 3, :ArcLen, :Average;
                    extrapolation_right = Xtp
                )
                itp_dim = BSplineInterpolation(
                    A_dimvec, 3, :ArcLen, :Average;
                    extrapolation_right = Xtp
                )
                (; itp_raw, itp_dim)

            elseif Itp == CubicHermiteSpline
                itp_raw = CubicHermiteSpline(
                    dA_vec, A_vec, x_vec;
                    extrapolation_right = Xtp
                )
                itp_dim = CubicHermiteSpline(
                    dA_vec, A_dimvec;
                    extrapolation_right = Xtp
                )
                (; itp_raw, itp_dim)

            elseif Itp == QuinticHermiteSpline
                itp_raw = QuinticHermiteSpline(
                    ddA_vec, dA_vec, A_vec, x_vec;
                    extrapolation_right = Xtp
                )
                itp_dim = QuinticHermiteSpline(
                    ddA_vec, dA_vec, A_dimvec;
                    extrapolation_right = Xtp
                )
                (; itp_raw, itp_dim)

            else
                itp_raw = Itp(
                    A_vec, x_vec;
                    extrapolation_right = Xtp
                )
                itp_dim = Itp(
                    A_dimvec;
                    extrapolation_right = Xtp
                )
                (; itp_raw, itp_dim)
            end

            if (Itp, Xtp) == (
                SmoothedConstantInterpolation,
                ExtrapolationType.Linear
            )
                @testset "$x" for x in x_vec_wider
                   if x < minimum(x_vec)
                       @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x)
                   elseif x > maximum(x_vec)
                        @test_broken isequal(
                            itp_raw(x),
                            itp_dim(x)
                        )
                   else
                        @test isequal(
                            itp_raw(x),
                            itp_dim(x)
                        )
                   end

                end

                @testset "Vector Input" begin
                    @test_broken isequal(
                       itp_raw(x_vec_right),
                       itp_dim(x_vec_right)
                       )
                end

            else
                @testset "$x" for x in x_vec_wider
                    if x < minimum(x_vec)
                        @test_throws DataInterpolations.LeftExtrapolationError itp_raw(x)
                        @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x)
                    else
                        @test isequal(
                            itp_raw(x),
                            itp_dim(x)
                        )
                    end
                end

                @testset "Vector Input" begin
                    @test_throws DataInterpolations.LeftExtrapolationError itp_raw(x_vec_wider)
                    @test isequal(
                        itp_raw(x_vec_right),
                        itp_dim(x_vec_right)
                    )
                end
            end
        end

        @testset "Backward `QuadraticInterpolation`" begin
            itp_raw = QuadraticInterpolation(
                A_vec, x_vec, :Backward;
                    extrapolation_right = Xtp
            )
            itp_dim = QuadraticInterpolation(
                A_dimvec, :Backward;
                    extrapolation_right = Xtp
            )

            @testset "$x" for x in x_vec_wider
                if x < minimum(x_vec)
                    @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x)
                else
                    @test isequal(
                        itp_raw(x),
                        itp_dim(x)
                    )
                end
            end

            @testset "Vector Input" begin
                @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x_vec_wider)

                @test isequal(
                    itp_raw(x_vec_right),
                    itp_dim(x_vec_right)
                )
            end
        end

        @testset "Right `ConstantInterpolation`" begin
            itp_raw = ConstantInterpolation(
                A_vec, x_vec; dir = :Right,
                extrapolation_right = Xtp
            )
            itp_dim = ConstantInterpolation(
                A_dimvec; dir = :Right,
                extrapolation_right = Xtp
            )

            @testset "$x" for x in x_vec_wider
                if x < minimum(x_vec)
                    @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x)
                else
                    @test isequal(
                        itp_raw(x),
                        itp_dim(x)
                    )
                end
            end

            @testset "Vector Input" begin
                @test_throws DataInterpolations.LeftExtrapolationError itp_dim(x_vec_wider)

                @test isequal(
                    itp_raw(x_vec_right),
                    itp_dim(x_vec_right)
                )
            end
        end
    end
end

@testset "Preserves Mixed Extrapolation" begin
    @testset "$XtpLeft" for XtpLeft in extrapolators
        @testset "$XtpRight" for XtpRight in extrapolators
            @testset "$Itp" for Itp in interpolators

                (; itp_raw, itp_dim) = if Itp == BSplineInterpolation
                    itp_raw = BSplineInterpolation(
                        A_vec, x_vec, 3, :ArcLen, :Average;
                        extrapolation_left = XtpLeft,
                        extrapolation_right = XtpRight
                    )
                    itp_dim = BSplineInterpolation(
                        A_dimvec, 3, :ArcLen, :Average;
                        extrapolation_left = XtpLeft,
                        extrapolation_right = XtpRight
                    )
                    (; itp_raw, itp_dim)

                elseif Itp == CubicHermiteSpline
                    itp_raw = CubicHermiteSpline(
                        dA_vec, A_vec, x_vec;
                        extrapolation_left = XtpLeft,
                        extrapolation_right = XtpRight
                    )
                    itp_dim = CubicHermiteSpline(
                        dA_vec, A_dimvec;
                        extrapolation_left = XtpLeft,
                        extrapolation_right = XtpRight
                    )
                    (; itp_raw, itp_dim)

                elseif Itp == QuinticHermiteSpline
                    itp_raw = QuinticHermiteSpline(
                        ddA_vec, dA_vec, A_vec, x_vec;
                        extrapolation_left = XtpLeft,
                        extrapolation_right = XtpRight
                    )
                    itp_dim = QuinticHermiteSpline(
                        ddA_vec, dA_vec, A_dimvec;
                        extrapolation_left = XtpLeft,
                        extrapolation_right = XtpRight
                    )
                    (; itp_raw, itp_dim)

                else
                    itp_raw = Itp(
                        A_vec, x_vec;
                        extrapolation_left = XtpLeft,
                        extrapolation_right = XtpRight
                    )
                    itp_dim = Itp(
                        A_dimvec;
                        extrapolation_left = XtpLeft,
                        extrapolation_right = XtpRight
                    )
                    (; itp_raw, itp_dim)
                end

                @testset "$x" for x in x_vec_wider
                    if (Itp, XtpRight) == (
                        SmoothedConstantInterpolation,
                        ExtrapolationType.Linear
                    ) && x > maximum(x_vec)
                        @test_broken isequal(
                            itp_raw(x),
                            itp_dim(x)
                        )
                    else
                        @test isequal(
                            itp_raw(x),
                            itp_dim(x)
                        )
                    end
                end

                if (Itp, XtpRight) == (
                        SmoothedConstantInterpolation,
                        ExtrapolationType.Linear
                    )
                    @testset "$x" for x in x_vec_wider
                        if x > maximum(x_vec)
                            @test_broken isequal(
                                itp_raw(x),
                                itp_dim(x)
                            )
                        else
                            @test isequal(
                                itp_raw(x),
                                itp_dim(x)
                            )
                        end
                    end

                    @testset "Vector Input" begin
                        @test_broken itp_dim(x_vec_wider)

                        @test isequal(
                            itp_raw(x_vec_left),
                            itp_dim(x_vec_left)
                        )
                    end

                else
                    @testset "$x" for x in x_vec_wider
                        @test isequal(
                            itp_raw(x),
                            itp_dim(x)
                        )
                    end

                    @testset "Vector Input" begin
                        @test isequal(
                            itp_raw(x_vec_wider),
                            itp_dim(x_vec_wider)
                        )
                    end
                end
            end

            @testset "Backward `QuadraticInterpolation`" begin
                itp_raw = QuadraticInterpolation(
                    A_vec, x_vec, :Backward;
                    extrapolation_left = XtpLeft,
                    extrapolation_right = XtpRight
                )
                itp_dim = QuadraticInterpolation(
                    A_dimvec, :Backward;
                    extrapolation_left = XtpLeft,
                    extrapolation_right = XtpRight
                )

                @testset "$x" for x in x_vec_wider
                    @test isequal(
                        itp_raw(x),
                        itp_dim(x)
                    )
                end

                @testset "Vector Input" begin
                    @test isequal(
                        itp_raw(x_vec_wider),
                        itp_dim(x_vec_wider)
                    )
                end
            end

            @testset "Right `ConstantInterpolation`" begin
                itp_raw = ConstantInterpolation(
                    A_vec, x_vec; dir = :Right,
                    extrapolation_left = XtpLeft,
                    extrapolation_right = XtpRight
                )
                itp_dim = ConstantInterpolation(
                    A_dimvec; dir = :Right,
                    extrapolation_left = XtpLeft,
                    extrapolation_right = XtpRight
                )

                @testset "$x" for x in x_vec_wider
                    @test isequal(
                        itp_raw(x),
                        itp_dim(x)
                    )
                end

                @testset "Vector Input" begin
                    @test isequal(
                        itp_raw(x_vec_wider),
                        itp_dim(x_vec_wider)
                    )
                end
            end
        end
    end
end
