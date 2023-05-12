@enum OptionType begin
    Put
    Call
end

struct Option{T<:Real}
    strikeprice::T
    currentprice::T
    type::OptionType
end

function profit(o::Option)
    if o.type == Put
        max(0, o.strikeprice - o.currentprice)
    elseif o.type == Call
        max(0, o.currentprice - o.strikeprice)
    end
end

function profit(portfolio::Vector{Option{T}}) where T <: Real
    (profit.(portfolio))
end

import Base:*,+

*(coeff, o::Option) = Option(coeff * o.strikeprice, coeff * o.currentprice, o.type)
*(o::Option, coeff) = coeff * o


import Plots

referencePrice = 100 # 
optioncost = 20
profitline = vcat(
    profit.([Option(exercisePrice, price, Put) for price in 1:exercisePrice]),
    profit.([Option(price, price, Put) for price in (exercisePrice+1):(exercisePrice + 20)]),
    profit.([Option(exercisePrice, price, Call) for price in (exercisePrice + 1):(exercisePrice + 100)])
)

Plots.plot(
    1:length(profitline),
    [profitline profitline .- optioncost],
    labels=["Price at Sale" "Profit"],
    linecolors=[:blue :green],
    title="The Strangle Hedge",
)


