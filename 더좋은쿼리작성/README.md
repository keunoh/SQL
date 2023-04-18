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