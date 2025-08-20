"""
SeatingSimulation.jl - メインモジュール

飲み会席決めシミュレーションパッケージ
"""

module SeatingSimulation

# 標準ライブラリのインポート
using Random
using Statistics
using LinearAlgebra

# データ構造の定義
include("types.jl")
export DesireParams, SeatingState, SimulationConfig, SimulationResult
export get_agent_seat, copy_seating_state

# テーブル・座席管理
include("table.jl") 
export get_adjacent_seats, get_adjacent_agents, get_adjacent_agents_by_id, generate_random_seating
export move_agent_to_empty_seat, format_seating, are_adjacent, validate_table_setup

# エージェント・関係性管理
include("agents.jl")
export generate_relationship_matrix, analyze_relationships, categorize_relationships
export display_relationships, get_relationship, validate_relationships
export generate_predefined_relationships

# 効用計算
include("utility.jl")
export calculate_agent_utility, calculate_total_utility, calculate_utility_change
export find_best_move, analyze_utility_breakdown, display_utility_analysis
export evaluate_all_moves

# シミュレーション実行
include("simulation.jl")
export initialize_simulation, run_simulation, run_simulation_quiet
export run_multiple_simulations, display_simulation_result

# バージョン情報
const VERSION = v"0.1.0"

"""
パッケージ情報を表示
"""
function package_info()
    println("=== SeatingSimulation.jl v$VERSION ===")
    println("飲み会席決めシミュレーションパッケージ")
    println()
    println("主な機能:")
    println("- 長方形テーブル（10席）での席決め最適化")
    println("- エージェントベースシミュレーション（1-9人対応）")
    println("- 関係性に基づく効用計算")
    println("- 貪欲法による局所最適解探索")
    println()
    println("使用例:")
    println("julia> using SeatingSimulation")
    println("julia> config = SimulationConfig(desires=DesireParams(0.7, 0.3), random_seed=42)")
    println("julia> result = run_simulation(config)")
    println()
end

"""
基本的な動作確認テスト
"""
function basic_test()
    println("=== 基本動作確認テスト ===")
    
    try
        # テーブル設定の確認
        print("テーブル設定確認... ")
        @assert validate_table_setup()
        println("OK")
        
        # データ構造の確認
        print("データ構造確認... ")
        desires = DesireParams(0.6, 0.4)
        config = SimulationConfig(desires=desires, random_seed=123)
        println("OK")
        
        # 関係性行列生成
        print("関係性行列生成... ")
        relationships = generate_relationship_matrix(config.num_agents; random_seed=123)
        @assert validate_relationships(relationships)
        println("OK")
        
        # 座席配置生成
        print("座席配置生成... ")
        state = generate_random_seating(config.num_agents, config.num_seats; random_seed=123)
        println("OK")
        
        # 効用計算
        print("効用計算... ")
        total_utility = calculate_total_utility(state, relationships, desires)
        @assert total_utility >= 0.0
        println("OK")
        
        # シミュレーション実行
        print("シミュレーション実行... ")
        result = run_simulation_quiet(config)
        @assert isa(result, SimulationResult)
        println("OK")
        
        println()
        println("全てのテストが成功しました！")
        println("最終効用: $(round(result.utility_history[end], digits=3))")
        println("収束: $(result.converged ? "○" : "×")")
        
    catch e
        println("FAILED")
        println("エラー: $e")
        rethrow(e)
    end
end

end # module SeatingSimulation
