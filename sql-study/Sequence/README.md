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

