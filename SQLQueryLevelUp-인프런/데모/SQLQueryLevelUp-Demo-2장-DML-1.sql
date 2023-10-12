/*
*********************************************************************
SQL Query Level Up - DML-1

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
테이블 값 생성자
*******************************************************************************
*/


/*
-------------------------------------------------------------------------------
가상 테이블 데이터 구성
*/
/*
2005까지 전통적인 방법
*/
SELECT *
FROM (
	SELECT 1
	UNION ALL SELECT 2
	UNION ALL SELECT 3
) AS d(code);


/*
2008 이후엔
*/
SELECT *
FROM 




/*
-------------------------------------------------------------------------------
INSERT용 다중 레코드 값 정의
*/
DECLARE @Products TABLE 
(
	ProductName	varchar(80)
,	UnitPrice	money
);

INSERT INTO @Products
VALUES ('왕눈이', \1000),
       ('꽃돼지', \2000),
       ((SELECT ProductName FROM dbo.Products WHERE ProductID = 3),
				(SELECT UnitPrice FROM dbo.Products WHERE ProductID = 3));

SELECT * FROM @Products;




/*
-------------------------------------------------------------------------------
행 복제를 위한 조인용 Copy 테이블
*/
	-- 복제 전 데이터
	SELECT 
		p.ProductName
	FROM 
		dbo.Products AS p
	WHERE 
		p.ProductID IN (1, 2)
	;

	SELECT * FROM (VALUES (1), (2)) AS c(copyNo)
	;

SELECT 
	p.ProductName
,	c.copyNo
FROM 
	dbo.Products AS p
CROSS JOIN 
	(VALUES (1), (2)) AS c(copyNo) 
WHERE 
	p.ProductID <= 2

ORDER BY c.copyNo ASC
;




/*
-------------------------------------------------------------------------------
MERGE 문의 Using
*/
USE AdventureWorks;
GO

BEGIN TRAN

	DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));

	MERGE INTO Sales.SalesReason AS Target
	USING (VALUES ('Recommendation','Other')
					, ('Review', 'Marketing')
					, ('Internet', 'Promotion')
			) AS Source (NewName, NewReasonType)
		ON Target.Name = Source.NewName
	WHEN MATCHED THEN
		UPDATE SET ReasonType = Source.NewReasonType
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (Name, ReasonType) VALUES (NewName, NewReasonType)
	OUTPUT $action INTO @SummaryOfChanges;

	-- 결과 확인
	SELECT *	FROM @SummaryOfChanges

IF @@TRANCOUNT > 0 ROLLBACK;
SELECT @@TRANCOUNT;



/*
*******************************************************************************
INSERT, UPDATE, DELETE + TOP()
*******************************************************************************
*/
USE Northwind;
GO

/*
-------------------------------------------------------------------------------
기초 데이터 - 필요 시 생성해서 사용
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


/*
-------------------------------------------------------------------------------
DELETE 기준으로 예제 다룸
*/
/*
1) 단순 TOP - 삭제 기준 정의는 없음
*/
DELETE TOP(3) FROM dbo.DupData
-- 결과 확인용 OUTPUT 절
OUTPUT deleted.*;


/*
2) TOP PERCENT - 삭제 기준 정의는 없음
*/
DELETE TOP(30) PERCENT FROM dbo.DupData
OUTPUT deleted.*;


-- 확인
SELECT * FROM dbo.DupData;


/*
3) 파생테이블를 이용한 TOP 
*/
DELETE OrdersRN
OUTPUT deleted.*
FROM 
(
  SELECT TOP(3) *
  FROM dbo.DupData
  ORDER BY CustID DESC, Qty ASC
) AS OrdersRN
;
SELECT @@ROWCOUNT;


	/*
	CTE를 이용한 경우
	*/
	WITH OrdersRN AS
	(
	  SELECT TOP(3) *
	  FROM dbo.DupData
	  ORDER BY CustID DESC, Qty ASC
	)
	DELETE 
	FROM OrdersRN
	OUTPUT deleted.*;

	SELECT @@ROWCOUNT;



