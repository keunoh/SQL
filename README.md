# SQL 
다룰 내용
- 쿼리 성능 측정 기초
- 개발 및 관리 도구 사용 주의, ANSI ISO 표준
- WHERE 절과 JOIN 절 작성 순서, 스키마 이름 지정
- 날짜시간 상수 이해, char vs varchar 이해
- 조인조건 vs 검색 조건, 임의 쿼리 식별자 달기
- 의미 오류는 잠재적인 성능 이슈

--- 
# 쿼리작성법
### 쿼리는 Database의 Framework
1. 성능과 유지관리 고려
    - JOIN, ORDER BY, WITH ROLLUP 등
    - 사라지는 구문들은 사용배제
        - SELECT *
        - FROM dbo.Orders AS o
        - INNER JOIN dbo.[Order Details] AS d
        - ON o.OrderID = d.OrderID

2. WHERE 절 작성 순서는 상관이 없이 Optimizer가 판단해서 해준다.
    - 수학에서 A + B = B + A 인 것처럼

3. FROM 절 작성 순서도 Optimizer 판단에 의해서 성능이 좋은 쪽으로 JOIN 한다.
    - INNER JOIN 사용할 때는 고민하지 않아도 되고, OUTER JOIN은 다르다.

4. 스키마 이름 지정
    - 되도록 스키마도 함께 작성해주는 것이 좋다.
    - 개체 유일성
    - db.schema.object
    - schema 생략 시 ID 사용
    - SELECT * FROM dbo.A, EXEC dbo.up_Orders

5. 코드에서 임의/매개변수 쿼리의 호출 식별자 달기
    - 주석에 호출 모듈 설명 달기

6. 의미 오류(Semantic Error)
    - IS NULL 조건을 지정할 때 이미 NOT NULL 컬럼이거나, PK라면 의미가 없는 조건절
    - CHECK(Quantity > 0)인 컬럼 상황에서 WHERE Quantity < 0 는 의미 없는 조건걸
    - SELECT OrderDate, CustomerID FROM dbo.Orders WHERE CustomerID = 'QUICK';
        - 이미 CustomerID = 'QUICK'라는게 명확하므로 SELECT 절에 쓰지 않는 것이 좋다.
    - EXISTS 안에 SELECT 절은 옵티마이저의 관심 밖이다. 즉, 관계없음
    - NOT IN (NULL) -> SubQuery 안의 결과가 한 건이라도 NULL이라면 이 조건은 확인불가가 되어서 외부 쿼리의SELECT 결과가 나오지 않는다.
    - OUTER JOIN을 할 때 기준테이블을 WHERE 조건절에 적어주어야 한다. OUTER JOIN되는 테이블을 조건절에 적어주면 의미없는 OUTER JOIN이 된다.

---
# 쿼리금기사항
1. SARG -> (Search ARGument, 검색 인수) - 사그, 사지
    - Predicate에서 검색 대상 및 범위를 제한할 수 있는 식 -> WHERE 절이나 FROM 절 JOIN 조건 등
    - 해당 열에 인덱스 사용 및 쿼리 최적화를 위한 필요 조건
2. Non-SARG 유형 + a -> 피해야함
    - 불필요한 열 참조 : ex) SELECT * FROM dbo.Categories
    - 불필요한 행 검색 : ex) SELECT * FROM 웹사이트_오류_로그 WHERE 작성일자 BETWEEN '20201001' AND '20201001 23:59:59' ORDER BY 작성일자 DESC -> 500,000건 발생
        - 추가 검색 조건이나 적절한 페이징처리를 해줘서 해결한다.
    - Index열에 부정형 사용 주의
        - 조건은 "="이 가장 빠르고 효율적
        - NOT IN은 최후의 보루이므로 다른 방식으로 해결할 수 있는지 파악
    - 인덱스 선두 컬럼은 최대한 "="로 처리한다.
3. Index 열 값 변형
    - Index 열엔 함수로 가공되지 않도록 구현
        - SELECT OrderID, OrderDate, CustomerID
        - FROM dbo.Orders
        - WHERE Convert(varchar, OrderDate, 112) = '19960704'
    - 식(expression)의 데이터 형식은 열과 동일한 형식으로 작성해야함
        - 주요 문제 대상 (암시적 데이터 형 변환)
            - 문자 vs. 숫자
            - 문자 vs. 날짜
            - (var)char vs. n(var)char
