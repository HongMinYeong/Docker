# Docker 이미지 최적화

## 1. 개요

Docker 컨테이너는 애플리케이션을 개발, 테스트, 배포하는 데 유용
하지만 Docker 이미지의 용량이 클 경우 다운로드, 저장, 배포가 느려지고 네트워크 부하가 증가할 수 있음

=> Docker 이미지를 최적화하여 이미지 크기를 줄이는 것이 좋음.

Docker 이미지를 최적화하는 것은 효율적인 리소스 활용, 더 빠른 배포 및 향상된 보안에 필수적

## 2. Docker 이미지 최적화 팁
### 1. 더 작은 Base 이미지 사용
Alpine Linux 또는 Scratch와 같은 최소 기본 이미지를 사용

- ubuntu:latest 이미지 = 29.02MB
- alpine:latest 이미지 = 3.21MB

[주의: 경량화된 이미지에는 필요한 패키지가 누락될 수 있음]

### 2. 멀티 스테이지 빌드
여러 개의 FROM 명령을 사용하여 빌드

빌드에 필요한 패키지는 빌드 이미지에만 포함, 최종 이미지는 가볍게 유지

```dockerfile
# dockerfile
# 빌드 단계
FROM maven:3.8.4-openjdk-17 AS build

WORKDIR /app
COPY pom.xml .
COPY src ./src

RUN mvn clean package

# 프로덕션 단계
FROM openjdk:17-alpine AS production
COPY --from=build /app/target/myapp.jar /app/myapp.jar

EXPOSE 8080
CMD ["java", "-jar", "/app/myapp.jar"]
```
### 3. 불필요한 레이어의 수 줄이기
- Docker 이미지는 여러 개의 레이어로 구성
- 각 레이어는 Dockerfile에 정의된 `RUN`, `COPY`, `FROM` 명령문이 실행되면서 생성
- 레이어가 많을수록 이미지를 빌드하는 시간이 늘어나고 크기가 증가할 수 있음

=> 따라서 불필요한 레이어를 최소화하는 것이 중요

### 예시
다음 Dockerfile은 여러 개의 `RUN` 명령을 사용하여 불필요한 레이어를 생성

```dockerfile
# dockerfile
FROM ubuntu:latest

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install vim net-tools dnsutils -y
```
이런 경우 각 명령이 개별 레이어를 생성하므로, 하나의 레이어로 합치는 것이 좋음

### 개선된 예시
```dockerfile
# dockerfile
FROM ubuntu:latest

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y vim net-tools dnsutils
```
### 4. Production Dependencies만 설치
- 애플리케이션을 빌드할 때는 개발용 패키지나 파일이 필요하지 않음
- Maven을 사용할 경우 -DskipTests 옵션을 사용하여 테스트를 건너뛰고 production dependencies만 포함된 JAR 파일을 생성

### 예시
```dockerfile
# dockerfile
RUN mvn clean package -DskipTests
```

### 5. 불필요한 패키지 설치하지 않기
- Dockerfile에서 RUN 명령문을 사용할 때는 불필요한 패키지의 설치를 피해야 함
- apt-get을 사용할 때 --no-install-recommends 옵션을 활용하면 추천 패키지를 설치하지 않음

### 예시
```dockerfile
# dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends netcat
```

### 6. apt cache 삭제하기
- apt-get을 사용할 때 /var/lib/apt/lists/* 디렉토리에 캐시가 저장
- 이 캐시는 이미지를 빌드할 때 불필요한 용량을 차지
- 따라서 apt-get을 사용할 때는 캐시를 삭제하는 것이 좋음

### 예시
```dockerfile
# dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends netcat && \
    rm -rf /var/lib/apt/lists/*
```

### 7. .dockerignore 활용하기
- .dockerignore 파일을 사용하면 이미지를 빌드할 때 불필요한 파일이나 디렉토리를 제외할 수 있음
- 이를 통해 이미지 크기를 줄일 수 있음

### 예시
```bash
# .dockerignore
target
*.log
*.class
```

### 8. 애플리케이션 데이터를 별도 볼륨으로 분리
- 이미지를 빌드할 때 애플리케이션의 데이터를 이미지에 포함시키면 이미지 크기가 커질 수 있음
- 이럴 경우 별도의 볼륨을 사용하는 것이 좋음
- 볼륨은 컨테이너에 저장된 데이터를 외부 파일 시스템에 저장하여, 컨테이너 재시작이나 이미지 업그레이드 시에도 데이터를 유지할 수 있음

### 예시
```dockerfile
# dockerfile
FROM openjdk:17-alpine

WORKDIR /app
COPY target/myapp.jar .

VOLUME /app/data

CMD ["java", "-jar", "myapp.jar"]
```

