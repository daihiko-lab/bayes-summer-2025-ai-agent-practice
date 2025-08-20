# 飲み会席決めシミュレーション 設計図

## 概要

長方形テーブルでの飲み会における席決めを、エージェントベースシミュレーションで最適化するシステム。

## システム仕様

### テーブル構造
- 長方形テーブル: 長辺5席×2、短辺0席（計10席）
- 参加者9人、空席1つ
- 座席配置:
```
座席番号配置図:
[1] [2] [3] [4] [5]
                  
[6] [7] [8] [9] [10]

隣接関係:
- 横隣り: (1-2), (2-3), (3-4), (4-5), (6-7), (7-8), (8-9), (9-10)
- 向かい合い: (1-6), (2-7), (3-8), (4-9), (5-10)
```

### エージェント仕様
- 9人のエージェント（ID: 1~9）
- 各エージェント間に関係性値（0~1.0、対称行列）
- 2つの欲求パラメータ:
  1. 仲良し欲求（desire_close）: 仲の良い人と隣接/対面したい
  2. 新規開拓欲求（desire_explore）: あまり仲良くない人とも隣接/対面したい

### 効用計算
```julia
# 各席配置での総効用 = Σ(全エージェント) agent_utility(agent_id)
# agent_utility = close_satisfaction + explore_satisfaction

function agent_utility(agent_id, seating, relationships, desires)
    neighbors = get_adjacent_agents(agent_id, seating)
    close_satisfaction = 0.0
    explore_satisfaction = 0.0
    
    for neighbor_id in neighbors
        rel_strength = relationships[agent_id, neighbor_id]
        if rel_strength >= 0.5  # 仲が良い閾値
            close_satisfaction += desires.close * rel_strength
        else  # 仲があまり良くない
            explore_satisfaction += desires.explore * (1.0 - rel_strength)
        end
    end
    
    return close_satisfaction + explore_satisfaction
end
```

## アーキテクチャ設計

### ディレクトリ構造
```
bayes-summer-2025-ai-agent-practice/
├── src/
│   ├── SeatingSimulation.jl          # メインモジュール
│   ├── types.jl                      # データ構造定義
│   ├── table.jl                      # テーブル・座席管理
│   ├── agents.jl                     # エージェント生成・管理
│   ├── utility.jl                    # 効用計算
│   └── simulation.jl                 # シミュレーション実行エンジン
├── scripts/
│   ├── run_simulation.jl             # 基本シミュレーション実行
│   ├── parameter_sweep.jl            # パラメータスイープ実験
│   └── visualization.jl              # 結果可視化
├── Project.toml                      # Julia依存関係
└── devs/
    ├── promt.md                      # 要件定義
    └── design_document.md            # 設計書（本ファイル）
```

### データ構造設計

```julia
# types.jl

"""エージェントの欲求パラメータ"""
struct DesireParams
    close::Float64      # 仲良し欲求 [0.0, 1.0]
    explore::Float64    # 新規開拓欲求 [0.0, 1.0]
end

"""座席配置状態"""
struct SeatingState
    seating::Vector{Union{Int, Nothing}}  # 座席[1:10] → エージェントID or nothing(空席)
    empty_seat::Int                       # 現在の空席位置
end

"""シミュレーション設定"""
struct SimulationConfig
    num_agents::Int                       # エージェント数（固定9）
    num_seats::Int                        # 座席数（固定10）
    desires::DesireParams                 # 全エージェント共通の欲求パラメータ
    max_iterations::Int                   # 最大イテレーション数
    random_seed::Union{Int, Nothing}      # 乱数シード
end

"""シミュレーション結果"""
struct SimulationResult
    initial_state::SeatingState
    final_state::SeatingState
    iterations::Int
    utility_history::Vector{Float64}
    converged::Bool
end
```

### 主要アルゴリズム

#### 1. 初期化フェーズ
```julia
function initialize_simulation(config::SimulationConfig)
    # 1. 関係性行列生成（9×9対称行列、対角成分1.0）
    relationships = generate_random_relationships(config.num_agents)
    
    # 2. 初期座席配置（ランダム）
    initial_seating = randomize_seating(config.num_agents, config.num_seats)
    
    return relationships, initial_seating
end
```

#### 2. シミュレーション実行
```julia
function run_simulation(config::SimulationConfig)
    relationships, current_state = initialize_simulation(config)
    utility_history = Float64[]
    
    for iteration in 1:config.max_iterations
        # 現在の総効用計算
        current_utility = calculate_total_utility(current_state, relationships, config.desires)
        push!(utility_history, current_utility)
        
        # 最適移動エージェント探索
        best_agent, best_gain = find_best_move(current_state, relationships, config.desires)
        
        # 収束判定
        if best_gain <= 0.0
            return SimulationResult(initial_state, current_state, iteration, utility_history, true)
        end
        
        # 席移動実行
        current_state = execute_move(current_state, best_agent)
    end
    
    # 最大イテレーション到達
    return SimulationResult(initial_state, current_state, config.max_iterations, utility_history, false)
end
```

#### 3. 最適移動探索
```julia
function find_best_move(state::SeatingState, relationships, desires)
    best_agent = nothing
    best_gain = 0.0
    
    for agent_id in 1:9
        # エージェントが空席に移動した場合の効用増加計算
        new_state = simulate_move(state, agent_id)
        utility_gain = calculate_utility_difference(state, new_state, agent_id, relationships, desires)
        
        if utility_gain > best_gain
            best_gain = utility_gain
            best_agent = agent_id
        end
    end
    
    return best_agent, best_gain
end
```

## 実装順序

### フェーズ1: 基本データ構造
1. `types.jl` - 基本データ構造定義
2. `table.jl` - 座席管理、隣接関係定義
3. `agents.jl` - エージェント・関係性生成

### フェーズ2: 効用計算システム  
4. `utility.jl` - 効用計算ロジック実装

### フェーズ3: シミュレーションエンジン
5. `simulation.jl` - メインシミュレーションロジック
6. `SeatingSimulation.jl` - モジュール統合

### フェーズ4: 実行環境
7. `Project.toml` - 依存関係設定
8. `scripts/run_simulation.jl` - 基本実行スクリプト

### フェーズ5: 拡張機能（オプション）
9. `scripts/parameter_sweep.jl` - パラメータ実験
10. `scripts/visualization.jl` - 結果可視化

## 実行例

```julia
# scripts/run_simulation.jl での使用例

using SeatingSimulation

# 設定作成
config = SimulationConfig(
    num_agents = 9,
    num_seats = 10,
    desires = DesireParams(close=0.7, explore=0.3),
    max_iterations = 100,
    random_seed = 42
)

# シミュレーション実行
result = run_simulation(config)

# 結果表示
println("=== シミュレーション結果 ===")
println("収束: $(result.converged)")
println("イテレーション数: $(result.iterations)")
println("最終効用: $(result.utility_history[end])")
println("最終座席配置: $(result.final_state.seating)")
```

## テスト戦略

今回はテストコード実装は不要だが、以下の要素が重要な検証ポイント:

1. **座席隣接関係の正確性**: `get_adjacent_seats()` 関数の検証
2. **効用計算の妥当性**: 手計算との一致確認
3. **収束条件**: 局所最適解での正常停止
4. **乱数再現性**: 同一シードでの結果一致

## 拡張可能性

- 異なるテーブル形状への対応
- エージェント個別の欲求パラメータ
- より複雑な関係性（友人グループ、敵対関係等）
- 動的関係性（シミュレーション中の変化）
- 多目的最適化（複数の評価軸）
