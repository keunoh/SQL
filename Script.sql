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
 
--------------------------- 조인튜닝 47번 ----------------------------------
/** [ 인덱스 구성 ]
 *  상품_PK : [상품코드]
 *  주문상품_PK : [고객번호 + 상품코드 + 주문일시]
 *  주문상품_X1 : [주문일시 + 할인유형코드]
 * */
/** [ 테이블 구성 및 데이터 ]
 * - 주문상품은 비파티션 테이블
 * - 한 달 주문상품 = 100만 건
 * - 주문상품의 보관기간 = 10년
 * - 주문상품 총 건수 = 총 1억 2천만 건(= 100만 * 120개월)
 * - 할인유형코드 조건을 만족하는 데이터 비중 = 20%
 * - 등록된 상품 = 2만 개
 * - 2만 개 상품을 고르게 주문
 * */
SELECT P.상품코드, MIN(P.상품명) 상품명, MIN(P.상품가격) 상품가격
	 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  FROM 주문상품 O, 상품 P
 WHERE O.상품코드 = P.상품코드
   AND O.할인유형코드 = 'K890'
   AND O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
 GROUP BY P.상품코드
 ORDER BY 총추문금액 DESC, 상품코드

/** SORT (ORDER BY)
 *    HASH (GROUP BY)
 *      NESTED LOOPS
 *        NESTED LOOPS
 *    		TABLE ACCESS (BY INDEX ROWID) OF '주문상품' (TABLE)
 * 			  INDEX (RANGE SCAN) OF '주문상품_X1' (INDEX)
 * 			INDEX (UNIQUE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * 		  TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE) 
 * */

-- [내 답안]
-- 1. 주문상품_X1 인덱스를 수정하고싶다. 
---- 주문상품_X1 : [주문일시 + 할인유형코드]  --> [할인유형코드 + 주문일시] 로 수정
-- 2. HASH GROUP BY를 제거하고 싶다. 
SELECT /*+ LEADING (O P) USE_NL(P) */
	   P.상품코드, P.상품명, P.상품가격, O.주문수량, O.총주문금액
  FROM (SELECT /*+ NO_UNNEST INDEX(주문상품 주문상품_X1) */
  			   상품코드, SUM(주문수량) 주문수량, SUM(주문금액) 총주문금액
  		  FROM 주문상품
  		 WHERE 할인유형코드 = 'K890'
  		   AND 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  		 GROUP BY 상품코드
  ) O, 상품 P
 WHERE O.상품코드 = P.상품코드
 ORDER BY O.총주문금액 DESC
 
/** [SQL - 1안] 해설 
 * 상품은 2만 개, SQL에서 사용된 컬럼도 3개뿐.
 * 상품 데이터를 PGA에 충분히 담을 수 있고, 2만 개 상품을 고르게 주문하므로 불필요한 상품을 PGA에 적재하는 비효율도 없다.
 * 따라서 20만개 주문상품 기준으로 NL 조인으로 버퍼 캐시를 탐색하는 것 보다 해시 조인을 PGA를 탐색하는 것이 훨씬 효과적 
 * */  

-- [SQL - 1안]
SELECT /*+ LEADING(P) USE_HASH(O) INDEX(O 주문상품_X1) FULL(P) */
	   P.상품코드, MIN(P.상품명) 상품명, MIN(P.상품가격) 상품가격
	 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  FROM 주문상품 O, 상품 P
 WHERE O.상품코드 = P.상품코드
   AND O.할인유형코드 = 'K890'
   AND O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
 GROUP BY P.상품코드
 ORDER BY 총추문금액 DESC, 상품코드
 
/** SORT (ORDER BY)
 *    HASH (GROUP BY)
 *      HASH JOIN
 *        TABLE ACCESS (FULL) OF '상품' (TABLE)
 *        TABLE ACCESS (BY INDEX ROWID) OF '주문상품' (TABLE)
 *          INDEX (RANGE SCAN) OF '주문상품_X1' (INDEX)
 * */

/** 2안 해설
 * 2만 개상품을 고르게 주문하므로 GROUP BY 결과 집합은 2만여건이다. 상품코드당 주문상품은 평균 10건이므로
 * 이 방식으로 처리하면 조인 횟수를 1/10로 줄일 수 있다. GROUP BY 추가 수행에 따른 부담을 상쇄하고도 남는다.
 * 조인 횟수가 줄고 같은 상품코드로 여러 번 조인하지도 않으므로 NL 조인의 부담이 줄지만, 여기서도 해시 조인이 더 빠르고 
 * 효과적이다. 상품 데이터를 PGA에 충분히 담을 수 있을 뿐만 아니라 2만 개 상품을 고르게 주문하므로 불필요한 상품을 PGA에 적재하는 비효율도 없기 때문이다.
 * 해시 조인은 출력 순서를 보장하지 않으므로 ORDER BY는 맨 마지막에 기술해야 한다. ORDER BY가 없는 인라인 뷰는 옵티마이저에 의해 Merging 될 수 있으므로
 * 정확히 아래 실행계획이 나오게 하려면 NO_MERGE 힌트가 필요하다.
 * */  

-- [SQL - 2안]
SELECT /*+ LEADING(O) USE_HASH(P) FULL(P) */
	   P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액
  FROM ( 
  	SELECT /*+ INDEX(A 주문상품_X1) NO_MERGE */ 
  		   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 A
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드) O
  	 , 상품 P
 WHERE O.상품코드 = P.상품코드
 ORDER BY 총주문금액 DESC, 상품코드
 
/** SORT (ORDER BY)
 *    HASH JOIN
 *      VIEW
 *        HASH (GROUP BY)
 *          PARTITION RANGE (ITERATOR)
 *        	  TABLE ACCESS (FULL) OF '주문상품' (TABLE)
 *      TABLE ACCESS (FULL) OF '상품' (TABLE)
 * */
-------------------------------------------------------------------------
  
--------------------------- 조인튜닝 48번 ----------------------------------  
/** [ 인덱스 구성 ]
 *  상품_PK : [상품코드]
 *  주문상품_PK : [고객번호 + 상품코드 + 주문일시]
 *  주문상품_X1 : [주문일시 + 할인유형코드]
 * */
