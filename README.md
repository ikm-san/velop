# OpenWrt搭載 Linksys Velop WRT Pro 7 サンプルスクリプト集

Velop WRT Pro 7にて動作検証済みのサンプルスクリプト集です。
  
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
Terminalをまず起動する  
* Winの場合 - Win + X -> A で立ち上がります  
* Macの場合 - CMD + Space -> terminalと入力して立ち上げるのが一番早いかも  

OpenWrtルーターにSSHログインする  
`ssh root@192.168.10.1`と入力してエンター  
SSHログインできたら、#スクリプトへ進みます。  
もし、警告が出てログインできない場合は、以下のコマンドを実行して再度トライすれば入れます。  
初回はyes/no/fingerprintあたりの設問が出ます。yesで進んでください。 

### Win Powershell
```
Clear-Content .ssh\known_hosts -Force
```
### Mac Terminal
```
ssh-keygen -R 192.168.10.1
```

## ■ ルーター本体初期化
本体底面のリセットボタンを10秒間長押し、もしくは以下のCLIコマンドを実行。  
```
firstboot && reboot now
```
