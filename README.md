eks-practice
---

# About
EKSの学習用リポジトリ

# Version
- EKS
    - 1.12
- Terraform
    - 0.12.0
- Helm
    - 2.12.0

# How To Use
## クラスタの構築
terraformでVPCの構築

```
$ cd /path/to/eks-practice/aws
$ terraform init
$ terraform apply
```

apply後に出力された `eksctl` コマンドを入力。  
`--vpc-public-subnets` `--vpc-private-subnets` にTerraformで作成したSubnetのIDを入力する。  
`config.yaml` は起動するnodegroup(Workerノード)の設定。今回WorkerノードはPrivateSubnetへ登録し、オートスケールさせるようにする。

```
$ cd /path/to/eks-practice/eks
$ eksctl create cluster \
    --name <YOUR CLUSTER NAME. e.g. "search"> \
    --vpc-public-subnets <PUBLIC SUBNET IDS> \
    --vpc-private-subnets <PRIVATE SUBNET IDS> \
    -f config.yaml
```

## Deploymentの作成
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

```console
$ kubectl delete deploy/nginx
```

## Serviceの作成
Deploymentの作成後、そのDeploymentを用いたServiceを作成
```console
$ kubectl create deployment nginx --image nginx
deployment.apps/nginx created
$ kubectl expose deploy nginx --port=80 --target-port=80
service/nginx exposed
```

動作確認
```console
$ kubectl get all
NAME                        READY   STATUS    RESTARTS   AGE
pod/nginx-55bd7c9fd-v7x2c   1/1     Running   0          49s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.100.0.1       <none>        443/TCP   23h
service/nginx        ClusterIP   10.100.160.225   <none>        80/TCP    12s

NAME                    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1         1         1            1           49s

NAME                              DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-55bd7c9fd   1         1         1       49s
```

```console
$ kubectl run test -it --restart=Never --rm --image=amazonlinux:2 -- curl -I http://nginx:80
HTTP/1.1 200 OK
Server: nginx/1.17.0
Date: Sat, 29 Jun 2019 04:01:56 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 21 May 2019 14:23:57 GMT
Connection: keep-alive
ETag: "5ce409fd-264"
Accept-Ranges: bytes

pod "test" deleted
```

削除
```console
$ kubectl delete svc/nginx
service "nginx" deleted
$ kubectl delete deploy/nginx
deployment.extensions "nginx" deleted
```

## [WIP] Ingressの作成
- ALB ingress
- ACM

```console
$ helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
"incubator" has been added to your repositories
$ helm install incubator/aws-alb-ingress-controller \
    --set clusterName=test \
    --set autoDiscoverAwsRegion=true \
    --set autoDiscoverAwsVpcID=true \
    --name alb-ingress \
    --namespace kube-system
```

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

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx # has to match .spec.template.metadata.labels
  serviceName: "nginx"
  replicas: 3 # by default is 1
  template:
    metadata:
      labels:
        app: nginx # has to match .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: k8s.gcr.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "my-storage-class"
      resources:
        requests:
          storage: 1Gi

```


## [WIP] HPA


## [WIP] CronJob


## [WIP] ServiceMesh
- Istio
- AppMesh

## [WIP] CD Tool

# Tips
## Helmのインストール

helmのインストール
```console
$ brew install kubernetes-helm
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

tillerのインストール
```console
$ kubectl create serviceaccount --namespace kube-system tiller
serviceaccount/tiller created
$ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
clusterrolebinding.rbac.authorization.k8s.io/tiller-cluster-rule created
$ helm init --service-account tiller
  :
Happy Helming!
```

> [Helm](https://helm.sh/docs/install/)

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
