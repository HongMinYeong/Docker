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