/*
4) (데이터 다시 만들고) ROW_NUMBER()를 이용한 TOP 
*/
WITH OrdersRN AS
(
	SELECT *,
		RowNum = ROW_NUMBER() OVER(ORDER BY CustID DESC, Qty DESC)
	FROM dbo.DupData
)
DELETE FROM OrdersRN
OUTPUT deleted.*
WHERE RowNum <= 3;



/*
TOP(Expression) 이용 예제
*/
-- CustID = 2, Qty = 20인 중복 행 중 1건만 남기고 삭제
DELETE TOP (SELECT COUNT(*)-1 FROM dbo.DupData WHERE CustID = 2 AND Qty = 20)
FROM dbo.DupData
WHERE CustID = 2 AND Qty = 20;

-- 확인
SELECT * FROM dbo.DupData;




/*
*******************************************************************************
UPDATE
	SET 
		@variable = expression
    | @variable = column = expression

*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
기본 활용법 - 변경된 값을 변수에 저장
*/
DECLARE @PID int = 3;
BEGIN TRAN

	SELECT ProductID, UnitPrice FROM dbo.Products WHERE ProductID = @PID;

	DECLARE @bPrice money, @aPrice money;

	UPDATE dbo.Products
		SET @bPrice = UnitPrice
			, @aPrice = UnitPrice = UnitPrice * 2
	WHERE ProductID = @PID; 

	SELECT @bPrice AS bPrice, @aPrice AS aPrice;
	SELECT ProductID, UnitPrice FROM dbo.Products WHERE ProductID = @PID;

IF @@trancount > 0 ROLLBACK;
GO


/*
-------------------------------------------------------------------------------
열 값 상호교환-1. 기본적인 공식
*/
DECLARE @PID int = 5;
BEGIN TRAN

	SELECT UnitsInStock, UnitsOnOrder FROM dbo.Products WHERE ProductID <= @PID;

	DECLARE @before smallint;

	UPDATE dbo.Products
		SET @before = UnitsInStock
			, UnitsInStock = UnitsOnOrder
			, UnitsOnOrder = @before
	WHERE ProductID <= @PID; 

	SELECT UnitsInStock, UnitsOnOrder FROM dbo.Products WHERE ProductID <= @PID;

IF @@trancount > 0 ROLLBACK;
GO



/*
-------------------------------------------------------------------------------
열 값 상호교환-2. 보다 단순한 방법
*/
DECLARE @PID int = 5;
BEGIN TRAN

	SELECT UnitsInStock, UnitsOnOrder FROM dbo.Products WHERE ProductID <= @PID;

	UPDATE dbo.Products
		SET  UnitsInStock = UnitsOnOrder
			, UnitsOnOrder = UnitsInStock

	WHERE ProductID <= @PID; 

	SELECT UnitsInStock, UnitsOnOrder FROM dbo.Products WHERE ProductID <= @PID;

IF @@trancount > 0 ROLLBACK;
GO



/*
*******************************************************************************
OUTPUT 절
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
1) 단순 예제
*/
BEGIN TRAN

	SELECT MAX(OrderID) FROM dbo.Orders;

	INSERT Orders (CustomerID)
	OUTPUT inserted.*
	VALUES ('QUICK');

IF @@trancount > 0 ROLLBACK;
GO


/*
-------------------------------------------------------------------------------
2) 다양한 형식
*/
BEGIN TRAN

	DECLARE @order table (OrderID int, OrderDate datetime);

	SELECT MAX(OrderID) FROM dbo.Orders;

	INSERT dbo.Orders (OrderDate)
	OUTPUT inserted.OrderID, inserted.CustomerID INTO @order
	VALUES (GETDATE());

	SELECT * FROM @order;

	UPDATE dbo.Orders
		SET OrderDate += 7
	OUTPUT 'deleted', deleted.*, 'inserted', inserted.*
	WHERE OrderID = (SELECT OrderID FROM @order);

	DELETE dbo.Orders
	OUTPUT 'deleted', deleted.*
	WHERE OrderID = (SELECT OrderID FROM @order);

	SELECT * FROM dbo.Orders 
	WHERE OrderID = (SELECT OrderID FROM @order);

