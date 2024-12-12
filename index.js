//npm install node-cron
//npm install brcypt
//npm install connect-redis redis express-session

const express = require('express');
const mysql = require('mysql');
const bodyParser = require('body-parser');
const cron = require('node-cron');
const bcrypt = require('bcrypt');
const saltRounds = 10; // Salt rounds 값은 보안성에 영향을 미칩니다.

const app = express();
const port = 15023;

// MySQL 연결 설정
const db = mysql.createConnection({
    host: '0.0.0.0',
    user: 'checkjin_2023874', // MySQL 사용자명
    password: 'checkjin_2023874', // MySQL 비밀번호
    database: 'checkjin_2023874', // 사용할 데이터베이스
    multipleStatements: true // 여기에 추가
});

// MySQL 연결
db.connect((err) => {
    if (err) throw err;
    console.log('Connected to MySQL database');
});

// 로그인 세션
const redis = require('redis');
// Redis 연결 설정
const redisClient = redis.createClient({
  url: `redis://default:DaEPvJcFiv7V75JSHaNaptAj1zaD16P7@redis-12810.c258.us-east-1-4.ec2.redns.redis-cloud.com:12810/0`,
});

redisClient.on('connect', () => {
  console.log('Redis 연결 성공');
});
redisClient.on('ready', () => {
  console.log('Redis 준비 완료');
});
redisClient.on('end', () => {
  console.log('Redis 연결 종료');
});
redisClient.on('error', (err) => {
  console.error('Redis 에러 발생:', err);
}); 

(async () => {
  try {
    await redisClient.connect();
    console.log('Redis 연결 시도 중...');
    await redisClient.flushAll();
    console.log('Redis 초기화 완료');
  } catch (err) {
    console.error('Redis 연결 실패:', err);
  }
})();


// 미들웨어 설정
app.use(bodyParser.json());
app.use(express.json());

// 월간 초기화 및 메달 수여 작업 (매월 1일 0시 실행)
cron.schedule('0 0 1 * *', async () => {
    try {
        // 현재 날짜에서 현재 달 계산
        const { month, year } = getCurrentMonth(); // 현재 달 메달 수여
        const getDateString = `${year}년 ${month}월`; // 예: "2024년 1월"

        // 대회 시작일(start_date)과 종료일(end_date) 계산 (현재 달)
        const startDate = new Date(year, month - 1, 1);  // 현재 달의 1일
        const endDate = new Date(year, month, 0);        // 현재 달의 마지막 날 (예: 12월 31일)

        // 지난달 계산
        const { lastMonth, lastYear } = getLastMonth(); // 지난달 계산
        const lastMonthDateString = `${lastYear}년 ${lastMonth}월`;

        // 지난달의 메달 수여 (RANK() 사용)
        const topSchoolsLastMonth = await queryAsync(`
            SELECT
                school_id,
                school_name,
                school_local,
                monthly_total_time,
                RANK() OVER (ORDER BY monthly_total_time DESC) AS monthly_ranking
            FROM School
            WHERE monthly_total_time > 0
            AND MONTH(start_date) = ${lastMonth}  -- 지난달의 데이터를 필터링
        `);

        // 지난달 메달 수여: 순위에 따라 메달 부여
        for (const school of topSchoolsLastMonth) {
            const ranking = School.monthly_ranking; // RANK()로 계산된 순위 사용
            if (ranking > 3) break; // 4등 이상은 메달 수여 제외

            // 해당 학교 소속 사용자 가져오기
            const users = await queryAsync(`
                SELECT user_id
                FROM Users
                WHERE school_id = ?
            `, [School.school_id]);

            // 사용자에게 메달 부여
            if (users.length > 0) {
                const battleInf = `${lastMonthDateString} 전국대회 메달`; // 지역 포함 메달 정보
                await Promise.all(users.map(user =>
                    queryAsync(`
                        INSERT INTO Medal (user_id, school_id, school_name, ranking, monthly_total_time, get_date, battle_inf, school_local)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    `, [
                        user.user_id,                // 사용자 ID
                        School.school_id,            // 학교 ID
                        School.school_name,          // 학교 이름
                        ranking,                     // 순위
                        School.monthly_total_time,   // 월간 총 시간
                        lastMonthDateString,         // 메달 수여 날짜 (ex. "2024년 1월")
                        battleInf,                   // "월 전국대회 메달" 형식의 정보
                        School.school_local
                    ])
                ));

                // 메달 수여 알림 생성
                await Promise.all(users.map(user =>
                    queryAsync(`
                        CALL CreateNotification(?, ?, '대회 메달을 수여 받았습니다!', 'reward')
                    `, [user.user_id, `${lastMonthDateString} 메달 수여`])
                ));
            }
        }

        // 현재 달의 RANK() 사용하여 월간 순위 계산
        const topSchools = await queryAsync(`
            SELECT
                school_id,
                school_name,
                school_local,
                monthly_total_time,
                RANK() OVER (ORDER BY monthly_total_time DESC) AS monthly_ranking
            FROM School
            WHERE monthly_total_time > 0
        `);

        // 메달 수여: 순위에 따라 메달 부여
        for (const school of topSchools) {
            const ranking = School.monthly_ranking; // RANK()로 계산된 순위 사용
            if (ranking > 3) break; // 4등 이상은 메달 수여 제외

            // 해당 학교 소속 사용자 가져오기
            const users = await queryAsync(`
                SELECT user_id
                FROM Users
                WHERE school_id = ?
            `, [School.school_id]);

            // 사용자에게 메달 부여
            if (Users.length > 0) {
                const battleInf = `${getDateString} 전국대회 메달`; // 지역 포함 메달 정보
                await Promise.all(users.map(user =>
                    queryAsync(`
                        INSERT INTO Medal (user_id, school_id, school_name, ranking, monthly_total_time, get_date, battle_inf, school_local)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    `, [
                        user.user_id,                // 사용자 ID
                        School.school_id,            // 학교 ID
                        School.school_name,          // 학교 이름
                        ranking,                     // 순위
                        School.monthly_total_time,   // 월간 총 시간
                        getDateString,               // 메달 수여 날짜 (ex. "2024년 1월")
                        battleInf,                   // "월 전국대회 메달" 형식의 정보
                        School.school_local
                    ])
                ));

                // 메달 수여 알림 생성
                await Promise.all(users.map(user =>
                    queryAsync(`
                        CALL CreateNotification(?, ?, '대회 메달을 수여 받았습니다!', 'reward')
                    `, [user.user_id, `${getDateString} 메달 수여`])
                ));
            }
        }

        // monthly_total_time 초기화
        await queryAsync('UPDATE School SET monthly_total_time = 0');

        console.log(`${getDateString} 메달 수여 완료 및 월간 초기화`);

        // 대회 시작 알림을 모든 사용자에게 전송
        const allUsers = await queryAsync('SELECT user_id FROM Users');
        await Promise.all(allUsers.map(user =>
            queryAsync(`
                CALL CreateNotification(?,?,'대회가 시작되었습니다!', 'system')
            `, [user.user_id, `${getDateString} 대회 시작`])
        ));

        // 대회 시작일(start_date)과 종료일(end_date) 업데이트
        await queryAsync(`
            UPDATE School
                SET start_date = ?, end_date = ?
        `, [startDate, endDate]);

        console.log(`대회 시작일과 종료일이 업데이트되었습니다: ${startDate} ~ ${endDate}`);

    } catch (error) {
        console.error('월간 초기화 오류:', error);
    }
});

