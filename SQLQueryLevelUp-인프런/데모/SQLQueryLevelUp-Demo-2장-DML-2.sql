/*
*********************************************************************
SQL Query Level Up - DML-2

작성자: 김정선 (jskim@sqlroad.com)
        (주)씨퀄로 대표컨설턴트/이사


여기에 사용된 코드와 정보들은 단지 데모를 위해서 제공되는 것이며 
그 외 어떤 보증이나 책임도 없습니다. 테스트나 개발을 포함해 특정 용도로
아래 코드를 사용할 경우 주의를 요합니다.

*********************************************************************
*/
USE Northwind;
GO

/*
*******************************************************************************
임시 Table과 Table 변수
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
예제-1) Local Temp Table
*/
-- 1-1) 직접 생성
CREATE TABLE #MyOrders
(
	OrderID		int IDENTITY(1, 1) PRIMARY KEY
,	OrderDate	datetime
);
GO

--
CREATE INDEX #IX_MyOrders
ON #MyOrders (OrderDate);
GO


-- 1-2) SELECT INTO를 이용한 방법
SELECT * INTO #MyOrders2
FROM dbo.Orders;

SELECT * FROM #MyOrders2;


/*
-------------------------------------------------------------------------------
개체 참조
	- 다른 세션에서 동일 개체 생성 후 확인
	- 다른 세션 종료 후 확인
*/
SELECT OBJECT_ID('#MyOrders');
SELECT OBJECT_ID('tempdb..#MyOrders');
SELECT OBJECT_ID('tempdb..#MyOrders', 'U');

-- 이름, 길이, object_id 정보 확인
SELECT LenofName = DataLength(name), *
FROM tempdb.sys.objects
WHERE name LIKE '#%';

-- schema 정보 확인
EXEC tempdb.sys.sp_help N'#MyOrders';



/*
-------------------------------------------------------------------------------
개체 변경 작업
*/
ALTER TABLE #MyOrders
	ADD CustomerID nvarchar(10) NULL
GO

SELECT * FROM #MyOrders;

DROP TABLE #MyOrders;
DROP TABLE #MyOrders2;



/*
-------------------------------------------------------------------------------
예제-2) Global Temp Table
*/
CREATE TABLE ##MyOrders
(
	OrderID		int IDENTITY(1, 1) PRIMARY KEY
,	OrderDate	datetime
);
GO

-- 다른 세션에서도 확인
SELECT * FROM ##MyOrders;

-- object_id 차이 확인
SELECT LenofName = DataLength(name), *
FROM tempdb.sys.objects
WHERE name LIKE '##%';

 
/*
-------------------------------------------------------------------------------
언제 삭제되나? -- 모든 세션 종료 후 위 코드로 확인
*/



/*
*******************************************************************************
Table 변수
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
예제-3) 테이블 변수
*/
DECLARE @MyOrders TABLE 
(
	OrderID		int		IDENTITY(1, 1) PRIMARY KEY
,	OrderID2		int		UNIQUE
,	OrderDate	datetime DEFAULT (GETDATE())
,	Quantity		int		CHECK(Quantity >= 0)
);

/*
-------------------------------------------------------------------------------
IDENTITY(PK),  Insert Defaut 확인
*/
INSERT @MyOrders (OrderID2, Quantity)
SELECT TOP(10) OrderID, OrderID FROM Northwind.dbo.Orders;

SELECT * FROM @MyOrders;


/*
JOIN
*/
SELECT 
	* 
FROM 
	@MyOrders AS o 
INNER JOIN 
	Northwind.dbo.[Order Details] AS od ON o.OrderID2 = od.OrderID
WHERE 
	o.OrderID <= 10;


/*
-------------------------------------------------------------------------------
UNIQUE 확인
*/
INSERT @MyOrders (OrderID2, Quantity)
SELECT TOP(10) OrderID, OrderID FROM Northwind.dbo.Orders;


/*
-------------------------------------------------------------------------------
CHECK 확인
*/
INSERT @MyOrders (OrderID2, Quantity)
SELECT TOP(10) OrderID * 10, OrderID * -1 FROM Northwind.dbo.Orders;



/*
-------------------------------------------------------------------------------
예제-4) 고객 별 매 5th 주문마다 이전 4개 주문의 해당 총액에 대해 아래 할인 적용

	AmountPrevious < 10000.0 이면 5%
	AmountPrevious < 15000.0 이면 10%
	그 이상이면 20%
*/
USE Northwind;
GO