4. 열 간 비교
    - 열 간 비교되지 않도록 다른 형식으로 구현 (아래와 같이 쓰지 않도록)
        - SELECT ...
        - FROM Northwind.dbo.Orders
        - WHERE OrderID = COALESCE(@OrderID, OrderID)
        - AND CustomerID = COALESCE(@CustomerID, CustomerID)

---
# JOIN
### 조인의 배경, 목적, 유형 ..
1. 조인의 배경
    - 정규화라는 모델링 과정을 거쳤기 때문
    - 중복된 데이터를 제거하여 I/O를 줄여야 함으로 정규화
    - 처리되는 데이터를 줄이고자 정규화
        - 조인을 하는 이유는 다른 테이블이 필요한 컬럼이 있는 것 때문인데
        - 이것의 성질이 SELECT 절에서 필요한 컬럼인지 WHERE 절에서
        - 필요한 컬럼인지에 따라 그 내용도 달라진다.
2. 조인의 목적
    - 분리된 열 재결합
        - 정규화로 인한 분리된 열이 "결과집합"에 필요한 경우
    - 행 복제
        - 중복 행 생성 (N * M)
    - 일치 행 검색과 결합
        - 불 일치 행 제거(INNER JOIN)
    - NULL 값 생성
        - 차집합 포함(OUTER JOIN)
3. 조인 연산
    - LEFT OUTER JOIN
    - INNER JOIN
    - RIGHT OUTER JOIN
      ![join](https://github.com/keunoh/SQL/assets/96904103/381c0caf-25d0-476e-a070-900172b80890)
4. CROSS JOIN
    - 결과 집합
    - Cartesian Product
      (N * M, 양쪽 입력 전체 행의 곱)  
      행 단위로 집합을 복제
      ex) t1 : 3건, t2 : 10건 -> 총 30건
    - 조인 조건
    - (명시적으로) 없음
    - (물리적으로) 양쪽 입력의 행 * 행
    - 사용 예
      - 비 관계 열 기준 복제
         - ex) 제품 총 편균가 대비 각 제품 단가 별 편차
      - 전체 행 복제(행을 원하는 수 만큼 복제)
         - ex) 소계(Subtotal) 출력
5. INNER JOIN
    - 결과 집합
    - 교집합 (중복허용)
    - 행복제, 열결합
        - (1:M, N:M)
    - 조인 조건
    - 복제할 행에 대한 식별조건
    - Equi(=) or Non-Equal(<, >, IN, LIKE, etc.)
6. OUTER JOIN
    - 결과 집합
    - 차집합 + 교집합
        - 교집합은 INNER JOIN
        - 차집합은 NULL값 열로 결합
    - 조인조건
    - 교집합에 대한 조건
        - (주의) 검색 조건과 구별
    - 참고
    - Q) 조인 순서에 영향?
        - 불필요한(잘못된) OUTER JOIN 사용 비 권장
    - 예제
      - 교집합 + 차집합
      - NULL 값 생성 이해
      - FULL OUTER JOIN 이해
7. Self 조인과 Non-equal(equi)조인
    - 일반 조인은
    - 부모-자식 관계
    - Equi(=) 조건으로 결합
    - 예외
    - 자기 자신과 조인
    - Equi가 아닌 조건 필요

---
# Subquery
### 서브쿼리
- 유형
    - 중첩(Nested Scalar) - 단독 실행 가능한 형태
    - 상관(Correlated) - 외부 테이블 열 참조
- 내부 처리
    - 조인으로 변환(Unnest, Flattened) 후 실행
        - 따라서 서브쿼리를 조인으로 대체하거나 그 반대도 가능
        - 변환된 결과에 따라 조인과 차이 발생
- 적용 예
    - 한 쪽 테이블의 열만 결과 집합으로 요구 (일명 Semi Join)
    - 전체 중 일부 데이터만 확인/검색이 필요한 경우 (데이터의 존재 여부)
    - 결과 집합 중 일부 데이터만 처리하는 경우 (TOP/OFFSET)
    - 조인(그 외 연산) 전 데이터를 사전 처리할 경우
        - 조인 기능 자체 한계 해결 - 파생테이블, CTE, APPLY

### 언제 Subquery를 사용할 것인가?
1. Semi Join
    - 한 쪽 테이블만 SELECT 결과 집합으로 요구
    - 다른 쪽 테이블은 데이터를 체크하는 선택(selection) 연산만 수행
        - Subquery로 작성해서 최적화 작업