// 현재 달 계산 함수
function getCurrentMonth() {
    const now = new Date();
    const month = now.getMonth() + 1; // 0 = 1월, 11 = 12월
    const year = now.getFullYear(); // 현재 연도
    return { month, year };
}

// 지난달 계산 함수
function getLastMonth() {
    const now = new Date();
    let month = now.getMonth(); // 0 = 1월, 11 = 12월
    let year = now.getFullYear();

    if (month === 0) {
        month = 12;
        year -= 1;
    }

    return { lastMonth: month, lastYear: year };
}

// Promise 기반으로 MySQL 쿼리 실행
function queryAsync(query, params = []) {
    return new Promise((resolve, reject) => {
        db.query(query, params, (err, result) => {
            if (err) reject(err);
            else resolve(result);
        });
    });
}

// 대회 종료일을 기준으로 7일, 3일, 1일 남았을 때 알림 발송
cron.schedule('0 0 * * *', async () => {
    try {
        // 대회 종료일 계산 (예: endDate가 대회 종료일이라고 가정)
        const { month, year } = getCurrentMonth();
        const endDate = new Date(year, month, 0); // 대회 종료일 (매달 마지막 날)

        // 대회 종료일까지 남은 일수 계산
        const today = new Date();
        const timeDiff = endDate.getTime() - today.getTime();
        const daysLeft = Math.ceil(timeDiff / (1000 * 3600 * 24));

        // 남은 일수가 7일, 3일, 1일일 때 알림 발송
        if ([7, 3, 1].includes(daysLeft)) {
            const allUsers = await queryAsync('SELECT user_id FROM Users');
            await Promise.all(allUsers.map(user =>
                queryAsync(`
                    CALL CreateNotification(?, ?, '대회 종료까지 ${daysLeft}일 남았습니다.', 'system')
                `, [user.user_id, `${daysLeft}일 남음`])
            ));
            console.log(`${daysLeft}일 남음 알림 발송 완료`);
        }

    } catch (error) {
        console.error('대회 종료 알림 발송 오류:', error);
    }
});

// 현재 달 계산 함수 (기존 유지)
function getCurrentMonth() {
    const now = new Date();
    const month = now.getMonth() + 1; // 0 = 1월, 11 = 12월
    const year = now.getFullYear(); // 현재 연도
    return { month, year };
}



// 학교 검색 API
app.get('/search-schools', (req, res) => {
  const query = req.query.query; // 클라이언트에서 보낸 검색어

  if (!query) {
    console.log("Query parameter missing."); // 디버깅 메시지
    return res.status(400).json({ error: 'Query parameter is required.' });
  }

  // SQL LIKE 연산자를 사용해 검색
  const sql = `SELECT school_name FROM School WHERE school_name LIKE CONCAT('%', ?, '%')`;
  const searchValue = `${query}`;

  db.query(sql, [searchValue], (err, results) => {
    if (err) {
      console.error('Error fetching schools:', err);
      return res.status(500).json({ error: 'Failed to fetch schools.' });
    }

    // 결과를 서버 콘솔에 출력
    console.log('Search results:', results);

    // 결과 반환
    res.json(results);
  });
});

app.post('/signup', (req, res) => {
  const { email, password, nickname, school_name } = req.body;

  if (!email || !password || !nickname || !school_name) {
    return res.status(400).json({ message: 'Email, password, nickname, and school_name are required' });
  }

  bcrypt.hash(password, saltRounds, (err, hashedPassword) => {
    if (err) {
      return res.status(500).json({ message: 'Error hashing password' });
    }

    // 트랜잭션 시작
    db.beginTransaction((err) => {
      if (err) return res.status(500).json({ message: 'Transaction start error' });

      db.query('SELECT email FROM Users WHERE email = ?', [email], (err, result) => {
        if (err) {
          db.rollback();
          return res.status(500).json({ message: 'Error checking email' });
        }
        if (result.length > 0) {
          db.rollback();
          return res.status(400).json({ message: 'Email is already taken' });
        }

        db.query('SELECT nickname FROM Users WHERE nickname = ?', [nickname], (err, result) => {
          if (err) {
            db.rollback();
            return res.status(500).json({ message: 'Error checking nickname' });
          }
          if (result.length > 0) {
            db.rollback();
            return res.status(400).json({ message: 'Nickname is already taken' });
          }

          db.query('SELECT school_id FROM School WHERE school_name = ?', [school_name], (err, result) => {
            if (err) {
              db.rollback();
              return res.status(500).json({ message: 'Error checking existing school' });
            }

            if (result.length === 0) {
              db.rollback();
              return res.status(404).json({ message: 'School does not exist' });
            }

            const school_id = result[0].school_id;

            // Users 테이블에 데이터 삽입 (해시된 비밀번호 사용)
            const query = `INSERT INTO Users (email, password, nickname, school_name, account_status, school_id) VALUES (?, ?, ?, ?, 'active', ?)`;
            db.query(query, [email, hashedPassword, nickname, school_name, school_id], (err, result) => {
              if (err) {
                db.rollback();
                return res.status(500).json({ message: 'Error creating user' });
              }

              const userId = result.insertId;

              // StudyTimeRecords 테이블 초기화
              db.query(`INSERT INTO StudyTimeRecords (user_id) VALUES (?)`, [userId], (err) => {
                if (err) {
                  db.rollback();
                  return res.status(500).json({ message: 'Error initializing StudyTimeRecords' });
                }

                db.commit((err) => {
                  if (err) {
                    db.rollback();
                    return res.status(500).json({ message: 'Transaction commit error' });
                  }
                  res.status(201).json({ message: 'User registered successfully' });
                });
              });
            });
          });
        });
      });
    });
  });
});