/** [ 테이블 구성 및 데이터 ]
 * - 주문상품은 월 단위 파티션 테이블(주문일시 기준)
 * - 한 달 주문상품 = 100만 건
 * - 주문상품의 보관기간 = 10년
 * - 주문상품 총 건수 = 총 1억 2천만 건(= 100만 * 120개월)
 * - 할인유형코드 조건을 만족하는 데이터 비중 = 20%
 * - 등록된 상품 = 2만 개
 * - 대부분의 상품을 한 달에 한 개 이상 주문
 * */  
SELECT P.상품코드, MIN(P.상품명) 상품명, MIN(P.상품가격) 상품가격
	 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  FROM 주문상품 O, 상품 P
 WHERE O.상품코드 = P.상품코드
   AND O.할인유형코드 = 'K890'
   AND O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
 GROUP BY P.상품코드
 ORDER BY 총주문금액 DESC, 상품코드
 
/** SORT (ORDER BY)
 *    HASH (GROUP BY)
 *      NESTED LOOPS
 *        NESTED LOOPS
 * 			PARTITION RANGE (ITERATOR)
 * 			  TABLE ACCESS (BY LOCAL INDEX ROWID) OF '주문상품' (TABLE)
 * 				INDEX (RANGE SCAN) OF '주문상품_X1' (INDEX)
 * 		 	INDEX (UNIQUE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * 		  TABLE ACESS (BY INDEX ROWID) OF '상품' (TABLE)
 * */ 
  
-- 내 답안 
-- 1. 인덱스 컬럼추가 : 주문상품_X1 : [할인유형코드 + 주문일시 + 상품코드] -> 결과적으로는 바꿀이유 없음
-- 2. 파티션 테이블이니까 NL 조인이 유리하지 않을까? -> 힌트만 작성
SELECT /*+ LEADING(O) USE_NL(P) INDEX(O 주문상품_X1)  */
	   P.상품코드, MIN(P.상품명) 상품명, MIN(P.상품가격) 상품가격
	 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  FROM 주문상품 O, 상품 P
 WHERE O.상품코드 = P.상품코드
   AND O.할인유형코드 = 'K890'
   AND O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
 GROUP BY P.상품코드
 ORDER BY 총주문금액 DESC, 상품코드  
  
/** [실행계획] 해설 
 * 한 달 주문상품 100만 건 중 할인유형코드 = 'K890' 조건을 만족하는 데이터는 20만 건이다.
 * 주문상품은 월 단위 파티션 테이블이므로 인덱스로 20만 건을 랜덤 액세스하는 것보다 Full Scan이 유리하다.
 * 2만 개 상품을 한 달에 한 개 이상 주문하므로 GROUP BY 결과 집합은 2만여 건이다.
 * 상품코드당 주문상품은 평균 10건이므로 모범답안처럼 GROUP BY 후 조인하면 조인 횟수를 1/10로 줄일 수 있다.
 * */  

/** SORT (ORDER BY)
 *    HASH JOIN
 *      VIEW
 *  	  HASH (GROUP BY)
 * 		    PARTITION RANGE (ITERATOR)
 * 			  TABLE ACCESS (FULL) OF '주문상품' (TABLE)
 * 		TABLE ACCESS (FULL) OF '상품' (TABLE)
 * */ 
SELECT /*+ LEADING(O) USE_HASH(P) FULL(P) */
	   P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액
  FROM (
  	SELECT /*+ FULL(A) NO_MERGE */
  		   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 A
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드) O
  	 , 상품 P
 WHERE O.상품코드 = P.상품코드
 ORDER BY 총주문금액 DESC, 상품코드
   
/** [SQL] 해설
 * 조인 횟수가 줄고 같은 상품코드로 여러 번 조인하지도 않으므로 NL 조인의 부담이 줄지만, 해시 조인이 더 빠르고 효과적이다.
 * 상품 데이터를 PGA에 충분히 담을 수 있을 뿐만 아니라 2만 개 상품을 고르게 주문하므로 불필요한 상품을 PGA에 적재하는 비효율도 없기 때문이다.
 * 해시 조인은 출력 순서를 보장하지 않으므로 ORDER BY는 맨 마지막에 기술해야 한다.
 * ORDER BY가 없는 인라인 뷰는 옵티마이저에 의해 Merging 될 수 있으므로 정확히 위 실행계획이 나오게 하려면 NO_MERGE 힌트가 필요하다.
 * */
-------------------------------------------------------------------------

--------------------------- 조인튜닝 49번 ----------------------------------  
/** [ 인덱스 구성 ]
 *  상품_PK : [상품코드]
 *  주문상품_PK : [고객번호 + 상품코드 + 주문일시]
 *  주문상품_X1 : [주문일시 + 할인유형코드]
 * */
/** [ 테이블 구성 및 데이터 ]
 * - 주문상품은 월 단위 파티션 테이블(주문일시 기준)
 * - 한 달 주문상품 = 100만 건
 * - 주문상품의 보관기간 = 10년
 * - 주문상품 총 건수 = 총 1억 2천만 건(= 100만 * 120개월)
 * - 할인유형코드 조건을 만족하는 데이터 비중 = 20%
 * - 등록된 상품 = 2만 개
 * - 할인유형코드 = 'K890' 조건으로 판매되는 상품은 100여개
 * */  
SELECT P.상품코드, MIN(P.상품명) 상품명, MIN(P.상품가격) 상품가격
	 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  FROM 주문상품 O, 상품 P
 WHERE O.상품코드 = P.상품코드
   AND O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
   AND O.할인유형코드 = 'K890'
 GROUP BY P.상품코드
 ORDER BY 총주문금액 DESC, 상품코드

/** SORT (ORDER BY)
 *    HASH (GROUP BY)
 *      NESTED LOOPS
 * 		  NESTED LOOPS
 * 		    PARTITION RANGE (ITERATOR)
 * 			  TABLE ACCESS (BY LOCAL INDEX ROWID) OF '주문상품' (TABLE)
 * 				INDEX (RANGE SCAN) OF '주문상품_X1' (INDEX)
 * 			INDEX (UNIQUE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * 		  TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
 * */

-- 내 답안 
-- 1. 할인유형코드 조건으로 판매되는 상품이 100여 개 밖에 안 되니까, 스칼라 서브쿼리로 조회하는게 더 낫지 않을까?
SELECT O.상품코드
	 , (SELECT P.상품명 FROM 상품 P WHERE O.상품코드 = P.상품코드) 상품명
	 , (SELECT P.상품가격 FROM 상품 P WHERE O.상품코드 = P.상품코드) 상품가격
	 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  FROM 주문상품 O
 WHERE O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
   AND O.할인유형코드 = 'K890'
 GROUP BY O.상품코드
 ORDER BY 총주문금액 DESC, 상품코드

