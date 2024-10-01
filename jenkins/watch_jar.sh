#!/bin/bash
#운영서버 셸 스크립트 
# JAR 파일 경로 설정
JAR_FILE="/home/username/appjardir/SpringApp-0.0.1-SNAPSHOT.jar"

# 파일 수정 감지 및 .sh 파일 실행
inotifywait -m -e close_write "$JAR_FILE" |
while read -r directory events filename; do
    echo "$(date): $filename 파일이 수정되었습니다. 애플리케이션 재시작 중..."

    # autorunning.sh 실행
    bash /home/username/appjardir/autorunning.sh
done
