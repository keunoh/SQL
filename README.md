# SQL

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
<h3>언제 Subquery를 사용할 것인가?</h4>

1. Semi Join
    - 한 쪽 테이블만 SELECT 결과 집합으로 요구
    - 다른 쪽 테이블은 데이터를 체크하는 선택(selection) 연산만 수행
        - Subquery로 작성해서 최적화 작업
2. TOP절 등을 이용 결과 집합이 일부로 제한되는 경우
3. 데이터 가공(선 처리) 후 Join이나 기타 연산 수행 시
4. Subquery 고유 문법이나 기능이 필요한 경우

- 파생테이블, CTE, APPLY 활용

### 성능 좋은 고급 쿼리 적용 예
1. 중복 I/O 제거 - "같은 데이터는 2번 이상 중복해서 읽지 않는다"
   A. JOIN으로 변경
   B. 기준 결과 집합 선 처리 후 결합
   C. 행 복제
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