/** [실행계획] 해설 
 * 한 달 주문상품 100만 건 중 할인유형코드 = 'K890' 조건을 만족하는 데이터는 20만 건이다.
 * 주문상품은 월 단위 파티션 테이블이므로 인덱스로 20만 건을 랜덤 액세스하는 것보다 Full Scan이 유리하다.
 * 2만 개 상품 중 할인유형코드 = 'K890' 조건으로 판매되는 상품은 100여 개이므로 GROUP BY 결과 집합도 100여 건이다.
 * 상품당 주문상품은 평균 2,000건(=20만 개 주문상품 / 100개 상품)이므로 모범답안처럼 GROUP BY를 먼저 처리하면 조인횟수가 많이 감소한다.
 * */  
 
/** SORT (ORDER BY)
 *    NESTED LOOPS
 * 	    NESTED LOOPS
 * 		  VIEW
 * 			HASH (GROUP BY)
 * 			  PARTITION RANGE (ITERATOR)
 * 			    TABLE ACCESS (FULL) OF '주문상품' (TABLE)
 * 		  INDEX (UNIQUE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * 		TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
 * */ 
SELECT /*+ LEADING(O) USE_NL(P) */
	   P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액
  FROM (
  	SELECT /*+ FULL(A) NO_MERGE */
  		   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 A
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드 
	) O, 상품 P
 WHERE O.상품코드 = P.상품코드
 ORDER BY 총주문금액 DESC, 상품코드
	
/** [SQL] 해설
 * GROUP BY 결과 집합은 100건이고 상품은 2만 개이므로 해시 조인보다 NL 조인이 효과적이다.
 * 조인 기준 집합이 소량이고, 같은 상품코드로 여러 번 조인하지도 않기 때문이다.
 * 오히려 해시조인으로 처리하면, 할인유형코드 = 'K890' 조건으로 판매되는 상품이 100여 개 뿐인데 2만 개 상품을 모두 PGA에 적재하는 비효율이 있다.
 * (배치 I/O가 작동하지 않는 한) NL 조인은 출력 순서를 보장하지만, 전체범위 처리이므로 굳이 ORDER BY를 인라인 뷰에서 처리할 이유가 없다.
 * ORDER BY가 없는 인라인 뷰는 옵티마이저에 의해 Merging 될 수 있으므로 정확히 위 실행계획이 나오게 하려면 NO_MERGE 힌트가 필요하다.
 * */
------------------------------------------------------------------------- 
 
--------------------------- 조인튜닝 50번 ----------------------------------  
/** [ 인덱스 구성 ]
 *  상품_PK : [상품코드]
 *  주문상품_PK : [고객번호 + 상품코드 + 주문일시]
 *  주문상품_X1 : [주문일시 + 할인유형코드]
 * */
/** [ 테이블 구성 및 데이터 ]
 * - 주문상품은 월 단위 파티션 테이블(주문일시 기준)
 * - 한 달 주문상품 = 100만 건
 * - 주문상품의 보관기간 = 10년
 * - 주문상품 총 건수 = 총 1억 2천만 건(= 100만 * 120개월)
 * - 할인유형코드 조건을 만족하는 데이터 비중 = 20%
 * - 등록된 상품 = 2만 개
 * - 대부분 상품을 한 달에 한 개 이상 주문
 * */  
SELECT 상품코드, 상품명, 상품가격, 총주문수량, 총주문금액
  FROM (
  	SELECT P.상품코드
  		 , MIN(P.상품명) 상품명, MIN(P.상품가격) 상품가격
  		 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  	  FROM 주문상품 O
  	     , 상품 P
  	 WHERE O.주문상품 = P.주문상품
  	   AND O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND O.할인유형코드 = 'K890'
  	 GROUP BY P.상품코드
  	 ORDER BY 총주문금액 DESC, 상품코드
  )
 WHERE ROWNUM <= 100
 
/** COUNT (STOPKEY)
 *    VIEW
 * 	    SORT (ORDER BY STOPKEY)
 * 		  HASH (GROUP BY)
 * 			NESTED LOOPS
 * 			  NESTED LOOPS
 * 				PARTITION RANGE (ITERATOR) 
 * 				  TABLE ACCESS (BY LOCAL INDEX ROWID) OF '주문상품' (TABLE)
 * 					INDEX (RANGE SCAN) OF '주문상품_X1' (INDEX)
 * 				INDEX (UNIQUE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * 			  TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE) 
 * */ 
 
-- 내 답안
-- 최상위 100건만 뽑아오고 싶다면, Full scan 보다 Index range scan이 더 효율적이지 않을까?
-- 그리고 Hash group by -> 순서가 무작위로 추출되니까 그냥 그룹바이로 변환해주고 싶은데..
SELECT 상품코드, 상품명, 상품가격, 총주문수량, 총주문금액
  FROM (
  	SELECT /*+ LEADING(O) USE_NL(P) INDEX(O 주문상품_X1) */
  		   P.상품코드
  		 , MIN(P.상품명) 상품명, MIN(P.상품가격) 상품가격
  		 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  	  FROM 주문상품 O
  	     , 상품 P
  	 WHERE O.주문상품 = P.주문상품
  	   AND O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND O.할인유형코드 = 'K890'
  	 GROUP BY P.상품코드
  	 ORDER BY 총주문금액 DESC, 상품코드
  )
 WHERE ROWNUM <= 100
 
/** [실행계획 - 1안 ] 해설 
 * 한 달 주문상품 100만 건 중 할인유형코드 = 'K890' 조건을 만족하는 데이터는 20만 건이다.
 * 주문상품은 월 단위 파티션 테이블이므로 인덱스로 20만 건을 랜덤 액세스하는 것보다 Full Scan이 유리하다.
 * 2만 개 상품을 한 달에 한 개 이상 주문하므로 GROUP BY 결과 집합은 2만여 건이다.
 * 상품코드당 주문상품은 평균 10건이므로 모범답안 1안처럼 GROUP BY 후 조인하면 조인 횟수를 1/10으로 줄일 수 있다.
 * */  
 
