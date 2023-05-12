# module Options

"""

Representation of an Option that would be purchased, traded, and/or acted upon
in financial markets. More useful with functions.
If a `Symbol` is required, it will be either `:Call` or `:Put`, to express the
form of usage.
May convert to (https://docs.julialang.org/en/v1/base/base/#Base.Enums.Enum) later
"""
struct Option{T<:Real}
    strike_price::T
    current_price::T
end

function profit(o::Option, s::Symbol)
    if s == :Call
        return max(0, o.current_price - o.strike_price)
    elseif s == :Put
        return max(0, o.strike_price - o.current_price)
    end
end

struct Portfolio{T<:Real}
    Call::Option{T}
    Put::Option{T}

    Portfolio(o::Option{T}) where T <:Real = new{T}(o, o)
end


function profit(p::Portfolio)
    return max(profit(p.Call, :Call), profit(p.Put, :Put))
end

# end

import Plots

#=
Plotting the profit curve for a fixed option cast, but a variable strick / exercise price.
=#

exerciseprices = 1:200

optioncost = 15

profitline = profit.([Option(ex, 120) for ex in exerciseprices], :Call)

Plots.plot(
    exerciseprices,
    [profitline profitline .- optioncost],
    labels=["Profit" "(Reasonable) Option Cost"],
    linecolors=[:blue :green],
    title="When shouldn't you buy an option"
)


#=
Repeating the profit curve-plotting from above, this time for a variety of realized prices.
This shows how things vary with the value of the stock at the time of (optional) purchase.
=#
exercisePrice = 100
currentprices = 1:200

optioncost = 20

profitline = profit.([Option(exercisePrice, c) for c in currentprices], :Call)

Plots.plot(
    currentprices,
    [profitline profitline .- optioncost],
    labels=["Profit" "(Reasonable) Option Cost"],
    linecolors=[:blue :green],
    title="When should you buy an option"
)


#=
We now do the same thing, but for a Put
=#

# Option = Options.Option
profitline = profit.([Option(exercisePrice, c) for c in currentprices], :Put)

Plots.plot(
    currentprices,
    [profitline profitline .- optioncost],
    labels=["Price at Sale" "Profit"],
    linecolors=[:blue :green],
    title="When should you buy an option"
)


#=
Plotting the straddle hedging strategy
=#

profitline = profit.(Portfolio.([Option(exercisePrice, cp) for cp in currentprices]))
Plots.plot(
    currentprices,
    [profitline profitline .- optioncost],
    labels=["Price at Sale" "Profit"],
    linecolors=[:blue :green],
    title="The Straddle Hedge",
)

#=
Attempting to draw the strangle strategy
=#
exercisePrice = 100

profitline = vcat(
    profit.(Portfolio.([Option(exercisePrice, cp) for cp in 1:exercisePrice])),
    profit.(Portfolio.([Option(exercisePrice + 10, cp) for cp in (exercisePrice+1):(exercisePrice + 20)])),
    profit.(Portfolio.([Option(exercisePrice + 10, cp) for cp in (exercisePrice + 21):(exercisePrice + 100)]))
)

Plots.plot(
    1:length(profitline),
    [profitline profitline .- optioncost],
    labels=["Price at Sale" "Profit"],
    linecolors=[:blue :green],
    title="The Strangle Hedge",
)

