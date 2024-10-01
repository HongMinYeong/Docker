#!/bin/bash
#운영서버 셸 스크립트 
# Spring Boot 애플리케이션 재시작
# 기존 8888 포트 사용 중인 프로세스 종료
if  lsof -i :8888 > /dev/null; then
  # 8888 포트가 사용 중일 경우 이전 프로세스를 종료
  kill -9 $(lsof -t -i:8888)
  echo '정상적으로 종료되었습니다.'
fi

# 백그라운드에서 새로 실행
# > $DEPLOY_DIR/app.log : 애플리케이션 로그를 app.log 파일에 저장하도록 구성
nohup java -jar SpringApp-0.0.1-SNAPSHOT.jar > app.log 2>&1 &

echo "배포완료 및 재 실행됩니다."