/** SORT (ORDER BY)
 *    COUNT (STOPKEY)
 * 		NESTED LOOPS
 * 		  NESTED LOOPS
 * 			VIEW
 * 			  SORT (ORDER BY)
 * 				HASH (GROUP BY)
 * 				  PARTITION RANGE (ITERATOR)
 * 					TABLE ACCESS (FULL) OF '주문상품' (TABLE)
 * 			INDEX (UNIQUE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * 		  TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
 * */ 
 
-- [ SQL - 1안 ]
SELECT /*+ LEADING(O) USE_NL(P) */
	   P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액
  FROM (
  	SELECT /*+ FULL(A) */
  	  	   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 A
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드
  	 ORDER BY 총주문금액 DESC, 상품코드
  ) O, 상품 P
 WHERE O.상품코드 = P.상품코드
   AND ROWNUM <= 100
 ORDER BY 총주문금액 DESC, 상품코드
 
/** [실행계획 - 2안 ] 해설 
 * 총주문금액 내림차순, 상품코드 오름차순으로 정렬한 2만여 개 결과집합 중 상위 100개만 추출해야하므로 ORDER BY는 인라인 뷰 안에 기술해야 한다.
 * 등록된 2만 개 상품 중 100개만 조인하므로 해시 조인보다 NL 조인이 효과적이다.
 * ORDER BY가 있고 바깥에 ROWNUM을 사용한 인라인 뷰는 Merging 될 수 없으므로 NO_MERGE 힌트는 불필요하다.
 * 인라인 뷰에서 정렬한 결과집합 중 100건을 추출했는데 NL 조인 과정에 배치 I/O가 작동하면 출력 순서가 흐트러질 수 있으므로 정렬 기준을 바깥에 한 번 더 명시해야한다.
 * 인라인 뷰 바깥에 ORDER BY를 한 번 더 기술하지 않으려면 모범답안 2안처럼 NO_NLJ_BATCHING 힌트를 추가하면 된다.
 * */   
 
-- [ SQL - 2안 ]
SELECT /*+ LEADING(O) USE_NL(P) NO_NLJ_BATCHING(P) */
	   P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액
  FROM (
  	SELECT /*+ FULL(A) */
  	  	   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 A
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드
  	 ORDER BY 총주문금액 DESC, 상품코드
  ) O, 상품 P
 WHERE O.상품코드 = P.상품코드
   AND ROWNUM <= 100
------------------------------------------------------------------------- 
 
--------------------------- 조인튜닝 51번 ---------------------------------- 
-- 결과집합을 일부(보통 상위100개)만 출력하고 멈추는 애플리케이션 환경
/** [ 인덱스 구성 ]
 *  상품_PK : [상품코드]
 *  주문상품_PK : [고객번호 + 상품코드 + 주문일시]
 *  주문상품_X1 : [주문일시 + 할인유형코드]
 * */
/** [ 테이블 구성 및 데이터 ]
 * - 주문상품은 비파티션 테이블
 * - 한 달 주문상품 = 100만 건
 * - 주문상품의 보관기간 = 10년
 * - 주문상품 총 건수 = 총 1억 2천만 건(= 100만 * 120개월)
 * - 할인유형코드 조건을 만족하는 데이터 비중 = 10%
 * - 등록된 상품 = 50만 개 / 속성 = 500개
 * - 대부분 상품을 한 달에 한 개 이상 주문
 * */

SELECT P.상품코드, MIN(P.상품명) 상품명, MIN(P.등록일시) 등록일시
	 , MIN(P.상품가격) 상품가격, MIN(P.공급자ID) 공급자ID
	 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  FROM 주문상품 O
  	 , 상품 P
 WHERE O.상품코드 = P.상품코드
   AND O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
   AND O.할인유형코드 = 'K890'
 GROUP BY P.상품코드
 ORDER BY 등록일시 DESC 
 
/** SORT (ORDER BY)
 *    HASH (GROUP BY)
 *   	NESTED LOOPS
 * 		  NESTED LOOPS
 * 		    TABLE ACCESS (BY INDEX ROWID) OF '주문상품' (TABLE)
 * 			  INDEX (RANGE SCAN) OF '주문상품_X1' (INDEX)
 * 			INDEX (UNIQUE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * 		  TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
 * */ 
 
/** 내 답안
* 등록된 상품이 너무 많다. -> 너무 많은 조인이 일어나겠다.
* 할인유형코드 조건을 만족하는 비중이 10%니까 원하는 데이터는 10만 건이 조회될 것이다.
* 비파티션 테이블이므로 10만건 빠르게 조회해도록 NDV가 좋은 할인유형코드를 선두컬럼으로 하는 인덱스를 생성해주자. -> 주문상품_X1 = [할인유형코드 + 주문일시]
* 인라인뷰 10만건만 먼저 조회하고 상품테이블과 NL 조인 유도한다.
* SORT (ORDER BY) 제거 하기 위해 인덱스 추가 -> 상품_X1 = [상품코드 + 등록일시]
* */
SELECT /*+ LEADING(O) USE_NL(P) INDEX(P 상품_X1) */
	   P.상품코드, P.상품명, P.등록일시, P.상품가격, P.공급자ID
	 , O.총주문수량, O.총주문금액  
  FROM (
  	SELECT /*+ INDEX(주문상품 주문상품_X1) NO_MERGE  */
  		   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드
  ) O, 상품 P
 WHERE O.상품코드 = P.상품코드
 ORDER BY 등록일시 DESC
 
/** [ 실행계획 ] 해설 
 * 결과집합을 일부만 출력하고 멈춘다는 건 부분범위 처리 기능함을 의미한다.
 * 부분범위 처리를 활용하려면 소트 연산을 생략할 수 있어야 한다.
 * 소트 연산을 생략하고 상품 등록일시 역순으로 정렬된 결과집합을 빠르게 출력하려면, 등록일시가 선두인 상품 인덱스를 역순으로 스캔하면서 주문상품 GROUP BY 집합과 NL 조인하면 된다.
 * 단, 반드시 Join Predicate Pushdown 기능이 작동해야 한다.
 * 따라서 튜닝 의도대로 정확히 실행되게 하려면 NO_MERE와 PUSH_PRED 힌틀르 사용해야 한다.
 * */   
 
