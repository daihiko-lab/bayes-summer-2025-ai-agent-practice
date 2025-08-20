# SeatingSimulation.jl

飲み会の席決めをシミュレーションで最適化するJuliaパッケージ

## 概要

SeatingSimulation.jlは、長方形テーブルでの飲み会における席決めを、エージェントベースシミュレーションで最適化するツールです。参加者間の関係性と個人の欲求に基づいて、効用を最大化する座席配置を探索します。

### 主な特徴

- **エージェントベースシミュレーション**: 各参加者が自分の効用を最大化する行動をとる
- **関係性モデリング**: 参加者間の関係性（仲の良さ）を数値化
- **2つの欲求モデル**: 
  - **仲良し欲求**: 仲の良い人と隣接したい
  - **新規開拓欲求**: あまり仲良くない人とも交流したい
- **可変エージェント数**: 1-9人まで対応（10席固定テーブル）
- **貪欲法最適化**: 局所最適解への収束保証

## システム仕様

### テーブル構成
```
座席番号配置（10席、長方形テーブル）:
[1] [2] [3] [4] [5]
                  
[6] [7] [8] [9] [10]

隣接関係:
- 横隣り: (1-2), (2-3), (3-4), (4-5), (6-7), (7-8), (8-9), (9-10)
- 向かい合い: (1-6), (2-7), (3-8), (4-9), (5-10)
```

### エージェントモデル
- **関係性**: 各ペア間で0.0~1.0の関係性値（対称）
- **仲良し欲求**: 関係性≥0.5の人と隣接したい度合い
- **新規開拓欲求**: 関係性<0.5の人とも隣接したい度合い
- **効用計算**: 隣接する人との関係性と欲求に基づく満足度の合計

## インストールと設定

### 必要環境
- Julia 1.11.6以上
- 標準ライブラリのみ使用（LinearAlgebra, Random, Statistics）

### セットアップ
```bash
# リポジトリをクローン
git clone <repository-url>
cd bayes-summer-2025-ai-agent-practice

# Julia環境をアクティベート
julia --project=.

# パッケージをインストール
julia> using Pkg; Pkg.instantiate()
```

## 基本的な使用方法

### 1. パッケージの読み込み
```julia
using SeatingSimulation
```

### 2. シミュレーション設定
```julia
# 欲求パラメータを設定
desires = DesireParams(close=0.7, explore=0.3)  # 仲良し重視

# シミュレーション設定
config = SimulationConfig(
    num_agents = 9,        # エージェント数（1-9）
    num_seats = 10,        # 座席数（10固定）
    desires = desires,     # 欲求パラメータ
    max_iterations = 100,  # 最大イテレーション数
    random_seed = 42       # 乱数シード（再現性確保）
)
```

### 3. シミュレーション実行
```julia
# 詳細表示付き実行
result = run_simulation(config)

# 静かな実行（結果のみ）
result = run_simulation_quiet(config)
```

### 4. 結果の確認
```julia
println("収束: $(result.converged)")
println("イテレーション数: $(result.iterations)")
println("最終効用: $(result.utility_history[end])")
println("効用改善: $(result.utility_history[end] - result.utility_history[1])")
```

## スクリプトでの実行

### 基本シミュレーション
```bash
# 標準9人シミュレーション
julia --project=. --compiled-modules=no scripts/run_simulation.jl basic

# パラメータ比較実験
julia --project=. --compiled-modules=no scripts/run_simulation.jl compare

# 統計分析（10回実行）
julia --project=. --compiled-modules=no scripts/run_simulation.jl stats
```

### エージェント数可変シミュレーション
```bash
# 6人でのシミュレーション
julia --project=. --compiled-modules=no scripts/run_variable_agents.jl single 6

# エージェント数比較（3,5,7,9人）
julia --project=. --compiled-modules=no scripts/run_variable_agents.jl compare

# 欲求パラメータ×エージェント数分析
julia --project=. --compiled-modules=no scripts/run_variable_agents.jl analysis

# 全機能デモ
julia --project=. --compiled-modules=no scripts/run_variable_agents.jl demo
```

## 実行例と結果

### 標準シミュレーション例
```
=== シミュレーション開始 ===
乱数シード: 42
最大イテレーション: 50
欲求パラメータ: close=0.7, explore=0.3

初期座席配置:
[3] [1] [2] [5] [9]
[8] [6] [4] [7] [ ]
空席: 座席10
初期総効用: 6.853

イテレーション 1:
  移動エージェント: 3
  効用改善: 0.606
  新しい総効用: 7.459

=== 収束検出 ===
イテレーション: 7
最終総効用: 10.135
効用改善: 3.282
```

### エージェント数比較結果
```
人数  収束  回数  最終効用  改善量  平均効用
   3     ○     1      1.77     0.0      0.59
   5     ○     1      2.28     0.0      0.46
   7     ○     4      6.11    1.35      0.87
   9     ○     5     10.39    2.28      1.15
```

