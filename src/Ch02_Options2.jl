@enum OptionType begin
    Put
    Call
end

struct Option{T<:Real}
    exercisePrice::T
    ticker::Base.Symbol
    type::OptionType
end
C(exercisePrice, symbol) = Option(exercisePrice, symbol, Call)
Option(exercisePrice, symbol) = C(exercisePrice, symbol)
P(exercisePrice, symbol) = Option(exercisePrice, symbol, Put)

prices = 50:.5:200 # prices at exercise time
referenceExercisePrice = 60


function profit(option::Option, priceAtExerciseTime)
    if option.type == Call
        max(0, priceAtExerciseTime - option.exercisePrice)
    else # option.type == Put
        max(0, option.exercisePrice - priceAtExerciseTime)
    end
end

import Base:*,+,-

struct MultiOption{T<:Real}
    coeff::Int
    option::Option{T}
    # exercisePrice=option.exercisePrice*coeff
end

# the following line is cool but not what I'm looking for.
# *(coeff, o::Option) = MultiOption(convert(typeof(o.exercisePrice), coeff), o)
*(coeff::Int, o::Option) = MultiOption(coeff, o)
*(o::Option, coeff) = coeff * o
-(o::Option) = -1 * o
-(mo::MultiOption) = MultiOption(-mo.coeff, mo.option)

"""
A portfolio representation that doesn't have a cost for a given option.
Meant for toy modeling
"""
struct FreePortfolio
    options::Vector{MultiOption}
    """
    FreePortfolio(mos...)

    You can construct a FreePortfolio from discrete `MultiOption`s
    """
    function FreePortfolio(mos...)
        new([mos...])
    end
end

profit(mo::MultiOption, priceAtExerciseTime) = mo.coeff * profit(mo.option, priceAtExerciseTime)

"""
    profitcurve(option::Option, pricesequence)

Computes the profit from an `option`, given prices `pricesequence`.
"""
function profitcurve(option::Option, pricesequence)
    # alt: profit.((o,), pricesequence) # written as below to be explicit
    broadcast(profit, (option,), pricesequence)
end

"""
    profitcurve(port::FreePortfolio, pricesequence)

Computes the profit from a portfolio of cost-free `Option`s.

See also
========
`profit`: for the underlying computation
"""
function profitcurve(port::FreePortfolio, pricesequence)
    # hcat([profit.((o,), pricesequence) for o in port.options]...)
    # using reduce because the docs recommend. These spreads   ^^^ tend to be expensive
    # while `reduce` is tail-optimized
    mat = reduce(hcat,[profit.((o,), pricesequence) for o in port.options])
    
    # sum(mat, dims=2) -> 1xN
    # vec(^^^) -> N-long column vector
    vec(sum(mat, dims=2))
end
o = Option(referenceExercisePrice, :StockToTrack)

curve = profitcurve(o, prices)

# This portfolio is the Call-only construction of the toy curve in the text book (Figure 2.8)
toyportfolio = FreePortfolio(
    -2C(50, :S), 2C(70, :S), 3C(90, :S), -C(110, :S), -2C(120, :S)
)

prices = 30:.5:150
curve = profitcurve(toyportfolio, prices)

using Plots

myplot = plot(
    prices,
    curve
)

#=
Now to do the same with the portfolio

Because I've been able to produce the computation, from nothing, I feel a greater confidence than I did before.
Because I've drawn the figure from the book, with atoms I've constructed, I feel powerful and competent.
Because I've found a way to computerize the handheld computations in a way that I won't err, I am more able to do
  the work of a professional.
=#