/** NESTED LOOPS
 *    TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
 * 		INDEX (FULL SCAN DESCENDING) OF '상품_X1' (INDEX)
 * 	  VIEW PUSHED PREDICATE
 * 		FILTER
 * 		  SORT (AGGREGATE)
 * 			TABLE ACCESS (BY INDEX ROWID) OF '주문상품' (TABLE)
 * 			  INDEX (RAGNE SCAN) OF '주문상품_X2' (INDEX)
 * */ 
 
-- 모범답안 - [ SQL ]
SELECT /*+ LEADING(P) USE_NL(O) INDEX_DESC(P 상품_X1) */
  	   P.상품코드, P.상품명, P.등록일시, P.상품가격, P.공급자ID
	 , O.총주문수량, O.총주문금액  
  FROM (
  	SELECT /*+ NO_MERGE PUSH_PRED INDEX(A 주문상품_X2) */
  		   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 A
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드
  ) O, 상품 P
 WHERE O.상품코드 = P.상품코드
 ORDER BY P.등록일시 DESC
 
/** [ 인덱스 재구성 ]
 * 상품_X1 : [ 등록일시 ]
 * 주문상품_X2 : [ 할인유형코드 + 상품코드 + 주문일시 ] 또는 [ 상품코드 + 할인유형코드 + 주문일시 ]
 * */ 
------------------------------------------------------------------------- 
 
--------------------------- 조인튜닝 52번 ----------------------------------  
-- 결과집합을 일부(보통 상위100개)만 출력하고 멈추는 애플리케이션 환경
/** [ 인덱스 구성 ]
 *  상품_PK : [상품코드]
 *  주문상품_PK : [고객번호 + 상품코드 + 주문일시]
 *  주문상품_X1 : [주문일시 + 할인유형코드]
 * */
/** [ 테이블 구성 및 데이터 ]
 * - 주문상품은 월 단위 파티션 테이블(주문일시 기준)
 * - 한 달 주문상품 = 100만 건
 * - 주문상품의 보관기간 = 10년
 * - 주문상품 총 건수 = 총 1억 2천만 건(= 100만 * 120개월)
 * - 할인유형코드 조건을 만족하는 데이터 비중 = 10%
 * - 등록된 상품 = 50만 개 / 속성 = 500개
 * - 할인유형코드 = 'K890' 조건으로 판매되는 상품은 5,000개
 * */ 

SELECT P.상품코드, MIN(P.상품명) 상품명, MIN(P.등록일시) 등록일시
	 , MIN(P.상품가격) 상품가격, MIN(P.공급자ID) 공급자ID
	 , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
  FROM 주문상품 O
     , 상품 P
 WHERE O.상품코드 = P.상품코드
   AND O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
   AND O.할인유형코드 = 'K890'
 GROUP BY P.상품코드
 ORDER BY 등록일시 DESC
 
/** SORT (ORDER BY)
 * 	  HASH (GROUP BY)
 * 		NESTED LOOPS
 * 		  NESTED LOOPS
 * 			PARTITION RANGE (ITERATOR)
 * 			  TABLE ACCESS (BY LOCAL INDEX ROWID) OF '주문상품' (TABLE)
 * 				INDEX (RANGE SCAN) OF '주문상품_X1' (INDEX)
 * 			INDEX (UNIQUE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * 		  TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
 * */
 
/** 내 답안
 * 파티션 테이블이므로 FULL SCAN 유도
 * 인라인뷰에서 GROUP BY 먼저 수행 후 조인 유도
 * 인라인뷰 안에 ORDER BY절이 없으므로 뷰 머징 방지
 * 부분범위처리 가능하므로 SORT연산 없애주기 위해 인덱스 생성 -> 상품_X1 : [ 등록일시 ]
 * */

SELECT /*+ LEADING(O) USE_NL(P) INDEX(P 상품_X1) */
	   P.상품코드, P.상품명, P.등록일시, P.상품가격, P.공급자ID
	 , O.총주문수량, O.총주문금액
  FROM (
  	SELECT /*+ FULL(A) NO_MERGE */
  		   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 A
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드
  ) O, 상품 P
 WHERE O.상품코드 = P.상품코드
 ORDER BY 등록일시 DESC;
 
/** 해설 
 * 부분범위 처리를 활용하려면 상품의 등록일시 인덱스를 역순으로 스캔하면서 주문상품 GROUP BY 집합을 Join Predicate Pushdown 방식으로 NL 조인해야한다.
 * */ 
SELECT /*+ LEADING(P) USE_NL(O) INDEX_DESC(P (등록일시)) */
	   P.상품코드, P.상품명, P.등록일시, P.상품가격, P.공급자ID
	 , O.총주문수량, O.총주문금액
  FROM (
  	SELECT /*+ NO_MERGE PUSH_PRED INDEX(A) */
  		   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 A
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드
  ) O, 상품 P
 WHERE O.상품코드 = P.상품코드
 ORDER BY 등록일시 DESC
/**문제는 상품 기준으로 주문상품과 조인하면 첫 번째 Fetch Call을 위한 Array를 채우기까지 상당히 많은 데이터를 읽어야 한다는 데 있다.
 * 할인유형코드 = 'K890' 조건으로 판매되는 상품은 5,000개이므로 나머지 495,000개는 조인에 실패하기 때문이다.
 * 상위 100개 상품을 출력하려면 대략 10,000개 상품을 스캔하면서 주문상품과 조인하고 조건절을 필터링해야하므로 빠른 응답속도를 얻기 힘들다.
 * 반면, 정렬 기준이 상품의 등록일시인 상황에서 아래처럼 주문상품을 먼저 읽어서 GROUP BY하면 조인까지 모두 마쳐야 출력을 시작할 수 있다.
 * 즉, 부분범위 처리의 이점을 전혀 활용하지 못 한다.
 * */
SELECT /*+ LEADING(O) USE_NL(P) */
	   P.상품코드, P.상품명, P.등록일시, P.상품가격, P.공급자ID
	 , O.총주문수량, O.총주문금액
  FROM (
  	SELECT /*+ NO_MERGE */
  		   상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
  	  FROM 주문상품 A
  	 WHERE 주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND 할인유형코드 = 'K890'
  	 GROUP BY 상품코드
  ) O, 상품 P
 WHERE O.상품코드 = P.상품코드
 ORDER BY 등록일시 DESC