IF @@trancount > 0 ROLLBACK;
GO



/*
-------------------------------------------------------------------------------
3) Composable DML - (OUTPUT 결과를 테이블 입력으로 사용) 
*/
IF OBJECT_ID('dbo.ProductsLog', 'U') IS NOT NULL
  DROP TABLE dbo.ProductsLog
GO

CREATE TABLE dbo.ProductsLog
(
	Seq			int NOT NULL identity(1,1) PRIMARY KEY
,  LogDate		datetime NOT NULL DEFAULT(GETDATE())
,  ProductID	INT NOT NULL
,  OldValue		money NOT NULL
,	NewValue		money NOT NULL
);
GO

/* 데이터 확인, 총 12건 */
SELECT * 
FROM dbo.Products
WHERE CategoryID = 2;


/* 변경 작업 수행 */
BEGIN TRAN

	/* 
	CategoryID = 2 제품 단가를 20% 올린 뒤, 이전 단가 10$ 이상 --> 30$이하 목록 
	*/
	INSERT INTO dbo.ProductsLog(ProductID, OldValue, NewValue)
	SELECT ProductID, OldValue, NewValue
	FROM (
		UPDATE dbo.Products
			SET UnitPrice *= 1.2
		OUTPUT 
			inserted.ProductID,
			deleted.UnitPrice AS OldValue,
			inserted.UnitPrice AS NewValue
		WHERE CategoryID = 2
	) AS D
	WHERE OldValue > 10.0 AND NewValue <= 30.0;

	SELECT * FROM dbo.ProductsLog;
  
IF @@trancount > 0 ROLLBACK;
GO




/*
*******************************************************************************
SELECT INTO
*******************************************************************************
*/
/*
데이터 확인
*/
SELECT 
	OrderID, CustomerID, Freight
FROM 
	dbo.Orders
WHERE 
	OrderID <= 10250;


/*
-------------------------------------------------------------------------------
IDENTITY, Constraints, Datatype/Nullable 등 확인
*/
SELECT 
	OrderID, CustomerID, Freight, OrderDate = CAST(GETDATE() AS date)
INTO 
	dbo.Orders2
FROM 
	dbo.Orders
WHERE 
	OrderID <= 10250;


EXEC sys.sp_help N'dbo.Orders';
EXEC sys.sp_help N'dbo.Orders2';


/*
*/
DROP TABLE dbo.Orders2;


/*
-------------------------------------------------------------------------------
임시 테이블 생성
*/
SELECT 
	OrderID, CustomerID, Freight, OrderDate = CAST(GETDATE() AS date)
INTO 
	#Orders
FROM 
	dbo.Orders
WHERE 
	OrderID <= 10250;

SELECT * FROM #Orders;


/*
-------------------------------------------------------------------------------
빈 테이블 만들기
*/
SELECT TOP(0) 
	OrderID, CustomerID, Freight, OrderDate = CAST(GETDATE() AS date)
INTO 
	#Orders2
FROM 
	dbo.Orders
WHERE 
	OrderID <= 10250;

SELECT * FROM #Orders2;



DROP TABLE #Orders, #Orders2;



/*
*******************************************************************************
INSERT
	+ VALUES ()
	+ SELECT
	+ EXEC()

*******************************************************************************
*/
CREATE PROC dbo.up_OrdersInfo
	@OrderID	int = 0
AS
BEGIN
	SELECT OrderID, OrderDate FROM dbo.Orders
	WHERE OrderID = @OrderID;
END
GO

-- TOP(0) or WHERE 1 = 2
SELECT TOP(0) OrderID, OrderDate 
INTO #Orders
FROM dbo.Orders;