// 로그인 API
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  const query = 'SELECT * FROM Users WHERE email = ?';
  db.query(query, [email], async (error, results) => {
    if (error) {
      console.error('쿼리 실행 실패:', error);
      return res.status(500).json({ message: '서버 오류' });
    }

    if (results.length > 0) {
      const user = results[0];
      
      // 해시된 비밀번호인지 평문 비밀번호인지 체크하는 로직
      if (user.password.startsWith('$2b$')) {
        // 비밀번호 비교
        bcrypt.compare(password, user.password, async (err, isMatch) => {
          if (err) {
            console.error('비밀번호 비교 실패:', err);
            return res.status(500).json({ message: '서버 오류' });
          }

          if (isMatch) {
            // Redis에서 로그인 상태 확인
            const userId = user.user_id.toString(); // 키를 문자열로 변환
            const isLoggedIn = await redisClient.get(userId);
            if (isLoggedIn) {
              return res.status(400).json({ message: '이미 로그인된 사용자입니다.' });
            }

            // 마지막 로그인 시간 업데이트
            const updateQuery = 'UPDATE Users SET last_login = NOW() WHERE email = ?';
            db.query(updateQuery, [email], (updateError) => {
              if (updateError) {
                console.error('마지막 로그인 시간 업데이트 실패:', updateError);
                return res.status(500).json({ message: '서버 오류' });
              }
            });

            try {
              // Redis 데이터 저장 시
              const status = 'loggedIn';
              const result = await redisClient.set(userId, status, { EX: 3600 });
              console.log(`Redis SET 결과: ${result}`);
              if (result !== 'OK') {
                console.error('Redis SET 실패:', userId);
              }
              console.log(`Redis에 저장됨: key=${userId}, value=${status}`);

              // 데이터가 제대로 저장되었는지 바로 확인
              const redisValue = await redisClient.get(userId);
              console.log(`Redis에서 조회: key=${userId}, value=${redisValue}`);

              console.log('Redis SET 성공');
              console.log('로그인 성공:', userId);
            } catch (err) {
              console.error('Redis 연결 실패:', err);
            }
            
            return res.status(200).json({
              user_id: user.user_id,
              nickname: user.nickname,
              message: '로그인 성공',
            });
          } else {
            console.log(`로그인 실패: 잘못된 비밀번호 ${email}`);
            return res.status(401).json({ message: '잘못된 이메일 또는 비밀번호' });
          }
        });
      } else {
        // 평문 비밀번호인 경우 (단순 비교)
        if (password === user.password) {
          // Redis에서 로그인 상태 확인
          const userId = user.user_id.toString(); // 키를 문자열로 변환
          const isLoggedIn = await redisClient.get(userId);
          if (isLoggedIn) {
            return res.status(400).json({ message: '이미 로그인된 사용자입니다.' });
          }

          // 마지막 로그인 시간 업데이트
          const updateQuery = 'UPDATE Users SET last_login = NOW() WHERE email = ?';
          db.query(updateQuery, [email], (updateError) => {
            if (updateError) {
              console.error('마지막 로그인 시간 업데이트 실패:', updateError);
              return res.status(500).json({ message: '서버 오류' });
            }
          });

          try {
            // Redis 데이터 저장 시
            const status = 'loggedIn';
            const result = await redisClient.set(userId, status, { EX: 3600 });
            console.log(`Redis SET 결과: ${result}`);
            if (result !== 'OK') {
              console.error('Redis SET 실패:', userId);
            }
            console.log(`Redis에 저장됨: key=${userId}, value=${status}`);

            // 데이터가 제대로 저장되었는지 바로 확인
            const redisValue = await redisClient.get(userId);
            console.log(`Redis에서 조회: key=${userId}, value=${redisValue}`);

            console.log('Redis SET 성공');
            console.log('로그인 성공:', userId);
          } catch (err) {
            console.error('Redis 연결 실패:', err);
          }
          
          return res.status(200).json({
            user_id: user.user_id,
            nickname: user.nickname,
            message: '로그인 성공',
          });
        } else {
          console.log(`로그인 실패: 잘못된 비밀번호 ${email}`);
          return res.status(401).json({ message: '잘못된 이메일 또는 비밀번호' });
        }
      }
      
    } else {
      console.log(`로그인 실패: 존재하지 않는 이메일 ${email}`);
      return res.status(401).json({ message: '잘못된 이메일 또는 비밀번호' });
    }
  });
});

// 로그아웃 API
app.post('/logout', async (req, res) => {
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ message: '사용자 ID가 필요합니다.' });
  }

  try {
    // Redis에서 사용자 로그인 상태 제거
    const result = await redisClient.del(userId.toString());
    if (result === 1) {
      console.log(`Redis에서 로그아웃 처리 완료: key=${userId}`);
      return res.status(200).json({ message: '로그아웃 성공' });
    } else {
      console.log(`Redis에서 키를 찾을 수 없음: key=${userId}`);
      return res.status(404).json({ message: '사용자가 로그인되어 있지 않습니다.' });
    }
  } catch (err) {
    console.error('Redis에서 로그아웃 처리 실패:', err);
    return res.status(500).json({ message: '로그아웃 실패' });
  }
});

// get-school-name 엔드포인트
app.post('/get-school-name', (req, res) => {
  const { userEmail } = req.body;

  // 쿼리 실행
  const query = 'SELECT school_name FROM Users WHERE email = ?';
  db.query(query, [userEmail], (err, results) => {
    if (err) {
      return res.status(500).json({ message: 'Database error', error: err });
    }

    if (results.length > 0) {
      // 이메일에 해당하는 학교 이름이 존재하면 반환
      res.status(200).json({ school_name: results[0].school_name });
    } else {
      // 해당하는 사용자 없음
      res.status(404).json({ message: 'User not found' });
    }
  });
});

// 지역 목록을 반환하는 API
app.get('/school-local', (req, res) => {
  const query = 'SELECT DISTINCT school_local FROM School WHERE school_local IS NOT NULL';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching regions: ', err);
      res.status(500).send('Server error');
      return;
    }

    const locals = results.map((row) => row.school_local);
    res.json(locals);
  });
});

