# Node.js 기본 이미지
FROM node:18

# 컨테이너 내 작업 디렉터리 설정
WORKDIR /app

# 호스트의 모든 파일을 컨테이너에 복사
COPY . .

# 필요한 패키지 설치
RUN npm install

# 기본 포트 설정 (3000으로 가정)
EXPOSE 15023 

# 서버 실행 명령
CMD ["node", "index.js"]
