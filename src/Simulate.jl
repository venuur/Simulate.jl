module Simulate

using StructArrays

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
function Log(init, periods)
    log = StructArray{typeof(init)}(undef, periods + 1)
    log[1] = deepcopy(init)
    return log
end

# Accessors
gethistory(log) = log

end # module
