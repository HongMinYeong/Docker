FROM openjdk:17-slim AS base
# 작업 디렉토리 설정
WORKDIR /app

# 애플리케이션 JAR 파일을 컨테이너의 /app 디렉토리로 복사
COPY step18_empApp-0.0.1-SNAPSHOT.jar app.jar

# 헬스 체크 설정
HEALTHCHECK --interval=10s --timeout=30s CMD curl -f http://localhost:8088/index.html || exit 1


# 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "app.jar"]