2. TOP절 등을 이용 결과 집합이 일부로 제한되는 경우
3. 데이터 가공(선 처리) 후 Join이나 기타 연산 수행 시
4. Subquery 고유 문법이나 기능이 필요한 경우
    - 파생테이블, CTE, APPLY 활용

### 중첩 (Scalar) 서브쿼리
- 주요 구문
    - SELECT 절
        - 비교 연산자 (=, <, >, etc.)
        - {ANY | SOME}, ALL
        - TOP, OFFSET 또는 FOR XML을 함께 지정하지 않으면 뷰, 인라인 함수, 파생 테이블, 하위 쿼리 및 공통 테이블 식에서 ORDER BY 절을 사용할 수 없다.
    - IN ()
        - 비교연산자(=) + 논리연산자(OR) 결합
        - 암시적 Distinct 내포
        - Null 값 고려
    - NOT IN ()
        - 비교연산자(<>) + 논리연산자(AND) 결합
        - 주의사항
            - Null 값 포함 시 정합성 문제 주의
            - NOT IN (NULL) 값 참조되지 않도록 주의
    - 내부 쿼리에 없는 외부 테이블 열 참조시
        - 특히 Insert/Update/Delete와 결합되는 경우 주의
        - 따라서 쿼리 작성 시 "테이블 별칭.열이름" 방식 권장

### 상관(Correlated) 서브쿼리
- 주요 구문
    - SELECT 절
    - WHERE 조건
        - 비교 연산자
        - IN, NOT IN
        - EXISTS, NOT EXISTS
    - HAVING <검색_조건>
    - APPLY 연산자

### CTE(Common Table Expression)(공통 테이블 식)
- 기능
    - 테이블 식(파생테이블 + 뷰 장점)
    - 재귀(Recursive) CTE
        - 순환 관계 모델
        - 일반 재귀 호출
      
### Flattened (Unnest subqueries)
- Join으로 변환 후, Join으로서 처리
    - 직접 Join 사용 경우와 차이 발생 가능(조인 순서, 연산 방법 등의 차이 발생)
- 기본은 Join 사용

### 성능 좋은 고급 쿼리 적용 예
1. 중복 I/O 제거 - "같은 데이터는 2번 이상 중복해서 읽지 않는다"
   - A. JOIN으로 변경
   - B. 기준 결과 집합 선 처리 후 결합
   - C. 행 복제
2. 연산 순서 조정 -  더 나은 순서로 연산 처리
   - Ex. 결합(Join, Subquery) 전 Group 먼저
       - (거래 데이터 x 코드 테이블) -> 집계 vs (거래 데이터 -> 집계) x 코드 테이블

3. Subquery에서 CASE WHEN 사용할 때 CASE 절에 SELECT를 사용한다면, WHEN 갯수만큼 반복액세스하기 때문에 사용하지 말기를 권장
   - Ex.
     --------------------- 잘못 사용된 예
     SELECT   
     OrderID,   
     CASE (SELECT Country FROM dbo.Customers cu WHERE cu.CustomerID = oh.CustomerID)   
     WHEN 'Germany' THEN 'Germany'    
     WHEN 'Mexico' THEN 'Mexico'  
     WHEN 'UK' THEN 'UK'  
     ELSE 'N/A'    
     END  
     FROM dbo.Orders AS oh  
     WHERE OrderID <= 10250

   - Ex.
   ----------------------> 아래와 같이 수정
   /*
   권장 - Subquery 내 CASE
   */
   SELECT   
   OrderID,   
   (SELECT CASE Country  
   WHEN 'Germany' THEN 'Germany'    
   WHEN 'Mexico' THEN 'Mexico'  
   WHEN 'UK' THEN 'UK'  
   ELSE 'N/A'    
   END  
   FROM dbo.Customers cu  
   WHERE cu.CustomerID = oh.CustomerID) AS Country  
   FROM dbo.Orders AS oh  
   WHERE OrderID <= 10250;  

---
# 더 좋은 쿼리 작성
1. IN 조건 vs. BETWEEN
    - 의미와 용도에 맞게 선택
    - IN
        - Equal(=) 조건과 OR 연산(합집합) 결합
        - Random Access(IO) 동작
        - 검색 대상 값이 많을수록 인덱스 사용기회 감소
        - 비 연속 값 검색
        - 검색 대상이 적은 경우 적합
    - BETWEEN
        - Non-Equal(>= <=) 조건과 AND 연산 결합
        - Sequence Access 동작
        - 연속 값 검색 시 적합

