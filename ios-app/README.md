# 館内ナビ iOS版

App Store / TestFlight提出用のSwiftUIプロジェクトです。Web版だけを表示する構成ではなく、ネイティブの施設検索、お気に入り、Core Location、Core Motionを含みます。

## MacまたはクラウドMacでの生成

1. Xcode 26以降とXcodeGenを用意する
2. `cd ios-app`
3. `sh Scripts/setup.sh`
4. `xcodegen generate`
5. `KannaiNavi.xcodeproj` をXcodeで開く
6. Signing & CapabilitiesでApple DeveloperのTeamを選択する
7. 実機で位置情報・方位・歩数と各施設の表示を確認する
8. Product > ArchiveからApp Store Connectへアップロードする

## 提出前に必ず行うこと

- Bundle ID `jp.olesama.kannainavi` が取得可能か確認
- AppIconを最終版へ差し替え
- 施設名・リンク・概算表示を実機確認
- 利用規約とプライバシーポリシーの正式情報を確認
- App Store Connectのプライバシー回答を実装と一致させる
- TestFlightで複数のiPhoneサイズを確認

館内GPSで正確な位置を特定しているとは表示しません。実測・施設許可が済むまでは概算案内として扱います。