app.get('/school-rankings', (req, res) => {
  const { competition, local } = req.query;

  // '지역 대회' 처리
  if (competition === '지역 대회' && local) {
      const query = 'SELECT school_name, total_ranking, monthly_ranking, local_ranking, total_time, monthly_total_time, school_level, school_local FROM School WHERE school_local = ? ORDER BY local_ranking ASC';

    db.query(query, local, (err, results) => {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: '데이터베이스 쿼리 오류' });
      }
      console.log('지역 대회');
      console.log(results);
      return res.json(results);
    });
  }

  // '전국 대회' 처리
  else if (competition === '전국 대회') {
    const query = `WITH RankedSchools AS (
                           SELECT
                             school_name,
                             total_ranking,
                             monthly_ranking,
                             local_ranking,
                             total_time,
                             monthly_total_time,
                             school_level,
                             school_local,
                             ROW_NUMBER() OVER (PARTITION BY school_local ORDER BY monthly_ranking ASC) AS rn
                           FROM School
                         )
                         SELECT school_name, total_ranking, monthly_ranking, local_ranking, total_time, monthly_total_time, school_level, school_local
                         FROM RankedSchools
                         WHERE rn <= 3
                         ORDER BY monthly_total_time DESC;`;

    db.query(query, (err, results) => {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: '데이터베이스 쿼리 오류' });
      }

      console.log('전국 대회');
      console.log(results);
      return res.json(results); // 월별 총 시간 기준으로 정렬된 지역별 1, 2, 3등 반환
    });
  }

  // '랭킹' 대회 처리
  else if (competition === '랭킹') {
    const query = `SELECT school_name, total_ranking, monthly_ranking, local_ranking, total_time, monthly_total_time, school_level, school_local
                   FROM School
                   ORDER BY total_ranking ASC;`;
    db.query(query, (err, results) => {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: '데이터베이스 쿼리 오류' });
      }
      console.log('랭킹');
      console.log(results);
      return res.json(results); // 총 시간 기준으로 학교 데이터 반환
    });
  }

  // 잘못된 파라미터 처리
  else {
    return res.status(400).json({ error: 'Invalid competition or missing parameters' });
  }
});