/**20만 개 상품 중 할인유형코드 = 'K890' 조건으로 판매되는 상품은 5,000개이므로 GROUP BY 결과 집합도 5,000건이다.
 * GROUP BY 후 NL 조인하면 50만 개 중 5,000개 상품만 인덱스로 읽어서 조인하면 되지만, NL 조인의 특성상 느리다.
 * 반면, GROUP BY 후 해시 조인하면, 50만 개 상품을 "모두" 해시 맵에 올린 후 해시 맵을 5,000번 탐색한다.
 * PGA에서 탐색하므로 조인 과정의 성능은 해시 조인이 우세하겠지만, 상품 테이블에 컬럼이 많으므로 해시 맵을 생성하기 위해 FULL SCAN 하는 과정에 블록 I/O가 많이 발생한다.
 * 자칫 가용 PGA 공간이 가득차면, 그로 인한 성능 저하도 감수해야 한다.
 * */ 

/** [실행계획 - 1안 ] 해설
 * 상품 인덱스를 [등록일시 + 상품코드] 또는 [상품코드 + 등록일시] 순으로 구성하고 모범답안 1안처럼 인라인 뷰 내에서 인덱스만 읽어서 해시 조인하면 정렬 기준인 등록일시를 빠르게 얻을 수 있다.
 * 상품코드로 GROUP BY 하고 등록일시로 ORDER BY 까지 끝낸 집합을 기준으로 인덱스로 NL 조인하면, 앞쪽 일부(보통 100개) 상품만 읽으면 되기 때문에 효과적이다.  
 * */
 
/** TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
 *    NESTED LOOPS
 * 		VIEW
 * 		  SORT (ORDER BY)
 * 			HASH (GROUP BY)
 * 			  HASH JOIN
 * 				INDEX (FAST FULL SCAN) OF '상품_X1' (INDEX)
 * 				PARTITION RANGE (ITERATOR) 
 * 				  TABLE ACCESS (FULL) OF '주문상품' (TABLE)
 * 		INDEX (UNIQUE SCAN) OF '상품_PK' (INDEX (UNIQUE))
 * */ 
 
-- 모범답안 [SQL - 1안]
SELECT /*+ LEADING(O) USE_NL(P) NO_NLJ_BATCHING(P) */
	   P.상품코드, P.상품명, B.등록일시, P.상품가격, P.공급자ID
	 , O.총주문수량, O.총주문금액
  FROM (
  	SELECT /*+ LEADING(B) USE_HASH(A) FULL(A) INDEX_FFS(B) */
  		   A.상품코드, MIN(B.등록일시) 등록일시
  		 , SUM(A.주문수량) 총주문수량, SUM(A.주문금액) 총주문금액
  	  FROM 주문상품 A
  	 	 , 상품 B
  	 WHERE A.상품코드 = B.상품코드
  	   AND A.주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND A.할인유형코드 = 'K890'
  	 GROUP BY A.상품코드
  	 ORDER BY 등록일시 DESC
  ) O, 상품 P
 WHERE O.상품코드 = P.상품코드
 
/** [실행계획 - 2안 ] 해설
 * GROUP BY와 ORDER BY를 함께 사용한 인라인 뷰는 Merging 될 수 없으므로 NO_MERGE 힌트는 불필요하다.
 * NL 조인 과정에 배치 I/O가 작동하면 출력 순서가 흐트러질 수 있으므로 NO_NLJ_BATCHING 힌트를 추가해야한다.
 * 모범답안 2안처럼 인라인 뷰에서 상품_X1 인덱스와 해시 조인할 때 ROWID를 읽어서 상품 테이블과 다시 조인할 때 사용하는 방법도 있다.
 * */ 
 
/** NESTED LOOPS
 * 	  VIEW
 * 		SORT (ORDER BY)
 * 		  HASH (GROUP BY)
 * 			HASH JOIN
 * 			  INDEX (FAST FULL SCAN) OF '상품_X1' (INDEX)
 * 			  PARTITION RANGE (ITERATOR)
 * 				TABLE ACCESS (FULL) OF '주문상품' (TABLE)
 * 	  TABLE ACCESS (BY USER ROWID) OF '상품' (TABLE)
 * */ 
 
-- 모범답안 [SQL - 2안]
SELECT /*+ LEADING(O) USE_NL(P) */
	   P.상품코드, P.상품명, B.등록일시, P.상품가격, P.공급자ID
	 , O.총주문수량, O.총주문금액
  FROM (
  	SELECT /*+ LEADING(B) USE_HASH(A) FULL(A) INDEX_FFS(B) */
  		   A.상품코드, MIN(B.등록일시) 등록일시
  		 , SUM(A.주문수량) 총주문수량, SUM(A.주문금액) 총주문금액
  	  FROM 주문상품 A
  	 	 , 상품 B
  	 WHERE A.상품코드 = B.상품코드
  	   AND A.주문일시 >= ADD_MONTHS(SYSDATE, -1)
  	   AND A.할인유형코드 = 'K890'
  	 GROUP BY A.상품코드
  	 ORDER BY 등록일시 DESC
  ) O, 상품 P
 WHERE O.ROWID = P.ROWID 
 
/** [인덱스 재구성]
 * 상품_X1 : [등록일시 + 상품코드] 또는 [상품코드 + 등록일시]
 * 주문상품_X1 : 할인유형코드 + 주문일시
 * */ 
------------------------------------------------------------------------- 
 
--------------------------- 조인튜닝 53번 ---------------------------------- 
-- 아래 데이터 모델에서 'Z123456' 작업자(작업자ID = 'Z123456')가 최근 한 달간 방문해서 처리한
-- 작업지시 중 실제방문일자 역순으로 최근 10건만 출력하는 SQL을 작성하고, 최적 인덱스를 설계하시오
/** [ 인덱스 구성 ]
 *  작업지시_PK : [ 작업일련번호 ]
 *  개통접수_PK : [ 개통접수번호 ]
 *  장애접수_PK : [ 장애접수번호 ]
 * */
/** [ 데이터 발생 규칙 ]
 * 작업지시에 데이터를 입력할 때 개통접수번호 또는 장애접수번호에 반드시 값 입력
 * 개통접수번호와 장애접수번호 양쪽 모두에 값을 입력할 수는 없음
 * */  
 
/** 내 답안
 * [ 인덱스 구성 ] 
 * 작업지시_X1 : [ 작업자ID + 실제방문일자 ]
 * */ 
