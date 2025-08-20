# 技術スタック - ベイズ夏の学校2025プロジェクト

最終更新: 2025-08-18

----
[! これはテンプレートです。以下を用途に合わせて調整してください。AIに書かせると楽です。]

## コアバージョン
- Julia: 1.11.6 (juliaup 推奨)
- Python: 3.11.x
- R: 4.4.x
- Quarto: 1.7.32（固定）

## 方針
- まずローカル（macOS, juliaup/pyenv）で開発。Docker は配布・再現用。
- 依存は各プロジェクトの `Project.toml`（Julia）・`requirements.txt`/`renv.lock` 等に明記。

## Juliaローカルセットアップ (最小)
```bash
# Julia (juliaup)
curl -fsSL https://install.julialang.org | sh
juliaup add 1.11.6 && juliaup default 1.11.6

# Python (pyenv 推奨)
brew install pyenv && pyenv install 3.11.9 && pyenv global 3.11.9

# Quarto (固定版)
brew install --cask quarto
```

## テスト運用 (要点)
- テスト実行は Julia REPL から `include("test/runtests.jl")` を使用（CI 等は別途）
- カバレッジは各プロジェクトのスクリプトに従う

## 実装ルール (抜粋)
- 標準ライブラリは明示 `using`、外部依存は `Project.toml` へ
- 直接の `Manifest.toml` 編集は不可
- 関数で副作用を分離し、テスト容易性を確保

## コードフォーマット (任意)
- 設定ファイル: `.cursor/context/project_info/.JuliaFormatter.toml`
- 使い方（推奨のどちらか）
  - ルートにリンクを置いて自動検出
    - `.JuliaFormatter.toml -> .cursor/context/project_info/.JuliaFormatter.toml`
    - 実行: `julia -e 'using JuliaFormatter; format(".")'`
  - または設定なしでデフォルト整形
    - 実行: `julia -e 'using JuliaFormatter; format(".")'`

## Julia 強化ポイント (実用)
- 推奨パッケージ
  - 開発: `Revise.jl`（ホットリロード）、`TestEnv.jl`（テスト環境切替）
  - 計測: `BenchmarkTools.jl`（`@btime`）、`Profile`/`ProfileView`（プロファイル）
  - 解析: `ProgressLogging.jl`（進捗ログ一元化）
- 型・性能
  - 型安定性を保つ（`@code_warntype` で確認）。非 `const` のグローバル回避。
  - 反復は `eachindex`/`axes` を用い、ブロードキャストを活用。
  - TTY 判定は `isatty(stdout)` を使う（`Base.isatty` は不可）。必要に応じて `try/catch` で例外安全に。
- 並列・並行（最小）
  - スレッド: `JULIA_NUM_THREADS` を環境で指定（例: `JULIA_NUM_THREADS=auto`）。
  - `Threads.@threads` はループ外部でメモリ確保、内部は最小の処理に限定。
- 再現性
  - 乱数は実行入口で `Random.seed!`。外部I/Oは引数で受け取り、関数内で路盤固定。
- REPL ワークフロー
  - `using Revise; using PackageName` をデフォルト。編集→即時反映→小ステップ検証。
- 互換性管理
  - `Project.toml` に `[compat]` を設定（主要依存は `~` 固定、CI で上限アラート）。

## Julia パッケージ運用 (簡潔ガイド)
- 環境の基本
  - 各プロジェクト直下で実行: `julia --project=.` → REPL で `] activate .` → `instantiate`
  - 生成物: `Project.toml`（宣言）と `Manifest.toml`（ロック）を必ずコミット（手編集はしない）
- 代表タスクとコマンド
  - 依存追加: `] add PackageName`
  - 依存削除: `] rm PackageName` → `] resolve`
  - 更新（全体/個別）: `] update` / `] update PackageName`
  - 環境初期化: `] instantiate`
  - ローカル開発パッケージ: `] dev path/to/pkg`（終了は `] free PackageName`）
- 標準ライブラリの扱い
  - 例: `Random`, `Statistics` などは `add` 不要。コードで `using Random` と明示（`Project.toml` への追加はしない）
- 典型フロー（失敗しない順）
  1) `activate .` → `instantiate`
  2) 変更: `add`/`rm`/`update` → `resolve` → `status`
  3) テスト（REPLで `include("test/runtests.jl")`）
- よくある落とし穴
  - 別環境で `add` してしまう → 常に `status` で「(active)」を確認
  - 名前違い/似たパッケージを誤追加 → `add AuthorName/RepoName` 形式や URL で厳密指定
  - Julia バージョン差異で `compat` 不整合 → `julia --version` と `[compat]` を揃える