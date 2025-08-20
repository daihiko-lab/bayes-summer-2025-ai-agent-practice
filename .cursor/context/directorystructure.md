# ディレクトリ構成

このドキュメントは `bayes-summer-2025-ai-agent-practice` ワークスペースの主なディレクトリ構成を示します。

Last Updated: 2025-08-20

```
bayes-summer-2025-ai-agent-practice/
├── .cursor/
│   ├── context/
│   │   ├── directorystructure.md
│   │   ├── progress.md
│   │   └── technologystack.md
│   └── rules/
│       └── myrule.mdc
├── devs/
│   ├── design_document.md
│   ├── Manifest.toml                   # 開発用Julia依存関係ロック
│   ├── Project.toml                    # 開発用Julia依存関係管理
│   ├── promt.md
│   ├── README.md                       # 開発用README
│   └── src/                            # 開発用Juliaソースコード
│       ├── agents.jl
│       ├── SeatingSimulation.jl
│       ├── simulation.jl
│       ├── table.jl
│       ├── types.jl
│       └── utility.jl
├── scripts/
│   ├── run_simulation.jl
│   └── run_variable_agents.jl
├── .gitignore
└── .git/
    └── [Git関連ファイル]
```

## 主要ディレクトリの説明

- `.cursor/`: Cursor IDE設定ディレクトリ
  - `context/`: プロジェクト関連コンテキストファイル
    - 技術スタック、進捗管理、ディレクトリ構成の情報を格納
  - `rules/`: プロジェクト固有のルール設定
    - AIアシスタントの動作指針を定義
- `devs/`: 開発関連ドキュメント
  - `promt.md`: プロジェクト要件定義
  - `design_document.md`: システム設計書
  - `src/`: 開発用Juliaソースコード（ライブラリ）
    - `SeatingSimulation.jl`: メインモジュール
    - `types.jl`: データ構造定義
    - `table.jl`: テーブル・座席管理
    - `agents.jl`: エージェント・関係性生成
    - `utility.jl`: 効用計算システム
    - `simulation.jl`: シミュレーション実行エンジン
  - `Project.toml` & `Manifest.toml`: 開発用Julia依存関係管理
- `scripts/`: 実行スクリプト
  - `run_simulation.jl`: 基本シミュレーション実行
  - `run_variable_agents.jl`: エージェント数可変シミュレーション
- `.gitignore`: Git 管理外ファイル
- `.git/`: Git バージョン管理システムファイル