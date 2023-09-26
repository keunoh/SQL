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
  - 1) PARTITION BY - Windows 범위 (기본은 전체 행), 파티션 마다 reset 된다고 생각!
  - 2) ORDER BY - 연산 & (이동/누적) 대상 열
  - 3) (이동/누적) 범위 (기본은 Range) 

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