/*
-------------------------------------------------------------------------------
INSERT EXEC - 사용자 저장 프로시저
*/
SET IDENTITY_INSERT #Orders ON

INSERT #Orders (OrderID, OrderDate)
EXEC dbo.up_OrdersInfo @OrderID = 10250;

-- 데이터 확인.
SELECT * FROM #Orders;

SET IDENTITY_INSERT #Orders OFF



-- 정리
DROP PROC dbo.up_OrdersInfo;
DROP TABLE #Orders;



/*
*******************************************************************************
MERGE (UPSERT)
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
예제-1: 기본 형식
*/
IF OBJECT_ID('dbo.Source', 'U') IS NOT NULL
  DROP TABLE dbo.Source
GO
IF OBJECT_ID('dbo.Target', 'U') IS NOT NULL
  DROP TABLE dbo.Target
GO

CREATE TABLE dbo.[Source]
(
	ID		int	NOT NULL
,	PID	int	NOT NULL
,	Qty	int	NOT NULL
);
GO
CREATE CLUSTERED INDEX IX_Source_PID ON dbo.[Source] (PID ASC);
GO

CREATE TABLE dbo.[Target]
(
	PID	int	NOT NULL
,	Qty	int	NOT NULL
,	CONSTRAINT PK_Target PRIMARY KEY CLUSTERED (PID ASC)
);
GO

INSERT [Source]
VALUES (1, 100, 500), (2, 200, 1500), (4, 400, 750), (5, 500, 850);

INSERT [Target]
VALUES (100, 7000), (200, 15000), (300, 2500), (600, 3500);



/*
원본 데이터 - 여기서 부터 실행
*/
SELECT * FROM dbo.[Target];
SELECT * FROM dbo.[Source];

/*
단순 UPSERT - 있으면 UPDATE, 없으면 INSERT, Source에 없으면 DELETE
*/
MERGE [Target] AS t
USING [Source] AS s
	ON t.PID = s.PID
WHEN MATCHED THEN						-- 있으면
	UPDATE SET t.Qty += s.Qty
WHEN NOT MATCHED BY TARGET THEN	-- target에 없으면
	INSERT VALUES (s.PID, s.Qty)
WHEN NOT MATCHED BY SOURCE THEN	-- source에 없으면
	DELETE
OUTPUT
	$action, deleted.*, inserted.*
;
-- 행 수는 몇개로 계산될까?
SELECT @@ROWCOUNT;

-- 최종 확인
SELECT * FROM dbo.[Target];



/*
-------------------------------------------------------------------------------
예제-2) 중복 소스를 가지는 경우의 처리 고려
*/
TRUNCATE TABLE SOURCE;

INSERT [Source]
VALUES (1, 100, 500), (2, 200, 1500), (2, 200, 2500), (4, 400, 750);

SELECT * FROM dbo.[Target];
SELECT * FROM dbo.[Source];

/*
그냥 처리하면?
*/
MERGE [Target] AS t
USING [Source] AS s
	ON t.PID = s.PID
WHEN MATCHED THEN
	UPDATE SET t.Qty += s.Qty
WHEN NOT MATCHED BY TARGET THEN
	INSERT VALUES (s.PID, s.Qty)
OUTPUT
	$action, deleted.*, inserted.*
;


/*
파생테이블(or CTE)에서 GROUP BY 선 처리
*/
MERGE [Target] AS t
USING (SELECT PID, QtySum = SUM(Qty)
			FROM [Source]
			GROUP BY PID) AS s
	ON t.PID = s.PID
WHEN MATCHED THEN
	UPDATE SET t.Qty += s.QtySum 
WHEN NOT MATCHED BY TARGET THEN
	INSERT VALUES (s.PID, s.QtySum)
OUTPUT
	$action, deleted.*, inserted.*
;

SELECT * FROM dbo.[Target];


