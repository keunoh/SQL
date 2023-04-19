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
        - AND t3.col1 =?