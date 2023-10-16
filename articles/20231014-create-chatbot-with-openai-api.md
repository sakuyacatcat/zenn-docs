---
title: "OpenAI APIでチャットボットを作ってみた学び"
emoji: "🙌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [chatbot, openai, 機械学習, 自然言語処理]
published: false
---

## TL;DR

Udemy教材の[ChatGPT を使った AI チャットボットの Web アプリ・アレクサスキル開発ハンズオン](https://www.udemy.com/course/chatgpt_webapp/)を実践してみた学びを書き記した記事。

### [OpenAI API](https://platform.openai.com/overview)

#### クレジット

クレジットをチャージして使う必要がある。
SignUpから3ヶ月分有効な無料クレジットがある。それを切らしてしまうと、クレジットをチャージする必要がある。
クレジット無しでOpenAI APIを実行しようとすると`RateLimitError`に出くわす。

### [Hugging Face Model Hub](https://huggingface.co/models)

モデルハブには、ローカルでも実行できるモデルが公開されている。
MIT Licenseのものもある。

#### [gpt-neox-japanese-2.7b](https://huggingface.co/abeja/gpt-neox-japanese-2.7b)

日本語のGPT-Neo 2.7Bモデル。GPT-3に匹敵するモデル。

### transformers

Hugging Faceの提供しているPythonライブラリ。
Hugging Faceに公開されているモデルを簡単に実行できる。
