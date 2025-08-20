"""
SeatingSimulation.jl - シミュレーション実行エンジン

メインのシミュレーションループと収束判定
"""

using Random
using Statistics

"""
シミュレーションの初期化

引数:
- config: シミュレーション設定

戻り値: (relationships, initial_state)
- relationships: エージェント間関係性行列
- initial_state: 初期座席配置
"""
function initialize_simulation(config::SimulationConfig)::Tuple{Matrix{Float64}, SeatingState}
    # 乱数シード設定
    if !isnothing(config.random_seed)
        Random.seed!(config.random_seed)
    end
    
    # 関係性行列生成
    relationships = generate_relationship_matrix(config.num_agents; random_seed=config.random_seed)
    
    # 初期座席配置生成
    initial_state = generate_random_seating(config.num_agents, config.num_seats; 
                                          random_seed=config.random_seed)
    
    return relationships, initial_state
end

"""
メインシミュレーション実行

引数:
- config: シミュレーション設定

戻り値: SimulationResult構造体
"""
function run_simulation(config::SimulationConfig)::SimulationResult
    # 初期化
    relationships, initial_state = initialize_simulation(config)
    current_state = copy_seating_state(initial_state)
    utility_history = Float64[]
    
    if config.random_seed !== nothing
        println("=== シミュレーション開始 ===")
        println("乱数シード: $(config.random_seed)")
        println("最大イテレーション: $(config.max_iterations)")
        println("欲求パラメータ: close=$(config.desires.close), explore=$(config.desires.explore)")
        println()
    end
    
    # 初期効用計算
    initial_utility = calculate_total_utility(current_state, relationships, config.desires)
    push!(utility_history, initial_utility)
    
    if config.random_seed !== nothing
        println("初期座席配置:")
        println(format_seating(current_state))
        println("初期総効用: $(round(initial_utility, digits=3))")
        println()
    end
    
    # メインシミュレーションループ
    for iteration in 1:config.max_iterations
        # 最適移動探索
        best_agent, best_gain = find_best_move(current_state, relationships, config.desires)
        
        # 収束判定
        if isnothing(best_agent) || best_gain <= 1e-10  # 数値誤差を考慮
            if config.random_seed !== nothing
                println("=== 収束検出 ===")
                println("イテレーション: $iteration")
                println("最終総効用: $(round(utility_history[end], digits=3))")
                println("効用改善: $(round(utility_history[end] - initial_utility, digits=3))")
                println()
            end
            
            return SimulationResult(initial_state, current_state, iteration, 
                                  utility_history, true)
        end
        
        # 席移動実行
        current_state = move_agent_to_empty_seat(current_state, best_agent)
        new_utility = calculate_total_utility(current_state, relationships, config.desires)
        push!(utility_history, new_utility)
        
        # 進捗表示
        if config.random_seed !== nothing
            println("イテレーション $iteration:")
            println("  移動エージェント: $best_agent")
            println("  効用改善: $(round(best_gain, digits=3))")
            println("  新しい総効用: $(round(new_utility, digits=3))")
            println()
        end
    end
    
    # 最大イテレーション到達
    if config.random_seed !== nothing
        println("=== 最大イテレーション到達 ===")
        println("収束しませんでした")
        println("最終総効用: $(round(utility_history[end], digits=3))")
        println("効用改善: $(round(utility_history[end] - initial_utility, digits=3))")
        println()
    end
    
    return SimulationResult(initial_state, current_state, config.max_iterations, 
                          utility_history, false)
end

