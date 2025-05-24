---
title: "Rails の ActionCable は ALB の背後にある EC2 上ではどの様に動いているのか"
emoji: "🤖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["aws", "rails", "websocket", "actioncable"]
published: false
---

## この記事は

ActionCable を使った Rails アプリケーションの挙動について、AWS などのインフラ上ではどのように動作するのかを調査した際に学んだことを解説します。

## 背景

Rails アプリケーションにおけるブルーグリーンデプロイの実現方法を調査していた際に抱いた疑問をきっかけに調査しました。

![](/images/actioncable-app-working-in-the-aws.png)

上記の図のように、Elastic Beanstalk で管理される ALB + AutoScaling + EC2 の構成で、Docker コンテナで EC2 上に Rails アプリケーション(ActionCable を利用した Websocket 通信を含む)をデプロイしていました。ちなみに WebSocket に関わるユーザーからのリクエスト・レスポンスに関しては、リクエストは WebSocket を使わずに Web API を通じて行い、Rails の API コントローラ以下で ActionCable のブロードキャストを実行しています。クライアントはレスポンスのみを WebSocket で受け取る構成です。

この構成で、[Elastic Beanstalk を使用したブルー/グリーンデプロイ](https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/dg/using-features.CNAMESwap.html) のサービス紹介を参考に、Elastic Beanstalk の CNAME スワップが Rails アプリケーションの無停止デプロイに利用可能か評価していました。

この時、WebSocket 通信が都度 HTTP リクエストを行わず、確立したコネクションを維持し続けることを踏まえると、CNAME スワップの影響として以下の疑問が生じました。

- CNAME スワップを行うと、WebSocket のコネクションは維持されるのか
- WebSocket のコネクションが維持される場合、CNAME スワップ後の新しい EC2 インスタンスにはいつ接続されるのか
- WebSocket のコネクションが維持される場合、CNAME スワップ後の新しい EC2 インスタンスに接続されるまでの間、WebSocket のコネクションを通じてレスポンスを受け取れるのか

この疑問の是非によっては、ActionCable を利用した Rails アプリケーションのユーザーに不具合が発生する可能性があります。ブロードキャストされたメッセージが受信できない時間が発生する可能性がある。もしくは deprecated されるべき EC2 サーバの処理が続いてしまいユーザーに見える挙動に一貫性がなくなる可能性があります。

## 各リソースでの WebSocket の挙動

この疑問の解決のため、まずは使用している各リソースでの WebSocket の挙動について調査しました。

### CloudFront

[CloudFront ディストリビューションで WebSockets を使用する](https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/distribution-working-with.websockets.html) によると、CloudFront は WebSocket をサポートしています。WebSocket リクエストは、CloudFront がオリジンサーバーにリクエストを転送します。この際、Upgrade ヘッダーを含む HTTP/1.1 リクエストがオリジンに送信されます。そのため、実質の WebSocket リクエストの処理はオリジンサーバに委ねられます。

### ALB (Application Load Balancer)

[Application Load Balancer のリスナー](https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/application/load-balancer-listeners.html) によると、ALB もまた WebSocket をネイティブにサポートしています。

> Application Load Balancer は WebSocket のネイティブ サポートを提供します。HTTP 接続のアップグレードを使用して、既存の HTTP/1.1 接続を WebSocket (ws または wss) 接続にアップグレードできます。アップグレードすると、リクエストに使用される TCP 接続 (ロードバランサーとターゲットへの) は、ロードバランサーを介したクライアントとターゲット間の永続的な WebSocket 接続になります。WebSocket は、HTTP リスナーと HTTPS リスナーの両方で使用できます。リスナーに対して選択したオプションは、HTTP トラフィックだけでなく、WebSocket 接続にも適用されます。詳細については、Amazon CloudFront デベロッパーガイドの How the WebSocket Protocol Works を参照してください。

ALB は HTTP/1.1 のアップグレードリクエストを受け入れると、ロードバランサーを介してクライアント-ターゲット間とで WebSocket の接続を確立します。以降の WebSocket の通信は、この確立されたコネクションを通じて行われます。ALB にはスティッキーセッションの設定がありますが、WebSocket の接続はプロトコルレベルで接続の張り付きが保証されるため、スティッキーセッションを有効にする必要はありません。

### EC2 (Rails アプリケーション)

