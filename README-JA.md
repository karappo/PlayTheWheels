
## ローカルマシンでビルドできるように、Cirtificatesを作成して、インストールしておく
https://i-app-tec.com/ios/apply-application.html

## エントリーポイント

Xcodeで開くのは、`PlayTheWheels.xcodeproj`ではなく`PlayTheWheels.xcworkspace`の方にすること。
でなければ、ビルド時にライブラリが見つからないという下記の様なエラーが出てしまう。

```
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```


## dgコマンドでデプロイ

- `--message`オプションを使う
- 対話形式で、bundle identifierをその都度打つ必要がある

```
cd PlayTheWheels
dg deploy --message 'this is test build'
Please input your app bundle identifier
Example: com.example.ios
Enter your app bundle identifier: jp.1001p.wheels.PlayTheWheels
```

留意点

- ProvisioningFileにデバイスのUUIDが登録されていないとインストールできない
