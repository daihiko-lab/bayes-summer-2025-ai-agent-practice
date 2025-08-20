"""
SeatingSimulation.jl - エージェント・関係性生成

エージェント間の関係性行列生成とエージェント管理
"""

using Random
using Statistics
using LinearAlgebra

"""
ランダムな関係性行列を生成

戻り値: num_agents×num_agentsの対称行列
- 対角成分は1.0（自分との関係）
- 非対角成分は0.0~1.0のランダム値
- matrix[i,j] = matrix[j,i] (対称性)
"""
function generate_relationship_matrix(num_agents::Int = 9; 
                                    random_seed::Union{Int, Nothing} = nothing,
                                    mean_relationship::Float64 = 0.5,
                                    std_relationship::Float64 = 0.2)::Matrix{Float64}
    @assert num_agents > 0 "num_agents must be positive"
    @assert 0.0 <= mean_relationship <= 1.0 "mean_relationship must be in [0.0, 1.0]"
    @assert std_relationship > 0.0 "std_relationship must be positive"
    
    if !isnothing(random_seed)
        Random.seed!(random_seed)
    end
    
    relationships = Matrix{Float64}(undef, num_agents, num_agents)
    
    # 対角成分を1.0に設定（自分との関係）
    for i in 1:num_agents
        relationships[i, i] = 1.0
    end
    
    # 上三角行列をランダムに生成
    for i in 1:num_agents
        for j in (i+1):num_agents
            # 正規分布からサンプリングして[0,1]にクランプ
            raw_value = randn() * std_relationship + mean_relationship
            clamped_value = clamp(raw_value, 0.0, 1.0)
            
            # 対称行列にする
            relationships[i, j] = clamped_value
            relationships[j, i] = clamped_value
        end
    end
    
    return relationships
end

"""
関係性行列の統計情報を取得
"""
function analyze_relationships(relationships::Matrix{Float64})::NamedTuple
    num_agents = size(relationships, 1)
    @assert size(relationships) == (num_agents, num_agents) "relationships must be square matrix"
    @assert num_agents > 0 "relationships matrix must not be empty"
    
    # 非対角成分のみを抽出
    off_diagonal = Float64[]
    for i in 1:num_agents
        for j in 1:num_agents
            if i != j
                push!(off_diagonal, relationships[i, j])
            end
        end
    end
    
    return (
        mean = mean(off_diagonal),
        std = std(off_diagonal),
        min = minimum(off_diagonal),
        max = maximum(off_diagonal),
        median = median(off_diagonal)
    )
end

"""
関係性の強さによる分類

戻り値: (close_pairs, neutral_pairs, distant_pairs)
- close_pairs: 関係性 >= threshold_close のペア
- neutral_pairs: threshold_distant < 関係性 < threshold_close のペア  
- distant_pairs: 関係性 <= threshold_distant のペア
"""
function categorize_relationships(relationships::Matrix{Float64};
                                threshold_close::Float64 = 0.6,
                                threshold_distant::Float64 = 0.4)::NamedTuple
    num_agents = size(relationships, 1)
    @assert size(relationships) == (num_agents, num_agents) "relationships must be square matrix"
    @assert 0.0 <= threshold_distant < threshold_close <= 1.0 "invalid thresholds"
    
    close_pairs = Tuple{Int, Int}[]
    neutral_pairs = Tuple{Int, Int}[]
    distant_pairs = Tuple{Int, Int}[]
    
    for i in 1:num_agents
        for j in (i+1):num_agents  # 上三角のみ（対称行列なので）
            rel_strength = relationships[i, j]
            
            if rel_strength >= threshold_close
                push!(close_pairs, (i, j))
            elseif rel_strength <= threshold_distant
                push!(distant_pairs, (i, j))
            else
                push!(neutral_pairs, (i, j))
            end
        end
    end
    
    return (
        close = close_pairs,
        neutral = neutral_pairs,
        distant = distant_pairs
    )
end

"""
関係性行列の表示（デバッグ用）
"""
function display_relationships(relationships::Matrix{Float64}; digits::Int = 2)
    num_agents = size(relationships, 1)
    @assert size(relationships) == (num_agents, num_agents) "relationships must be square matrix"
    
    println("=== エージェント間関係性行列 ===")
    print("   ")
    for j in 1:num_agents
        print(lpad("[$j]", 6))
    end
    println()
    
    for i in 1:num_agents
        print("[$i]")
        for j in 1:num_agents
            if i == j
                print(lpad("1.00", 6))  # 対角成分
            else
                value_str = string(round(relationships[i, j], digits=digits))
                print(lpad(value_str, 6))
            end
        end
        println()
    end
    println()