SELECT Y.작업일련번호, Y.실제방문일자, Y.접수구분
  	 , Y.고객번호, Y.주소
  FROM (
  	SELECT X.작업일련번호, X.실제방문일자, X.접수구분
  		 , X.고객번호, X.주소
	  FROM (
		 SELECT /*+ INDEX(A 작업지시_X1) */
			   A.작업일련번호, A.실제방문일자, '개통' AS 접수구분
			 , B.고객번호, B.주소
		  FROM 작업지시 A
		  	 , 개통접수 B
		 WHERE A.개통접수번호 = B.개통접수번호
		   AND A.작업자ID = 'Z123456'
		 UNION ALL
		 SELECT 
			   C.작업일련번호, C.실제방문일자, '장애'
			 , D.고객번호, D.주소
		  FROM 작업지시 C 
		  	 , 장애접수 D
		 WHERE C.개통접수번호 = D.개통접수번호
		   AND C.작업자ID = 'Z123456'
	 	) X
	 ORDER BY X.실제방문일자 DESC
  ) Y
WHERE ROWNUM <= 10;
 
/** 해설 
 * 'Z123456' 작업자가 최근 한 달간 방문해서 처리한 작업지시 중 실제방문일자 역순으로 최근 10건만 출력하는 SQL은 아래와 같고, 최적 인덱스 구성은 [ 작업자ID + 실제방문일자 ]
 * */  
SELECT *
  FROM (
  	SELECT 작업일련번호, 실제방문일자
  	  FROM 작업지시
  	 WHERE 작업자ID = :작업자ID
  	   AND 실제방문일자 >= TRUNC(ADD_MONTHS(SYSDATE, -1))
  	 ORDER BY 실제방문일자 DESC 
  )
 WHERE ROWNUM <= 10
/** 고객번호와 주소 정보는 개통접수 또는 장애접수 테이블에서 읽어야 하는데, 제시한 발생규칙은 작업지시가 나머지 두 테이블과 배타적(Exclusive OR) 관계임을 설명하고 있다.
 * 따라서 아래 모범답안처럼 두 테이블과 OUTER 조인해서 선택적으로 값을 읽어야 한다.
 * 접수구분은 작업지시의 개통접수번호와 장애접수번호 중 어느 쪽에 값이 입력됐는지 여부에 따라 구분해도 되고, 모범답안처럼 어느 테이블과 조인에 성공했는지 여부에 따라 구분해도 된다.
 * (개통접수와 장애접수를 인라인 뷰 바깥에서 조인하면 좋다고 생각할 수 있지만, 인덱스만 잘 구성해 주면 어차피 10건만 읽고 멈추기 때문에 상관없다.
 *  부분범위 처리 불가능하도록 인덱스를 구성한 경우라면, SQL을 그렇게 작성하는 것이 좋다.)
 * */ 
-- 모범답안 [ SQL ]
SELECT *
  FROM (
  	SELECT /*+ ORDERED USE_NL(B) USE_NL(C) */
  	  	   A.작업일련번호, A.실제방문일자
  	  	 , NVL2(B.개통접수번호, '개통', '장애') 접수구분
  	  	 , NVL2(B.개통접수번호, B.고객번호, C.고객번호) 고객번호
  	  	 , NVL2(B.개통접수번호, B.주소, C.주소) 주소
   	  FROM 작업지시 A, 개통접수 B, 장애접수 C
   	 WHERE A.개통접수번호 = B.개통접수번호(+)
   	   AND A.장애접수번호 = C.장애접수번호(+)
   	   AND A.작업자ID = :작업자ID
   	   AND A.실제방문일자 >= TRUNC(ADD_MONTHS(SYSDATE, -1))
   	 ORDER BY A.실제방문일자 DESC
  )
 WHERE ROWNUM <= 10
 
/** [ 인덱스 구성 ]
 * 작업지시_X1 : [ 작업자ID + 실제방문일자 ]
 * */ 
------------------------------------------------------------------------- 
 
--------------------------- 조인튜닝 54번 ---------------------------------- 
-- 아래 데이터 모델에서 인덱스 구성 하에서 방문예정일자가 오늘인 작업지시 데이터를 모두 출력하는 쿼리를 작성
-- (NL 조인 기준으로 최적 쿼리를 작성하되, 인덱스 변경 및 힌트 지정은 불가)
/** [ 인덱스 구성 ]
 * 작업지시_PK : [ 작업일련번호 ]
 * 작업지시_X1 : [ 작업구분코드 + 방문예정일자 ]
 * 개통접수_PK : [ 개통접수번호 ]
 * 장애접수_PK : [ 장애접수번호 ]
 * */
/** [ 데이터 발생 규칙 ]
 * 작업지시에 데이터를 입력할 때, 개통건(작업구분코드 = 'A')이면 접수번호에 개통접수번호를 입력하고,
 * 장애건(작업구분코드 = 'B')이면 장애접수번호를 입력
 * */   
 
-- 내 답안
SELECT A.작업일련번호
	 , A.작업자ID
	 , NVL2(B.개통접수번호, '개통', '장애') 접수구분
	 , NVL2(B.개통접수번호, B.고객번호, C.고객번호) 고객번호
	 , NVL2(B.개통접수번호, B.주소, C.주소) 주소
  FROM 작업지시 A, 개통접수 B, 장애접수 C
 WHERE A.접수번호 = B.개통접수번호(+)
   AND A.접수번호 = C.장애접수번호(+)
   AND A.작업구분코드 IN ('A', 'B')
   AND A.방문예정일자 = TO_CHAR(TRUNC(SYSDATE, 'YYYYMMDD'));
  
/** 해설
 * 데이터를 모두 출력해야 하므로 부분범위 처리를 활용한 튜닝 기법은 고려할 필요가 없다.
 * 데이터 모델은 작업지시가 나머지 두 테이블과 배타적(Exclusive OR) 관계임을 나타내고 있다.
 * 제시한 발생규칙은 좀 더 구체적으로 말해, 개통건(작업구분코드 = 'A')은 개통접수 테이블과, 장애건(작업구분코드 = 'B')은 장애접수 테이블과 관계를 갖는다고 설명하고 있다.
 * 작업지시_X1 인덱스가 [ 작업구분코드 + 방문예정일자 ] 순으로 구성돼 있으므로 개통건과 장애건을 각각 조회해서 UNION ALL로 결합했을 때 발생하는 비효율은 없다.
 * */   
 
