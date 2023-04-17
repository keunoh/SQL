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