end

"""
特定のエージェントペアの関係性値を取得
"""
function get_relationship(relationships::Matrix{Float64}, agent1::Int, agent2::Int)::Float64
    num_agents = size(relationships, 1)
    @assert size(relationships) == (num_agents, num_agents) "relationships must be square matrix"
    @assert 1 <= agent1 <= num_agents "agent1 must be in range 1-$num_agents"
    @assert 1 <= agent2 <= num_agents "agent2 must be in range 1-$num_agents"
    
    return relationships[agent1, agent2]
end

"""
関係性行列の妥当性チェック
"""
function validate_relationships(relationships::Matrix{Float64})::Bool
    num_agents = size(relationships, 1)
    @assert size(relationships) == (num_agents, num_agents) "relationships must be square matrix"
    
    # 対角成分が1.0であることをチェック
    for i in 1:num_agents
        if relationships[i, i] != 1.0
            @warn "対角成分 relationships[$i, $i] が 1.0 ではありません: $(relationships[i, i])"
            return false
        end
    end
    
    # 対称性をチェック
    for i in 1:num_agents
        for j in 1:num_agents
            if abs(relationships[i, j] - relationships[j, i]) > 1e-10
                @warn "非対称: relationships[$i, $j] = $(relationships[i, j]), relationships[$j, $i] = $(relationships[j, i])"
                return false
            end
        end
    end
    
    # 値の範囲をチェック
    for i in 1:num_agents
        for j in 1:num_agents
            value = relationships[i, j]
            if !(0.0 <= value <= 1.0)
                @warn "範囲外の値: relationships[$i, $j] = $value"
                return false
            end
        end
    end
    
    return true
end

"""
事前定義された関係性パターンの生成（テスト用）

パターン:
- "balanced": 全体的にバランスの取れた関係性
- "polarized": 仲の良いグループと悪いグループが明確
- "random": 完全ランダム
"""
function generate_predefined_relationships(pattern::String; 
                                         random_seed::Union{Int, Nothing} = nothing)::Matrix{Float64}
    if !isnothing(random_seed)
        Random.seed!(random_seed)
    end
    
    if pattern == "balanced"
        return generate_relationship_matrix(9; random_seed=random_seed, 
                                          mean_relationship=0.5, std_relationship=0.15)
    elseif pattern == "polarized"
        relationships = Matrix{Float64}(I, 9, 9)  # 単位行列で初期化
        
        # グループ1 (1,2,3): 高い関係性
        for i in 1:3, j in 1:3
            if i != j
                relationships[i, j] = 0.8 + 0.1 * randn()
                relationships[i, j] = clamp(relationships[i, j], 0.7, 1.0)
            end
        end
        
        # グループ2 (4,5,6): 高い関係性  
        for i in 4:6, j in 4:6
            if i != j
                relationships[i, j] = 0.8 + 0.1 * randn()
                relationships[i, j] = clamp(relationships[i, j], 0.7, 1.0)
            end
        end
        
        # グループ3 (7,8,9): 高い関係性
        for i in 7:9, j in 7:9
            if i != j
                relationships[i, j] = 0.8 + 0.1 * randn()
                relationships[i, j] = clamp(relationships[i, j], 0.7, 1.0)
            end
        end
        
        # グループ間: 低い関係性
        for i in 1:3, j in 4:9
            value = 0.2 + 0.1 * randn()
            value = clamp(value, 0.0, 0.4)
            relationships[i, j] = value
            relationships[j, i] = value
        end
        
        for i in 4:6, j in 7:9
            value = 0.2 + 0.1 * randn()
            value = clamp(value, 0.0, 0.4)
            relationships[i, j] = value
            relationships[j, i] = value
        end
        
        return relationships
        
    elseif pattern == "random"
        return generate_relationship_matrix(9; random_seed=random_seed,
                                          mean_relationship=0.5, std_relationship=0.3)
    else
        error("Unknown pattern: $pattern. Available: 'balanced', 'polarized', 'random'")
    end
end
