# 共通の指示

## 差分レビュー: `difit` を使う

「diff を見る」「変更を確認する」系の依頼で使う。GitHub 風の files-changed view をローカル Web サーバーで立てる CLI。

- バックグラウンド実行する(`&` か Bash の `run_in_background`)
- デフォルトでブラウザが自動オープン、ブラウザのタブを閉じるとサーバーも自動停止する(`--no-open` や `--keep-alive` は基本付けない)
- 念のため起動時の URL もユーザーに伝える
- よく使う形: `difit` / `difit HEAD` / `difit main HEAD` / `difit --pr <PR URL>`
- 引数詳細は `difit --help`
- スクリプト的な比較や grep には引き続き `git diff` を使う
