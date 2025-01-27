@testsetup module WrapperRootfindImports
using Reexport
@reexport using LinearAlgebra, NLsolve, SIAMFANLEquations, MINPACK
end

@testitem "Steady State Problems" setup=[WrapperRootfindImports] begin
    # IIP Tests
    function f_iip(du, u, p, t)
        du[1] = 2 - 2u[1]
        du[2] = u[1] - 4u[2]
    end
    u0 = zeros(2)
    prob_iip = SteadyStateProblem(f_iip, u0)

    for alg in [NLsolveJL(), CMINPACK(), SIAMFANLEquationsJL()]
        sol = solve(prob_iip, alg)
        @test SciMLBase.successful_retcode(sol.retcode)
        @test maximum(abs, sol.resid) < 1e-6
    end

    # OOP Tests
    f_oop(u, p, t) = [2 - 2u[1], u[1] - 4u[2]]
    u0 = zeros(2)
    prob_oop = SteadyStateProblem(f_oop, u0)

    for alg in [NLsolveJL(), CMINPACK(), SIAMFANLEquationsJL()]
        sol = solve(prob_oop, alg)
        @test SciMLBase.successful_retcode(sol.retcode)
        @test maximum(abs, sol.resid) < 1e-6
    end
end

@testitem "Nonlinear Root Finding Problems" setup=[WrapperRootfindImports] begin
    # IIP Tests
    function f_iip(du, u, p)
        du[1] = 2 - 2u[1]
        du[2] = u[1] - 4u[2]
    end
    u0 = zeros(2)
    prob_iip = NonlinearProblem{true}(f_iip, u0)

    for alg in [NLsolveJL(), CMINPACK(), SIAMFANLEquationsJL()]
        local sol
        sol = solve(prob_iip, alg)
        @test SciMLBase.successful_retcode(sol.retcode)
        @test maximum(abs, sol.resid) < 1e-6
    end

    # OOP Tests
    f_oop(u, p) = [2 - 2u[1], u[1] - 4u[2]]
    u0 = zeros(2)
    prob_oop = NonlinearProblem{false}(f_oop, u0)
    for alg in [NLsolveJL(), CMINPACK(), SIAMFANLEquationsJL()]
        local sol
        sol = solve(prob_oop, alg)
        @test SciMLBase.successful_retcode(sol.retcode)
        @test maximum(abs, sol.resid) < 1e-6
    end

    # Tolerance Tests
    f_tol(u, p) = u^2 - 2
    prob_tol = NonlinearProblem(f_tol, 1.0)
    for tol in [1e-1, 1e-3, 1e-6, 1e-10, 1e-15],
        alg in [NLsolveJL(), CMINPACK(), SIAMFANLEquationsJL(; method = :newton),
            SIAMFANLEquationsJL(; method = :pseudotransient),
            SIAMFANLEquationsJL(; method = :secant)]

        sol = solve(prob_tol, alg, abstol = tol)
        @test abs(sol.u[1] - sqrt(2)) < tol
    end

    f_jfnk(u, p) = u^2 - 2
    prob_jfnk = NonlinearProblem(f_jfnk, 1.0)
    for tol in [1e-1, 1e-3, 1e-6, 1e-10, 1e-11]
        sol = solve(prob_jfnk, SIAMFANLEquationsJL(linsolve = :gmres), abstol = tol)
        @test abs(sol.u[1] - sqrt(2)) < tol
    end

    # Test the finite differencing technique
    function f!(fvec, x, p)
        fvec[1] = (x[1] + 3) * (x[2]^3 - 7) + 18
        fvec[2] = sin(x[2] * exp(x[1]) - 1)
    end

    prob = NonlinearProblem{true}(f!, [0.1; 1.2])
    sol = solve(prob, NLsolveJL(autodiff = :central))
    @test maximum(abs, sol.resid) < 1e-6
    sol = solve(prob, SIAMFANLEquationsJL())
    @test maximum(abs, sol.resid) < 1e-6

    # Test the autodiff technique
    sol = solve(prob, NLsolveJL(autodiff = :forward))
    @test maximum(abs, sol.resid) < 1e-6

    # Custom Jacobian
    f_custom_jac!(F, u, p) = (F[1:152] = u .^ 2 .- p)
    j_custom_jac!(J, u, p) = (J[1:152, 1:152] = diagm(2 .* u))

    init = ones(152)
    A = ones(152)
    A[6] = 0.8

    f = NonlinearFunction(f_custom_jac!; jac = j_custom_jac!)
    p = A

    ProbN = NonlinearProblem(f, init, p)

    sol = solve(ProbN, NLsolveJL(); abstol = 1e-8)
    @test maximum(abs, sol.resid) < 1e-6
    sol = solve(ProbN, SIAMFANLEquationsJL(; method = :newton); abstol = 1e-8)
    @test maximum(abs, sol.resid) < 1e-6
    sol = solve(ProbN, SIAMFANLEquationsJL(; method = :pseudotransient); abstol = 1e-8)
    @test maximum(abs, sol.resid) < 1e-6
end
