"""
SeatingSimulation.jl - データ構造定義

飲み会席決めシミュレーションで使用する基本データ構造を定義
"""

"""エージェントの欲求パラメータ"""
struct DesireParams
    close::Float64      # 仲良し欲求 [0.0, 1.0]
    explore::Float64    # 新規開拓欲求 [0.0, 1.0]
    
    function DesireParams(close::Real, explore::Real)
        @assert 0.0 <= close <= 1.0 "close must be in [0.0, 1.0]"
        @assert 0.0 <= explore <= 1.0 "explore must be in [0.0, 1.0]"
        new(Float64(close), Float64(explore))
    end
end

"""座席配置状態"""
struct SeatingState
    seating::Vector{Union{Int, Nothing}}  # 座席 → エージェントID or nothing(空席)
    empty_seat::Int                       # 現在の空席位置
    num_agents::Int                       # エージェント数
    num_seats::Int                        # 座席数
    
    function SeatingState(seating::Vector{Union{Int, Nothing}}, num_agents::Int, num_seats::Int)
        @assert length(seating) == num_seats "seating must have exactly $num_seats elements"
        @assert num_agents < num_seats "num_agents ($num_agents) must be less than num_seats ($num_seats)"
        @assert num_agents > 0 "num_agents must be positive"
        @assert num_seats > 0 "num_seats must be positive"
        
        # 空席数を確認
        empty_seats = findall(isnothing, seating)
        expected_empty = num_seats - num_agents
        @assert length(empty_seats) == expected_empty "exactly $expected_empty empty seats required, got $(length(empty_seats))"
        
        # エージェントIDの範囲と重複チェック
        occupied_seats = filter(!isnothing, seating)
        @assert length(occupied_seats) == num_agents "exactly $num_agents agents required"
        @assert all(1 <= id <= num_agents for id in occupied_seats) "agent IDs must be in range 1-$num_agents"
        @assert length(unique(occupied_seats)) == num_agents "all agent IDs must be unique"
        
        new(seating, empty_seats[1], num_agents, num_seats)
    end
    
    # 従来の互換性のためのコンストラクタ（10席9人）
    function SeatingState(seating::Vector{Union{Int, Nothing}})
        SeatingState(seating, 9, 10)
    end
end

"""シミュレーション設定"""
struct SimulationConfig
    num_agents::Int                       # エージェント数
    num_seats::Int                        # 座席数
    desires::DesireParams                 # 全エージェント共通の欲求パラメータ
    max_iterations::Int                   # 最大イテレーション数
    random_seed::Union{Int, Nothing}      # 乱数シード
    
    function SimulationConfig(;
        num_agents::Int = 9,
        num_seats::Int = 10,
        desires::DesireParams,
        max_iterations::Int = 100,
        random_seed::Union{Int, Nothing} = nothing
    )
        @assert num_agents > 0 "num_agents must be positive"
        @assert num_seats == 10 "num_seats must be 10 (currently only 10-seat table supported)"
        @assert num_agents < num_seats "num_agents ($num_agents) must be less than num_seats ($num_seats)"
        @assert max_iterations > 0 "max_iterations must be positive"
        
        new(num_agents, num_seats, desires, max_iterations, random_seed)
    end
end

"""シミュレーション結果"""
struct SimulationResult
    initial_state::SeatingState
    final_state::SeatingState
    iterations::Int
    utility_history::Vector{Float64}
    converged::Bool
    
    function SimulationResult(
        initial_state::SeatingState,
        final_state::SeatingState,
        iterations::Int,
        utility_history::Vector{Float64},
        converged::Bool
    )
        @assert iterations >= 0 "iterations must be non-negative"
        @assert length(utility_history) > 0 "utility_history must not be empty"
        
        new(initial_state, final_state, iterations, utility_history, converged)
    end
end

# 便利な関数
"""座席配置から指定エージェントの座席番号を取得"""
function get_agent_seat(state::SeatingState, agent_id::Int)::Union{Int, Nothing}
    @assert 1 <= agent_id <= state.num_agents "agent_id must be in range 1-$(state.num_agents)"
    
    for (seat_idx, occupant) in enumerate(state.seating)
        if occupant == agent_id
            return seat_idx
        end
    end
    return nothing
end

"""座席配置をコピーして新しい状態を作成"""
function copy_seating_state(state::SeatingState)::SeatingState
    return SeatingState(copy(state.seating), state.num_agents, state.num_seats)
end
