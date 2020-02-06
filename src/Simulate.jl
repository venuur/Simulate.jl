module Simulate

using StructArrays
using RecipesBase

export simulate, gethistory

## API
function simulate(step!, init, data, periods; verbose = false)
    log = Log(init, periods)
    state = deepcopy(init)
    for i = 2:(periods+1)
        verbose && println(state)
        step!(state, data)
        log[i] = deepcopy(state)
    end
    verbose && println(state)
    return log
end


## Simulation log object
struct Log
    history

    function Log(init, periods)
        history = StructArray{typeof(init)}(undef, periods + 1)
        history[1] = deepcopy(init)
        return new(history)
    end
end

# Accessors
gethistory(log) = log.history
Base.setindex!(log::Log, v, i) = log.history[i] = v

## Log visualization
@recipe function f(log::Log, x::Symbol, ys::Vector{Symbol})
    history = gethistory(log)
    xv = getproperty(history, x)
    for name in ys
        @series (xv, getproperty(history, name))
    end
end

end # module
