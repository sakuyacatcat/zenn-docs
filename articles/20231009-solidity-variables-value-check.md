---
title: "Solidity で変数の値を確認する方法"
emoji: "💬"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["solidity", "ethereum", "debugging", "console.log"]
published: false
---

## TL;DR

- Solidityで書いたコードの中にある変数の値をローカルで簡単に確認する方法をまとめる

## 使用ライブラリ

`forge-std/console.sol` の `console.log*`
[参考](https://book.getfoundry.sh/forge/forge-std)

## 使用例

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";

contract Sample {
  uint256 public value;

  function setValue(uint256 _value) public {
    value = _value;

    console.logString("-------------------");
    console.logUint(value);
    console.logString("-------------------");
  }
}
```

## 注意点

Hardhatでの動作は未検証なので、Foundryでの使用を前提に考えてください。
