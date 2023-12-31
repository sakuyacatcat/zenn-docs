---
title: "開発初期のアジャイル開発での学び"
emoji: "🐡"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["要件", "設計", "実装", "テスト"]
published: false
---

## TL;DR

アジャイルでプロダクトのコア機能ぎめからソフトウェア開発をしてみて、MVP定義・要件定義・設計・実装・テストのプロセスで、重要さを改めて感じたことをまとめる。

## MVP 定義(要求)

- 一気に複数の機能を考えて作ろうとしすぎない。最も重要な機能を1つに決めて、MVPの要件を絞る。
- MVPに正解はない。その〇〇は本当に必要か、と問い続け必要最小限を絞る姿勢が大切。
- より小さくして、コアな最初の一歩を決める。その一歩を踏み出すことから始める。
- このユーザー目線の粒度感で、プロダクトバックログにすると良い。

## 要件定義

- ユーザーから見て、どの様に動作するのかを考えて、入出力を論理レベルで決める。
- 入出力をさらに具体化して、仕様とできる様なレベル(データも含めた出力例など)で決める。

## 設計

- 最初の設計ではあまり色々考えすぎずてパラメータやアーキテクチャを複雑にしすぎないこと。
- 可変にしたパラメータ以外で登場するパラメータがあれば、前提条件として扱った固定パラメータ情報は明記する。

## 実装

## テスト
