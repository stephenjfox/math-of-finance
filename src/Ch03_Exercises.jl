# Evaluating my Taylor approximation of cosine around x = π
my_cos(x; p) = cos(p) - 0.5 * cos(p) * (x - p)^2 + (cos(p) * (x - p)^4) / 24

function evaluatemycos()
    radius_stream = (pi - 1):0.05:(pi + 1)
    truth = radius_stream .|> cos
    pred  = my_cos.(radius_stream, p=pi)

    truth - pred

    @assert isapprox(abs(cos(pi - 0.1) - my_cos(pi - 0.1, p=pi)), 0, atol=1e-8)
end

"""
    dumbtrapintegral(t; f, lowerbound=-200, stepsize=0.1)

A working implementation of the trapezoid rule for integration,
tested against a Gaussian PDF, CDF, and the integral of x²
"""
function dumbtrapintegral(t; f, lowerbound=-200, stepsize=0.1)
    Δx2 = stepsize / 2
    steps = lowerbound:stepsize:t
    evaluated = f.(steps)
    s = 0.
    for (f_x_0, f_x_1) in zip(evaluated[1: length(evaluated)-1], evaluated[2:end])
        s += Δx2*(f_x_0 + f_x_1)
    end
    return s
end

# Tests:
# 1. The normal distribution
@assert dumbtrapintegral(0, f=x -> 1/sqrt(2pi) * exp(-(x^2)/2)) ≈ 0.5 # == 0.5000000000000001 on my machine 

# 2. Expectation of pdf f(x) = 2x on random variable X(x) = x
@assert 2 * dumbtrapintegral(1, f=(x->x^2), lowerbound=0) |> rationalize == 67//100

# Factor out a function, let the compiler do the heavy lifting
dumbnormaleval(zscore) = dumbtrapintegral(zscore, f=x -> 1/sqrt(2pi) * exp(-(x^2)/2), stepsize=0.05)

# 3. Normal distribution with higher precision
@assert dumbnormaleval(0) == 0.5

# 4. two standard deviations should how ≈ 95% of the data. Let's check
@assert dumbnormaleval(2) - dumbnormaleval(-2) ≈ 0.9544547455072381

#= Exercise 3.8.
    What is the probability that the sum of 100 rolls of this random variable is between 0 and 50?
        PDF f(x) = Cx if x ∈ [0, 1] else 0
    and random variable X(x) = x specifying a game outcome
=#
@assert isapprox(dumbnormaleval((50 - 200//3) / sqrt(100//18)), 6e-13, atol=1e-13)
# in other words, you have no chance to get the expectation ∈ [0, 50] if you play this game 100 times.
# More on this to follow

import Statistics: mean


"""
    summary_stats(xs)

    Just fiddling a little: if I draw from the uniform distribution U[0, 1] n-times (say 100) and sum,
    what's the distribution on those results?
    Do they concur with the theoretical result I have, or do they suggest that I did something wrong?
"""
function summary_stats(xs)
    xs = vec(xs)
    μ = mean(xs)
    σ = sqrt(mean((xs .- μ).^2))
    (μ=μ, σ=σ)
end

# below is a look at (10^k)*∫x^2 dx, by sampling, for values of k ∈ [2, 3, 4]
sum(rand(Float32, (100, 100))    .^2, dims=1) |> summary_stats
sum(rand(Float32, (1000, 1000))  .^2, dims=1) |> summary_stats
sum(rand(Float64, (10000, 10000)).^2, dims=1) |> summary_stats
# Results:
# (μ = 33.1535f0,           σ = 3.3111968f0)
# (μ = 333.68414f0,         σ = 9.655513f0)
# (μ = 3333.351690553022,   σ = 29.94195021802331)

# doubling those agrees with our computation.

# Walking through Exercise 3.8, again.
function exercise3_8_stepbywise()
    @assert dumbtrapintegral(1, f=(x->2x), lowerbound=0) == 1
    # so the PDF is correct

    # reconsidering the expectation
    E_Xᵢ = dumbtrapintegral(1, f=(x->2x^2), lowerbound=0, stepsize=1//200)
    @assert round(E_Xᵢ, digits=2) == 0.67
    # E[Xᵢ] = ∫₀¹ (pdf(p) ⋅ X(p)) dp = ∫ (2p ⋅ p) dp = 2∫p² dp = 2 ⋅ [p³/3] -> 2/3 on the interval [0, 1]
    # E[Y₁₀₀] = E[100 Xᵢ] = 100 E[Xᵢ] = 100 ⋅ 2/3 ≈ 66.666666667 ≠ 50, as we'd expect from (a) intuition (2) empirical inspection
    E_Y₁₀₀ = 100 * E_Xᵢ

    E_Xᵢ² = 2*dumbtrapintegral(1, f=(x->x^3), lowerbound=0, stepsize=1//100) |> rationalize

    Var_X = E_Xᵢ² - E_Xᵢ^2

    @assert round(Var_X * 18, digits=2) == 1 # Var_X ≈ 1//18

    Var_Y₁₀₀ = 100 * Var_X

    ⎷Var_Y₁₀₀ = √(Var_Y₁₀₀)

    # Towards
    # Z_100 ≤ (50 - E[Y₁₀₀]) / ⎷Var_Y₁₀₀
    Z₁₀₀ꜛ = (50 - E_Y₁₀₀) / ⎷Var_Y₁₀₀ # about -7σ...

    dumbnormaleval(Z₁₀₀ꜛ) < 6e-12 # basically zero, so worry about the lowerbound.
end

# per the breakdown in Chapter 4, it should be handled slightly differently

"""
    probwithinrange(; a, b)


Computes probability of being with range `[a, b]`, where
`a`, `b` are lower- and upperbounds of the integral of the Gaussian distribution
"""
function probwithinrange(; a, b)
    1/sqrt(2pi) * dumbtrapintegral(b, lowerbound=a, f=x -> exp(-(x^2)/2), stepsize=0.01)
end

@assert probwithinrange(a=-2, b=2) - 0.9545 < 1e-5

# let's do the normalization operations on the bounds and see what happens
bounds = @. ([0, 50] - E_Y₁₀₀) / ⎷Var_Y₁₀₀
# result:
# [-28.27473039410145, -7.068947670809405]

@assert isapprox(probwithinrange(a=bounds[1], b=bounds[2]), 0, atol=1e-12)
# Not a snowball's chance in hell that you're mean would be between 0 and 50...

export probwithinrange, dumbtrapintegral