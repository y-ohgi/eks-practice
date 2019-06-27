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

apply後に出力された `eksctl` コマンドを入力

```
$ eksctl create cluster --name ${var.name} --vpc-public-subnets ${join(",", module.vpc.public_subnets)} --vpc-private-subnets ${join(",", module.vpc.private_subnets)} -f config.yaml
```

## [WIP] Deploymentの作成
nginx

## [WIP] Serviceの作成
cluster ip

## [WIP] Ingressの作成
ALB ingress

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

## [WIP] CD

## [WIP] CronJob

## [WIP] ServiceMesh
