# 테스트 및 운영 서버의 자동 배포 아키텍처

## 환경 구성

- **myserver01**: 개발 및 테스트 서버
- **myserver02**: 운영 서버

## 목표

- JAR 파일 갱신 시 실시간으로 운영 서버에 반영
    - 개발 및 테스트 서버에서 운영 서버로 JAR 파일이 수정될 때마다 자동으로 배포

## 원격 서버 접근을 위한 사전 준비 사항

### 1. SSH 키 생성

로컬 서버 (myserver01)에서 SSH 키를 생성

```bash
ssh-keygen -t rsa -b 4096

```

- **개인키와 공개키 파일 생성**
    - 개인키 파일명: `~/.ssh/id_rsa`
    - 공개키 파일명: `~/.ssh/id_rsa.pub`

### 🌿 명령어 설명

1. **ssh-keygen**: SSH 키를 생성하는 기본 명령어
    1. 비밀번호 기반 인증 대신 안전한 인증 방식을 제공
2. **t rsa**: 사용할 키 유형(type)을 지정하는 옵션으로, RSA 알고리즘을 선택
3. **b 4096**: 비트 길이를 지정하는 옵션으로, 4096비트로 설정
    1. 보안성을 높이기 위해 선택
- **키 생성 후 확인 명령어**:

```bash
ls -l .ssh
cat .ssh/authorized_keys
cat .ssh/id_rsa
cat .ssh/id_rsa.pub

```

### 2. 원격 서버에 SSH 공개 키 추가

SSH 키를 통해 비밀번호 없이 접속할 수 있도록 로컬 서버의 공개 키를 원격 서버에 추가

```bash
ssh-copy-id username@remote_server_ip

# 예시
ssh-copy-id username@10.0.2.19

```

### 3. 비밀번호 없이 접속 확인

비밀번호 없이 원격 서버에 접속할 수 있는지 확인

```bash
# myserver02에서 실행
ssh username@10.0.2.19

```

### 4. `inotify-tools` 설치

파일 수정 감지를 위해 원격 서버에서 `inotify-tools`를 설치

```bash
sudo apt-get update
sudo apt-get install inotify-tools

```

### 5. Jenkins 컨테이너 생성 및 설정

- Jenkins 컨테이너를 생성할 때, `bind mount` 옵션을 사용하여 로컬 디렉토리와 Jenkins 내부의 디렉토리를 연결
    - 이 방법을 통해 로컬에서 생성된 파일이 Jenkins 내부에서도 사용 가능하게 됨

```bash
docker run --name myjenkins2 --privileged -p 8080:8080 -v $(pwd)/appjardir:/var/jenkins_home/appjar jenkins/jenkins:lts-jdk17

```

- **옵션 설명**:
    - `-name myjenkins2`: 생성할 컨테이너의 이름을 `myjenkins2`로 설정
    - `-privileged`: 컨테이너에 추가적인 권한을 부여
    - `p 8080:8080`: 호스트의 8080 포트를 컨테이너의 8080 포트에 매핑
    - `v $(pwd)/appjardir:/var/jenkins_home/appjar`: 현재 디렉토리의 `appjardir` 폴더를 Jenkins의 `/var/jenkins_home/appjar`로 마운트
    - `jenkins/jenkins:lts-jdk17`: 사용하려는 Jenkins 이미지와 태그를 지정

- Jenkins 컨테이너가 실행된 후, `/var/jenkins_home/appjar` 경로에 `appjar` 폴더가 자동으로 생성
- 이 폴더는 Jenkins에서 빌드한 JAR 파일을 저장하는 데 사용

!https://prod-files-secure.s3.us-west-2.amazonaws.com/75620ae2-9ad6-409a-a317-5ea81d4349ba/2c7309f8-8215-4376-b1eb-2947e2c4c970/image.png

