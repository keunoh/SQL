/*
*********************************************************************
SW 개발자를 위한 성능 좋은 쿼리 작성법

작성자: 김정선 (jskim@sqlroad.com)
        (주)씨퀄로 대표컨설턴트/이사
        Microsoft Data Platform MVP


여기에 사용된 코드와 정보들은 단지 데모를 위해서 제공되는 것이며 
그 외 어떤 보증이나 책임도 없습니다. 테스트나 개발을 포함해 어떤 용도로
코드를 사용할 경우 주의를 요합니다.

*********************************************************************
*/

/*
=====================================================================
2장. Non-SARG 튜닝
=====================================================================
*/
USE EPlanHeap;
GO

SET STATISTICS IO ON;


/*
참고. 데모를 위해 통계 업데이트

  UPDATE STATISTICS dbo.Orders;
  UPDATE STATISTICS dbo.[Order Details];
*/


/*
-------------------------------------------------------------
Non-SARG
-------------------------------------------------------------
*/

/*
불필요한 칼럼 참조
*/
-- I/O 비교
SELECT CategoryID, CategoryName FROM dbo.Categories
go

SELECT * FROM dbo.Categories
go

SELECT OrderID FROM dbo.Orders
go

SELECT OrderID, OrderDate FROM dbo.Orders
go


/*
(Index열) 불필요한 부정형 사용
*/
SELECT OrderID, OrderDate, CustomerID 
FROM dbo.Orders
WHERE OrderID <> 10250


/*
(Index열) 조건식 컬럼 연산
*/
SELECT *
FROM EPlan.dbo.[Order Details] 
WHERE OrderID + 10 = 10268
	AND ProductID = 5


   SELECT *
   FROM EPlan.dbo.[Order Details] 
   WHERE OrderID = (10268 - 10)
	   AND ProductID = 5


/*
(Index열) 조건식 컬럼 함수 적용
*/
-- 1. Substring, Left, Right
SELECT OrderID, OrderDate, CustomerID
FROM Northwind.dbo.Orders
WHERE SUBSTRING(CustomerID, 1, 3) = 'CEN'

   --정상 구현
	SELECT OrderID, OrderDate, CustomerID
	FROM Northwind.dbo.Orders
	WHERE CustomerID LIKE 'CEN%'


-- 2. Convert
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE CONVERT(varchar(8), OrderDate, 112) = '19960704'

   --정상 구현
	SELECT OrderID, OrderDate, CustomerID 
	FROM Northwind.dbo.Orders
	WHERE OrderDate >= '19960704' AND OrderDate < '19960705'


-- 3. datediff vs. dateadd
SELECT OrderID, ShippedDate, CustomerID
FROM Northwind.dbo.Orders
WHERE DateDiff(dd, ShippedDate, '19980506') <= 1

   --정상 구현
   SELECT OrderID, ShippedDate, CustomerID 
   FROM Northwind.dbo.Orders
   WHERE ShippedDate >= DATEADD(dd, -1, '19980506')


-- 4. ISNULL
SELECT *
FROM Northwind.dbo.Orders
WHERE ISNULL(OrderDate, '19970702') = '19970702'

   --정상 구현
	SELECT *
	FROM Northwind.dbo.Orders
	WHERE (OrderDate = '19970702' OR OrderDate IS NULL)
 


/*
(Index열) 암시적 형 변환
*/
----------------------------------
-- char_column vs. 정수형
----------------------------------
SELECT stor_id, stor_name
FROM Pubs.dbo.Stores
WHERE stor_id >= 6380	-- Convert([stores].[stor_id]) = Convert([@1])

	-- vs.
	SELECT stor_id, stor_name
	FROM Pubs.dbo.Stores
	WHERE stor_id >= '6380'	



/*
(Index열) 잘못된 LIKE 연산
*/
-- 정상
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE CustomerID LIKE 'CE%'

-- 1) 불필요한 LIKE
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE CustomerID LIKE 'VINET'

   SELECT OrderID, OrderDate, CustomerID 
   FROM Northwind.dbo.Orders
   WHERE CustomerID = 'VINET'

-- 2) %로 시작
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE CustomerID LIKE '%CE%'

-- 3) 숫자열
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE OrderID LIKE '1024%'

-- 4) 날짜시간 열
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE OrderDate LIKE '05% 1998%'



/*
열 간 비교
*/
DECLARE @OrderID int = 10248;
DECLARE @OrderDate datetime = '19960704';
DECLARE @CustomerID nchar(10) = NULL;

SELECT *
FROM Northwind.dbo.Orders
WHERE OrderID       = COALESCE(@OrderID,  OrderID)
     AND OrderDate  = COALESCE(@OrderDate, OrderDate)
     AND CustomerID = COALESCE(@CustomerID, CustomerID)
;

   -- vs.
   SELECT *
   FROM Northwind.dbo.Orders
   WHERE OrderID       = 10248
        AND OrderDate  = '19960704';


/*
------------------------------------------
조건절 상수화 이슈
------------------------------------------
*/
/*
1) Index열 조건에 로컬변수
*/
USE EPlanHeap
GO

-- 상수
SELECT * FROM dbo.Orders WHERE OrderID <= 10248;

-- 로컬변수
DECLARE @ID int = 10248;
-- PK + = 조건
SELECT * FROM dbo.Orders WHERE OrderID = @ID; 
-- 범위조건 or Unique 하지 않은 경우
SELECT * FROM dbo.Orders WHERE OrderID <= @ID; 


/*
2) Index열 조건에 사용자 정의 함수
*/
CREATE OR ALTER FUNCTION dbo.uf_OrderNo()
RETURNS int
AS
BEGIN
   RETURN 10248
END;
GO

SELECT * FROM dbo.Orders
WHERE OrderID <= dbo.uf_OrderNo()

-- SQLServer2019의 TSQL_SCALAR_UDF_INLINING 기능 해지 시
OPTION (USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'));



/*
참고. 테이블 변수의 최적화
*/
USE EPlanHeap;

-- 일반 테이블 
SELECT TOP(5) *
FROM dbo.Orders AS o INNER JOIN dbo.[Order Details] AS d
   ON o.OrderID = d.OrderID
WHERE d.ProductID < 2
GO


-- 테이블 변수
DECLARE @Orders table (
   OrderID int PRIMARY KEY, OrderDate datetime 
);
INSERT @Orders
SELECT OrderID, OrderDate FROM Orders

SELECT TOP(5) *
FROM [Order Details]  AS d INNER JOIN @Orders AS o 
   ON o.OrderID = d.OrderID
WHERE d.ProductID <  2

-- 쿼리힌트: SQL Server 2019 EE의 자동 튜닝 기능 해제 후 비교
OPTION(USE HINT('DISABLE_DEFERRED_COMPILATION_TV'));



/*
정리
*/
DROP FUNCTION IF EXISTS dbo.uf_OrderNo;
GO