2. NULL 고려한 집계 연산
    - 대량 NULL 값을 가진 열의 경우
        - 불필요한 NULL 데이터를 사전 필터링 한다.
            - SELECT SUM(TRX_AMT) FROM dbo.MonyTrx
            - WHERE TRX_AMT IS NOT NULL

3. OLTP 쿼리의 기본 - Nested Loops Join 성능 이해
    - 외부입력 : 검색 행 수가 더 적은 테이블
    - 내부입력 : 반드시 Index 사용(없으면 생성) (SARG 준수)
    - ON 절에서도 인덱스를 가공하지 말 것
    - 불필요한 OUTER JOIN을 사용하지 말 것 (INNER JOIN으로 해결하는 방법 먼저 생각)
    - 유지보수를 위한 권장 [WHERE 절 조건식 순서]
        - 같은 테이블 별칭끼리 묶어서
        - 검색 주인공은 선두에
            - WHERE t1.col1 = ?
            - AND t1.col2 = ?
            - AND t2.col1 = ?
            - AND t2.col2 = ?
            - AND t3.col1
4. Subquery 이해
    - Join으로 변환 후, Join으로써 처리
5. 성능 좋은 고급 쿼리 적용 예
    - 중복 I/O 제거 = "같은 데이터는 2번 이상 주복해서 읽지 않는다"
        - A. JOIN으로 변경
        - B. 기준 결과 집합 선 처리 후 결합
        - C. 행 복제
    - 연산 순서 조정 - 더 나은 순서로 연산처리
        - Ex. 결합(Join, Subquery) 전 Group 먼저
6. Group by
    - 예를 들어 두개의 컬럼을 가지고 Group by한다면 중복이 제거된다.
   
---
# CASE 문

1. 특징
    - 고급 T-SQL의 핵심 기능 중 하나
        - 파생테이블, CTE, APPLY, etc.
    - 행 단위 조건 처리
        - 새로운 열 생성(ex. Pivoting, Row-to-Col)
    - 참고 및 주의사항
        - 서로 다른 데이터 형을 반환하는 경우
            - 명시적으로 변환 권장
        - ELSE 절이 없는 경우 NULL 반환
            - SUM() 같은 집계 작업에 활용
    - CASE 문 평가 전에 내부 식이 먼저 계산 되는 경우
        - Ex. 집계 식이 포함된 경우 (BOL참조)
        - 해당 식이 오류가 발생할 수 있다면 해결 코드 추가
2. 난수생성
    - 0 ~ 1 사이에 난수 생성가능

---
# DML
- 테이블 값 생성자 VALUES()
- SELECT INTO
- INSERT EXEC
- UPDATE SET 절 고급 활용
- DML + OUTPUT 절
- Composable DML
- MERGE
- 사용자 채번 코드
- SEQUENCE 개체

1. 테이블 값 생성자 - VALUES
   - 기능
       - 행 집합 선언 후 테이블 입력으로 사용
   - 구현
       - FROM () 파생 테이블
       - INSERT ... VALUES
       - MERGE 문의 USING
   - 예제
     - 가상 테이블 데이터 구성 - Live 데모
     - INSERT용 다중 레코드 값 정의
     - 행 복제를 위한 조인용 Copy 테이블
2. INSERT/UPDATE/DELETE + TOP
    - 기능
        - DML 작업에 데이터 개수 제한
        - 비율이나 수식(쿼리)으로 지정 가능
    - 구현 / 예제
        - TOP (expression) [ PERCENT ] 
        - DML + TOP(n)
        - DML + TOP(n) PERCENT
        - DML + 파생테이블(or CTE)
        - DML + TOP(expression) - 중복 행 삭제(1개 행만 보존)
    - 주의
        - 단순 TOP은 대상이 불명확 - ORDER BY 절 없음
3. UPDATE...SET 절 고급 활용
   - 기능
       - 열 값을 변수에 저장
       - 후행 SELECT 쿼리 불필요
   - 사례
       - 채번 로직에서 기존 UPDATE + SELECT 코드 개선
   - 예제
       - UPDATE 
         - SET  
           - @variable = expression
           - @variable = column = expression
       - 기본 활용 예
       - 열 값 상호교환(Swapping)
           - 기본 공식 vs. 단순 방법
       - 기존 열에 일련번호 달기
