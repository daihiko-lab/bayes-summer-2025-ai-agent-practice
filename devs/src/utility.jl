"""
SeatingSimulation.jl - 効用計算システム

エージェントの効用計算と最適化ロジック
"""

using Statistics

"""
個々のエージェントの効用を計算

引数:
- agent_id: エージェントID (1-num_agents)
- state: 現在の座席配置
- relationships: 関係性行列 (num_agents×num_agents)
- desires: 欲求パラメータ

戻り値: エージェントの総効用値
"""
function calculate_agent_utility(agent_id::Int, 
                               state::SeatingState,
                               relationships::Matrix{Float64}, 
                               desires::DesireParams)::Float64
    @assert 1 <= agent_id <= state.num_agents "agent_id must be in range 1-$(state.num_agents)"
    @assert size(relationships) == (state.num_agents, state.num_agents) "relationships must be $(state.num_agents)x$(state.num_agents) matrix"
    
    # 隣接エージェントを取得
    adjacent_agents = get_adjacent_agents_by_id(agent_id, state)
    
    # 隣接エージェントがいない場合は効用0
    if isempty(adjacent_agents)
        return 0.0
    end
    
    close_satisfaction = 0.0
    explore_satisfaction = 0.0
    
    for neighbor_id in adjacent_agents
        rel_strength = relationships[agent_id, neighbor_id]
        
        # 仲が良い場合（閾値0.5以上）: close欲求による満足度
        if rel_strength >= 0.5
            close_satisfaction += desires.close * rel_strength
        else  # 仲があまり良くない場合: explore欲求による満足度
            explore_satisfaction += desires.explore * (1.0 - rel_strength)
        end
    end
    
    return close_satisfaction + explore_satisfaction
end

"""
座席配置全体の総効用を計算

引数:
- state: 座席配置
- relationships: 関係性行列 (num_agents×num_agents)  
- desires: 欲求パラメータ

戻り値: 全エージェントの効用の合計
"""
function calculate_total_utility(state::SeatingState,
                               relationships::Matrix{Float64},
                               desires::DesireParams)::Float64
    @assert size(relationships) == (state.num_agents, state.num_agents) "relationships must be $(state.num_agents)x$(state.num_agents) matrix"
    
    total_utility = 0.0
    
    for agent_id in 1:state.num_agents
        agent_utility = calculate_agent_utility(agent_id, state, relationships, desires)
        total_utility += agent_utility
    end
    
    return total_utility
end

"""
エージェントが空席に移動した場合の効用変化を計算

引数:
- state: 現在の座席配置
- agent_id: 移動するエージェントID
- relationships: 関係性行列
- desires: 欲求パラメータ

戻り値: 効用変化量（正なら改善、負なら悪化）
"""
function calculate_utility_change(state::SeatingState,
                                agent_id::Int,
                                relationships::Matrix{Float64},
                                desires::DesireParams)::Float64
    @assert 1 <= agent_id <= state.num_agents "agent_id must be in range 1-$(state.num_agents)"
    @assert size(relationships) == (state.num_agents, state.num_agents) "relationships must be $(state.num_agents)x$(state.num_agents) matrix"
    
    # 現在の総効用
    current_utility = calculate_total_utility(state, relationships, desires)
    
    # エージェントを空席に移動した新しい状態
    new_state = move_agent_to_empty_seat(state, agent_id)
    
    # 新しい状態での総効用
    new_utility = calculate_total_utility(new_state, relationships, desires)
    
    # 効用変化量
    return new_utility - current_utility
end

"""
最も効用改善効果の高いエージェントと移動量を探索

引数:
- state: 現在の座席配置
- relationships: 関係性行列
- desires: 欲求パラメータ

戻り値: (best_agent_id, best_utility_gain)
- best_agent_id: 最適移動エージェントID（改善がない場合はnothing）
- best_utility_gain: 最大効用改善量（改善がない場合は0以下）
"""
function find_best_move(state::SeatingState,
                       relationships::Matrix{Float64},
                       desires::DesireParams)::Tuple{Union{Int, Nothing}, Float64}
    @assert size(relationships) == (state.num_agents, state.num_agents) "relationships must be $(state.num_agents)x$(state.num_agents) matrix"
    
    best_agent = nothing
    best_gain = 0.0
    
    for agent_id in 1:state.num_agents
        utility_change = calculate_utility_change(state, agent_id, relationships, desires)
        
        if utility_change > best_gain
            best_gain = utility_change
            best_agent = agent_id
        end
    end
    
    return best_agent, best_gain