app.post('/school-contributions', (req, res) => {
  const userEmail = req.body.userEmail;
  const isTotalTime = req.body.isTotalTime;  // total_time 또는 monthly_total_time을 구분하는 flag
  console.log('userEmail:', userEmail, 'isTotalTime:', isTotalTime);

  // 사용자 이메일에 해당하는 school_name과 nickname을 가져오기 위한 쿼리
  const schoolQuery = `
    SELECT school_name, nickname FROM Users WHERE email = ?
  `;

  db.query(schoolQuery, [userEmail], (error, schoolResults) => {
    if (error) {
      console.error('쿼리 실행 실패:', error);
      return res.status(500).json({ message: '서버 오류' });
    }

    if (schoolResults.length === 0) {
      console.log('사용자를 찾을 수 없음');
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    const schoolName = schoolResults[0].school_name;
    const userNickname = schoolResults[0].nickname;

    if (!schoolName) {
      console.log('현재 속한 학교가 없음');
      return res.status(404).json({ message: '현재 속한 학교가 없습니다.' });
    }

    console.log('학교 이름:', schoolName, '사용자 닉네임:', userNickname);

    // 학교의 total_time 또는 monthly_total_time에 따른 쿼리
    const schoolStatsQuery = isTotalTime ? `
      SELECT total_ranking, total_time FROM School WHERE school_name = ?
    ` : `
      SELECT monthly_ranking, monthly_total_time FROM School WHERE school_name = ?
    `;

    // 기여도 데이터도 total_time 또는 monthly_total_time에 따라 구분
    const contributionsQuery = isTotalTime ? `
      SELECT u.nickname, s.total_time
      FROM Users u
      JOIN StudyTimeRecords s ON u.user_id = s.user_id
      WHERE u.school_name = ?
      ORDER BY s.total_time DESC
    ` : `
      SELECT u.nickname, s.monthly_time AS total_time
      FROM Users u
      JOIN StudyTimeRecords s ON u.user_id = s.user_id
      WHERE u.school_name = ?
      ORDER BY s.monthly_time DESC
    `;

    db.query(schoolStatsQuery, [schoolName], (statsError, statsResults) => {
      if (statsError) {
        console.error('학교 기여도 및 통계 쿼리 실행 실패:', statsError);
        return res.status(500).json({ message: '서버 오류' });
      }

      if (statsResults.length === 0) {
        console.log('학교 기여도 및 통계 정보 없음');
        return res.status(200).json({
          message: '학교 기여도 및 순위 정보가 없습니다.',
        });
      }

      const ranking = isTotalTime ? statsResults[0].total_ranking || 0 : statsResults[0].monthly_ranking || 0;
      const total_time = isTotalTime ? statsResults[0].total_time || 0 : statsResults[0].monthly_total_time || 0;

      console.log('학교 순위:', ranking, '총 공부 시간:', total_time);

      db.query(contributionsQuery, [schoolName], (contribError, contribResults) => {
        if (contribError) {
          console.error('기여도 쿼리 실행 실패:', contribError);
          return res.status(500).json({ message: '서버 오류' });
        }

        if (contribResults.length === 0) {
          console.log('현재 학교에 속한 사용자가 없음');
          return res.status(200).json({
            schoolName: schoolName,
            ranking: ranking,
            total_time: total_time,
            userNickname: userNickname,
            contributions: [],
            message: '현재 학교에 속한 사용자가 없습니다.',
          });
        }

        console.log('기여도 결과:', contribResults);

        res.status(200).json({
          schoolName: schoolName,
          ranking: ranking,
          total_time: total_time,
          userNickname: userNickname, // 추가된 사용자 닉네임
          contributions: contribResults,
        });
      });
    });
  });
});



app.post('/selected-school-contributions', (req, res) => {
  const schoolName = req.body.schoolName;

  if (!schoolName) {
    return res.status(400).json({ error: '학교 이름이 필요합니다.' });
  }


  const query = `
    SELECT u.nickname, s.total_time
    FROM Users u
    JOIN StudyTimeRecords s ON u.user_id = s.user_id
    WHERE u.school_name = ?
    ORDER BY s.total_time DESC
  `;

  db.query(query, [schoolName], (err, results) => {
    if (err) {
      console.error('쿼리 오류:', err);
      return res.status(500).json({ error: '데이터를 가져오는 중 오류가 발생했습니다.' });
    }

    res.json({
      schoolName: schoolName,
      contributions: results.map(row => ({
        nickname: row.nickname,
        total_time: row.total_time
      }))
    });
  });
});

app.post('/selected-school-competition', (req, res) => {
  const schoolName = req.body.schoolName;

  if (!schoolName) {
    return res.status(400).json({ error: '학교 이름이 필요합니다.' });
  }


  const query = `
    SELECT u.nickname, s.monthly_time
    FROM Users u
    JOIN StudyTimeRecords s ON u.user_id = s.user_id
    WHERE u.school_name = ?
    ORDER BY s.monthly_time DESC
  `;

  db.query(query, [schoolName], (err, results) => {
    if (err) {
      console.error('쿼리 오류:', err);
      return res.status(500).json({ error: '데이터를 가져오는 중 오류가 발생했습니다.' });
    }

    res.json({
      schoolName: schoolName,
      contributions: results.map(row => ({
        nickname: row.nickname,
        monthly_time: row.monthly_time
      }))
    });
  });
});

app.post('/get-user-id', async (req, res) => {
  const { userEmail } = req.body;
  console.log(`Received request for user email: ${userEmail}`);

  const query = 'SELECT user_id FROM Users WHERE email = ?';
  db.query(query, [userEmail], (err, results) => {
  if(err) {
        return res.status(404).json({ message: 'User not fount'});
        }
        res.status(200).json({ user_id: results[0].user_id});
        });
});

// 타이머 기록을 계산하는 엔드포인트
app.post('/calculate-time-and-points', (req, res) => {
    const { input_record_time, user_id } = req.body;

    if (!input_record_time || !user_id) {
        return res.status(400).json({ message: 'Input record time and user ID are required' });
    }

    // 1. 사용자가 속한 학교 ID 조회
    const schoolIdQuery = `
      SELECT school_id FROM Users WHERE user_id = ?
    `;

    db.query(schoolIdQuery, [user_id], (err, schoolResult) => {
        if (err) {
            console.error('Error fetching school_id:', err);
            return res.status(500).json({ message: '학교 정보를 가져오는 중 오류가 발생했습니다.' });
        }

        if (schoolResult.length === 0) {
            return res.status(404).json({ message: '학교 정보를 찾을 수 없습니다.' });
        }

        const schoolId = schoolResult[0].school_id;

        // 2. 현재 학교의 레벨을 조회
        const currentLevelQuery = `
          SELECT school_level FROM School WHERE school_id = ?
        `;

        db.query(currentLevelQuery, [schoolId], (err, currentLevelResult) => {
            if (err) {
                console.error('Error fetching current school level:', err);
                return res.status(500).json({ message: '학교 레벨 정보를 가져오는 중 오류가 발생했습니다.' });
            }

            if (currentLevelResult.length === 0) {
                return res.status(404).json({ message: '학교 레벨 정보를 찾을 수 없습니다.' });
            }

            const currentSchoolLevel = currentLevelResult[0].school_level;

            // 3. 프로시저 호출
            const query = `CALL CalculateTimeAndPoints_proc(?, ?)`;
            db.query(query, [input_record_time, user_id], (err, results) => {
                if (err) {
                    return res.status(500).json({ message: 'Error calling stored procedure' });
                }

                // 4. 프로시저 실행 후 학교 레벨 다시 조회
                db.query(currentLevelQuery, [schoolId], (err, updatedLevelResult) => {
                    if (err) {
                        console.error('Error fetching updated school level:', err);
                        return res.status(500).json({ message: '업데이트된 학교 레벨 정보를 가져오는 중 오류가 발생했습니다.' });
                    }

                    const updatedSchoolLevel = updatedLevelResult[0].school_level;

                    // 5. 레벨 변경 여부 확인 후 알림 생성
                    if (currentSchoolLevel !== updatedSchoolLevel) {
                        // 6. 해당 학교의 모든 사용자에게 알림 생성
                        const getUsersQuery = `
                          SELECT user_id FROM Users WHERE school_id = ?
                        `;

                        db.query(getUsersQuery, [schoolId], (err, userResult) => {
                            if (err) {
                                console.error('Error fetching users for notification:', err);
                                return res.status(500).json({ message: '사용자 정보를 가져오는 중 오류가 발생했습니다.' });
                            }

                            userResult.forEach(user => {
                                const userId = user.user_id;

                                // 7. 학교 레벨업 알림 생성
                                const notificationMessage = `학교가 레벨업했습니다!`;  // 레벨업 메시지
                                const notificationQuery = `
                                    CALL CreateNotification(?, '학교 레벨업', ?, 'system')
                                `;
                                db.query(notificationQuery, [userId, notificationMessage], (err, notificationResult) => {
                                    if (err) {
                                        console.error('Error creating notification:', err);
                                        return res.status(500).send({ message: '알림 생성 중 오류가 발생했습니다.' });
                                    }
                                });
                            });
                        });
                    }

                    res.status(200).json({ message: 'Procedure called successfully', data: results });
                });
            });
        });
    });
});


// 사용자 ID에 해당하는 메달 목록을 가져오는 API
app.post('/get-user-medals', (req, res) => {
  const { userId } = req.body;

  // userId에 해당하는 메달 목록 가져오기
  const query = 'SELECT medal_id, ranking, battle_inf FROM Medal WHERE user_id = ? ORDER BY medal_id ASC';

  db.query(query, [userId], (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    // 결과 확인을 위한 로그 추가
        console.log('User ID:', userId);  // 요청한 userId 출력
        console.log('Fetched Medals:', results);  // 가져온 메달 목록 출력

    // 메달 목록 반환
    res.json(results);
  });
});

// 사용자 ID에 해당하는 메달 목록을 가져오는 API
app.post('/get-school-medals', (req, res) => {
  const { schoolId } = req.body;

  // userId에 해당하는 메달 목록 가져오기
  const query = `
                SELECT
                    school_id,
                    MIN(medal_id) AS medal_id,  -- 각 get_date별로 가장 작은 medal_id를 가져옵니다.
                    MIN(ranking) AS ranking,  -- 첫 번째 값을 가져옵니다. (기본적으로 MIN을 사용)
                    MIN(battle_inf) AS battle_inf,  -- 첫 번째 값을 가져옵니다.
                    get_date
                FROM Medal
                WHERE school_id = ?
                GROUP BY school_id, get_date
                ORDER BY medal_id ASC
                `;

  db.query(query, [schoolId], (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    // 결과 확인을 위한 로그 추가  // 요청한 userId 출력
        console.log('Fetched Medals:', results);  // 가져온 메달 목록 출력

    // 메달 목록 반환
    res.json(results);
  });
});

app.post('/get-medal-info', (req, res) => {
  const { queryType, userId, schoolId, medalId } = req.body;

  // Validate input
  if (!queryType || !medalId) {
    return res.status(400).json({ message: 'queryType and medalId are required' });
  }

  let query = '';
  let params = [];

  // Determine query type and construct appropriate query
  if (queryType === 'user') {
    if (!userId) {
      return res.status(400).json({ message: 'userId is required for queryType "user"' });
    }
    query = `
      SELECT *
      FROM Medal m
      WHERE m.user_id = ? AND m.medal_id = ?
    `;
    params = [userId, medalId];
  } else if (queryType === 'school') {
    if (!schoolId) {
      return res.status(400).json({ message: 'schoolId is required for queryType "school"' });
    }
    query = `
      SELECT *
      FROM Medal m
      WHERE m.school_id = ? AND m.medal_id = ?
    `;
    params = [schoolId, medalId];
  } else {
    return res.status(400).json({ message: 'Invalid queryType. Must be "user" or "school"' });
  }

  // Execute query
  db.query(query, params, (err, results) => {
    if (err) {
      console.error('Error retrieving medal info:', err);
      return res.status(500).json({ message: 'Error retrieving medal information' });
    }

    if (results.length > 0) {
      res.status(200).json(results[0]);
    } else {
      res.status(404).json({ message: 'Medal information not found' });
    }
  });
});

// 칠판에 학교명 띄우기
app.post('/get-user-school-name', (req, res) => {
  const { userId } = req.body;
  console.log(req.body);
  console.log('Received userId:', userId);

  if (!userId) {
    return res.status(400).json({ message: 'User ID is required' });
  }

  const query = `
    SELECT school_name
    FROM Users
    WHERE user_id = ?
  `;

  db.query(query, [userId], (err, results) => {
    if (err) {
      console.error('Error retrieving school name:', err);
      return res.status(500).json({ message: 'Error retrieving school name' });
    }

    console.log('Query results:', results);

    if (results.length > 0) {
      res.status(200).json({ school_name: results[0].school_name });
    } else {
      res.status(404).json({ message: 'School name not found for the user' });
    }
  });
});

// /get-user-nickname 엔드포인트 정의
app.post('/get-user-nickname', (req, res) => {
  const { userId } = req.body;  // 요청 본문에서 userId를 가져옴

  // userId로 사용자의 닉네임을 데이터베이스에서 조회
  const query = 'SELECT nickname FROM Users WHERE user_id = ?';  // 사용자 테이블에서 닉네임 조회
  db.query(query, [userId], (err, results) => {
    if (err) {
      console.error('닉네임 조회 실패:', err);
      return res.status(500).json({ error: '닉네임 조회 실패' });
    }

    // 사용자가 존재하면 닉네임 반환
    if (results.length > 0) {
      return res.json({ nickname: results[0].nickname });
    } else {
      return res.status(404).json({ error: '사용자를 찾을 수 없습니다' });
    }
  });
});

//fullSchool_screen.dart에 사용할 post문
app.post('/get-school-info', (req, res) => {
  const { userId } = req.body;
  console.log(req.body);

  const query = `
    SELECT School.school_id, School.school_name, School.school_level, School.total_time
    FROM Users
    JOIN School ON Users.school_id = School.school_id
    WHERE Users.user_id = ?;
  `;

  db.query(query, [userId], (err, results) => {
    if (err) {
      console.error('Error fetching school info:', err);
      return res.status(500).json({ message: 'Error retrieving school info' });
    }

    if (results.length > 0) {
      const schoolInfo = results[0];
      res.status(200).json(schoolInfo);
    } else {
      res.status(404).json({ message: 'School info not found' });
    }
  });
});

//user의 point를 가져옴.
app.post('/getUserPoints', (req, res) => {
  const userId = req.body.user_id;

  // Ensure user_id is provided
  if (!userId) {
    return res.status(400).json({ error: 'User ID is required' });
  }

  const query = 'SELECT points FROM Users WHERE user_id = ?';

  db.query(query, [userId], (err, results) => {
    if (err) {
      console.error('Error fetching points:', err);
      return res.status(500).json({ error: 'Failed to retrieve points' });
    }

    if (results.length > 0) {
      res.json({ points: results[0].points });
    } else {
      res.json({ points: 0 }); // Default if no points found
    }
  });
});

app.post('/purchaseItem', (req, res) => {
  const { user_id, item_id, item_price } = req.body;

  // MySQL 프로시저 호출
  const query = 'CALL purchaseItem(?, ?, ?)';
  db.query(query, [user_id, item_id, item_price], (err, results) => {
    if (err) {
      console.error('Error executing purchaseItem procedure:', err);
      res.status(500).json({ message: '구매 중 문제가 발생했습니다.' });
    } else {
      res.status(200).json({ message: '구매가 완료되었습니다.' });
    }
  });
});

//user의 가방
app.post('/getUserItems', (req, res) => {
  const { user_id, category } = req.body; // 카테고리도 함께 받아옴

  if (!user_id) {
    return res.status(400).json({ error: 'user_id is required' });
  }

  let query = `
    SELECT i.inventory_id, s.item_name, i.category, i.acquired_at, i.is_placed
    FROM Inventory i
    JOIN Store s ON i.item_id = s.item_id
    WHERE i.user_id = ?`;

  // 카테고리가 '전체'가 아닌 경우 필터링 추가
  if (category && category !== '전체') {
    query += ` AND i.category = ?`;
  }

  db.query(query, category && category !== '전체' ? [user_id, category] : [user_id], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: 'Failed to load user items' });
    }

    const items = results.map(item => ({
      inventory_id: item.inventory_id,
      item_name: item.item_name,
      category: item.category,
      acquired_at: item.acquired_at,
      is_placed: item.is_placed
    }));

    res.json({ items });
  });
});


