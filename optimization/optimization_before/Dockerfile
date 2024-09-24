# 공식 OpenJDK 17 이미지 사용
FROM openjdk:17-jdk

# JAR 파일을 위한 빌드 인자 설정
ARG JAR_FILE=./build/libs/*-SNAPSHOT.jar

# JAR 파일을 컨테이너에 복사
COPY ${JAR_FILE} app.jar

# 애플리케이션 포트 공개
EXPOSE 8080

# 애플리케이션 실행 명령 정의
ENTRYPOINT ["java", "-jar", "/app.jar"]

#그러나 위와 같이 Docker 이미지를 만드는 것은 상당히 비효율적이다.

#Docker는 빌드 시 레이어마다 캐시 기능을 사용할 수 있기 때문에 빠른 빌드가 가능하다.

#만약 변경된 부분이 없다면 캐시를 이용해 기존에 빌드했던 레이어를 재사용하기 때문에 속도가 빨라진다.

#하지만 위와 같이 코드를 작성하면 jar 파일 전체를 빌드하기 때문에 캐시 기능을 사용할 수 없다.

#Dockerfile을 위 구조로 구성하면, Java의 모든 구조가 jar 파일로 묶이기 때문에 layer를 재사용하기 어렵기 때문이다.