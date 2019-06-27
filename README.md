eks-practice
---

# About
EKSの学習用リポジトリ

# Version
- EKS
    - 1.12
- Terraform
    - 0.12.0

# How To Use
## クラスタの構築
terraformでVPCの構築

```
$ terraform init
$ terraform apply
```

apply後に出力された `eksctl` コマンドを入力。  
`--vpc-public-subnets` `--vpc-private-subnets` にTerraformで作成したSubnetのIDを入力する。  
`config.yaml` は起動するnodegroup(Workerノード)の設定。今回WorkerノードはPrivateSubnetへ登録し、オートスケールさせるようにする。

```
$ eksctl create cluster \
    --name <YOUR CLUSTER NAME. e.g. "search"> \
    --vpc-public-subnets <PUBLIC SUBNET IDS> \
    --vpc-private-subnets <PRIVATE SUBNET IDS> \
    -f config.yaml
```

## [WIP] Deploymentの作成
- nginxの起動
- ECRからpull

## [WIP] Serviceの作成
- cluster ip
- わり楽そう

## [WIP] Ingressの作成
- ALB ingress
- ACM

## [WIP] 監視
### Container Insights

### Datadog

## [WIP] クラスタのバージョンアップ

## nodegroupの更新
クラスタのアップデート時に行う認識

まず、green系のnodegroupをコメントアウトする
```
$ vi config.yaml
```

config.yamlを適用し、nodegroupをblue系とgreen系の2系統存在する状態にする
```
$ eksctl create nodegroup -f config.yaml
```

blue系のnodegroupドレイニングを行う
```
$ eksctl drain nodegroup search-private-blue --cluster search
```

しばらく立って、nodegroupの新規作成、podの再配置が行われるのを待ち、blue系のnodegroupの削除を行う
```
$ eksctl delete nodegroup search-private-blue --cluster search
```

次のnodegroupの更新はblueとgreenを逆に実行する。

## [WIP] StatefulSet
- PVC, PV, StorageClass
- AZ毎に配置されるか
- クラウド毎の挙動
    - EBS, PDがAZを跨げないことはどうなのか
- S3を使えたりしないか
- nodegroupの更新時にどのような挙動をするか

## [WIP] HPA

## [WIP] CA

## [WIP] CronJob

## [WIP] ServiceMesh
- Istio
- AppMesh

## [WIP] CD Tool

# 雑記
## 環境構築
VPC/RDS/ElastiCacheみたいなAWSリソースはTerraform、EKSはcksctlを使うことにした。  

理由としてはeksctlを使用したいこと。  
クラスタ/NodeGroupのバージョンアップを行う必要があり、その追従を行うのにeksctlが楽なため。  
逆にTerraformだとドレイニングを行ったりグレイスフルなアップデートが困難かつ複雑なHCLを書く必要が出てくる。

また、AWSリソースを管理したいモチベーションがあり、例えばRDSやElastiCacheなど、それらを管理するのにTerraformを使用する。  

CloudFormation出ない理由はHelmの管理をTerraformで行いたいことが理由

## リポジトリ構成
リポジトリをインフラとアプリで分けるのか、AWSリソースとK8sも分割するのかが見えてない。  

ざっくり、アプリケーションはマイクロサービスのサービス単位で、k8sのmanifestもそのリポジトリの中に含める、でいのかなと。  
で、K8sクラスタとVPCは1つのリポジトリ、インフラ用リポジトリ、として扱うといいのかなと。
