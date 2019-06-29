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

## Deploymentの作成
### コマンド
```console
$ kubectl create deployment nginx --image nginx
```

```console
$ kubectl get all
NAME                        READY   STATUS    RESTARTS   AGE
pod/nginx-55bd7c9fd-7gcmt   1/1     Running   0          31s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   23h

NAME                    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1         1         1            1           32s

NAME                              DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-55bd7c9fd   1         1         1       32s
```

### Manifest
```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  labels:
    run: nginx
  name: nginx

spec:
  replicas: 1
  selector:
    matchLabels:
      run: nginx
  template:
    metadata:
      labels:
        run: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
```


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

# Tips
## クラスタ内に一時的なコンテナの作成
```console
$ kubectl run test -it --restart=Never --image=amazonlinux:2 bash
bash-4.2#
```

削除
```console
$ kubectl get all
NAME       READY   STATUS      RESTARTS   AGE
pod/test   0/1     Completed   0          116s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   23h
$ kubectl delete pod/test
pod "test" deleted
$ kubectl get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   23h
```


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