- Ngrok을 통한 Jenkins 외부 접근 설정
    - ngrok을 실행하면 로컬에서 실행 중인 Jenkins 인스턴스에 대한 공개 URL (Jenkins에 접근할 수 있는 외부 URL) 이 생성
        
        ```bash
        ngrok http 8080
        ```
        
    - ngrok을 사용하여 로컬에서 실행 중인 Jenkins에 외부에서 접근할 수 있도록 설정할 수 있음
    - ngrok은 로컬 서버를 외부 인터넷과 연결해주는 도구
- GitHub Webhooks 설정
    - GitHub 레포지토리로 이동
    - **Settings** 탭을 클릭
    - 왼쪽 사이드바에서 **Webhooks**를 선택
    - **Add webhook** 버튼을 클릭
    - **Payload URL** 필드에 ngrok URL을 추가
        - 예: `http://your-ngrok-url.ngrok.io/github-webhook/`

!https://prod-files-secure.s3.us-west-2.amazonaws.com/75620ae2-9ad6-409a-a317-5ea81d4349ba/d34a29c1-437e-4cf6-8736-91720bcd5d58/image.png

### 요약

- Jenkins 컨테이너를 bind mount 옵션으로 생성하여 로컬 디렉토리와 연결
- Jenkins 내부에 `appjar` 폴더가 자동 생성, 이를 통해 빌드한 파일을 저장
- Ngrok을 사용하여 로컬 Jenkins 인스턴스에 대한 외부 URL을 생성
    - 이 URL을 GitHub 레포지토리의 Webhooks 설정에 추가
        - GitHub 이벤트에 따라 Jenkins가 자동으로 트리거되도록 설정

 `jenkins pipeline script` 

```bash
pipeline {
    agent any

    stages {
        stage('Clone Repository') {
            steps {
                // GitHub에서 main 브랜치를 클론
                git branch: 'main', url: 'https://github.com/HongMinYeong/Docker.git'
            }
        }
          
        stage('Build') {
            steps {
                dir('./SpringApp') { // SpringApp 디렉토리로 이동
                    sh 'chmod +x gradlew' // gradlew 실행 권한 부여
                    sh './gradlew clean build -x test' // 테스트 제외하고 빌드
                    sh 'echo $WORKSPACE' // 현재 작업 공간 출력
                }
            }
        }
        
        stage('Copy jar') { 
            steps {
                script {
                    // JAR 파일 경로 정의
                    def jarFile = 'SpringApp/build/libs/SpringApp-0.0.1-SNAPSHOT.jar'                   
                    // JAR 파일을 지정된 경로로 복사
                    sh "cp ${jarFile} /var/jenkins_home/appjar/"
                }
            }
        }
    }
}

```

## 스크립트 및 자동화 구성

### 1. `change.sh` (myserver01)

```bash
#!/bin/bash

# JAR 파일 경로 설정
JAR_FILE="./SpringApp-0.0.1-SNAPSHOT.jar"

# COOLDOWN 중복 실행 방지 대기 시간 (예: 10초)
COOLDOWN=10
LAST_RUN=0

# 원격 서버 정보
REMOTE_USER="username"
REMOTE_HOST="10.0.2.19"
REMOTE_PATH="/home/username/appjardir"

# 파일 수정 감지
inotifywait -m -e close_write "$JAR_FILE" |
while read -r directory events filename; do
    CURRENT_TIME=$(date +%s)

    if (( CURRENT_TIME - LAST_RUN > COOLDOWN )); then
        echo "$(date): $filename 파일이 수정되었습니다."
        scp "$JAR_FILE" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"
        echo "$(date): JAR 파일이 원격 서버로 복사되었습니다."
        LAST_RUN=$CURRENT_TIME
    else
        echo "$(date): 쿨다운 기간 중입니다. 실행하지 않음."
    fi
done

```

### 2. `autorunning.sh` (myserver02)

```bash
#!/bin/bash

# Spring Boot 애플리케이션 재시작
if lsof -i :8888 > /dev/null; then
    kill -9 $(lsof -t -i:8888)
    echo '정상적으로 종료되었습니다.'
fi

# 새로 실행
nohup java -jar SpringApp-0.0.1-SNAPSHOT.jar > app.log 2>&1 &

echo "배포 완료 및 재실행됩니다."

```

