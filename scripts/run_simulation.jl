#!/usr/bin/env julia

"""
run_simulation.jl - 基本シミュレーション実行スクリプト

飲み会席決めシミュレーションの基本実行例
"""

using SeatingSimulation

"""
基本シミュレーション実行
"""
function run_basic_simulation()
    println("=== 飲み会席決めシミュレーション ===")
    println()
    
    # パッケージ情報表示
    SeatingSimulation.package_info()
    
    # 基本動作確認
    println("動作確認テスト実行中...")
    SeatingSimulation.basic_test()
    println()
    
    # シミュレーション設定
    desires = DesireParams(0.7, 0.3)
    config = SimulationConfig(
        desires = desires,
        max_iterations = 50,
        random_seed = 42
    )
    
    println("=== シミュレーション実行 ===")
    result = run_simulation(config)
    
    # 結果の詳細表示のために関係性行列を再生成
    relationships, _ = initialize_simulation(config)
    
    println("=== 結果詳細 ===")
    display_simulation_result(result, relationships, config)
    
    return result
end

"""
パラメータ比較実験
"""
function run_parameter_comparison()
    println("=== パラメータ比較実験 ===")
    
    # 異なる欲求パラメータでの比較
    parameter_sets = [
        ("仲良し重視", DesireParams(0.9, 0.1)),
        ("バランス型", DesireParams(0.5, 0.5)),
        ("探索重視", DesireParams(0.1, 0.9)),
        ("仲良し型", DesireParams(0.7, 0.3)),
        ("社交型", DesireParams(0.3, 0.7))
    ]
    
    results = []
    
    for (name, desires) in parameter_sets
        println()
        println("--- $name ---")
        
        config = SimulationConfig(
            desires = desires,
            max_iterations = 30,
            random_seed = 100  # 比較のため固定シード
        )
        
        result = run_simulation_quiet(config)
        push!(results, (name, result))
        
        println("収束: $(result.converged ? "○" : "×")")
        println("イテレーション: $(result.iterations)")
        println("最終効用: $(round(result.utility_history[end], digits=3))")
        println("効用改善: $(round(result.utility_history[end] - result.utility_history[1], digits=3))")
    end
    
    # 結果まとめ
    println()
    println("=== パラメータ比較結果 ===")
    println(lpad("パラメータ", 12), lpad("収束", 6), lpad("回数", 6), lpad("最終効用", 10), lpad("改善量", 8))
    println("-" ^ 50)
    
    for (name, result) in results
        converged_str = result.converged ? "○" : "×"
        final_utility = result.utility_history[end]
        improvement = final_utility - result.utility_history[1]
        
        println(
            lpad(name, 12),
            lpad(converged_str, 6),
            lpad(string(result.iterations), 6),
            lpad(string(round(final_utility, digits=2)), 10),
            lpad(string(round(improvement, digits=2)), 8)
        )
    end
    
    return results
end

"""
複数回実行統計
"""
function run_statistical_analysis()
    println("=== 統計分析実験 ===")
    
    # バランス型パラメータで10回実行
    config = SimulationConfig(
        desires = DesireParams(0.6, 0.4),
        max_iterations = 50,
        random_seed = 200  # ベースシード
    )
    
    results = run_multiple_simulations(config, 10; seed_offset=0)
    
    return results
end

"""
メイン実行
"""
function main()
    println("飲み会席決めシミュレーション実行スクリプト")
    println("=" ^ 60)
    println()
    
    # 引数チェック
    if length(ARGS) == 0
        # 引数なしの場合は基本実行
        run_basic_simulation()
    elseif ARGS[1] == "basic"
        run_basic_simulation()
    elseif ARGS[1] == "compare"
        run_parameter_comparison()
    elseif ARGS[1] == "stats"
        run_statistical_analysis()
    elseif ARGS[1] == "all"
        println("全実験実行中...")
        println()
        run_basic_simulation()
        println("\n" * "=" ^ 60 * "\n")
        run_parameter_comparison() 
        println("\n" * "=" ^ 60 * "\n")
        run_statistical_analysis()
    else
        println("使用法:")
        println("  julia scripts/run_simulation.jl [mode]")
        println()
        println("モード:")
        println("  (なし)  : 基本シミュレーション実行")
        println("  basic   : 基本シミュレーション実行")
        println("  compare : パラメータ比較実験")
        println("  stats   : 統計分析実験（10回実行）")
        println("  all     : 全実験実行")
        return
    end
end

# スクリプトが直接実行された場合のみmain()を呼び出し
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