end

"""
座席配置の効用詳細分析（デバッグ用）

引数:
- state: 座席配置
- relationships: 関係性行列
- desires: 欲求パラメータ

戻り値: 各エージェントの効用詳細を含むNamedTuple
"""
function analyze_utility_breakdown(state::SeatingState,
                                 relationships::Matrix{Float64},
                                 desires::DesireParams)::NamedTuple
    @assert size(relationships) == (state.num_agents, state.num_agents) "relationships must be $(state.num_agents)x$(state.num_agents) matrix"
    
    agent_utilities = Float64[]
    agent_close_satisfactions = Float64[]
    agent_explore_satisfactions = Float64[]
    agent_neighbor_counts = Int[]
    
    for agent_id in 1:state.num_agents
        adjacent_agents = get_adjacent_agents_by_id(agent_id, state)
        neighbor_count = length(adjacent_agents)
        
        close_satisfaction = 0.0
        explore_satisfaction = 0.0
        
        for neighbor_id in adjacent_agents
            rel_strength = relationships[agent_id, neighbor_id]
            
            if rel_strength >= 0.5
                close_satisfaction += desires.close * rel_strength
            else
                explore_satisfaction += desires.explore * (1.0 - rel_strength)
            end
        end
        
        total_utility = close_satisfaction + explore_satisfaction
        
        push!(agent_utilities, total_utility)
        push!(agent_close_satisfactions, close_satisfaction)
        push!(agent_explore_satisfactions, explore_satisfaction)
        push!(agent_neighbor_counts, neighbor_count)
    end
    
    return (
        total_utility = sum(agent_utilities),
        agent_utilities = agent_utilities,
        close_satisfactions = agent_close_satisfactions,
        explore_satisfactions = agent_explore_satisfactions,
        neighbor_counts = agent_neighbor_counts,
        mean_utility = sum(agent_utilities) / state.num_agents,
        utility_std = std(agent_utilities)
    )
end

"""
効用分析結果の表示（デバッグ用）
"""
function display_utility_analysis(state::SeatingState,
                                relationships::Matrix{Float64},
                                desires::DesireParams)
    @assert size(relationships) == (state.num_agents, state.num_agents) "relationships must be $(state.num_agents)x$(state.num_agents) matrix"
    
    analysis = analyze_utility_breakdown(state, relationships, desires)
    
    println("=== 効用分析結果 ===")
    println("総効用: $(round(analysis.total_utility, digits=3))")
    println("平均効用: $(round(analysis.mean_utility, digits=3))")
    println("効用標準偏差: $(round(analysis.utility_std, digits=3))")
    println()
    
    println("エージェント別詳細:")
    println(lpad("Agent", 6), lpad("Total", 8), lpad("Close", 8), lpad("Explore", 9), lpad("Neighbors", 10))
    println("-" ^ 47)
    
    for i in 1:state.num_agents
        agent_seat = get_agent_seat(state, i)
        seat_str = isnothing(agent_seat) ? "?" : string(agent_seat)
        
        println(
            lpad("$i($seat_str)", 6),
            lpad("$(round(analysis.agent_utilities[i], digits=2))", 8),
            lpad("$(round(analysis.close_satisfactions[i], digits=2))", 8), 
            lpad("$(round(analysis.explore_satisfactions[i], digits=2))", 9),
            lpad("$(analysis.neighbor_counts[i])", 10)
        )
    end
    println()
end

"""
複数の移動候補の効用変化を一括計算（デバッグ用）
"""
function evaluate_all_moves(state::SeatingState,
                          relationships::Matrix{Float64},
                          desires::DesireParams)::Vector{Tuple{Int, Float64}}
    @assert size(relationships) == (state.num_agents, state.num_agents) "relationships must be $(state.num_agents)x$(state.num_agents) matrix"
    
    moves = Tuple{Int, Float64}[]
    
    for agent_id in 1:state.num_agents
        utility_change = calculate_utility_change(state, agent_id, relationships, desires)
        push!(moves, (agent_id, utility_change))
    end
    
    # 効用改善量で降順ソート
    sort!(moves, by=x -> x[2], rev=true)
    
    return moves
end
