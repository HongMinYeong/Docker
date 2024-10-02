# Spring 애플리케이션을 Minikube에 Docker로 배포

## 1. Docker Image 만들기

저번 실습때 이용했던 SpringApp 프로젝트 파일을 사용했다. 

빌드한 jar파일(`SpringApp-0.0.1-SNAPSHOT.jar`)을 해당 디렉토리에 넣어주고 

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/75620ae2-9ad6-409a-a317-5ea81d4349ba/6b61b324-03f2-4f9e-8cec-1e8057af480a/image.png)

나는 혹시 몰라서 jar 파일에 실행권한도 추가해줬다. 

```bash
$ chmod +x SpringApp-0.0.1-SNAPSHOT.jar
```

### 1-1. 이미지 생성을 위한 Dockerfile 작성

docker image를 만들기 위해 build 하기 전 dockerfile을 작성해줬다. 

```bash
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

```bash
$ docker build -t hongminyeong/hongminikube:1.0 .
```

나는 도커허브에 push ,까지 해주었다. 

```bash
$ docker push hongminyeong/hongminikube:1.0
```

## 2. deployment.yaml 작성하기

### 2-1. deployment.yaml 파일이란

쿠버네티스는 컨테이너를 등록하고 관리하기 위해 Pod라는 오브젝트를 사용하는데 Pod는 다시 Pod의 단위를 그룹으로 만들어 관리한다. 

이때, Pod의 복제 단위인 Replica와 Replica의 배포단위인 Deployment 가 바로 그것들이다. 

즉, 지금 내가 만든 hongminikube 어플리케이션은 컨테이너 이미지화 되어있고 이 컨테이너 이미지는 Pod에 탑재되어 관리된다. 

쿠버네티스에 이러한 Pod를 몇쌍의 복제로 만들어 (=레플리카) 배포(Deployment)할 것인지 지정하는것이 deployment.yaml 파일이다. 

`deployment.yaml`

```bash
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

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/75620ae2-9ad6-409a-a317-5ea81d4349ba/d7613772-1048-44ce-9994-9977bb17e682/image.png)

작성이 완료되면 다음과같은 명령어로 실행한다. 

```bash
$ kubectl apply -f deployment.yaml 
$ kubectl get deployments # 생성된 deployment 오브젝트 확인 
```

## 3. service.yaml 작성 및 배포

이제 deployment 된 pod들을 외부에서 접속할 수 있게 ip 와 port를 노출시켜줘야 하기 때문에 이를 위해 service.yaml 을 작성해준다. 

`service.yaml`

```bash
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

컨테이너 이미지에서 8888으로 expose한 port를 30090 으로 nodePost를 이용해 expose 시켜주었다. 

마찬가지로 명령어로 적용시켜준다. 

```bash
$ kubectl apply -f service.yaml
```

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/75620ae2-9ad6-409a-a317-5ea81d4349ba/1eff6b0f-ecf6-44ee-b59e-67e61311a061/image.png)

## 4. 웹 브라우저를 통한 접속

nodePort 를 통해 생성한 hongminikube 서비스에 접근하는 IP 및 Port를 아래 명령어를 통해 확인 후 

```bash
$ minikube service hongminikube 
```

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/75620ae2-9ad6-409a-a317-5ea81d4349ba/2639579d-d697-4e41-a1bb-0fcbc04b9f34/image.png)

웹 브라우저에서 확인하게 위해  VSC 에서 포트포워딩을 진행해주었다. 

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/75620ae2-9ad6-409a-a317-5ea81d4349ba/e364a98e-f18c-4a83-afe9-04c8e28eb0ca/image.png)

이제 [localhost/test로](http://localhost/test로) 접속시 

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/75620ae2-9ad6-409a-a317-5ea81d4349ba/4c3638ce-3aba-4478-aab5-561d1179c91d/image.png)

스프링부트로 작성한 프로젝트가 잘 나오는 모습이다. 

## 5. 아키텍처 개요

 

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
> ```bash
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

```bash
$ minikube dashboard # dashboard 확인 명령어 
```

Kubernetes 대시보드로 확인 

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/75620ae2-9ad6-409a-a317-5ea81d4349ba/33a0c934-456c-4099-8e42-bd1d930bdf10/image.png)