//Store테이블 가져오기
app.post('/getItemsByCategory', (req, res) => {
  const category = req.body.category;
  const query = `SELECT item_id, item_name, description, price FROM Store WHERE category = ?`;

  db.query(query, [category], (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json({ items: results });
  });
});

// Update is_placed API
app.post('/updateItemIsPlaced', (req, res) => {
  const { user_id, inventory_id, x, y } = req.body; // inventory_id 받아오기

  console.log('Received request:', { user_id, inventory_id, x, y });

  // SQL 쿼리 작성 (inventory_id 사용)
  const query = `
    UPDATE Inventory
    SET is_placed = 1, x = ?, y = ?
    WHERE inventory_id = ? AND user_id = ?;
  `;

  // 쿼리 실행
  db.query(query, [x, y, inventory_id, user_id], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Database error' });
    }
    if (result.affectedRows > 0) {
      return res.status(200).json({ message: 'Item updated successfully' });
    } else {
      return res.status(404).json({ message: 'Item not found' });
    }
  });
});

// 배치된 아이템 가져오기 API
app.post('/get-placed-items', (req, res) => {
  const { userId } = req.body;

  const query = `
    SELECT i.inventory_id, s.item_name, i.x, i.y, i.category, i.priority
    FROM Inventory AS i
    INNER JOIN Store AS s ON i.item_id = s.item_id
    WHERE i.user_id = ? AND i.is_placed = 1
  `;

  db.query(query, [userId], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Database error' });
    }
    res.status(200).json(results);
  });
});