/*
기초 데이터 확인
*/
SELECT d.OrderID
	, Amount = SUM(d.Quantity * d.UnitPrice)
	, Seq = ROW_NUMBER() OVER(ORDER BY d.OrderID)
FROM dbo.Orders AS o
INNER JOIN dbo.[Order Details] As d
	ON o.OrderID = d.OrderID
WHERE o.CustomerID = 'QUICK'
GROUP BY d.OrderID


/*
임시 Table를 활용한 경우 
*/
SELECT d.OrderID
	, Amount = SUM(d.Quantity * d.UnitPrice)
	, Seq = ROW_NUMBER() OVER(ORDER BY d.OrderID)
INTO #CustOrders
FROM dbo.Orders AS o
INNER JOIN dbo.[Order Details] As d
	ON o.OrderID = d.OrderID
WHERE o.CustomerID = 'QUICK'
GROUP BY d.OrderID
ORDER BY d.OrderID

--CREATE INDEX #Idx ON #CustOrders (Seq);

SELECT 
	OrderID
,	Amount
,	DiscountRate = (CASE WHEN AmountPrevious < 10000.0 THEN 0.05
								WHEN AmountPrevious < 15000.0 THEN 0.1
								ELSE 0.2
								END)
,	AmountPrevious
FROM (
	SELECT 
		OrderID
	,	Amount
	,	AmountPrevious = (SELECT SUM(sc.Amount)
								FROM #CustOrders AS sc
								WHERE sc.Seq >= (c.Seq - 4)
									AND sc.Seq < c.Seq
		)
	FROM #CustOrders AS c
	WHERE c.Seq % 5 = 0
) AS c


DROP TABLE #CustOrders;


/*
Q: 임시 테이블을 사용하지 않는다면?
*/



/*
-------------------------------------------------------------------------------
예제-5) 중복 행에서 한 행만 남기고 나머지 삭제하기

		1) 임시 Table을 활용
		2) Table에 Seq 열이 있다면 바로 Join해서 삭제 가능(혹은 Seq열 추가 후 작업)
		3) 그 외에도 다양한 방법 존재
*/
DROP TABLE dbo.DupData;
GO

CREATE TABLE dbo.DupData (
	CustID	int
,	Qty	int
);
GO

INSERT dbo.DupData
VALUES 
	(1,	10),
	(1,	10),	-- dup
	(2,	20),
	(2,	20),	-- dup
	(2,	20),	-- dup
	(2,	30),
	(3,	30),
	(3,	40),
	(3,	50)
;

SELECT CustID, Qty, Dups = COUNT(*)
INTO #DupData
FROM dbo.DupData
GROUP BY CustID, Qty
HAVING COUNT(*) > 1;

DELETE d
FROM dbo.DupData AS d
INNER JOIN #DupData AS p
	ON d.CustID = p.CustID
		AND d.Qty = p.Qty;

INSERT dbo.DupData
SELECT CustID, Qty FROM #DupData;


-- 최종 데이터 확인
SELECT * FROM dbo.DupData
ORDER BY CustID ASC, Qty ASC;
GO

-- 정리
DROP TABLE dbo.#DupData;


/*
-------------------------------------------------------------------------------
UNIQUE 열이 있는 경우라면
*/
IF OBJECT_ID('dbo.DupData', 'U') IS NOT NULL 
	DROP TABLE dbo.DupData;
GO

CREATE TABLE dbo.DupData (
	CustID	int
,	Qty	int
);
GO

INSERT dbo.DupData
VALUES 
	(1,	10),
	(1,	10),	-- dup
	(2,	20),
	(2,	20),	-- dup
	(2,	20),	-- dup
	(2,	30),
	(3,	30),
	(3,	40),
	(3,	50)
;


--주의) 대용량 Table이라면 아래 작업 부하가 큼
ALTER TABLE dbo.DupData
	ADD Seq int IDENTITY(1, 1);
GO

-- Seq 확인
SELECT * FROM dbo.DupData


-- 실제 작업
DELETE d1
FROM dbo.DupData AS d1
INNER JOIN dbo.DupData AS d2
	ON d1.CustID = d2.CustID
		AND d1.Qty = d2.Qty
		AND d1.Seq > d2.Seq	-- 중복값 중 제일 작은 Seq만 남기고

-- 
SELECT * FROM dbo.DupData
ORDER BY CustID ASC, Qty ASC;
GO

ALTER TABLE dbo.DupData
	DROP COLUMN Seq;
GO



/*
*******************************************************************************
동적 SQL, EXEC[UTE] vs. sp_executesql
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
EXEC() - 순수 동적 SQL

	8000 vs MAX, QUOTENAME()
*/
DECLARE @TableName varchar(128) = 'Orders',
			@OrderID	int = 10248;

