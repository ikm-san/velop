# OpenWrt | Linksys Velop WRT Pro 7 スクリプト集

## ■ 新しい OpenWrt を LN6001 で楽しもう

LN6001 / MBE70 の本家 OpenWrt への統合が進んでいます。2026年11月16日時点では、Wi-Fi 対応の [PR #25449](https://github.com/openwrt/openwrt/pull/25449) がレビュー中です。

新しい OpenWrt を試したい方は、**[ln6001-lab コミュニティファームウェア](https://github.com/ikm-san/ln6001-lab)** へどうぞ！ 機能紹介からダウンロード、インストール手順までまとめています。Linksys・OpenWrt の公式版とは別のコミュニティ版です。

純正版に戻すため、A/B の片方には純正ファームウェアを残しておきましょう。以下のスクリプトは、従来の公式ファームウェア ver1.2 向けです。

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

ルーターの IP アドレスに合わせて、次のコマンドで接続します。以下は `192.168.10.1` の例です。初期設定の `192.168.1.1` など、実際に使っているアドレスに置き換えてください。

```sh
ssh root@192.168.10.1
```

初回は表示された fingerprint（ホスト鍵の指紋）を、ルーターのコンソールなど信頼できる方法で確認して `yes` を入力します。ログインできたら、使いたいスクリプトへ進みましょう。

### 1. 鍵の変更警告が出たら、ルーターの記録だけ更新

ファームウェア更新や初期化の後は、`REMOTE HOST IDENTIFICATION HAS CHANGED` と表示されることがあります。正当な鍵変更だと確認できたら、Windows / Mac ともに次の手順で古い記録を削除して再接続します。心当たりがない場合は、先に接続先と fingerprint を確認してください。

```sh
ssh-keygen -R 192.168.10.1
ssh root@192.168.10.1
```

ホスト名や別のポートで接続している場合は、そのホスト名や `[IPアドレス]:ポート番号` を指定します。

### 2. まだ鍵の警告が続く場合は、全記録をクリア

警告に出ている保存先と接続先を確認したうえで、次の方法も使えます。バックアップを作り、`known_hosts` 内の**ほかのサーバーを含む全記録**をクリアします。その後は各接続先の fingerprint を確認して再登録してください。なお、パスワードエラーや接続タイムアウトには効果がありません。

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

## ■ ルーター本体初期化
本体底面のリセットボタンを10秒間長押し、もしくは以下のCLIコマンドを実行。  
```
firstboot && reboot now
```
