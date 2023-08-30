SELECT * FROM EMP;
SELECT * FROM DEPT;

-- 문제점 기술 후 튜닝
/*
 * 1. 입금일시 컬럼을 변환했으므로 인덱스 RANGE SCAN 불가
 * 2. 수납일자 조건 자동 형변환 발생하므로 RANGE SCAN 불가
 * 3. LITERAL SQL 의한 하드파싱 부하
 * 4. 절차적 루프 처리에 의한 반복 DB CALL
 * 5. 루프 내에서 건건 커밋
 * */
DECLARE
	L_수납금액 NUMBER;
BEGIN
	FOR C IN (SELECT 고객ID, SUM(입금액) 입금액
				FROM 은행입금내역
			   WHERE TO_CHAR(입금일시, 'YYYYMMDD') = '20210329' -- 1
			   GROUP BY 고객ID)
	LOOP	
		BEGIN
			SELECT 수납금액 INTO L_수납금액
			  FROM 수납
			 WHERE 고객ID = C.고객ID
			   AND 수납일자 = 20210329; -- 2
			  EXECUTE IMMEDIATE
			  	' UPDATE 수납 SET 수납금액 = ' || C.입금액 ||
			  	'  WHERE 고객 ID = ' || C.고객ID ||
			  	'    AND 수납일자 = 20210329';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				'INSERT INTO 수납(고객ID, 수납일자, 수납금액) VALUES (' ||
				C.고객ID || ', 20210329, ' || C.입금액 || ')';
		END;
	COMMIT;
	END LOOP;
END;

-- [튜닝 SQL]
MERGE INTO 수납 R
USING (SELECT 고객ID, SUM(입금액) 입금액
		 FROM 은행입금애녁
		WHERE 입금일시 BETWEEN TO_DATE('20210329', 'YYYYMMDD') AND TO_DATE('20210330', 'YYYYMMDD') - 1/24/60/60
		GROUP BY 고객ID) I
   ON (R.고객ID = I.고객ID AND R.수납일자 = '20210329')
 WHEN MATCHED THEN UPDATE
 	SET R.수납금액 = I.입금액
 WHEN NOT MATCHED THEN
 	INSERT (고객ID, 수납일자, 수납금액) VALUES (I.고객ID, '20210329', I.입금액);
 COMMIT;
 
CREATE INDEX 회원_X01 ON 회원(생년월일);
CREATE INDEX 회원_X02 ON 회원(생년월일, 전화번호);
CREATE INDEX 회원_X03 ON 회원(생년월일, 회원명, 전화번호);
CREATE INDEX 회원_X04 ON 회원(전화번호);

SELECT *
  FROM 회원
 WHERE 생년월일 LIKE '1979%'
   AND 전화번호 = ENCRYPTION(:PHONE);
   
-- 튜닝 후
SELECT DISTINCT GET_USERNAME(사원id)
  FROM 휴가기록
 WHERE 휴가일자 >= ADD_MONTHS(SYSDATE, -3)
 GROUP BY 사원ID; 
 
-- 주문 테이블 파티셔닝
/* 1. 주문 테이블에 입력하려고 백업해 둔 임시 테이블에는 2020년 1월부터 2021년 10월까지이 주문데이터가 입력되어있음
 * 2. 예상치 못한 주문일시가 입력되더라도 에러가 발생하지 않아야함
 * 3. 파티션 명명규칙은 자유 
 */
