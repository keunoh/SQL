# DML

1. 테이블 값 생성자 - VALUES
   - 기능
     - 행 집합 선언 후 테이블 입력으로 사용
   - 구현
     - FROM () 파생 테이블
     - INSERT ... VALUES
     - MERGE 문의 USING


2. INSERT/UPDATE/DELETE + TOP
    - 기능
      - DML 작업에 데이터 개수 제한
      - 비율이나 수식(쿼리)으로 지정 가능
    - 구현 / 예제
      - DML + TOP(n)
      - DML + TOP(n) PERCENT
      - DML + 파생테이블(or CTE)
      - DML + TOP(expression) - 중복 행 삭제(1개 행만 보존)
    - 주의
      - 단순 TOP은 대상이 불명확 - ORDER BY 절 없음