-- 모범답안 [ SQL ] 
SELECT X.작업일련번호, X.작업자ID, '개통' AS 작업구분, Y.고객번호, Y.주소
  FROM 작업지시 X, 개통접수 Y
 WHERE X.접수번호 = Y.개통접수번호
   AND X.작업구분코드 = 'A'
   AND X.방문예정일자 = TO_CHAR(SYSDATE, 'YYYYMMDD')
 UNION ALL
SELECT X.작업일련번호, X.작업자ID, '장애' AS 작업구분, Y.고객번호, Y.주소
  FROM 작업지시 X, 장애접수 Y
 WHERE X.접수번호 = Y.장애접수번호
   AND X.작업구분코드 = 'B'
   AND X.방문예정일자 = TO_CHAR(SYSDATE, 'YYYYMMDD') 
------------------------------------------------------------------------- 
 
--------------------------- 조인튜닝 55번 ---------------------------------- 
-- 아래 데이터 모델에서 인덱스 구성 하에서 방문예정일자가 오늘인 작업지시 데이터를 모두 출력하는 쿼리를 작성
-- (NL 조인 기준으로 최적 쿼리를 작성하되, 인덱스 변경 및 힌트 지정은 불가)
/** [ 인덱스 구성 ]
 * 작업지시_PK : [ 작업일련번호 ]
 * 작업지시_X1 : [ 방문예정일자 ]
 * 개통접수_PK : [ 개통접수번호 ]
 * 장애접수_PK : [ 장애접수번호 ]
 * */
/** [ 데이터 발생 규칙 ]
 * 작업지시에 데이터를 입력할 때, 개통건(작업구분코드 = 'A')이면 접수번호에 개통접수번호를 입력하고,
 * 장애건(작업구분코드 = 'B')이면 장애접수번호를 입력
 * */    
 
-- 내 답안
SELECT A.작업일련번호
	 , A.작업자ID
	 , NVL2(B.개통접수번호, '개통', '장애') 접수구분
	 , NVL2(B.개통접수번호, B.고객번호, C.고객번호) 고객번호
	 , NVL2(B.개통접수번호, B.주소, C.주소) 주소
  FROM 작업지시 A, 개통접수 B, 장애접수 C
 WHERE A.접수번호 = B.개통접수번호(+)
   AND A.접수번호 = C.장애접수번호(+)
   AND A.방문예정일자 = TO_CHAR(SYSDATE, 'YYYYMMDD'); 
 
/** 해설
 * 데이터 모델은 작업지시가 나머지 두 테이블과 배타적(Exclusive OR) 관계임을 나타내고 있다.
 * 제시한 발생규칙은 좀 더 구체적으로 말해, 개통건(작업구분코드 = 'A')은 개통접수 테이블과, 장애건(작업구분코드 = 'B')은 장애접수 테이블과 관계를 갖는다고 설명하고 있다.
 * 이 문제의 핵심은 작업지시_X1 인덱스가 방문예정일자 단일 컬럼으로 구성돼 있다는 데 있다.
 * 지금과 같은 인덱스 구성에서 앞서 푼 문제처럼 개통건과 장애건을 각각 조회해서 UNION ALL로 결합하도록 SQL을 작성했다고 가정해보자.
 * 그러면 작업지시_X1 인덱스에서 방문예정일자 조건절 구간을 두 번 스캔해야 한다.
 * 테이블 레코드도 각각 두 번씩 액세스한 후에 작업구분코드로 필터링해야 한다.
 * 모범답안에서 아래 조건은 작업지시의 작업구분코드가 'A'일 때만 개통접수 테이블과 조인을 시도한다.
 * 작업구분코드가 'A'가 아닐 때는 DECODE 함수가 NULL을 반환하므로 조인을 시도하지 않는다.
 * DECODE 함수 대신 CASE 문을 사용해도 된다.
 * 
 * AND B.개통접수번호(+) = DECODE(A.작업구분코드, 'A', A.접수번호)
 * 
 * 아래 조건은 작업지시의 작업구분코드가 'B'일 때만 장애접수 테이블과 조인을 시도한다.
 * 작업구분코드가 'B'가 아닐 때는 DECODE 함수가 NULL을 반환하므로 조인을 시도하지 않는다.
 * AND C.장애접수번호(+) = DECODE(A.작업구분코드, 'B', A.접수번호)
 * 
 * SQL을 이렇게 작성하면 작업지시_X1 인덱스에서 방문예정일자 조건절 구간을 한 번만 스캔하면 된다.
 * 그리고 작업구분코드 값에 따라 개통접수 또는 장애접수와 선택적으로 조인하므로 테이블 레코드도 각각 한 번씩만 액세스한다.
 * (작업지시 테이블은 어차피 액세스해야 하므로 인덱스에 작업구분코드를 추가해서 얻는 이점은 없다.)
 * 데이터를 모두 출력해야 한다고 전제하였으므로 부분범위 처리를 활용한 튜닝 기법은 고려할 필요가 없지만, SQL을 이 방식으로 작성하면 부분범위 처리가 가능한 장점도 있다.
 * 예를들어, 접수번호로 정렬한 결과집합에서 앞쪽 일부만 읽고 멈출 수 있는 상황이라면, 인덱스를 [ 방문예정일자 + 접수번호 ] 순으로 구성해 주면 된다.
 * 앞서 푼 문제처럼 UNION ALL로 작성한 경우에는 인덱스를 이용한 소트 생략이 불가능하므로 부분범위 처리도 불가능하다.
 * (결과집합을 정렬하지 않는 부분범위 처리는 가능하다.)
 * */ 
 
-- 모범답안 [ SQL ]
SELECT A.작업일련번호
	 , A.작업자ID
	 , DECODE(A.작업구분코드, 'A', '개통', 'B', '장애') AS 작업구분
	 , DECODE(A.작업구분코드, 'A', B.고객번호, 'B', C.고객번호) AS 고객번호
	 , DECODE(A.작업구분코드, 'A', B.주소, 'B', C.주소) AS 주소
  FROM 작업지시 A, 개통접수 B, 장애접수 C
 WHERE B.개통접수번호(+) = DECODE(A.작업구분코드, 'A', A.접수번호)
   AND C.장애접수번호(+) = DECODE(A.작업구분코드, 'B', A.접수번호)
   AND A.방문예정일자 = TO_CHAR(SYSDATE, 'YYYYMMDD')
------------------------------------------------------------------------- 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 