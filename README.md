# OpenWrt | Linksys Velop WRT Pro 7 スクリプト集

## ■ 新しい OpenWrt ベースのファームウェアをお探しの方へ

LN6001 / MBE70 の upstream OpenWrt（本家 OpenWrt）への統合作業を進めています。2026年11月16日時点では、Wi-Fi 対応の [PR #25449](https://github.com/openwrt/openwrt/pull/25449) はレビュー中で、まだすべての変更がマージされたわけではありません。

新しい OpenWrt ベースのファームウェアを試したい方は、**[ln6001-lab コミュニティファームウェア](https://github.com/ikm-san/ln6001-lab)** をご覧ください。ダウンロード、機能、対応モデル、インストール手順と注意事項をまとめています。これは **Linksys・OpenWrt の公式リリースではない非公式コミュニティ版**です。

導入前にリンク先の注意事項を確認し、純正ファームウェアへ戻せるよう **A/B の片方のスロットには純正ファームウェアを残してください**。このページのスクリプトは下記の公式ファームウェア向けで、コミュニティ版への適用を前提としていません。

---

Velop WRT Pro 7 (LN6001/MBE70)にて動作検証済みのサンプルスクリプト集です。
公式ファームウェアver1.2専用です。
  
## ■ LuCI日本語化スクリプト
LN6001-JP ver 1.x 向けに、Web管理画面のメニューを日本語化するためのスクリプトです。  
日本語の基本翻訳に加え、DDNS / Firewall / OpenVPN / Software / UPnP の翻訳パッケージをインストールし、LuCIの既定言語を日本語、タイムゾーンを Asia/Tokyo に設定します。
```
curl -sS -o /tmp/jp_setup.sh https://raw.githubusercontent.com/ikm-san/velop/main/jp_setup.sh && sh /tmp/jp_setup.sh -v
```

## ■ WDS子機として設定するスクリプト
２台のVelop WRT Pro 7を繋ぐための設定スクリプトです。6GHz帯をバックホールにしてWiFiを拡張する一番シンプルな方法です。  
親機側の設定は特にありません。子機側にターミナルでSSH接続して、以下のスクリプトを実行してください。
```
curl -sS -o /tmp/wds_setup.sh https://raw.githubusercontent.com/ikm-san/velop/main/wds_setup.sh && sh /tmp/wds_setup.sh -v
```

## ■ 広告ブロック導入スクリプト
ブラウザの広告表示を９割近くブロックします。adblock導入後はスマホ等のすべての接続デバイスで効果を発揮します。  
ビジネスや教育の現場で集中したい／させたい場合や、子供に見せたくないゲーム・マンガ広告を極力グレーアウトします。
```
curl -sS -o /tmp/adb_setup.sh https://raw.githubusercontent.com/ikm-san/velop/main/adb_setup.sh && sh /tmp/adb_setup.sh -v
```

## ■ ワイヤレスアクセスポイント・ブリッジモード設定導入スクリプト
ワイヤレスアクセスポイント・ブリッジモードとして設定するスクリプトです。OpenWrt界隈ではDumb APと呼ばれます。  
完全にコントロールを切るとルーターのIPアドレスを見失ったときに困るので、IPアドレスを指定して残すようにしました。  
再起動後も指定したIPアドレスでWEB管理画面へのログインおよびSSH接続が可能です。ダメな場合は初期化してください。
```
curl -sS -o /tmp/dumb_ap_setup.sh https://raw.githubusercontent.com/ikm-san/velop/main/dumb_ap_setup.sh && sh /tmp/dumb_ap_setup.sh -v
```


  
## ■ ターミナルへの入り方

* Windows：スタートメニューから PowerShell または Windows Terminal を開きます（管理者権限は不要）。
* Mac：CMD + Space を押し、`Terminal` と入力して開きます。

まずルーターの **現在の LAN IP アドレス**を確認してください。以下は `192.168.10.1` に変更した構成の例です。初期設定の `192.168.1.1` や別のアドレスを使っている場合は、すべて実際のアドレスに置き換えてください。

```sh
ssh root@192.168.10.1
```

初回の接続確認では、表示されたホスト鍵の fingerprint（指紋）が接続先ルーターのものか、信頼できる方法（本体のコンソールなど）で確認してから `yes` を入力します。ログインできたら、目的のスクリプトへ進んでください。

### 1. ホスト鍵の変更警告が出た場合：まずルーターの記録だけ削除

ファームウェアの入れ替えや初期化でルーターのホスト鍵が変わると、`REMOTE HOST IDENTIFICATION HAS CHANGED` と表示されることがあります。**心当たりのない変更では先に接続先と fingerprint を確認し、警告を消すためだけに削除しないでください。**

正当な鍵変更と確認できたら、Windows / Mac ともに次のコマンドで対象ルーターの古い記録だけを削除し、再接続します。

```sh
ssh-keygen -R 192.168.10.1
ssh root@192.168.10.1
```

ホスト名で接続している場合はそのホスト名、標準以外のポートなら `[192.168.10.1]:ポート番号` の記録を対象にします。新しい fingerprint を確認してから登録してください。

### 2. それでも解決しない場合：バックアップ後に全記録をクリア（最終手段）

まず警告が示すファイル・接続先・ポートが正しいか確認してください。接続タイムアウトやパスワードエラーは、この操作では直りません。

**以下はルーターだけでなく、その `known_hosts` ファイル内の全サーバーのホスト鍵記録を消します。ほかの接続先も次回から初回接続扱いとなり、鍵の再確認が必要です。影響を理解し、正当な鍵変更を確認できた場合だけ実行してください。** 日時付きバックアップを作ってからクリアします。SSH 設定で保存先を変更している場合は、そのファイルを確認してください。

#### Windows PowerShell

```powershell
$knownHosts = Join-Path $HOME '.ssh\known_hosts'
$backup = "$knownHosts.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')"
try {
    Copy-Item -LiteralPath $knownHosts -Destination $backup -ErrorAction Stop
    Clear-Content -LiteralPath $knownHosts -Force -ErrorAction Stop
} catch {
    Write-Error $_
}
```

#### Mac Terminal

```sh
known_hosts="$HOME/.ssh/known_hosts"
cp -p "$known_hosts" "$known_hosts.bak-$(date +%Y%m%d-%H%M%S)-$$" && : > "$known_hosts"
```

再接続時は各接続先の fingerprint を信頼できる方法で確認してから登録してください。不明な警告が続く場合は、無理に接続せず原因を調べてください。

## ■ ルーター本体初期化
本体底面のリセットボタンを10秒間長押し、もしくは以下のCLIコマンドを実行。  
```
firstboot && reboot now
```
