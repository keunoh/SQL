# 집계(Aggregate)함수 특성 이해를 위한 예제
1. COUNT(expression) vs. 다른 집계 함수
2. COUNT(*) vs. COUNT(column) & 다른 집계 함수
3. COUNT(*) vs. COUNT(1) vs. COUNT(NOT NULL)
4. AVG() vs. SUM() / COUNT(*)
5. ([ ALL | DISTINCT ] expression)
  - 디폴트는 ALL
  - DISTINCT는 개별 고유 값을 정의하고 집계 연산
6. 산술 Overflow 오류와 COUNT_BIG() 