/*
-------------------------------------------------------------------------------
예제-3: Delta값 처리
*/
IF OBJECT_ID('dbo.ProductInventory', 'U') IS NOT NULL
  DROP TABLE dbo.ProductInventory
GO

CREATE TABLE dbo.ProductInventory 
(
	ProductID	int	PRIMARY KEY
,	Quantity		int
);
GO

INSERT dbo.ProductInventory 
VALUES 
		(3, 1000)
	,	(4, 2000)
	,	(5, 3000);


/*
재고가 0이 될 때까지 반복하면서 동작 확인
*/
MERGE dbo.ProductInventory AS Inv
USING (
			SELECT ProductID, SUM(Quantity) 
			FROM dbo.[Order Details] AS sod
			GROUP BY ProductID
		) AS Ord (ProductID, TotalQty)
	ON Inv.ProductID = Ord.ProductID
WHEN MATCHED AND (Inv.Quantity - Ord.TotalQty) > 0 
   THEN UPDATE SET Inv.Quantity -= Ord.TotalQty
WHEN MATCHED AND (Inv.Quantity - Ord.TotalQty) <= 0 
   THEN DELETE
OUTPUT $action, Ord.TotalQty, deleted.ProductID, deleted.Quantity AS [before], inserted.Quantity AS [after];

-- 확인용
SELECT * FROM dbo.ProductInventory;

-- 정리
DROP TABLE dbo.ProductInventory



/*
*******************************************************************************
(사용자 정의) 채번 코드와 MERGE
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
예제-4: 채번
*/
IF OBJECT_ID('dbo.Sequence', 'U') IS NOT NULL
  DROP TABLE dbo.Sequence
GO

CREATE TABLE dbo.Sequence 
(
	CompanyID	int	NOT NULL
,	ToDate		date	NOT NULL
,	Seq			int	NOT NULL
);

ALTER TABLE dbo.Sequence
	ADD CONSTRAINT PK_Sequence PRIMARY KEY CLUSTERED (CompanyID, ToDate, Seq);
GO



/*
1) 전통적인 UPSERT 코드 - Conditional Insert/Update
*/
DECLARE @CompanyID int = 1
		, @ToDay date = CONVERT(varchar(10), GETDATE(), 112);
	
IF EXISTS (SELECT * 
				FROM dbo.Sequence 
				WHERE CompanyID = @CompanyID
					AND ToDate = @ToDay)

	UPDATE dbo.Sequence 
		SET Seq +=1 
	OUTPUT inserted.*
	WHERE CompanyID = @CompanyID
		AND ToDate = @ToDay

ELSE
	INSERT dbo.Sequence VALUES (@CompanyID, @ToDay, 1)


SELECT * FROM dbo.Sequence;
GO


/*
2) 또 다른 방식의 UPSERT 코드.
*/
DECLARE @CompanyID int = 2
		, @ToDay date = CONVERT(varchar(10), GETDATE(), 112);
	
UPDATE dbo.Sequence 
	SET Seq +=1 
OUTPUT inserted.*
WHERE CompanyID = @CompanyID
	AND ToDate = @ToDay

IF @@ROWCOUNT = 0
	INSERT dbo.Sequence VALUES (@CompanyID, @ToDay, 1)


SELECT * FROM dbo.Sequence;
GO


/*
3) MERGE 사용할 경우
*/
DECLARE @CompanyID int = 3
		, @ToDay date = CONVERT(varchar(10), GETDATE(), 112);

MERGE dbo.Sequence AS tar
USING (SELECT @CompanyID, @ToDay) AS src(id, today)
	ON tar.CompanyID = @CompanyID
		AND tar.ToDate = src.today
WHEN MATCHED THEN
	UPDATE SET Seq +=1 
WHEN NOT MATCHED BY TARGET THEN
	INSERT VALUES (@CompanyID, @ToDay, 1)
OUTPUT inserted.*;

