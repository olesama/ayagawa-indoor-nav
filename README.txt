綾川イオン館内ナビ - Replitでそのまま動かせる版
================================================

入っているファイル
- index.html : 館内ナビ本体
- main.py : Replitで公開するためのWebサーバー
- .replit : Runボタン用設定
- manifest.webmanifest : ホーム画面追加用
- service-worker.js : 最低限のオフライン対応

Replitで動かす手順
1. 新しいReplitプロジェクトを作る
2. このZIPをアップロードして展開する
3. index.html / main.py / .replit などがプロジェクト直下にある状態にする
4. 「Run」を押す
5. Webviewに綾川イオン館内ナビが表示されれば成功
6. Publish/Deployできる状態なら、そのまま公開URLを作れる

注意
この版は「アプリとして動く」状態にしてありますが、
館内地図の店舗座標・通路・EV/ES・WCは最終的に公式図面/現地照合が必要です。