// 배치된 아이템 삭제 API
app.post('/remove-item', (req, res) => {
  const { user_id, inventory_id } = req.body;

  const query = `
    UPDATE Inventory
    SET is_placed = 0, priority = 0
    WHERE user_id = ? AND inventory_id = ?
  `;

  db.query(query, [user_id, inventory_id], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Database error' });
    }

    if (result.affectedRows > 0) {
      res.status(200).json({ message: 'Item removed successfully' });
    } else {
      res.status(404).json({ message: 'Item not found or not placed' });
    }
  });
});

// 아이템 위치 업데이트 API
app.post('/update-item-position', async (req, res) => {
  const { user_id, inventory_id, x, y, priority } = req.body;

  try {
    await db.query(
      `UPDATE Inventory SET priority = priority + 1 WHERE user_id = ? AND inventory_id != ? AND is_placed = 1`,
      [user_id, inventory_id]
    );

    await db.query(
      `UPDATE Inventory SET x = ?, y = ?, priority = ? WHERE user_id = ? AND inventory_id = ? AND is_placed = 1`,
      [x, y, priority, user_id, inventory_id]
    );

    res.json({ message: 'Item updated successfully' }); // 최종 응답
  } catch (err) {
    console.error('Error updating item:', err);
    res.status(500).json({ error: 'Failed to update item' }); // 오류 응답
  }
});

app.get('/search-user', (req, res) => {
  const { nickname } = req.query;
  const userId = req.userId;  // 요청 보낸 사용자의 userId (예: 토큰에서 추출)

  const query = 'SELECT user_id, nickname FROM Users WHERE nickname = ?';

  db.query(query, [nickname], (err, rows) => {
    if (err) {
      console.error('Error searching user by nickname:', err);
      return res.status(500).send({ message: '사용자를 검색하는 중 오류가 발생했습니다.' });
    }

    if (rows.length === 0) {
      return res.status(404).send({ message: '사용자를 찾을 수 없습니다.' });
    }

    // 자기 자신의 닉네임을 검색한 경우 거부
    if (rows[0].user_id === userId) {
      return res.status(400).send({ message: '자기 자신을 검색할 수 없습니다.' });
    }

    res.status(200).send(rows[0]); // 유저 정보 반환
  });
});


app.post('/send-friend-request', (req, res) => {
  const { userId, friendNickname } = req.body;

  const query = 'SELECT user_id FROM Users WHERE nickname = ?';

  db.query(query, [friendNickname], (err, rows) => {
    if (err) {
      console.error('Error searching user by nickname:', err);
      return res.status(500).send({ message: '친구 요청 대상 사용자를 찾을 수 없습니다.' });
    }

    if (rows.length === 0) {
      return res.status(404).send({ message: '친구 요청 대상 사용자를 찾을 수 없습니다.' });
    }

    const friendId = rows[0].user_id;

    if (userId === friendId) {
      return res.status(400).send({ message: '자기 자신에게 친구 요청을 보낼 수 없습니다.' });
    }

    const checkRequestQuery = `
      SELECT * FROM Friends WHERE (user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)
    `;

    db.query(checkRequestQuery, [userId, friendId, friendId, userId], (err, existingRequest) => {
      if (err) {
        console.error('Error checking existing friend request:', err);
        return res.status(500).send({ message: '친구 요청을 확인하는 중 오류가 발생했습니다.' });
      }

      if (existingRequest.length > 0) {
        return res.status(400).send({ message: '이미 친구 요청이 존재합니다.' });
      }

      const insertQuery = `
        INSERT INTO Friends (user_id, friend_id, status, created_at, updated_at)
        VALUES (?, ?, 'requested', NOW(), NOW())
      `;

      db.query(insertQuery, [userId, friendId], (err, result) => {
        if (err) {
          console.error('Error sending friend request:', err);
          return res.status(500).send({ message: '친구 요청을 보내는 중 오류가 발생했습니다.' });
        }

        // 친구 요청 성공 시 알림 생성
        const notificationQuery = `
          CALL CreateNotification(?, '새로운 친구 요청', '새로운 친구 요청이 있습니다.', 'friend_request')
        `;
        db.query(notificationQuery, [friendId], (err, notificationResult) => {
          if (err) {
            console.error('Error creating notification:', err);
            return res.status(500).send({ message: '알림 생성 중 오류가 발생했습니다.' });
          }

          res.status(200).send({ message: '친구 요청이 성공적으로 전송되었습니다.' });
        });
      });
    });
  });
});


// 친구 요청 목록 가져오기
app.get('/friend-requests/:userId', (req, res) => {
  const userId = req.params.userId;

  const query = `
      SELECT f.friendship_id, f.user_id, f.friend_id, u.nickname
      FROM Friends f
      JOIN Users u ON f.user_id = u.user_id
      WHERE f.friend_id = ? AND f.status = 'requested'
    `;

  db.query(query, [userId], (err, rows) => {
    if (err) {
      console.error('Error fetching friend requests:', err);
      return res.status(500).json({ message: '친구 요청을 가져오는 중 오류가 발생했습니다.' });
    }

    if (rows.length === 0) {
      return res.status(200).json([]);  // 요청 목록이 없으면 빈 배열 반환
    }

    res.status(200).json(rows);  // 친구 요청 목록 반환
  });
});