SELECT * FROM dbo.Sequence;
GO


	/*
	MERGE를 CTE와 함께 사용할 경우
	*/
	DECLARE @CompanyID int = 4
			, @Today date = CONVERT(varchar(10), GETDATE(), 112);

	WITH tar AS
	(
		SELECT *
		FROM dbo.Sequence
		WHERE CompanyID = @CompanyID
	)
	MERGE tar
	USING (SELECT @CompanyID, @Today) AS src(id, today)
		ON tar.ToDate = src.today
	WHEN MATCHED THEN
		UPDATE SET Seq +=1 
	WHEN NOT MATCHED BY TARGET THEN
		INSERT VALUES (@CompanyID, @Today, 1)
	OUTPUT inserted.*;


	SELECT * FROM dbo.Sequence;
	GO

--정리
DROP TABLE dbo.Sequence


/*
*******************************************************************************
SEQUENCE 개체
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
SEQUENCE 개체 생성
*/
USE Northwind;
GO

CREATE SEQUENCE dbo.SlipNo
AS bigint
	START WITH 1
	INCREMENT BY 1
	--MINVALUE 1		-- 김정선) 차후 Cycle 발생을 고려한다면 지정 권장
	NO MAXVALUE
	CACHE 5000;


/*
-------------------------------------------------------------------------------
단순 순번 처리 시 - 샘플 테이블 생성
*/
IF OBJECT_ID('dbo.Sales', 'U') IS NOT NULL
	DROP TABLE dbo.Sales;	
GO

CREATE TABLE dbo.Sales
(
   SlipNo bigint NOT NULL	DEFAULT (NEXT VALUE FOR dbo.SlipNo)
								PRIMARY KEY NONCLUSTERED
,	SaleDate	datetime	NOT NULL
);
GO

INSERT dbo.Sales (SaleDate) VALUES (GETDATE());
SELECT * FROM dbo.Sales;


/*
-------------------------------------------------------------------------------
Meta data 확인
*/
SELECT 
	name, type_desc, modify_date
,	current_value, start_value, increment, minimum_value
,	is_cycling, is_cached, cache_size, is_exhausted
,	*
FROM sys.sequences
WHERE name = 'SlipNo';



/*
-------------------------------------------------------------------------------
INSERT 시 채번
*/
INSERT dbo.Sales (SlipNo, SaleDate)
VALUES 
	(NEXT VALUE FOR dbo.SlipNo, GETDATE())
,	(NEXT VALUE FOR dbo.SlipNo, GETDATE())
,	(NEXT VALUE FOR dbo.SlipNo, GETDATE())

SELECT * FROM dbo.Sales;



/*
-------------------------------------------------------------------------------
사전 채번 – 할당될 값 알아내기
*/
DECLARE @SlipNo bigint = NEXT VALUE FOR dbo.SlipNo;
	/* 혹은
	DECLARE @SlipNo bigint;
	SELECT @SlipNo = NEXT VALUE FOR dbo.SlipNo;
	*/
INSERT dbo.Sales (SlipNo, SaleDate)
VALUES (@SlipNo, GETDATE())

-- 확인
SELECT TOP(5) * FROM dbo.Sales
ORDER BY SlipNo DESC;


/*
-------------------------------------------------------------------------------
할당 후 확인하기
*/
/*
1) OUTPUT 활용 - Scalar 값으로 리턴받을 수는 없을까?
*/
INSERT dbo.Sales (SlipNo, SaleDate)
OUTPUT inserted.SlipNo
VALUES (NEXT VALUE FOR dbo.SlipNo, GETDATE())
;

/*
2) sys.sequences 활용 - 전체 세션이 공유하는 값
*/
SELECT current_value	FROM sys.sequences 
WHERE object_id = OBJECT_ID('dbo.SlipNo', 'SO');



