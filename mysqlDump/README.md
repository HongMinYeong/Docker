# MySQL 데이터 백업 및 가져오기 & Docker MySQL 볼륨 마운트

## 현재 상황

- Docker Compose를 통해 MySQL 데이터베이스 컨테이너 & 스프링부트 앱 관리
- 목표 : 기존 DB 데이터를 유지하면서 새로운 DB를 추가

## 단계별 진행

### 1. 호스트에 MySQL 설치

- 호스트(Ubuntu) 위에 MySQL을 설치
    - 로컬

### 2. 덤프 파일 생성

- 기존 데이터베이스의 데이터를 덤프화하여 SQL 파일로 저장
    - 주의. Dockerfile 과 docker-compose.yml 과 같은경로에서 실행
    
    ```bash
    mysqldump -u root -p fisa > fisa_dump.sql
    ```
    

### 3. Docker Compose 파일 수정

- Docker Compose YAML 파일을 수정하여 MySQL 컨테이너와 호스트 간의 볼륨 마운트를 설정

```bash
services:
  db:
    container_name: mysqldb
    image: mysql:latest
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: fisa
      MYSQL_USER: user01
      MYSQL_PASSWORD: user01
    volumes:
      - ./mysql/db:/var/lib/mysql
      - ./mysql-init-files/:/docker-entrypoint-initdb.d
      - ./fisa_dump.sql:/docker-entrypoint-initdb.d/fisa_dump.sql
    networks:
      - spring-mysql-net
    healthcheck:
      test: ['CMD-SHELL', 'mysqladmin ping -h 127.0.0.1 -u root --password=$$MYSQL_ROOT_PASSWORD']
      interval: 10s
      timeout: 2s
      retries: 100

```

- `./fisa_dump.sql`는 로컬 경로를 의미
- 컨테이너의 `/docker-entrypoint-initdb.d/`에 매핑
- 이 디렉토리에 있는 SQL 파일은 MySQL 컨테이너가 시작될 때 자동으로 실행

### 4. Docker Compose 실행

- YAML 파일 수정 후 Docker Compose를 실행

```bash
docker-compose down
docker-compose up -d

```

### 5. 새로운 데이터베이스 생성

- 새로운 DB를 위해 `newmysqldb`라는 서비스를 추가

```bash
  newmysqldb:
    image: mysql:latest
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=newfisa
      - MYSQL_USER=user01
      - MYSQL_PASSWORD=user01
    ports:
      - "3307:3306"  # 호스트와의 포트 매핑
    volumes:
      - ./new_mysql_data:/var/lib/mysql
      - ./mysql-init-files/:/docker-entrypoint-initdb.d
      - ./fisa_dump.sql:/docker-entrypoint-initdb.d/fisa_dump.sql

```

### 6. 컨테이너 시작 및 데이터베이스 확인

- 기존 서비스를 중지한 후 새로운 컨테이너를 시작

```bash
docker-compose down
docker-compose up -d

```

- 새로운 데이터베이스에 접속
    - 데이터를 확인

```bash
docker exec -it newmysqldb mysql -u root -p
>>> USE newfisa;
```

### 7. 로컬 데이터 추가 및 덤프화

- 로컬에서 MySQL에 데이터를 추가한 후, 다시 덤프화

```bash
mysqldump -u root -p fisa > fisa_dump.sql

```

### 8. 로컬 MySQL 서비스 중지

- 로컬 MySQL 서비스를 중지

```bash
sudo systemctl stop mysql

```

### 9. Docker 컨테이너 재실행

- 컨테이너를 다시 실행

```bash
docker-compose up -d

```

---

이 과정을 통해 기존 데이터베이스를 유지하면서 새로운 데이터베이스를 추가하고, 로컬에서 데이터를 관리할 수 있다.

필요한 경우 데이터 덤프를 통해 데이터베이스를 업데이트도 가능하다.