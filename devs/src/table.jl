"""
SeatingSimulation.jl - テーブル・座席管理

長方形テーブルの座席配置と隣接関係を管理
"""

using Random

"""
長方形テーブルの座席隣接関係定義

座席番号配置:
[1] [2] [3] [4] [5]
                  
[6] [7] [8] [9] [10]

隣接関係:
- 横隣り: (1-2), (2-3), (3-4), (4-5), (6-7), (7-8), (8-9), (9-10)
- 向かい合い: (1-6), (2-7), (3-8), (4-9), (5-10)
"""

# 座席隣接関係の定数定義
const HORIZONTAL_ADJACENCIES = [
    (1, 2), (2, 3), (3, 4), (4, 5),      # 上側長辺
    (6, 7), (7, 8), (8, 9), (9, 10)      # 下側長辺
]

const FACE_TO_FACE_ADJACENCIES = [
    (1, 6), (2, 7), (3, 8), (4, 9), (5, 10)  # 向かい合い
]

# 全隣接関係（対称）
const ALL_ADJACENCIES = vcat(
    HORIZONTAL_ADJACENCIES,
    [(b, a) for (a, b) in HORIZONTAL_ADJACENCIES],  # 逆方向
    FACE_TO_FACE_ADJACENCIES,
    [(b, a) for (a, b) in FACE_TO_FACE_ADJACENCIES]  # 逆方向
)

"""指定座席の隣接座席番号リストを取得"""
function get_adjacent_seats(seat_num::Int)::Vector{Int}
    @assert 1 <= seat_num <= 10 "seat_num must be in range 1-10"
    
    adjacent_seats = Int[]
    for (seat1, seat2) in ALL_ADJACENCIES
        if seat1 == seat_num
            push!(adjacent_seats, seat2)
        end
    end
    
    return sort(adjacent_seats)
end

"""指定座席に座っているエージェントの隣接エージェントを取得"""
function get_adjacent_agents(seat_num::Int, state::SeatingState)::Vector{Int}
    @assert 1 <= seat_num <= 10 "seat_num must be in range 1-10"
    
    # 指定座席が空席の場合は空リストを返す
    if isnothing(state.seating[seat_num])
        return Int[]
    end
    
    adjacent_seats = get_adjacent_seats(seat_num)
    adjacent_agents = Int[]
    
    for adj_seat in adjacent_seats
        occupant = state.seating[adj_seat]
        if !isnothing(occupant)
            push!(adjacent_agents, occupant)
        end
    end
    
    return adjacent_agents
end

"""エージェントIDから隣接エージェントを取得"""
function get_adjacent_agents_by_id(agent_id::Int, state::SeatingState)::Vector{Int}
    @assert 1 <= agent_id <= state.num_agents "agent_id must be in range 1-$(state.num_agents)"
    
    # エージェントの座席を見つける
    agent_seat = get_agent_seat(state, agent_id)
    if isnothing(agent_seat)
        error("Agent $agent_id not found in seating")
    end
    
    return get_adjacent_agents(agent_seat, state)
end

"""ランダムな初期座席配置を生成"""
function generate_random_seating(num_agents::Int = 9, num_seats::Int = 10; 
                                random_seed::Union{Int, Nothing} = nothing)::SeatingState
    @assert num_agents > 0 "num_agents must be positive"
    @assert num_seats == 10 "num_seats must be 10 (currently only 10-seat table supported)"
    @assert num_agents < num_seats "num_agents ($num_agents) must be less than num_seats ($num_seats)"
    
    if !isnothing(random_seed)
        Random.seed!(random_seed)
    end
    
    # エージェントIDのリストを作成
    agents = collect(1:num_agents)
    seats = Vector{Union{Int, Nothing}}(nothing, num_seats)
    
    # ランダムにnum_agents席を選んでエージェントを配置
    occupied_positions = randperm(num_seats)[1:num_agents]
    for (i, pos) in enumerate(occupied_positions)
        seats[pos] = agents[i]
    end
    
    return SeatingState(seats, num_agents, num_seats)
end

"""エージェントを空席に移動する"""
function move_agent_to_empty_seat(state::SeatingState, agent_id::Int)::SeatingState
    @assert 1 <= agent_id <= state.num_agents "agent_id must be in range 1-$(state.num_agents)"
    
    # エージェントの現在位置を取得
    current_seat = get_agent_seat(state, agent_id)
    if isnothing(current_seat)
        error("Agent $agent_id not found in seating")
    end
    
    # 新しい座席配置を作成
    new_seating = copy(state.seating)
    
    # エージェントを空席に移動
    new_seating[state.empty_seat] = agent_id
    new_seating[current_seat] = nothing
    
    return SeatingState(new_seating, state.num_agents, state.num_seats)
end

"""座席配置の文字列表現を生成（デバッグ用）"""
function format_seating(state::SeatingState)::String
    function seat_repr(occupant)
        return isnothing(occupant) ? "[ ]" : "[$(occupant)]"
    end
    
    top_row = join([seat_repr(state.seating[i]) for i in 1:5], " ")
    bottom_row = join([seat_repr(state.seating[i]) for i in 6:10], " ")
    
    return """
$top_row

$bottom_row

空席: 座席$(state.empty_seat)
"""
end

"""2つの座席が隣接しているかチェック"""
function are_adjacent(seat1::Int, seat2::Int)::Bool
    @assert 1 <= seat1 <= 10 "seat1 must be in range 1-10"
    @assert 1 <= seat2 <= 10 "seat2 must be in range 1-10"
    
    return (seat1, seat2) in ALL_ADJACENCIES
end

"""テーブル設定の妥当性チェック（テスト用）"""
function validate_table_setup()::Bool
    # 各座席の隣接座席数をチェック
    expected_adjacencies = Dict(
        1 => [2, 6],        # 角：2つ
        2 => [1, 3, 7],     # 辺：3つ  
        3 => [2, 4, 8],     # 辺：3つ
        4 => [3, 5, 9],     # 辺：3つ
        5 => [4, 10],       # 角：2つ
        6 => [1, 7],        # 角：2つ
        7 => [2, 6, 8],     # 辺：3つ
        8 => [3, 7, 9],     # 辺：3つ
        9 => [4, 8, 10],    # 辺：3つ
        10 => [5, 9]        # 角：2つ
    )
    
    for seat in 1:10
        actual = get_adjacent_seats(seat)
        expected = expected_adjacencies[seat]
        if sort(actual) != sort(expected)
            @warn "座席$seat の隣接関係が不正: 期待値=$expected, 実際=$actual"
            return false
        end
    end
    
    return true
end
