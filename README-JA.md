
## ローカルマシンでビルドできるように、Cirtificatesを作成して、インストールしておく
https://i-app-tec.com/ios/apply-application.html

DeployGateコマンドをインストール
```
gem install deploygate --no-document
```

dgコマンドでデプロイ
```
cd PlayTheWheels
dg deploy --message 'this is test build'
Please input your app bundle identifier
Example: com.example.ios
Enter your app bundle identifier: jp.1001p.wheels.PlayTheWheels
```