### 3. `watch_jar.sh` (myserver02)

```bash
#!/bin/bash

# JAR 파일 경로 설정
JAR_FILE="/home/username/appjardir/SpringApp-0.0.1-SNAPSHOT.jar"

# 파일 수정 감지 및 .sh 파일 실행
inotifywait -m -e close_write "$JAR_FILE" |
while read -r directory events filename; do
    echo "$(date): $filename 파일이 수정되었습니다. 애플리케이션 재시작 중..."
    bash /home/username/appjardir/autorunning.sh
done

```

### 스크립트 실행

1. **myserver01에서 `change.sh` 실행**:
    
    ```bash
    ./change.sh &
    
    ```
    
2. **myserver02에서 `watch_jar.sh` 실행**:
    
    ```bash
    ./watch_jar.sh &
    
    ```
    

---

이 구성은 JAR 파일이 수정될 때마다 자동으로 운영 서버에 반영하고, 애플리케이션을 재시작하는 시스템을 제공합니다. 

`inotifywait`를 통해 파일 수정 이벤트를 감지하며, 쿨다운 시간으로 중복 실행을 방지합니다.

## 아키텍처 다이어그램

```bash
+-----------------+          +-----------------+          +-----------------+
|  GitHub         |          |  Ngrok          |          |  Jenkins        |
|  (Code Repo)    |          |  (Tunnel)       |          |  (CI/CD Server) |
+-----------------+          +-----------------+          +-----------------+
        |                             |                             |
        |                             |                             |
        |  Webhook on Push Event     |                             |
        +---------------------------->                             |
        |                             |                             |
        |                             +----------------------------> 
        |                             |                             |
        |                             |  Webhook Event Trigger      |
        |                             |                             |
        |                             |                             |
+-----------------+          +-----------------+          +-----------------+
|  myserver01     |          |  myserver02     |          |  Ngrok URL      |
|  (Development    |          |  (Production    |          |  (External Access) |
|   & Test Server) |          |   Server)       |          |                   |
+-----------------+          +-----------------+          +-----------------+
        |                             |                             |
        |  Copy JAR on Change        |  Deploy JAR and Restart App |
        +---------------------------->                             |
        |                             |                             |
        |                             |                             |
+-----------------+          +-----------------+          +-----------------+
|  App Code       |          |  App Code       |          |  App Code       |
|  (Spring Boot)  |          |  (Spring Boot)  |          |  (Spring Boot)  |
+-----------------+          +-----------------+          +-----------------+

```

- 코드가 푸시될 때마다 Webhook을 통해 Jenkins에 알림
- GitHub의 Webhook 이벤트를 받아 빌드를 수행하고, 빌드된 JAR 파일을 운영 서버로 복사
- **myserver01 (Development & Test Server)**: 개발 및 테스트 서버로, 코드 변경 시 JAR 파일을 모니터링하고 변경 사항이 발생하면 JAR 파일을 운영 서버로 복사
- **myserver02 (Production Server)**: 운영 서버로, Jenkins에서 복사된 JAR 파일을 받아 애플리케이션을 재시작

```bash
+----------------+                      +---------------------+
|   GitHub Repo   |                      |      ngrok         |
+----------------+                      +---------------------+
         |                                            |
         |                                            |
         |                                            |
         +--------------------------------------------+
                              |
                              | Webhook Trigger
                              |
                       +-------------------+
                       |     Jenkins       |
                       +-------------------+
                       |   CI/CD Pipeline   |
                       +-------------------+
                               |
                               | Build JAR
                               |
                       +-------------------+
                       |   myserver01      |
                       |(Development/Test) |
                       +-------------------+
                       | change.sh         |
                       +-------------------+
                               |
                               | JAR file update
                               |
                       +-------------------+
                       |   myserver02      |
                       |   (Production)    |
                       +-------------------+
                       |  watch_jar.sh     |
                       |  autorunning.sh    |
                       +-------------------+

```