/*
-------------------------------------------------------------------------------
범위 값 추출
*/
/*
보조(혹은 관련) 테이블 활용하는 경우
*/
WITH N1(Seq) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1)
   , N2(Seq) AS (SELECT 1 FROM N1 CROSS JOIN N1 AS n)
   , N3(Seq) AS (SELECT 1 FROM N2 CROSS JOIN N2 AS n)
   , Numbers(Seq) AS (SELECT ROW_NUMBER() OVER(ORDER BY n.Seq) FROM N3 CROSS JOIN N3 AS n) -- 6561 rows
SELECT SlipNo = NEXT VALUE FOR dbo.SlipNo 
FROM Numbers
WHERE Seq BETWEEN 1 AND 100;

-- 확인
SELECT current_value	FROM sys.sequences 
WHERE object_id = OBJECT_ID('dbo.SlipNo', 'SO');


/*
-------------------------------------------------------------------------------
OVER()를 이용한 정렬 순번
	Window Function (ORDER BY만 지원, PARTITION BY는 비 지원)
*/
SELECT 
	SlipNo = NEXT VALUE FOR dbo.SlipNo OVER (ORDER BY OrderDate DESC)
,	OrderDate
FROM dbo.Orders
WHERE OrderID BETWEEN 10248 AND (10248 + 9);

-- 확인
SELECT current_value	FROM sys.sequences 
WHERE object_id = OBJECT_ID('dbo.SlipNo', 'SO');


/*
-------------------------------------------------------------------------------
트랜잭션 롤백 여부
*/
BEGIN TRAN

	-- 트랜잭션 결과에 상관없이 순번 할당	
	SELECT SlipNo = NEXT VALUE FOR dbo.SlipNo;

ROLLBACK 

-- 롤밸 후 그 다음 할당 번호 확인
SELECT NEXT VALUE FOR dbo.SlipNo;



/*
-------------------------------------------------------------------------------
Cycle 설정

주의) 만일 MIN 값을 설정하지 않으면 -값이 채번될 수 있다.
*/
SELECT is_cycling, is_exhausted, current_value, start_value, minimum_value, maximum_value, *	
FROM sys.sequences 
WHERE object_id = OBJECT_ID('dbo.SlipNo', 'SO');

-- current_value 값 참조해서 최대한 제한
ALTER SEQUENCE dbo.SlipNo
	MAXVALUE	512	-- 현재 값보다 조금 더 큰 값으로 조정 후 테스트
	--NO MAXVALUE


-- 최대값 초과 할 때 까지
SELECT NEXT VALUE FOR dbo.SlipNo;

	/*
	메시지 11728, 수준 16, 상태 1, 줄 1
	시퀀스 개체 'SlipNo'이(가) 최소값 또는 최대값에 도달했습니다. 새 값이 생성될 수 있도록 시퀀스 개체를 다시 시작하십시오.
	*/

ALTER SEQUENCE dbo.SlipNo
	CYCLE;



/*
- 값이 할당된 후 MIN 변경 시 오류가 발생할 수 있다.

주의) 현재 값이 그 범위를 벗어나게 만드는 MIN/MAXVALUE는 할당할 수 없다.
	--> 이 경우 RESTART 로 현재 값을 조정 후에 MIN/MAX는 가능하다.
*/

	/*
	메시지 11704, 수준 16, 상태 1, 줄 1
	시퀀스 개체 'dbo.SlipNo'의 현재 값 '-9223372036854775793'은(는) 시퀀스 개체의 최소값과 최대값 사이에 있는 값이어야 합니다.
	*/



/*
-------------------------------------------------------------------------------
초기값 재설정
*/
ALTER SEQUENCE dbo.SlipNo
	RESTART WITH 1;	-- 이 값에서부터 시작


-- 번호 생성
SELECT SlipNo = NEXT VALUE FOR dbo.SlipNo;


-- 확인
SELECT current_value, *	FROM sys.sequences 
WHERE object_id = OBJECT_ID('dbo.SlipNo', 'SO');



/*
정리
*/
DROP TABLE Sales;
DROP SEQUENCE dbo.SlipNo;


/*
*******************************************************************************
End
*******************************************************************************
*/