// 친구 요청 수락
app.post('/accept-friend-request', (req, res) => {
  const { friendshipId } = req.body;

  // 1. 친구 요청 수락 상태로 업데이트
  const query = `
    UPDATE Friends
    SET status = 'accepted'
    WHERE friendship_id = ? AND status = 'requested'
  `;

  db.query(query, [friendshipId], (err, result) => {
    if (err) {
      console.error('Error accepting friend request:', err);
      return res.status(500).json({ message: '친구 요청 수락 중 오류가 발생했습니다.' });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: '해당 친구 요청을 찾을 수 없습니다.' });
    }

    // 2. friendship_id를 통해 상대방 user_id 가져오기
    const getUserIdQuery = `
      SELECT user_id FROM Friends
      WHERE friendship_id = ?
    `;

    db.query(getUserIdQuery, [friendshipId], (err, userResult) => {
      if (err) {
        console.error('Error fetching user_id:', err);
        return res.status(500).json({ message: '사용자 정보를 가져오는 중 오류가 발생했습니다.' });
      }

      if (userResult.length === 0) {
        return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
      }

      const userId = userResult[0].user_id;

      // 3. user_id를 통해 nickname 가져오기
      const getNicknameQuery = `
        SELECT nickname FROM Users
        WHERE user_id = ?
      `;

      db.query(getNicknameQuery, [userId], (err, nicknameResult) => {
        if (err) {
          console.error('Error fetching nickname:', err);
          return res.status(500).json({ message: '닉네임 정보를 가져오는 중 오류가 발생했습니다.' });
        }

        if (nicknameResult.length === 0) {
          return res.status(404).json({ message: '닉네임을 찾을 수 없습니다.' });
        }

        const nickname = nicknameResult[0].nickname;

        // 4. 친구 수락 알림 생성 (nickname 포함)
        const notificationMessage = `${nickname} 님이 친구 요청을 수락했습니다!`;
        const notificationQuery = `
          CALL CreateNotification(?, '친구 요청 수락', ?, 'friend_request')
        `;

        db.query(notificationQuery, [userId, notificationMessage], (err, notificationResult) => {
          if (err) {
            console.error('Error creating notification:', err);
            return res.status(500).send({ message: '알림 생성 중 오류가 발생했습니다.' });
          }

          // 5. 응답 전송
          res.status(200).send({ message: '친구 요청이 성공적으로 수락되었습니다.' });
        });
      });
    });
  });
});



// 친구 요청 거절
app.post('/reject-friend-request', (req, res) => {
  const { friendshipId } = req.body;

  const query = `
    DELETE FROM Friends
    WHERE friendship_id = ? AND status = 'requested'
  `;

  db.query(query, [friendshipId], (err, result) => {
    if (err) {
      console.error('Error rejecting friend request:', err);
      return res.status(500).json({ message: '친구 요청 거절 중 오류가 발생했습니다.' });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: '해당 친구 요청을 찾을 수 없습니다.' });
    }

    res.status(200).json({ message: '친구 요청이 거절되었습니다.' });
  });
});

// 알림 데이터 가져오기
app.post('/get-notifications', (req, res) => {
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).json({ error: 'User ID is required' });
    }

    const query = `
        SELECT notification_id, title, message, type, is_read, created_at
        FROM Notifications
        WHERE user_id = ?
        ORDER BY created_at DESC
    `;

    db.query(query, [userId], (error, results) => {
        if (error) {
            console.error('Error fetching notifications:', error);
            return res.status(500).json({ error: 'Database query error' });
        }
        res.status(200).json(results);
    });
});

// POST /get-notifications
app.post('/get-notifications', async (req, res) => {
    const { userId, includeRead } = req.body;

    if (!userId) {
        return res.status(400).json({ error: "Missing userId in request body" });
    }

    try {
        const connection = await mysql.createConnection(dbConfig);
        const query = includeRead
            ? 'SELECT * FROM Notifications WHERE user_id = ? ORDER BY created_at DESC'
            : 'SELECT * FROM Notifications WHERE user_id = ? AND is_read = FALSE ORDER BY created_at DESC';

        const [rows] = await connection.execute(query, [userId]);
        await connection.end();

        return res.status(200).json(rows);
    } catch (err) {
        console.error("Error fetching notifications:", err);
        return res.status(500).json({ error: "Failed to fetch notifications" });
    }
});

// 예제: db를 사용해 쿼리 실행
app.post('/mark-notification-read', (req, res) => {
    const { notificationId } = req.body;

    if (!notificationId) {
        return res.status(400).json({ error: "Missing notificationId in request body" });
    }

    db.query(
        'UPDATE Notifications SET is_read = TRUE WHERE notification_id = ?',
        [notificationId],
        (err, result) => {
            if (err) {
                console.error("Error marking notification as read:", err);
                return res.status(500).json({ error: "Failed to mark notification as read" });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({ error: "Notification not found" });
            }

            return res.status(200).json({ success: true });
        }
    );
});




// 서버 시작
app.listen(port, () => {
    console.log(`Server running at http://116.124.191.174:${port}`);
});
app.get('/friends/:userId', (req, res) => {
  const { userId } = req.params;

  const query = `
    SELECT
      CASE
        WHEN f.user_id = ? THEN f.friend_id
        ELSE f.user_id
      END AS friend_id,
      u.nickname
    FROM Friends f
    JOIN Users u ON u.user_id = (
      CASE
        WHEN f.user_id = ? THEN f.friend_id
        ELSE f.user_id
      END
    )
    WHERE (f.user_id = ? OR f.friend_id = ?) AND f.status = 'accepted'
  `;

  db.query(query, [userId, userId, userId, userId], (err, results) => {
    if (err) {
      console.error('Error fetching friends:', err);
      return res.status(500).json({ message: '친구 목록을 가져오는 중 오류가 발생했습니다.' });
    }

    // 결과가 비어 있을 경우 처리
    if (!results || results.length === 0) {
      return res.status(404).json({ message: '친구 목록이 비어 있습니다.' });
    }

    // 정상적인 결과 반환
    res.status(200).json(results);
  });
});