DECLARE @sql varchar(8000), @sql2 varchar(max);

SET @sql = 'SELECT OrderID, OrderDate'
			+ '	FROM ' + 'dbo' + '.' + QUOTENAME(@TableName)
			+ '	WHERE OrderID = ' + CAST(@OrderID AS varchar(10));

PRINT @sql;
EXEC (@sql);

SET @sql2 = @sql;
EXEC (@sql2);


/*
-------------------------------------------------------------------------------
문자열 매개변수 결합 
*/
DECLARE @CustID varchar(128) = 'QUICK'
DECLARE @sql varchar(8000);

SET @sql = 'SELECT OrderID, OrderDate'
			+ ' FROM dbo.Orders'
			+ ' WHERE CustomerID = ''' + @CustID + ''' ';

PRINT @sql;
EXEC (@sql);


	-- QUOTENAME() 활용, 최대 입력 128자, 출력 256 길이 제한 주의
	DECLARE @CustID varchar(128) = 'QUICK'
	DECLARE @sql varchar(8000);

	SET @sql = 'SELECT OrderID, OrderDate' 
				+ ' FROM dbo.Orders'
				+ ' WHERE CustomerID = ' + QUOTENAME(@CustID, '''');

	PRINT @sql;
	EXEC (@sql);


	-- CHAR(39) 활용
	DECLARE @CustID varchar(128) = 'QUICK'
	DECLARE @sql varchar(8000), @QM varchar(1) = CHAR(39);

	SET @sql = 'SELECT OrderID, OrderDate' 
				+ ' FROM dbo.Orders'
				+ ' WHERE CustomerID = ' + @QM + @CustID + @QM;

	PRINT @sql;
	EXEC (@sql);



/*
-------------------------------------------------------------------------------
sp_executsql - Unicode 문자열 기반(4000 or MAX)
*/
DECLARE @pCustID varchar(128) = 'VINET', @pOrderID int = 10260;
DECLARE @sql nvarchar(4000), @CR varchar(1) = CHAR(13), @QM varchar(1) = CHAR(39);

SET @sql = 'SELECT OrderID, OrderDate' + @CR
			+ ' FROM dbo.Orders' + @CR
			+ ' WHERE CustomerID = @CustomerID' + @CR
			+ '	AND OrderID <= @OrderID';

PRINT @sql;

EXEC sys.sp_executesql 
	@statment = @sql,
	@params = N'@CustomerID nvarchar(10), @OrderID int',
	@CustomerID = @pCustID, 
	@OrderID = @pOrderID
GO



/*
-------------------------------------------------------------------------------
sp_executsql - 출력 매개변수 활용
*/
DECLARE @pCustID varchar(128) = 'VINET';
DECLARE @sql nvarchar(4000), @CR varchar(1) = CHAR(13), @QM varchar(1) = CHAR(39);

SET @sql = 'SELECT @OrdersCount = COUNT(*)' + @CR
			+ ' FROM dbo.Orders' + @CR
			+ ' WHERE CustomerID = @CustomerID'

PRINT @sql;

DECLARE @pOrdersCount int;
EXEC sys.sp_executesql 
	@statment = @sql,
	@params = N'@CustomerID nvarchar(10), @OrdersCount int OUTPUT',
	@CustomerID = @pCustID, 
	@OrdersCount = @pOrdersCount OUTPUT;

SELECT @pOrdersCount;
GO


/*
-------------------------------------------------------------------------------
다중 쿼리 수행 - SET NOCOUNT ON
*/
DECLARE @pCustID varchar(128) = 'VINET';
DECLARE @sql nvarchar(4000), @CR varchar(1) = CHAR(13), @QM varchar(1) = CHAR(39);

SET @sql = 'SET NOCOUNT ON;' + @CR
			+ 'SELECT TOP(10) * FROM dbo.Customers;' + @CR
			+ 'SELECT TOP(10) * FROM dbo.Orders;'

PRINT @sql;

EXEC sys.sp_executesql 
	@statment = @sql
GO



/*
-------------------------------------------------------------------------------
현재 DB 변경
*/
DECLARE @sql nvarchar(4000), @CR varchar(1) = CHAR(13);

SET @sql = 'USE Pubs; SELECT DB_NAME();' + @CR
			+ 'SELECT TOP(10) * FROM dbo.Sales;'

PRINT @sql;

EXEC sys.sp_executesql 
	@statment = @sql
GO



