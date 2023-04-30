# 서브쿼리
1. Subquery
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


2. 중첩 (Scalar) 서브쿼리
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


3. CTE(Common Table Expression)(공통 테이블 식)
    - 기능
      - 테이블 식(파생테이블 + 뷰 장점)
      - 재귀(Recursive) CTE
        - 순환 관계 모델
        - 일반 재귀 호출