**発見**: エージェント数が多いほど効用改善の余地が大きく、よりダイナミックなシミュレーションになる

## APIリファレンス

### 主要な構造体

#### `DesireParams`
```julia
DesireParams(close::Float64, explore::Float64)
```
エージェントの欲求パラメータ（0.0-1.0）

#### `SimulationConfig`
```julia
SimulationConfig(;
    num_agents::Int = 9,
    num_seats::Int = 10,
    desires::DesireParams,
    max_iterations::Int = 100,
    random_seed::Union{Int, Nothing} = nothing
)
```
シミュレーション設定

#### `SimulationResult`
```julia
struct SimulationResult
    initial_state::SeatingState
    final_state::SeatingState
    iterations::Int
    utility_history::Vector{Float64}
    converged::Bool
end
```
シミュレーション結果

### 主要な関数

#### シミュレーション実行
- `run_simulation(config)`: 詳細表示付き実行
- `run_simulation_quiet(config)`: 静かな実行
- `run_multiple_simulations(config, num_runs)`: 複数回実行

#### 分析・可視化
- `display_simulation_result(result, relationships, config)`: 結果詳細表示
- `display_utility_analysis(state, relationships, desires)`: 効用分析表示
- `analyze_utility_breakdown(state, relationships, desires)`: 効用詳細分析

#### ユーティリティ
- `generate_relationship_matrix(num_agents)`: 関係性行列生成
- `generate_random_seating(num_agents, num_seats)`: ランダム座席配置
- `calculate_total_utility(state, relationships, desires)`: 総効用計算

## 実験・分析例

### パラメータ感度分析
```julia
# 異なる欲求パラメータでの比較
parameter_sets = [
    ("仲良し重視", DesireParams(0.9, 0.1)),
    ("バランス型", DesireParams(0.5, 0.5)),
    ("探索重視", DesireParams(0.1, 0.9))
]

for (name, desires) in parameter_sets
    config = SimulationConfig(desires=desires, random_seed=100)
    result = run_simulation_quiet(config)
    println("$name: 最終効用 $(round(result.utility_history[end], digits=2))")
end
```

### 収束性分析
```julia
# 複数回実行による統計分析
config = SimulationConfig(desires=DesireParams(0.6, 0.4), random_seed=200)
results = run_multiple_simulations(config, 20)

# 収束率、平均イテレーション数、効用分布の分析
convergence_rate = count(r -> r.converged, results) / length(results)
avg_iterations = mean([r.iterations for r in results])
```

## 技術的詳細

### アルゴリズム
1. **初期化**: ランダムな関係性行列と座席配置を生成
2. **効用計算**: 各エージェントの隣接関係に基づく効用を計算
3. **最適移動探索**: 最も効用改善効果の高いエージェントを特定
4. **席移動実行**: エージェントを空席に移動
5. **収束判定**: 効用改善がなくなれば終了

### 制約と限界
- **座席数固定**: 現在は10席のみ対応（長方形テーブル5×2配置）
- **単一空席**: 常に1つの空席が存在する前提
- **局所最適**: 貪欲法のため大域最適解は保証されない
- **関係性固定**: シミュレーション中の関係性変化は考慮しない

## 開発者向け情報

### プロジェクト構造
```
src/
├── SeatingSimulation.jl  # メインモジュール
├── types.jl             # データ構造定義
├── table.jl             # テーブル・座席管理
├── agents.jl            # エージェント・関係性生成
├── utility.jl           # 効用計算システム
└── simulation.jl        # シミュレーション実行エンジン

scripts/
├── run_simulation.jl        # 基本シミュレーション
└── run_variable_agents.jl   # エージェント数可変実行

devs/
├── promt.md            # 要件定義
└── design_document.md  # 設計書
```

### 拡張方法

#### 新しい欲求タイプの追加
1. `DesireParams`に新しいフィールドを追加
2. `calculate_agent_utility`で効用計算ロジックを拡張

#### 異なるテーブル形状への対応
1. `get_adjacent_seats`を抽象化
2. テーブル形状定義の構造体を作成
3. 隣接関係をパラメータ化

### テスト
```julia
# 基本動作確認
julia --project=. --compiled-modules=no -e "using SeatingSimulation; SeatingSimulation.basic_test()"

# パッケージ情報表示
julia --project=. --compiled-modules=no -e "using SeatingSimulation; SeatingSimulation.package_info()"
```

## ライセンス

このプロジェクトは研究・教育目的で作成されました。

## 貢献

バグ報告、機能提案、プルリクエストを歓迎します。

## 更新履歴

- v0.1.0: 初期リリース（9人固定）
- v0.1.1: エージェント数可変対応（1-9人）

## 参考文献

- エージェントベースモデリング理論
- 組み合わせ最適化手法
- 社会ネットワーク分析
