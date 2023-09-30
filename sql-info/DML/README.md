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

3. UPDATE...SET 절 고급 활용
  - 기능
    - 열 값을 변수에 저장
    - 후행 SELECT 쿼리 불필요
  - 사례
    - 채번 로직에서 기존 UPDATE + SELECT 코드 개선
  - 예제
    - 기본 활용 예
    - 열 값 상호교환(Swapping)
      - 기본 공식 vs. 단순 방법
    - 기존 열에 일련번호 달기

4. INSERT/UPDATE/DELETE/MERGE + OUTPUT 절 (SQL SERVER)
  - 기능
    - 변경 (전/후) 행 데이터 반환
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
  - 예제
    - 저장 프로시저 실행 결과 저장