[Action Cable の概要](https://railsguides.jp/action_cable_overview.html) によると、以下の記述があります。

> 2.5 Pub/Sub
> Pub/Sub（Publish-Subscribe）はメッセージキューのパラダイムの一種であり、情報の送信者（パブリッシャ）は個別の受信者を指定する代わりに、受信側の抽象クラスにデータを送信します。Action Cable では、この Pub/Sub アプローチを用いてサーバーと多数のクライアントの間の通信を行います。

サーバからのメッセージのブロードキャストは直接クライアントに送信されるわけではなく、受信側の抽象クラスである Pub/Sub を通じて行われます。
今回利用している [Postgresql アダプタの実装](https://github.com/rails/rails/blob/main/actioncable/lib/action_cable/subscription_adapter/postgresql.rb)を見ると、PostgreSQL の LISTEN/NOTIFY を利用してメッセージをブロードキャスト/サブスクライブしています。

## PostgreSQL の Pub/Sub 挙動の図解

他の人の発表資料の引用となりますが、PostgreSQL を ActionCable アダプタとして利用した場合の挙動について、図解がわかりやすかったので引用します。(p.19,20,21 の複数 Rails サーバと Postgresql/Redis の Pub/Sub サーバの存在している図です)

@[speakerdeck](2e3be1ceacfe4c2db3e24aec01b7c247)

このスライド中の図の様に、ActionCable のブロードキャストは一度 Rails サーバから Pub/Sub サーバに送信され、その後 Pub/Sub サーバに接続している Rails サーバにブロードキャストされ、その後 Rails サーバから WebSocket 接続しているクライアントの中で、ブロードキャスト対象のチャンネルをサブスクライブしているクライアントにメッセージが送信されます。

こうした挙動を Rails アプリケーション以降のリソースでしていることによって、たとえクライアントが接続している Rails サーバがロードバランサーの背後にある 1/N のインスタンスであっても、別の Rails サーバからブロードキャストされたメッセージを受信することが可能になっています。

## 疑問点についての動作確認

実際に CNAME スワップを行い、WebSocket のリクエストを実行するとどうなるのかを確認しました。結果として以下のようになりました。

- CNAME スワップを行うと、WebSocket のコネクションは維持されるのか => 維持された
- WebSocket のコネクションが維持される場合、CNAME スワップ後の新しい EC2 インスタンスにはいつ接続されるのか => WebSocket のコネクションが切れたタイミング、もしくはリロードをするなどして新しい WebSocket 接続のリクエストを行ったタイミングで接続される
- WebSocket のコネクションが維持される場合、CNAME スワップ後の新しい EC2 インスタンスに接続されるまでの間、WebSocket のコネクションを通じてレスポンスを受け取れるのか => 受け取れた

## 考察

ここまでの調査結果と動作確認の結果を踏まえ、ActionCable の Rails アプリケーションを Elastic Beanstalk の CNAME スワップを利用してブルーグリーンデプロイすることは可能であると考えられます。冒頭に掲載した図を再掲しておきます。

![](/images/actioncable-app-working-in-the-aws.png)

今回ケースでは CNAME スワップを行うと、WebSocket のコネクションは維持されますが、Blue 環境にあった Rails サーバ自体は Pub/Sub サーバと接続しているため、Green 環境の Rails サーバにブロードキャストされたメッセージを受信することができます。また、WebSocket に関わるクライアントからのリクエストは Web API で行われているため、こちらは CNAME スワップ後は CloudFront -> ALB -> Green 環境とトラフィックが一意に流れることになります。これにより、WebSocket リクエストの処理は Green 環境の Rails サーバにて一意に行われることになり、Blue 環境に接続しているクライアントも Green 環境の Rails サーバにブロードキャストされたメッセージを受信することができます。

ただし、Blue 環境を削除するタイミングでは、Blue 環境の Rails サーバは Pub/Sub サーバとの接続を切断し、WebSocket のコネクションも切断されるので、このタイミングで WebSocket を接続し直すまでの間のサブスクライブが中断されることへのケアは別途必要になるかもしれません。これは別途検討事項となりますが、おおむね CNAME スワップを利用した ActionCable の Rails アプリケーションのブルーグリーンデプロイは可能であると考えられます。

## まとめ

ActionCable を利用した Rails アプリケーションの WebSocket の挙動について、AWS の各リソースでの挙動を調査し、CNAME スワップを利用したブルーグリーンデプロイが可能であることを確認しました。
この調査を通じて、ActionCable のブロードキャストの仕組みや、PostgreSQL の Pub/Sub 機能を利用したメッセージの配信方法についても理解が深まりました。今後、ActionCable を利用したアプリケーションの設計やデプロイにおいて、これらの知識が役立つことを期待しています。
