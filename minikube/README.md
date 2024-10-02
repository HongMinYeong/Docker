# Spring 애플리케이션 클러스터 구성하기

## 1. Docker Image 만들기

저번 실습때 이용했던 SpringApp 프로젝트 파일을 사용했다. 

빌드한 jar파일(`SpringApp-0.0.1-SNAPSHOT.jar`)을 해당 디렉토리에 넣어주고 

![1001](https://github.com/user-attachments/assets/66c28d5a-c651-4ddd-a7c8-81ecde099fc5)


나는 혹시 몰라서 jar 파일에 실행권한도 추가해줬다. 

```yaml
$ chmod +x SpringApp-0.0.1-SNAPSHOT.jar
```

### 1-1. 이미지 생성을 위한 Dockerfile 작성

docker image를 만들기 위해 build 하기 전 dockerfile을 작성해줬다. 

```yaml
FROM openjdk:17-slim AS base
# 작업 디렉토리 설정
WORKDIR /app

# 애플리케이션 JAR 파일을 컨테이너의 /app 디렉토리로 복사
COPY SpringApp-0.0.1-SNAPSHOT.jar app.jar

# 헬스 체크 설정
HEALTHCHECK --interval=10s --timeout=30s CMD curl -f http://localhost:8888/test || exit 1

# 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 1-3. Docker Image 생성 및 push

```yaml
$ docker build -t hongminyeong/hongminikube:1.0 .
```

나는 도커허브에 push 까지 해주었다. 

```yaml
$ docker push hongminyeong/hongminikube:1.0
```

## 2. deployment.yaml 작성하기

### 2-1. deployment.yaml 파일이란

쿠버네티스는 컨테이너를 등록하고 관리하기 위해 Pod라는 오브젝트를 사용하는데 Pod는 다시 Pod의 단위를 그룹으로 만들어 관리한다. 

이때, Pod의 복제 단위인 Replica와 Replica의 배포단위인 Deployment 가 바로 그것들이다. 

즉, 지금 내가 만든 hongminikube 어플리케이션은 컨테이너 이미지화 되어있고 이 컨테이너 이미지는 Pod에 탑재되어 관리된다. 

쿠버네티스에 이러한 Pod를 몇쌍의 복제로 만들어 (=레플리카) 배포(Deployment)할 것인지 지정하는것이 deployment.yaml 파일이다. 

`deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hongminikube
spec:
  replicas: 3  # Pod 수를 3으로 설정
  selector:
    matchLabels:
      app: hongminikube
  template:
    metadata:
      labels:
        app: hongminikube
    spec:
      containers:
      - name: hongminikube
        image: hongminyeong/hongminikube:1.0
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 8888

```
![1002](https://github.com/user-attachments/assets/e1400398-35b7-454a-812e-cdfc74ae904b)

작성이 완료되면 다음과같은 명령어로 실행한다. 

```yaml
$ kubectl apply -f deployment.yaml 
$ kubectl get deployments # 생성된 deployment 오브젝트 확인 
```

## 3. service.yaml 작성 및 배포

이제 deployment 된 pod들을 외부에서 접속할 수 있게 ip 와 port를 노출시켜줘야 하기 때문에 이를 위해 service.yaml 을 작성해준다. 

`service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hongminikube
spec:
  selector:
    app: hongminikube
  ports:
  - port: 8888
    targetPort: 8888
    nodePort: 30090
  type: NodePort

```

컨테이너 이미지에서 8888으로 expose한 port를 30090 으로 nodePort를 이용해 expose 시켜주었다. 

마찬가지로 명령어로 적용시켜준다. 

```yaml
$ kubectl apply -f service.yaml
```

![1003](https://github.com/user-attachments/assets/4fba5493-c065-4a3b-8e28-88d025ac934b)

## 4. 웹 브라우저를 통한 접속

nodePort 를 통해 생성한 hongminikube 서비스에 접근하는 IP 및 Port를 아래 명령어를 통해 확인 후 

```yaml
$ minikube service hongminikube 
```

![1004](https://github.com/user-attachments/assets/d5dd0214-02ad-4563-9f0c-5060f55d5c28)

웹 브라우저에서 확인하게 위해  VSC 에서 포트포워딩을 진행해주었다. 

![1008](https://github.com/user-attachments/assets/c9a39243-fab3-4e8a-b540-bdc24d69b88a)

이제 [localhost/test로](http://localhost/test로) 접속시 

![1006](https://github.com/user-attachments/assets/578e746d-9a8e-4e94-b00a-b77794be8391)

스프링부트로 작성한 프로젝트가 잘 나오는 모습이다. 

## 5. 아키텍처 개요
다음은 DaC(Diagrams as Code)를 통한 다이어그램이다. 
아래의 python 코드를 통해 다이어그램 png 파일을 저장했다.
```python
from diagrams import Cluster, Diagram
from diagrams.k8s.compute import Pod
from diagrams.k8s.network import Service
from diagrams.aws.general import Users
from IPython.display import Image, display

# 다이어그램 생성 및 저장
with Diagram("User to Services to Pods", show=False, filename="ce"):
    user = Users("users")  # 사용자 노드 정의
    
    with Cluster("Service (hongminikube)" ,graph_attr={"bgcolor": "lightblue"}):
        svc = Service("Service(hongminikube)")
        
        pod1 = Pod("Pod 1\n(Spring App)", style="filled", fillcolor="white")
        pod2 = Pod("Pod 2\n(Spring App)", style="filled", fillcolor="white")
        pod3 = Pod("Pod 3\n(Spring App)", style="filled", fillcolor="white")

        svc >> pod1
        svc >> pod2
        svc >> pod3

    # 사용자와 서비스 연결
    user >> svc

# 이미지 표시
display(Image(filename="ce.png", width=500))
	
```

 ![1003](https://github.com/user-attachments/assets/7bc55855-c990-4a45-b4c2-427ab5b3c5da)

> 유저가 웹브라우저를 통해 서비스 요청 (localhost:30090)
> 
> 
> ⬇️
> 
> minikube 클러스터에서 Kubernetes가 이 요청을 처리 
> 
> ⬇️
> 
> Service가 클러스터 내에서 Pod로 요청을 라우팅 (요청을 각 Pod로 분산) 
> 
> ⬇️
> 
> 각 Pod는 Spring 애플리케이션의 인스턴스
> 
> ⇒요청흐름 
> 
> 1️⃣ 사용자가 Minikube IP와 NodePort(30090)로 요청을 보냄.
> 
> 2️⃣ Kubernetes의 Service가 이 요청을 수신하고 `selector`에 따라 Pod로 라우팅.
> 
> 3️⃣ 각 Pod에서 Spring 애플리케이션이 요청을 처리.
>
> 
> 
> ```yaml
> +----------+         +-------------+          +------------------+
> |  사용자   | -----> |  Service    | -----> |      Pod 1       |
> |          |         | (hongminikube)|       |  (Spring App)    |
> |          |         +-------------+          +------------------+
> |          |                              
> |          |                               
> |          |                              
> |          |                              
> |          |         +-------------+          +------------------+
> |          | -----> |  Service    | -----> |      Pod 2       |
> |          |         | (hongminikube)|       |  (Spring App)    |
> |          |         +-------------+          +------------------+
> |          |                              
> |          |                              
> |          |                              
> |          |                              
> |          |         +-------------+          +------------------+
> |          | -----> |  Service    | -----> |      Pod 3       |
> |          |         | (hongminikube)|       |  (Spring App)    |
> +----------+         +-------------+          +------------------+
> 
> ```
> 


```yaml
$ minikube dashboard # dashboard 확인 명령어 
```

Kubernetes 대시보드로 확인 
![1007](https://github.com/user-attachments/assets/4be21ef8-640f-488c-a5c2-8c413ff012e9)