"""
静かなシミュレーション実行（出力なし）

引数:
- config: シミュレーション設定

戻り値: SimulationResult構造体
"""
function run_simulation_quiet(config::SimulationConfig)::SimulationResult
    # 出力なしバージョンのためにrandom_seedを一時的にnothingに
    quiet_config = SimulationConfig(
        num_agents = config.num_agents,
        num_seats = config.num_seats,
        desires = config.desires,
        max_iterations = config.max_iterations,
        random_seed = nothing  # 出力制御のため
    )
    
    # 元の乱数シードは手動で設定
    if !isnothing(config.random_seed)
        Random.seed!(config.random_seed)
    end
    
    # 初期化
    relationships, initial_state = initialize_simulation(quiet_config)
    current_state = copy_seating_state(initial_state)
    utility_history = Float64[]
    
    # 初期効用計算
    initial_utility = calculate_total_utility(current_state, relationships, quiet_config.desires)
    push!(utility_history, initial_utility)
    
    # メインシミュレーションループ
    for iteration in 1:quiet_config.max_iterations
        # 最適移動探索
        best_agent, best_gain = find_best_move(current_state, relationships, quiet_config.desires)
        
        # 収束判定
        if isnothing(best_agent) || best_gain <= 1e-10
            return SimulationResult(initial_state, current_state, iteration, 
                                  utility_history, true)
        end
        
        # 席移動実行
        current_state = move_agent_to_empty_seat(current_state, best_agent)
        new_utility = calculate_total_utility(current_state, relationships, quiet_config.desires)
        push!(utility_history, new_utility)
    end
    
    # 最大イテレーション到達
    return SimulationResult(initial_state, current_state, quiet_config.max_iterations, 
                          utility_history, false)
end

"""
複数回実行による統計分析

引数:
- config: ベースとなるシミュレーション設定
- num_runs: 実行回数
- seed_offset: 各実行のシード値オフセット（config.random_seedがnothingでない場合）

戻り値: 実行結果の配列
"""
function run_multiple_simulations(config::SimulationConfig, 
                                 num_runs::Int;
                                 seed_offset::Int = 0)::Vector{SimulationResult}
    @assert num_runs > 0 "num_runs must be positive"
    
    results = SimulationResult[]
    
    println("=== 複数回実行開始 ===")
    println("実行回数: $num_runs")
    println("基本設定: close=$(config.desires.close), explore=$(config.desires.explore)")
    println()
    
    for run in 1:num_runs
        # 各実行に異なるシードを設定
        run_config = if isnothing(config.random_seed)
            config
        else
            SimulationConfig(
                num_agents = config.num_agents,
                num_seats = config.num_seats,
                desires = config.desires,
                max_iterations = config.max_iterations,
                random_seed = config.random_seed + seed_offset + run - 1
            )
        end
        
        result = run_simulation_quiet(run_config)
        push!(results, result)
        
        print("実行 $run/$num_runs 完了 ")
        print("(収束: $(result.converged ? "○" : "×"), ")
        print("イテレーション: $(result.iterations), ")
        print("最終効用: $(round(result.utility_history[end], digits=2)))")
        println()
    end
    
    # 統計サマリー表示
    final_utilities = [r.utility_history[end] for r in results]
    convergence_rate = count(r -> r.converged, results) / num_runs
    
    println()
    println("=== 統計サマリー ===")
    println("収束率: $(round(convergence_rate * 100, digits=1))%")
    println("最終効用 平均: $(round(mean(final_utilities), digits=3))")
    println("最終効用 標準偏差: $(round(std(final_utilities), digits=3))")
    println("最終効用 最小値: $(round(minimum(final_utilities), digits=3))")
    println("最終効用 最大値: $(round(maximum(final_utilities), digits=3))")
    println()
    
    return results
end

"""
シミュレーション結果の詳細表示
"""
function display_simulation_result(result::SimulationResult, 
                                  relationships::Matrix{Float64},
                                  config::SimulationConfig)
    println("=== シミュレーション結果詳細 ===")
    println("収束: $(result.converged ? "○" : "×")")
    println("実行イテレーション数: $(result.iterations)")
    println("最大イテレーション数: $(config.max_iterations)")
    println()
    
    println("効用変化:")
    initial_utility = result.utility_history[1]
    final_utility = result.utility_history[end]
    improvement = final_utility - initial_utility
    improvement_rate = (improvement / initial_utility) * 100
    
    println("  初期効用: $(round(initial_utility, digits=3))")
    println("  最終効用: $(round(final_utility, digits=3))")
    println("  改善量: $(round(improvement, digits=3))")
    println("  改善率: $(round(improvement_rate, digits=1))%")
    println()
    
    println("初期座席配置:")
    println(format_seating(result.initial_state))
    
    println("最終座席配置:")
    println(format_seating(result.final_state))
    
    println("最終状態での効用分析:")
    display_utility_analysis(result.final_state, relationships, config.desires)
end
