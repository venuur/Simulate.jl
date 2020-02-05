module ExInventory

using Simulate
using Parameters
using DataStructures

export simulate_constant_basestock

struct OpenOrder
    amount
    arrival_time
end

@with_kw mutable struct InventoryState
    time = 0
    onhand = 0
    inflight = 0
    open_orders = Dict()  # OpenOrder.arrival_time => OpenOrder
    sales = 0
    lost = 0
    backordered = 0
end

struct InventoryData
    demand
    leadtime
    get_order!
end

function backorder_inv_step!(state, data)
    state.time += 1

    # Handle arriving orders
    if haskey(state.open_orders, state.time)
        next_open_order = state.open_orders[state.time]
        # Order has arrived.
        state.onhand += next_open_order.amount
        delete!(state.open_orders, state.time)
        state.inflight -= next_open_order.amount
    end

    # Determine order prior to  sales arrival
    to_order = data.get_order!(state)
    if to_order > 0
        leadtime = data.leadtime[state.time]
        new_order = OpenOrder(to_order, state.time + leadtime)
        if haskey(state.open_orders, new_order.arrival_time)
            existing_order = state.open_orders[new_order.arrival_time]
            state.open_orders[new_order.arrival_time] = OpenOrder(
                existing_order.amount + new_order.amount,
                new_order.arrival_time,
            )
        else
            state.open_orders[new_order.arrival_time] = new_order
        end
        state.inflight += to_order
    end

    # Process arriving demand
    demand = data.demand[state.time]
    state.sales = min(state.onhand, demand)
    state.backordered += max(demand - state.onhand, 0)
    state.backordered = max(state.backordered - state.sales, 0)
    state.onhand = max(state.onhand - demand, 0)

    # No lost sales in this simulation.
end

struct ConstantBasestockPolicy
    order_upto
end

(p::ConstantBasestockPolicy)(state) = p.order_upto - state.onhand - state.inflight

function simulate_constant_basestock(init_inv, basestock, demand, leadtime; kwargs...)
    @assert length(demand) == length(leadtime)
    data = InventoryData(demand, leadtime, ConstantBasestockPolicy(basestock))
    init = InventoryState(onhand = init_inv)
    periods = length(demand)
    return simulate(backorder_inv_step!, init, data, periods; kwargs...)
end


end # module