CREATE TABLE 주문 (
	주문번호 NUMBER
  , 주문일시 DATE
  , 고객ID  VARCHAR2(5)
  , 주문금액 NUMBER
)
PARTITION BY RANGE(주문일시)
( PARTITION P2020_H1 VALUES LESS THAN (TO_DATE('20200701', 'YYYYMMDD'))
, PARTITION P2020_H2 VALUES LESS THAN (TO_DATE('20210101', 'YYYYMMDD') 
, PARTITION P2021_H1 VALUES LESS THAN (TO_DATE('20210701', 'YYYYMMDD') 
, PARTITION P2021_H2 VALUES LESS THAN (TO_DATE('20220101', 'YYYYMMDD') 
, PARTITION P9999_MX VALUES LESS THAN (MAXVALUE));

-- 튜닝 전 -> 후
SELECT  A.*
	  , (SELECT NVL(MAX('Y'), 'N') 
	  	   FROM 자료전송이력 
	  	  WHERE 상담원ID = A.상담원ID 
	  	    AND 상담일시 = A.상담일시 
	-- 추가  AND 등록일시 >= 상담일시  
	  	    AND ROWNUM = 1) 자료전송여부
  FROM (
  		SELECT 상담원ID, 상담일시, 상담접촉구분코드
  			 , 연락전화번호, 통화자명, 호식별번호
  			 , 상담처리상태코드, 조직ID
  		  FROM 고객상담
  		 WHERE 고객번호 = :CUST_NUM
  		 ORDER BY 고객번호 DESC, 상담일시 DESC) A
  	) 
 WHERE ROWNUM <= 10; 
/*
 * SORT AGGREGATE
 * 	 COUNT STOPKEY
 * 	   PARTITION RANGE ALL -> PARTITION RANGE ITERATOR
 * 	     INDEX RANGE SCAN
 * COUNT STOPKEY
 *   VIEW
 *     TABLE ACCESS BY INDEX ROWID
 *       INDEX RANGE SCAN DESCENDING 
 */

-- 튜닝 전
-- [테이블 정보]
/* 고객 : 1,000만명
 * 고객변경이력 : 변경일자 기준 월단위 RANGE 파티션
 * */
-- [인덱스 구성]
/* 고객_PK : [고객번호]
 * 고객_N1 : [고객번호 + 고객상태코드 + 상태변경일자]
 * 고객변경이력_PK : [고객번호 + 변경일자 + 변경구분코드 + 변경일련번호]
 * */
SELECT *
  FROM (
  		SELECT 고객번호, MAX(변경일자) 변경일자
  			 , MAX(변경구분코드) KEEP (DENSE_RANK LAST ORDER BY 변경일자, 변경일련번호) 변경구분코드
  		  FROM 고객변경이력 CH
  		 WHERE EXISTS (SELECT 'X' FROM 고객 C WHERE 고객번호 = CH.고객번호 AND 상태변경일자 <= CH.변경일자 AND 고객상태코드 = 'AI')
   -- 추가  AND 변경일자 >= :CHG_DT
  		 GROUP BY 고객번호
  	)
 WHERE 변경일자 = :CHG_DT
   AND 변경구분코드 = 'D1';
/* FILTER
 *   SORT (GROUP BY)
 * 	   HASH JOIN (SEMI)
 * 	     INDEX (RANGE SCAN) OF '고객_N1' (INDEX)
 *  	 PARTITION RANGE (ALL) -> PARTITION RANGE (ITERATOR)
 * 		   INDEX (FAST FULL SCAN) OF '고객변경이력_PK' (INDEX)
 * */
  
ALTER SESSION SET SQL_TRACE = TRUE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('5rsm4y10jd4p2',0,'ALLSTATS'));
EXPLAIN PLAN FOR
SELECT * FROM EMP;

-- 튜닝 전 -> 후
SELECT 주문번호, 주문일시
  FROM 주문
 WHERE 주문상태코드 IN ('0', '1', '2', '4', '5')
   AND 주문일자 BETWEEN :DT1 AND :DT2;

-- 튜닝 전 -> 후
/* [인덱스 구성]
 * 월말게좌상태_PK : [계좌번호 + 계좌일련번호 + 기준년월 ]
 * 월말계좌상태_X1 : [기준년월 + 상태구분코드 ]
 */
UPDATE 월별계좌상태 SET 상태구분코드 = '07'
 WHERE 상태구분코드 <> '01'
   AND 기준년월 = :BASE_DT
   AND (계좌번호, 계좌일련번호) IN 
   		(SELECT 계좌번호, 계좌일련번호
   		   FROM 계좌원장
   		  WHERE 개설일자 LIKE :STD_YM || '%');

-- 튜닝
/** [인덱스 구성]
 * 1. 일별지수업종별거래_PK : [지수구분코드 + 지수업종코드 + 거래일자]
 * 2. 일별지수업종별거래_X1 : [거래일자]
 * */ 
SELECT 거래일자
	 , SUM(DECODE(지수구분코드, '1', 지수종가, 0)) KOSPI200_IDX	
	 , SUM(DECODE(지수구분코드, '1', 누저거래량, 0)) KOSPI200_IDX_TRDVOL
	 , SUM(DECODE(지수구분코드, '2', 지수종가, 0)) KOSPI200_IDX
	 , SUM(DECODE(지수구분코드, '2', 누적거래량, 0)) KOSPI200_IDX_TRDVOL
  FROM 일별지수업종별거래 A
 WHERE 거래일자 BETWEEN :STARTDT AND :ENDDT
   AND (지수구분코드, 지수업종코드) IN (('100' ,'1'), ('200', '3'))
 GROUP BY 거래일자;
 
-- 튜닝
/* [인덱스 구성]
 * 1. 주문_PK : [주문일자 + 주문번호]
 */
SELECT NVL(MAX(주문번호) + 1, 1)
  FROM 주문
 WHERE 주문일자 = :주문일자;
/*
 * SORT (AGGREGATE)
 *   FIRST ROW
 *     INDEX (RANGE SCAN (MIN/MAX)) OF '주문_PK' (INDEX) 
 * */

-- 튜닝
/* [인덱스 추가]
 * X1_거래 : [증서번호 + 투입인출구분코드 + 이체사유발생일자]
 * */
SELECT 
	(X.기본이체금액_G + X.정산이자_G) - (X.기본이체금액_S + X.정산이자_S)
FROM (
	SELECT NVL(SUM(DECODE(투입인출구분코드, 'G', 기본이체금액)), 0) 기본이체금액_G
		 , NVL(SUM(DECODE(투입인출구분코드, 'G', 정산이자)), 0) 정산이자_G
		 , NVL(SUM(DECODE(투입인출구분코드, 'S', 기본이체금액)), 0) 기본이체금액_S
		 , NVL(SUM(DECODE(투입인출구분코드, 'S', 정산이자)), 0) 정산이자_S
	  FROM 거래
	 WHERE 증서번호 = :증서번호
	   AND 투인인출구분코드 IN ('G', 'S')
	   AND 이체사유발생일자 <= :일자
	   AND 거래코드 NOT IN ('7411', '7412', '7503', '7504')
) X;

-- 인덱스튜닝방안
/* [인덱스 구성]
 * 1. 상품_PK : [상품코드]
 * 2. 상품_X01 : [상품분류코드 + 상품가격 + 공급업체코드]
 * 3. 거래_PK : [거래번호]
 * 4. 거래_X01 : [거래일자 + 상품코드]
 * 5. 거래_X02 : [상품코드 + 거래구분코드 + 거래일자]
 * */
SELECT P.상품코드, P.상품가격, T.거래일자, T.거래수량, T.거래금액
  FROM 상품 P, 거래 T
 WHERE P.상품코드 = T.상품코드
   AND P.상품분류코드 = 'KTG'
   AND P.공급업체코드 = 'SP83732'
   AND P.상품가격 BETWEEN 10000 AND 100000
   AND T.거래일자 BETWEEN '20210101' AND '20210131';
/*
 * 368  NESTED LOOPS (CR=1311 ...)
 *  69    TABLE ACCESS BY INDEX ROWID 상품 (CR=986 ...)
 *  69      INDEX RANGE SCAN 상품_X01 (CR=922 ...)
 * 368    TABLE ACCESS BY INDEX ROWID 거래 (CR=325 ...)
 * 385      INDEX RANGE SCAN 거래_X02 (CR=140 ...)
 * -> 상품_X01의 인덱스를 [상품분류코드 + 공급업체코드 + 상품가격] 으로 조정 */ 


-- 튜닝방안
SELECT CASE WHEN A.일할계산여부 = 'Y' THEN NVL(A.총청구건수, 0) - NVL(A.청구횟수, 0) ELSE B.할부개월수 - NVL(A.청구횟수, 0) END
  FROM 서비스별할부 A, 할부계획 B
 WHERE A.서비스계약번호 = MV.서비스계약번호
   AND A.할부상태코드 = 'XR'
--   AND B.할부계획ID(+) = A.할부계획ID   
   AND B.할부계획ID(+) = (CASE WHEN A.일할계산여부 = 'Y' THEN NULL ELSE A.할부계획ID END)
   AND ROWNUM <= 1
 
/* 문제점 : 할부계획의 할부개월수(B)는 일할계산여부가 'Y'가 아닐 때만 필요한데, 일할계산여부가 'Y'일때도 조인을 수행하고있음
 * 튜닝방안 : 서비스별할부의 일할계산여부가 'Y'가 아닐때만 조인하도록 조건절을 아래와 같이 수정  
 * */
   
-- 튜닝방안
/* [데이터] : 대리점 : 1,000개 , 상품판매실적 : 월평균 100만건
 * [인덱스] : 대리점_PK : [대리점코드]
 * 		  : 상품판매실적_PK : [대리점코드 + 상품코드 + 판매일자]
 * 		  : 상품판매실적_X1 : [판매일자 + 상품코드] 
 * */
SELECT A.대리점명, SUM(B.매출금액) 매출금액
  FROM 대리점 A, 상품판매실적 B
 WHERE A.대리점코드 = B.대리점코드
   AND B.상품코드 IN ('A1847', 'Z0413')
   AND B.판매일자 BETWEEN '20210101' AND '20210331'
 GROUP BY B.대리점코드, A.대리점명
 ORDER BY 1, 2
 
SELECT A.대리점명, B.판매금액
  FROM 대리점 A
  	 , (SELECT /*+ NO_MERGE */ 대리점코드, SUM(판매금액) 판매금액 
  	   	  FROM 상품판매실적
  	   	 WHERE 상품코드 IN ('A1847', 'Z0413')
  	   	   AND 판매일자 BETWEEN '20210101' AND '20210331'
  	   	 GROUP BY 대리점코드) B
 WHERE A.대리점코드 = B.대리점코드;

/* SORT GROUP BY
 *   NESTED LOOPS
 *     TABLE ACCESS BY INDEX ROWID 상품판매실적
 *   	 INDEX RANGE SCAN 상품판매실적_X1 (NONUNIQUE)
 *     TABLE ACCESS BY INDEX ROWID 대리점
 *       INDEX UNIQUE SCAN 대리점_PK (UNIQUE)
 * */
  
-- 실행계획
/* (가입상품과 계약을 해시조인) -> 가입부가상품과 NL 조인 -> 상품과 해시 조인 */
/*+ leading(b a c d) use_hash(a) use_nl(c) use_hash(d) swap_join_inputs(d)
 *  index(b 가입상품_X1) index(a 계약_X1) index(c 가입부가상품_PK) index(d 상품_PK) */

/* HASH JOIN
 *   TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
 *     INDEX (RANGE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 *   NESTED LOOPS
 *     HASH JOIN
 *       TABLE ACESS (BY INDEX ROWID) OF '가입상품' (TABLE)
 *         INDEX (RANGE SCAN) OF '가입상품_X1' (INDEX)
 *       TABLE ACESS (BY INDEX ROWID) OF '계약' (TABLE)
 *         INDEX (RANGE SCAN) OF '계약_X1' (INDEX)
 *     INDEX (RANGE SCAN) OF '가입부가상품_PK' (INDEX (UNIQUE))
 * */

-- 실행계획
/* (가임상품과 계약을 해시조인) -> 가입부가상품과 NL 조인 -> 상품과 해시 조인
 *+ leading(b a c d) use_hash(a) use_nl(c) use_hash(d) no_swap_join_inputs(d) 
 *  index(b 가입상품_X1) index(a 계약_X1) index(c 가입부가상품_PK) index(d 상품_PK) */

/* HASH JOIN 
 *   NESTED LOOPS
 *     HASH JOIN
 *       TABLE ACCESS (BY INDEX ROWID) OF '가입상품' (TABLE)
 *         INDEX (RANGE SCAN) OF '가입상품_X1' (INDEX)
 *       TABLE ACCESS (BY INDEX ROWID) OF '계약' (TABLE)
 *         INDEX (RANGE SCAN) OF '계약_X1' (INDEX)
 *     INDEX (RANGE SCAN) OF '가입부가상품_PK' (INDEX (UNIQUE))
 *   TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
 *     INDEX (RANGE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * */
  
-- 스칼라 서브쿼리 실행계획
SELECT C.고객번호, C.고객명
	 , (SELECT ROUND(AVG(거래금액), 2) 평균거래금액
	 	  FROM 거래
	 	 WHERE 거래일시 >= TRUNC(SYSDATE, 'MM')
	 	   AND 고객변호 = C.고객번호)
  FROM 고객 C
 WHERE C.가입일시 >= TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM');

/* SORT (AGGREGATE)
 *   TABLE ACCESS (BY INDEX ROWID) OF '거래'
 *     INDEX (RANGE SCAN) OF '거래_IDX'
 * TABLE ACCESS (BY INDEX ROWID) OF '고객'
 *   INDEX (RANGE SCAN) OF '고객_IDX'
 * */
  
-- 인라인 뷰 쿼리 튜닝
/* [인덱스 구성] 
 * 고객_PK : [고객번호]
 * 고객_X1 : [가입일시]
 * 거래_PK : [거래번호]
 * 거래_X1 : [거래일시]
 * 거래_X2 : [고객번호 + 거래일시]
 * */  
SELECT C.고객번호, C.고객명, T.평균거래, T.최소거래, T.최대거래
  FROM 고객 C
  	 , (SELECT 고객번호
  	 		 , AVG(거래금액) 평균거래
  	 		 , MIN(거래금액) 최소거래
  	 		 , MAX(거래금액) 최대거래
  	 	  FROM 거래
  	     WHERE 거래일시 >= TRUNC(SYSDATE, 'MM')
  	     GROUP BY 고객번호
  	   ) T
 WHERE C.가입일시 >= TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM')
   AND C.고객번호 = T.고객번호;
  
/**
 * HASH (GROUP BY)
 *   HASH JOIN
 *     TABLE ACCESS (FULL) OF '고객' (TABLE)
 *     TABLE ACCESS (FULL) OF '거래' (TABLE)
 * */  
  	 
-- 튜닝 쿼리 [ 조인 조건 Pushdown 활용(11g 이후) ]
SELECT /*+ ORDERED USE_NL(T) */
	   C.고객번호, C.고객명, T.평균거래, T.최소거래, T.최대거래
  FROM 고객 C
     , (SELECT /*+ NO_MERGE PUSH_PRED */
     		   고객번호
  	 		 , AVG(거래금액) 평균거래
  	 		 , MIN(거래금액) 최소거래
  	 		 , MAX(거래금액) 최대거래
  	 	  FROM 거래
  	     WHERE 거래일시 >= TRUNC(SYSDATE, 'MM')
  	     GROUP BY 고객번호
  	   ) T
 WHERE C.가입일시 >= TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM')
   AND C.고객번호 = T.고객번호;

/** NESTED LOOPS
 *    TABLE ACCESS (BY INDEX ROWID BATCHED) OF '고객' (TABLE)
 *      INDEX (RANGE SCAN) OF '고객_X1' (INDEX)
 *    VIEW PUSHED PREDICATE
 *      SORT (GROUP BY)
 *        TABLE ACCESS (BY INDEX ROWID BATCHED) OF '거래' (TABLE)
 *          INDEX (RANGE SCAN) OF '거래_X2' (INDEX)
 * */
 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   













