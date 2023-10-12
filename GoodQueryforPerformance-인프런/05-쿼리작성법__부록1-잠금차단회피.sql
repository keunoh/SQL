/*
*******************************************************************************
SW 개발자를 위한 성능 좋은 쿼리 작성법

작성자: 김정선 (jskim@sqlroad.com)
        (주)씨퀄로 대표컨설턴트/이사
        Microsoft Data Platform MVP


여기에 사용된 코드와 정보들은 단지 데모를 위해서 제공되는 것이며 
그 외 어떤 보증이나 책임도 없습니다. 테스트나 개발을 포함해 어떤 용도로
코드를 사용할 경우 주의를 요합니다.

*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
부록-SELECT 쿼리 잠금 차단 회피
-------------------------------------------------------------------------------
*/
/*
세션 #1 - 잠금 발생
*/
USE master;

BEGIN TRAN
   SELECT @@TRANCOUNT;

	UPDATE EPlan.dbo.[Order Details]
	SET Quantity = Quantity + 1   -- 50 --> 51로
	WHERE OrderID = 10742
	  AND ProductID = 60
   -- 여기까지 실행 후 다른 세션에서 SELECT

ROLLBACK
SELECT @@TRANCOUNT;


/*
세션 #2 - SELECT로 데이터 조회
*/
USE master;
GO

/*
-------------------------------------------------------------------------------
SQL Server 기본 동작 - 읽기에서 잠금 대기(차단) 발생
-------------------------------------------------------------------------------
*/
-- 행 단위 잠금 & 잠금 차단
SELECT Quantity, OrderID, ProductID
FROM EPlan.dbo.[Order Details]
WHERE OrderID = 10742	
	AND ProductID = 60

   -- 다른 행 검색은 무관
   SELECT Quantity, OrderID, ProductID 
   FROM EPlan.dbo.[Order Details]
   WHERE OrderID = 10742	
	   AND ProductID = 72
  

/*
-------------------------------------------------------------------------------
회피 #1 - Dirty Read (Quantity가 현재 수정 중인 값 51을 읽음)
-------------------------------------------------------------------------------
*/
-- 방법-1) 테이블 단위 NOLOCK(or READUNCOMMITTED) 힌트
SELECT Quantity, OrderID, ProductID 
FROM EPlan.dbo.[Order Details] WITH (NOLOCK)
WHERE OrderID = 10742	
	AND ProductID = 60


-- 방법-2) 세션(or 프로시저) 단위 격리수준 조정
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT Quantity, OrderID, ProductID
FROM EPlan.dbo.[Order Details]
WHERE OrderID = 10742	
	AND ProductID = 60

   -- 격리수준 원본
   SET TRANSACTION ISOLATION LEVEL READ COMMITTED


/*
정리
*/
USE master;

/*
-------------------------------------------------------------------------------
회피 #2 - READ_COMMITTED_SNAPSHOT DB 옵션 (aka. MVCC, 수정 전 데이터 읽기)
-------------------------------------------------------------------------------
*/
/* 
주의) 기본적으로 DB 사용 중이면 차단되므로 트랜잭션 종료+DB사용 변경
*/
USE master;

/*
주의) 아래 코드는 테스트용으로 만 사용 (WITH ROLLBACK IMMEDIATE)
*/
ALTER DATABASE EPlan
	SET READ_COMMITTED_SNAPSHOT ON   -- OFF, ON
   WITH ROLLBACK IMMEDIATE; 

-- 옵션 상태 확인
SELECT is_read_committed_snapshot_on, snapshot_isolation_state_desc, * 
FROM sys.databases
WHERE name = 'EPlan';

/*
이전 데모에서 NOLOCK 없이 테스트
*/


/*
원본
*/
IF @@TRANCOUNT > 0 ROLLBACK;
GO

USE master;
GO
ALTER DATABASE EPlan
	SET READ_COMMITTED_SNAPSHOT OFF
   WITH ROLLBACK IMMEDIATE; 

/*
완료
*/