#!/usr/bin/env julia

"""
run_variable_agents.jl - エージェント数可変シミュレーション実行スクリプト

異なるエージェント数でのシミュレーション実行例
"""

using SeatingSimulation

"""
エージェント数を変更したシミュレーション実行
"""
function run_variable_agent_simulation(num_agents::Int; 
                                      desires::DesireParams = DesireParams(0.7, 0.3),
                                      random_seed::Int = 42)
    println("=== $(num_agents)人シミュレーション ===")
    
    config = SimulationConfig(
        num_agents = num_agents,
        num_seats = 10,  # 現在は10席固定
        desires = desires,
        max_iterations = 50,
        random_seed = nothing
    )
    
    result = run_simulation(config)
    
    println("=== 結果サマリー ===")
    println("エージェント数: $(config.num_agents)")
    println("空席数: $(config.num_seats - config.num_agents)")
    println("収束: $(result.converged ? "○" : "×")")
    println("イテレーション数: $(result.iterations)")
    println("最終効用: $(round(result.utility_history[end], digits=3))")
    println("効用改善: $(round(result.utility_history[end] - result.utility_history[1], digits=3))")
    
    return result
end

"""
複数のエージェント数での比較実験
"""
function run_agent_comparison()
    println("=== エージェント数比較実験 ===")
    
    agent_counts = [3, 5, 7, 9]  # 10席での異なるエージェント数
    desires = DesireParams(0.7, 0.3)
    
    results = []
    
    for num_agents in agent_counts
        println()
        result = run_variable_agent_simulation(num_agents; desires=desires, random_seed=100)
        push!(results, (num_agents, result))
    end
    
    # 結果まとめ
    println()
    println("=== エージェント数比較結果 ===")
    println(lpad("人数", 6), lpad("収束", 6), lpad("回数", 6), lpad("最終効用", 10), lpad("改善量", 8), lpad("平均効用", 10))
    println("-" ^ 54)
    
    for (num_agents, result) in results
        converged_str = result.converged ? "○" : "×"
        final_utility = result.utility_history[end]
        improvement = final_utility - result.utility_history[1]
        avg_utility = final_utility / num_agents
        
        println(
            lpad(string(num_agents), 6),
            lpad(converged_str, 6),
            lpad(string(result.iterations), 6),
            lpad(string(round(final_utility, digits=2)), 10),
            lpad(string(round(improvement, digits=2)), 8),
            lpad(string(round(avg_utility, digits=2)), 10)
        )
    end
    
    return results
end

"""
異なる欲求パラメータでのエージェント数依存性分析
"""
function run_desire_agent_analysis()
    println("=== 欲求パラメータ×エージェント数分析 ===")
    
    agent_counts = [4, 6, 8]
    desire_types = [
        ("仲良し重視", DesireParams(0.9, 0.1)),
        ("バランス型", DesireParams(0.5, 0.5)),
        ("探索重視", DesireParams(0.1, 0.9))
    ]
    
    results_matrix = []
    
    for (desire_name, desires) in desire_types
        println()
        println("--- $desire_name ---")
        row_results = []
        
        for num_agents in agent_counts
            config = SimulationConfig(
                num_agents = num_agents,
                desires = desires,
                max_iterations = 30,
                random_seed = 200 + num_agents  # 固定的だが異なるシード
            )
            
            result = run_simulation_quiet(config)
            push!(row_results, result)
            
            avg_utility = result.utility_history[end] / num_agents
            println("  $(num_agents)人: 効用 $(round(result.utility_history[end], digits=2)) (平均 $(round(avg_utility, digits=2)))")
        end
        
        push!(results_matrix, (desire_name, row_results))
    end
    
    # 結果マトリクス表示
    println()
    println("=== 総合比較マトリクス ===")
    print(lpad("パラメータ", 12))
    for num_agents in agent_counts
        print(lpad("$(num_agents)人", 8))
    end
    println()
    println("-" ^ (12 + 8 * length(agent_counts)))
    
    for (desire_name, row_results) in results_matrix
        print(lpad(desire_name, 12))
        for result in row_results
            avg_utility = result.utility_history[end] / result.final_state.num_agents
            print(lpad(string(round(avg_utility, digits=2)), 8))
        end
        println()
    end
    
    return results_matrix
end

"""
メイン実行
"""
function main()
    println("エージェント数可変シミュレーション実行スクリプト")
    println("=" ^ 60)
    println()
    
    # 引数チェック
    if length(ARGS) == 0
        println("使用法:")
        println("  julia --project=. --compiled-modules=no scripts/run_variable_agents.jl [mode] [num_agents]")
        println()
        println("モード:")
        println("  single N    : N人でのシミュレーション実行")
        println("  compare     : エージェント数比較実験（3,5,7,9人）")
        println("  analysis    : 欲求パラメータ×エージェント数分析")
        println("  demo        : デモンストレーション（各モード実行）")
        return
    end
    
    if ARGS[1] == "single"
        if length(ARGS) < 2
            println("エラー: エージェント数を指定してください")
            println("例: julia scripts/run_variable_agents.jl single 7")
            return
        end
        
        num_agents = parse(Int, ARGS[2])
        if num_agents <= 0 || num_agents >= 10
            println("エラー: エージェント数は 1-9 の範囲で指定してください")
            return
        end
        
        run_variable_agent_simulation(num_agents)
        
    elseif ARGS[1] == "compare"
        run_agent_comparison()
        
    elseif ARGS[1] == "analysis"
        run_desire_agent_analysis()
        
    elseif ARGS[1] == "demo"
        println("全機能デモンストレーション実行中...")
        println()
        run_variable_agent_simulation(6)
        println("\n" * "=" ^ 60 * "\n")
        run_agent_comparison()
        println("\n" * "=" ^ 60 * "\n")
        run_desire_agent_analysis()
        
    else
        println("エラー: 不明なモード '$(ARGS[1])'")
        println("使用可能なモード: single, compare, analysis, demo")
    end
end

# スクリプトが直接実行された場合のみmain()を呼び出し
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