/*
*******************************************************************************
UDT와 TVP
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
단일 열로 구성된 다중 값 처리 예제
*/
/*
예제-2) 동적(Dynamic) 쿼리 방식
*/
IF OBJECT_ID('dbo.up_GetOrders', 'P') IS NOT NULL
  DROP PROC dbo.up_GetOrders;
GO

CREATE PROC dbo.up_GetOrders
	@OrderIDs AS varchar(4000)
AS	
	DECLARE @sql AS varchar(MAX);

	SET @sql = N'SELECT OrderID, OrderDate, CustomerID
						FROM dbo.Orders
						WHERE OrderID IN(' + @OrderIDs + N')
						ORDER BY OrderID ASC;';

	EXEC(@sql);
GO


EXEC dbo.up_GetOrders N'10248,10250';
EXEC dbo.up_GetOrders N'10260,10270,10265,10290';
GO



/*
예제-3) 일반적인 단순 Loop Parsing 방식:
*/
IF OBJECT_ID('dbo.SplitVar', 'TF') IS NOT NULL
	DROP FUNCTION dbo.SplitVar
GO

CREATE FUNCTION dbo.SplitVar(@Data varchar(8000), @Sep varchar(2))  
RETURNS @result table (
	Code int
) 
AS  
BEGIN 
	DECLARE @cnt int
	SET @cnt = 1

	WHILE (CHARINDEX(@Sep, @Data) > 0)
	BEGIN
		INSERT INTO @result (Code)
		SELECT Code = LTRIM(RTRIM(SUBSTRING(@Data, 1, CHARINDEX(@Sep, @Data) - 1)));

		SET @Data = SUBSTRING(@Data, CHARINDEX(@Sep, @Data) + 1, LEN(@Data));
		SET @cnt = @cnt + 1;
	END
	
	INSERT INTO @result (Code)
	SELECT Data = LTRIM(RTRIM(@Data));

	RETURN
END
GO

SELECT o.OrderID, o.CustomerID, o.OrderDate
FROM dbo.SplitVar('10248', ',') AS p
INNER JOIN dbo.Orders AS o
		ON o.OrderID = p.Code
ORDER BY o.OrderID ASC;


SELECT o.OrderID, o.CustomerID, o.OrderDate
FROM dbo.SplitVar('10248, 10250, 10249', ',') AS p
INNER JOIN dbo.Orders AS o
		ON o.OrderID = p.Code
ORDER BY o.OrderID ASC;




/*
-------------------------------------------------------------------------------
예제-4) UDT + TVP 를 이용한 다중 레코드 매개변수 처리 예제
*/
/*
UDT 정의
*/
IF TYPE_ID('dbo.OrdersType') IS NOT NULL
	DROP TYPE dbo.OrdersType
GO

CREATE TYPE dbo.OrdersType 
AS TABLE 
(
	Seq				int	NOT NULL IDENTITY(1, 1)
,	OrderID			int	NOT NULL	PRIMARY KEY
);
GO


/*
UDT 매개변수 프로시저 생성
*/
IF OBJECT_ID('dbo.up_GetOrders', 'P') IS NOT NULL
	DROP PROC dbo.up_GetOrders;
GO

CREATE PROC dbo.up_GetOrders
	@Orders AS dbo.OrdersType READONLY
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT o.OrderID, o.CustomerID, o.OrderDate
	FROM @Orders AS p 
	INNER JOIN dbo.Orders AS o
		ON o.OrderID = p.OrderID
	ORDER BY o.OrderID ASC;

END
GO


/*
-------------------------------------------------------------------------------
프로시저 호출 예제
*/
DECLARE @Orders AS dbo.OrdersType;

INSERT @Orders (OrderID)
VALUES (10248), (10250), (10249)

SELECT * FROM @Orders;

-- 실제 호출
EXEC dbo.up_GetOrders @Orders;




/*
-------------------------------------------------------------------------------
STRING_SPLIT() - 2016+
*/
-- 좌우 공백에 주의
SELECT * 
FROM STRING_SPLIT('10248, 10250, 10249', ',');

SELECT o.OrderID, o.CustomerID, o.OrderDate
FROM STRING_SPLIT('10248,10250,10249', ',') AS p
	INNER JOIN dbo.Orders AS o
		ON o.OrderID = p.value
ORDER BY o.OrderID ASC;


SELECT d.id, TRIM(v.value) AS codes
FROM (VALUES
	(1, 'a, b, c, d'),
	(2, 'e, f, g')
) AS d (id, codes)
    CROSS APPLY STRING_SPLIT(codes, ',') AS v; 



/*
*******************************************************************************
End
*******************************************************************************
*/

