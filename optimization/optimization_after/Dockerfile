FROM adoptopenjdk:17-jre-hotspot as builder
WORKDIR application
ARG JAR_FILE=build/libs/*.jar
COPY ${JAR_FILE} application.jar
RUN java -Djarmode=layertools -jar application.jar extract

FROM adoptopenjdk:17-jre-hotspot
WORKDIR application
ENV spring.profiles.active dev
COPY --from=builder application/dependencies ./
COPY --from=builder application/spring-boot-loader ./
COPY --from=builder application/snapshot-dependencies ./
COPY --from=builder application/application ./

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]

# jar파일을 4개의 영역으로 분리하여 런타임 시 모듈화 및 커스터마이징
# 1. application: 애플리케이션 소스코드
# 2. snapshot-dependencies: 프로젝트 클래스 경로에 존재하는 스냅샷 종속성 jar 파일
# 3. spring-boot-loader: jar loader와 luncher
# 4. dependencies: 프로젝트 클래스 경로에 존재하는 라이브러리 jar 파일
# 위로 갈수록 변경이 잦은 부분이며, 아래로 갈수록 변경이 잦지 않다.