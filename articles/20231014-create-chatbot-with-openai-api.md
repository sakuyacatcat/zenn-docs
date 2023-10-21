---
title: "LLMでチャットボットを作ってみた学び"
emoji: "🙌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [chatbot, openai, 機械学習, 自然言語処理]
published: true
---

## TL;DR

Udemy教材の[ChatGPT を使った AI チャットボットの Web アプリ・アレクサスキル開発ハンズオン](https://www.udemy.com/course/chatgpt_webapp/)を実践してみた。教材やその周辺知識に関する学びを書き記す。

### 前提

#### 生成 AI の位置づけの理解

- AI: 人間を真似て、コンピュータに思考・行動させることで問題を解く技術。
- メーリングリスト: AIの一種。過去のデータを学習し、パターンを推論させる。その推論を元に予測する技術。
- 生成AI: メーリングリストの一種。過去のデータを学習し、様々なコンテンツを生成する技術。

#### GPT-3 とは

OpenAIが開発した大規模言語モデル。GPT-3はGPT-2の後継モデルで、GPT-2はGPT-1の後継モデルである。GPT-1から比べてモデルのサイズ(学習データセットの量、内部のニューラルネットワークのパラメータの数)を増加させることで、より人間が求める回答をできるようになった。

### [OpenAI API](https://platform.openai.com/overview)

#### クレジット

クレジットをチャージして使う必要がある。SignUpから3ヶ月分有効な無料クレジットがある。それを切らしてしまうと、クレジットをチャージする必要がある。クレジット無しでOpenAI APIを実行しようとすると`RateLimitError`に出くわす。

#### パラメータ

大規模言語モデルを使用するためのパラメータとしては以下があるらしい。OpenAI APIではデフォルト値があるパラメータもある(`max_token`, `temperature`, `top_p`)ので、呼び出し時には全てを設定せずともどうさせることはできる。

- `model`: 使用するモデル名称
- `prompt`: モデルに与える入力
- `max_tokens`: モデルが生成するトークンの最大数。トークン数は文章の長さに相当する。
- `temperature`: 生成される文章の多様性を調整するパラメータ。0に近いほど生成される文章は一定になる。1に近いほど生成される文章は多様になる。クリエイティブな文章を生成したい場合は1に近い値を設定する。`top_p` と同時に変更するのは推奨されていない。
- `top_p`: 生成される文章を作成するために選出する単語量を調整するパラメータ。`top_p` を超えない様に出現確率の高い順に単語が選択されていき、その中から最終的に1つの単語が選択される。`temperature` と同時に変更するのは推奨されていない。

#### Completion API

**リクエスト**

```python
response = openai.Completion.create(
  model="gpt-3.5-turbo-instruct",
  prompt="Write a tagline for an ice cream shop."
)
```

**レスポンス**

```python
{
  "choices": [
    {
      "finish_reason": "length",
      "index": 0,
      "logprobs": null,
      "text": "\n\n\"Let Your Sweet Tooth Run Wild at Our Creamy Ice Cream Shack"
    }
  ],
  "created": 1683130927,
  "id": "cmpl-7C9Wxi9Du4j1lQjdjhxBlO22M61LD",
  "model": "gpt-3.5-turbo-instruct",
  "object": "text_completion",
  "usage": {
    "completion_tokens": 16,
    "prompt_tokens": 10,
    "total_tokens": 26
  }
}
```

#### ChatCompletion API

**リクエスト**

```python
response = openai.ChatCompletion.create(
    model="gpt-3.5-turbo",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Who won the world series in 2020?"},
        {"role": "assistant", "content": "The Los Angeles Dodgers won the World Series in 2020."},
        {"role": "user", "content": "Where was it played?"}
    ]
)
```

**レスポンス**

```python
{
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "content": "The 2020 World Series was played in Texas at Globe Life Field in Arlington.",
        "role": "assistant"
      }
    }
  ],
  "created": 1677664795,
  "id": "chatcmpl-7QyqpwdfhqwajicIEznoc6Q47XAyW",
  "model": "gpt-3.5-turbo-0613",
  "object": "chat.completion",
  "usage": {
    "completion_tokens": 17,
    "prompt_tokens": 57,
    "total_tokens": 74
  }
}
```

#### [GPT best-practices](https://platform.openai.com/docs/guides/gpt-best-practices/six-strategies-for-getting-better-results)

`より良い結果を得るための6つの戦略` が書かれている。

1. 明確な指示を書く: GPTは読者の心を読むことはできません。求める出力に合わせて指示を明確にします。
1. 参照テキストを提供する: GPTは誤った答えを生み出すことがあります。参照テキストを提供することで、より正確な答えが得られる。
1. 複雑なタスクを単純なサブタスクに分割する: 複雑なタスクはより高いエラーレートを持つ傾向があります。
1. GPTに「考える」時間を与える: 即座の回答よりも、時間をかけて答えを出す方が、より正確な答えが得られます。
1. 外部ツールを使用する: GPTの弱点を補うために、他のツールの出力をフィードすることが有用です。
1. 変更を系統的にテストする: パフォーマンスの改善は、それを測定できる場合に限り容易です。

外部ツールを使用するのタクティクスの一文。

> Tactic: Use embeddings-based search to implement efficient knowledge retrieval
>
> A model can leverage external sources of information if provided as part of its input.
> This can help the model to generate more informed and up-to-date responses.
> For example, if a user asks a question about a specific movie.
> It may be useful to add high quality information about the movie (e.g. actors, director, etc…) to the model’s input.
> Embeddings can be used to implement efficient knowledge retrieval, so that relevant information can be added to the model input dynamically at run-time.
>
> A text embedding is a vector that can measure the relatedness between text strings.
> Similar or relevant strings will be closer together than unrelated strings.
> This fact, along with the existence of fast vector search algorithms means that embeddings can be used to implement efficient knowledge retrieval.
> In particular, a text corpus can be split up into chunks, and each chunk can be embedded and stored.
> Then a given query can be embedded and vector search can be performed to find the embedded chunks of text from the corpus that are most related to the query (i.e. closest together in the embedding space).
>
> Example implementations can be found in the OpenAI Cookbook.
> See the tactic “Instruct the model to use retrieved knowledge to answer queries” for an example of how to use knowledge retrieval to minimize the likelihood that a model will make up incorrect facts.

これをChatGPTに解説させるとこう返ってくる。

> Q. この要点を説明して。エンべディングについて書かれている。エンべディングはどの様に有用なの？
>
> A. このテキストは、エンベディングベースの検索を用いて効率的な知識の取得を実装するという戦術について説明しています。具体的には、外部の情報源をモデルの入力として提供することで、より緻密で最新の回答を生成する手助けができると述べています。
>
> ### エンベディングとは？
>
> エンベディングは、テキスト文字列間の関連性を測定することができるベクトルです。関連性のある文字列は、無関係な文字列よりもエンベディング空間で近くに配置されます。
>
> ### エンベディングの有用性は？
>
> 1.  効率的な知識検索: テキストコーパスをチャンク（部分）に分割し、各チャンクをエンベディングして保存することができます。その後、特定のクエリが与えられた場合、そのクエリもエンベディングして、ベクトル空間内で最も関連性のあるテキストチャンクを高速に検索できます。
>
> 2.  動的な情報追加: 実行時に関連する情報をモデルの入力に動的に追加できます。例えば、特定の映画についての質問があった場合、その映画に関する高品質な情報（俳優、監督など）をモデルの入力に加えることができます。
>
> 3.  誤情報の削減: 既存の知識から選択的に情報を取得することで、モデルが誤った事実を作り出す可能性が減少します。
>
> 4.  カスタマイズと拡張性: 特定の用途や問題に対して、エンベディングを使って特別な知識ベースを構築することができます。
>
> エンベディングは、これらの方法でモデルがより正確で総合的な回答を提供するのを助ける強力なツールです。

ユーザーからの質問自体をエンべディングして、近傍にある知識(学習データとしてエンべディングして保存したもの)をプロンプトに併せて入力してあげるということ。

このアプローチを [OpenAI Cookbook](https://cookbook.openai.com/examples/vector_databases/readme) で学習したい。

### [Hugging Face Model Hub](https://huggingface.co/models)

OSSのLLMなど、Webで公開されている大規模言語モデルはローカルにダウンロードして実行できる。
有名なモデルハブであるHugging Faceには、ローカルでも実行できてMIT Licenseのものもあるので有用。

#### [gpt-neox-japanese-2.7b](https://huggingface.co/abeja/gpt-neox-japanese-2.7b)

日本語のGPT-Neo 2.7Bモデル。GPT-3に匹敵するモデル。

#### 使い方

大規模言語モデルをプログラムから扱うための標準的なライブラリとして、Hugging Faceが提供している [transformers](https://pypi.org/project/transformers/) を使う。

**インストール**

```bash
pip install transformers
```

**使用例**

```python
from transformers import AutoModelForCausalLM, AutoTokenizer

tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name)

inputs = tokenizer("こんにちは", return_tensors="pt")
outputs = model.generate(
    **inputs,
    max_length=50,
    pad_token_id=tokenizer.pad_token_id
)
generated = tokenizer.decode(
    outputs[0], skip_special_tokens=True
)
print(generated)
```

**解説**

transformersで大規模言語モデルを使った開発をする場合には、基本的に `AutoClasses` というクラス群を使うこと。これは、モデルの種類に応じて、適切なクラスをインスタンス化してくれるクラス群である。

下記は `AutoClasses` の一部。

- `AutoTokenizer`: モデルのトークナイザーをインスタンス化する。`from_pretrained` にモデル名を渡すことで、モデルのトークナイザーをインスタンス化できる。
- `AutoModelForCausalLM`: モデルをインスタンス化する。`from_pretrained` にモデル名を渡すことで、モデルをインスタンス化できる。

**参考**

- [transformers のドキュメント](https://huggingface.co/transformers/)
