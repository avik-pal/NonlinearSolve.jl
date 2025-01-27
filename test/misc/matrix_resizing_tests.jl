@testitem "Out-of-place Matrix Resizing" begin
    using StableRNGs

    ff(u, p) = u .* u .- p
    u0 = rand(StableRNG(0), 2, 2)
    p = 2.0
    vecprob = NonlinearProblem(ff, vec(u0), p)
    prob = NonlinearProblem(ff, u0, p)

    for alg in (NewtonRaphson(), TrustRegion(), LevenbergMarquardt(),
        PseudoTransient(), RobustMultiNewton(), FastShortcutNonlinearPolyalg(), Broyden(),
        Klement(), LimitedMemoryBroyden(; threshold = 2))
        @test vec(solve(prob, alg).u) == solve(vecprob, alg).u
    end
end

@testitem "Inplace Matrix Resizing" begin
    using StableRNGs

    fiip(du, u, p) = (du .= u .* u .- p)
    u0 = rand(StableRNG(0), 2, 2)
    p = 2.0
    vecprob = NonlinearProblem(fiip, vec(u0), p)
    prob = NonlinearProblem(fiip, u0, p)

    for alg in (NewtonRaphson(), TrustRegion(), LevenbergMarquardt(),
        PseudoTransient(), RobustMultiNewton(), FastShortcutNonlinearPolyalg(), Broyden(),
        Klement(), LimitedMemoryBroyden(; threshold = 2))
        @test vec(solve(prob, alg).u) == solve(vecprob, alg).u
    end
end