4. INSERT/UPDATE/DELETE/MERGE + OUTPUT 절 (SQL SERVER)
   - 기능
       - 변경 (전/후) 행 데이터 반환
   - 구현
     - OUTPUT <dml_select_list>
     - OUTPUT <dml_select_list> INTO {@table_variable | output_table } [(column_list)]
     - <dml_select_list :: =
     - { DELETED | INSERTED | from_table_name }.{* | column_name } | $action
   - 용도
       - 단순 결과 데이터 반환
       - 테이블 입력 후 재활용
           - 테이블 혹은 테이블 변수에 입력 - 삭제 데이터 보관(archive)
           - 파생 테이블 기능과 연동해서 또 다른 쿼리와 결합
               - 일명 `Composable DML(or DML table source)`
5. SELECT...INTO
   - 기능
       - CREATE TABLE + SELECT + INSERT
       - 쿼리 결과집합으로 신규 테이블 생성 (Copy)
           - #, ## 시작하는 임시 테이블 생성 가능
           - 열 이름, 데이터 형식, NULL 여부, IDENTITY 상속
           - 제약조건, 인덱스, 트리거 등은 비 상속-추가 코드 필요
           - Bulk logged 작업으로 동작 (성능 향상)
   - 예제
       - Copy 테이블 구조 확인
       - 임시 테이블로 생성
       - 빈 테이블로 복사 (테이블 구조 복사)
6. INSERT + EXEC
   - 기능
       - EXEC 문과 INSERT 결합
           - 입력 테이블은 존재하는 상태로
       - 저장 프로시저 혹은 동적 쿼리 결과를 입력
   - 구현
     - INSERT table_name
     - {
       - EXEC procedure_name
       - | EXEC ('query_string')
     - }
   - 예제
       - 저장 프로시저 실행 결과 저장

---
# Sequence
1. 특징
    - 독립 개체로 생성
        - 순번의 중앙 저장소 - DB 단위
        - 디폴트 타입은 bigint
    - Caching 사용자 정의
    - 단점
        - 관리 이슈 발생
        - IDENTITIY와 동일 활용 시 테이블 단위 개체 필요
    - 적용 시나리오
        - 여러 테이블에 공유되는 고유 순번
        - 지정 번호 도달 시 다시 시작 필요한 경우(Cycling)
        - 순번의 조정/변경이 자유로워야 하는 경우
        - 시퀀스 값을 다른 열을 기준으로 정렬해야하는 경우
            - NEXT VALUE FOR OVER()절 사용 가능 (Window Function)

---
# 집계(Aggregate)함수 특성 이해를 위한 예제
1. COUNT(expression) vs. 다른 집계 함수
2. COUNT(*) vs. COUNT(column) & 다른 집계 함수
3. COUNT(*) vs. COUNT(1) vs. COUNT(NOT NULL)
4. AVG() vs. SUM() / COUNT(*)
5. ([ ALL | DISTINCT ] expression)
   - 디폴트는 ALL
   - DISTINCT는 개별 고유 값을 정의하고 집계 연산
6. 산술 Overflow 오류와 COUNT_BIG()


### OVER() 이해 - Window(Partition), Order, Frame 정의
FUNCTION()   
OVER   
(   
[ <[window partition clause]> ]   
[ <[window order clause]> ]   
[ <[window frame clause]> ]   
)
1. PARTITION BY - Windows 범위 (기본은 전체 행), 파티션 마다 reset 된다고 생각!
2. ORDER BY - 연산 & (이동/누적) 대상 열
3. (이동/누적) 범위 (기본은 Range)

### 분석(Analytic) 함수
- 분류
    - 위치(Offset) 함수
        - LAG : 현재 행에서 offset 이전 행 값
        - LEAD : 현재 행에서 offset 다음 행 값
        - FISRT_VALUE : Window Frame의 첫 번째 행 값
        - LAST_VALUE : Window Frame의 마지막 행 값
    - 분포(Distribution) 함수
        - PERCENT_RANK : 모집단 내 순위를 나타내는 백분율(%) (=백분위, 실제론 밀도 0 ~ 1.0 값)
        - PERCENTILE_DISC : 백분위수보다 작거나 같은 값 중 가장 큰 값 반환 (*NULL 값은 제외)
        - PERCENTILE_COUNT : 지정한 백분위에 해당하는 백분위수 계산 (실제 값과 같지 않을 수 있음)
        - CUME_DIST : 누적분포-누적순위에 대한 백분율(밀도값) (모집단내 하위 몇 %인지 0 ~ 1.0 값)
