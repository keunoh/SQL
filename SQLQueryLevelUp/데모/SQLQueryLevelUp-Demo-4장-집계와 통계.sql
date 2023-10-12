/*
*********************************************************************
SQL Query Level Up - 집계와 통계

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
집계함수 특성 이해
*******************************************************************************
*/
-- 예제-1)
SELECT COUNT(Freight)
FROM dbo.bigOrders
WHERE Freight IS NULL;

	SELECT SUM(Freight)
	FROM dbo.bigOrders
	WHERE Freight IS NULL;


-- 예제-2)
SELECT COUNT(*)
FROM dbo.bigOrders;

	SELECT COUNT(Freight)
	FROM dbo.bigOrders;

	/*
	경고: 집계 또는 다른 SET 작업에 의해 Null 값이 제거되었습니다.
	*/


-- 예제-3)
SELECT COUNT(*)
FROM dbo.bigOrders;

	SELECT COUNT(1)
	FROM dbo.bigOrders;

	SELECT COUNT(OrderID)
	FROM dbo.bigOrders;


-- 예제-4)
SELECT AVG(Freight), SUM(Freight) / COUNT(*), SUM(Freight) / COUNT(Freight)
FROM dbo.bigOrders;


-- 예제-5)
SELECT COUNT(DISTINCT EmployeeID)
FROM dbo.bigOrders;


-- 예제-6)
SELECT SUM(OrderID * 10)
FROM dbo.bigOrders;

	SELECT SUM(CAST(OrderID * 10 AS bigint))
	FROM dbo.bigOrders;

	SELECT SUM(OrderID * 10.0)
	FROM dbo.bigOrders;


SELECT COUNT(b1.OrderID)
FROM dbo.bigOrders AS b1, dbo.bigOrders AS b2;

SELECT COUNT_BIG(b1.OrderID)
FROM dbo.bigOrders AS b1, dbo.bigOrders AS b2;



/*
*******************************************************************************
Window Functions
*******************************************************************************
*/
/*
이해하기 - 고객별, 주문일자순에 대해
*/
SELECT 
   CustomerID, OrderDate, SalesYear = YEAR(OrderDate), OrderID
FROM 
   dbo.Orders
ORDER BY 
   CustomerID, OrderDate;

/*
제품별 단가
*/
SELECT 
   ProductName, UnitPrice
FROM 
   dbo.Products;


/*
*******************************************************************************
집계함수 + OVER()
*******************************************************************************
*/
/*
1) 이전 코드 (쿼리 튜닝 고려하지 않은 상태)
*/
SELECT 
	ProductName
,	UnitPrice
,	Average = ( SELECT AVG(UnitPrice) FROM dbo.Products )
,	Diff = UnitPrice - ( SELECT AVG(UnitPrice) FROM dbo.Products )
FROM dbo.Products;


/*
2) Window 함수 활용
*/
SELECT 
	ProductName
,	UnitPrice
,	Average = AVG(UnitPrice) OVER()
,	Diff = UnitPrice - AVG(UnitPrice) OVER()
FROM dbo.Products;



/*
-------------------------------------------------------------------------------
집계 함수 – OVER() 구문 예제 - 1
*/
SELECT 
	CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	SalesYear = YEAR(OrderDate)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 


SELECT COUNT(*) FROM dbo.Orders;


-- 1)
SELECT 	
	CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	SalesYear = YEAR(OrderDate)
,	Orders = COUNT(*) OVER()
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 


-- 2)
SELECT 	
	CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	SalesYear = YEAR(OrderDate)
,	Orders = COUNT(*) OVER(PARTITION BY CustomerID)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 



-- 3)
	SELECT 	
		SalesYear = YEAR(OrderDate)
	,	Orders = COUNT(*)
	FROM dbo.Orders
	GROUP BY YEAR(OrderDate)
	ORDER BY SalesYear;


SELECT 	
	CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	SalesYear = YEAR(OrderDate)
,	Orders = COUNT(*) OVER(ORDER BY YEAR(OrderDate) ASC)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 




/*
-------------------------------------------------------------------------------
집계 함수 – OVER() 구문 예제 - 2
*/
--1)
SELECT CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	SalesYear = YEAR(OrderDate)
,	OrdersDate = COUNT(*) OVER(
								PARTITION BY CustomerID
								ORDER BY OrderDate ASC)
,	OrdersYear = COUNT(*) OVER(
								PARTITION BY CustomerID
								ORDER BY YEAR(OrderDate) ASC)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 


	SELECT CustomerID
	,	OrderDate = CAST(OrderDate AS date)
	,	SalesYear = YEAR(OrderDate)
	,	OrdersDate = COUNT(*) OVER(PARTITION BY CustomerID
											ORDER BY OrderDate ASC)
	,	OrdersYear = COUNT(*) OVER(PARTITION BY CustomerID
											ORDER BY YEAR(OrderDate) ASC
											ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
	FROM dbo.Orders
	ORDER BY CustomerID ASC, OrderDate ASC; 



/*
-------------------------------------------------------------------------------
집계 함수 – OVER() 구문 예제 - 3
*/
--1)
SELECT CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	SalesYear = YEAR(OrderDate)
,	Orders = COUNT(*) OVER(PARTITION BY CustomerID, YEAR(OrderDate))
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 


--2)
SELECT 	
	CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	SalesYear = YEAR(OrderDate)
,	Orders = COUNT(*) OVER(ORDER BY CustomerID ASC, YEAR(OrderDate) ASC)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 


--3)
SELECT 	
	CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	SalesYear = YEAR(OrderDate)
,	Orders = COUNT(*) OVER(
					PARTITION BY CustomerID
					ORDER BY OrderID ASC)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 



/*
-------------------------------------------------------------------------------
집계 함수 – OVER() 구문 예제 - 4
*/
--1)
SELECT 	
	CustomerID
,	SalesYear = YEAR(OrderDate)
,	Freight
,	FreightSum = SUM(Freight) OVER(
							PARTITION BY CustomerID
							ORDER BY OrderID ASC)
,	FreightSumYear = SUM(Freight) OVER(
							PARTITION BY CustomerID
							ORDER BY YEAR(OrderDate) ASC)
FROM dbo.Orders
ORDER BY CustomerID ASC, SalesYear ASC; 


--2)
SELECT 	
	CustomerID
,	SalesYear = YEAR(OrderDate)
,	Freight
,	FreightSum = SUM(Freight) OVER(
						PARTITION BY CustomerID
						ORDER BY OrderID ASC)
,	FreightAvg = AVG(Freight) OVER(
						PARTITION BY CustomerID
						ORDER BY OrderID ASC)
,	FreightAvgYear = AVG(Freight) OVER(
								PARTITION BY CustomerID
								ORDER BY YEAR(OrderDate) ASC)
FROM dbo.Orders
ORDER BY CustomerID ASC, SalesYear ASC; 



/*
-------------------------------------------------------------------------------
집계 함수 – OVER() 구문 예제 - 5
*/
--1)
SELECT 	
	CustomerID
,	SalesYear = YEAR(OrderDate)
,	Freight
,	FreightMinYear = MIN(Freight) OVER(PARTITION BY CustomerID, YEAR(OrderDate))
,	FreightMaxYear = MAX(Freight) OVER(PARTITION BY CustomerID, YEAR(OrderDate))
,	FreightMinCustomer = MIN(Freight) OVER(PARTITION BY CustomerID)
,	FreightMaxCustomer = MAX(Freight) OVER(PARTITION BY CustomerID)
,	FreightMinMove = MIN(Freight) OVER(PARTITION BY CustomerID
													ORDER BY YEAR(OrderDate) ASC)
,	FreightMaxMove = MAX(Freight) OVER(PARTITION BY CustomerID
													ORDER BY YEAR(OrderDate) ASC)
FROM dbo.Orders
ORDER BY CustomerID ASC, SalesYear ASC; 



/*
-------------------------------------------------------------------------------
집계함수 - Frame
*/
/*
예제-1. ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
*/
SELECT 	
	CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	Freight
,	[FreightAvg(ROWS)] = AVG(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	OrderDate ASC
								ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC;



/*
예제-2. ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
*/
SELECT 	
	CustomerID
,	OrderDate = CAST(OrderDate as date)
,	Freight
,	FreightSumDate = SUM(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	OrderDate ASC
								ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
,	FreightCountDate = COUNT(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	OrderDate ASC
								ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
,	FreightAvgDate = AVG(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	OrderDate ASC
								ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 



/*
예제-3. ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
*/
SELECT 	
	CustomerID
,	OrderDate = CAST(OrderDate as date)
,	Freight
,	FreightMinDate = MIN(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	OrderDate ASC
								ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
								)
,	FreightMaxDate = MAX(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	OrderDate ASC
								ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
								)
,	FreightMinCust = MIN(Freight) OVER(	
								PARTITION BY CustomerID
								)
,	FreightMaxCust = MAX(Freight) OVER(	
								PARTITION BY CustomerID
								)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC; 



/*
예제-4. RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
*/
SELECT 	
	CustomerID
,	OrderYear = YEAR(OrderDate)
,	Freight
,	[FreightAvg(ROWS)] = AVG(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	YEAR(OrderDate) ASC
								ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
,	[FreightSum(RANGE)] = SUM(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	YEAR(OrderDate) ASC
								RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
,	[FreightCount(RANGE)] = COUNT(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	YEAR(OrderDate) ASC
								RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
,	[FreightAvg(RANGE)] = AVG(Freight) OVER(	
								PARTITION BY CustomerID
								ORDER BY	YEAR(OrderDate) ASC
								RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderYear ASC;






/*
*******************************************************************************
분석 함수
*******************************************************************************
*/
USE Northwind;

/*
*******************************************************************************
OFFSET 함수
*******************************************************************************
*/
SELECT
	CustomerID
,	OrderDate = CAST(OrderDate AS date)
,	Freight
,	FreightLEAD = LEAD(Freight) OVER(
											PARTITION BY CustomerID	ORDER BY OrderDate ASC)
,	FreightLAG = LAG(Freight) OVER(
											PARTITION BY CustomerID ORDER BY OrderDate ASC)
,	Freight2LEAD = LEAD(Freight, 2, 0) OVER(
											PARTITION BY CustomerID ORDER BY OrderDate ASC)
,	Freight2LAG = LAG(Freight, 2, 0) OVER(
											PARTITION BY CustomerID ORDER BY OrderDate ASC)
,	FreightFIRST = FIRST_VALUE(Freight) OVER(
											PARTITION BY CustomerID ORDER BY OrderDate ASC)
,	FreightLAST = LAST_VALUE(Freight) OVER(
											PARTITION BY CustomerID	ORDER BY OrderDate ASC)
FROM dbo.Orders
ORDER BY CustomerID ASC, OrderDate ASC;



/*
*******************************************************************************
Distribution 함수
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
1~100에 대한 백분위
*/	
WITH N1(Seq) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1)
   , N2(Seq) AS (SELECT 1 FROM N1 CROSS JOIN N1 AS n)
   , N3(Seq) AS (SELECT 1 FROM N2 CROSS JOIN N2 AS n)
   , Numbers(Seq) AS (SELECT ROW_NUMBER() OVER(ORDER BY n.Seq) FROM N3 CROSS JOIN N3 AS n) -- 6561 rows

SELECT Seq
,	[백분위(PERCENT_RANK())] = PERCENT_RANK() OVER(ORDER BY Seq ASC) 
,	[누적분포율(CUME_DIST)] = CUME_DIST() OVER(ORDER BY Seq ASC)
FROM Numbers	-- 없으면 DML-1에서 생성
WHERE Seq <= 100;



/*
-------------------------------------------------------------------------------
Distribution 함수 계산 (등수)
*/	
CREATE TABLE dbo.ScoreCards
(
	Subject		varchar(10)
,	StudentID	int
,	Score			int
);

TRUNCATE TABLE dbo.ScoreCards;

INSERT dbo.ScoreCards
VALUES 
	('Math', 1, 89)
,	('Math', 2, 88)
,	('Math', 3, 94)
,	('Math', 4, 90)
,	('Math', 5, 96)
,	('Math', 6, 78)
,	('Math', 7, 76)
,	('Math', 8, 86)
,	('Math', 9, 90)
,	('Math', 10, 90)
,	('English', 1, 80)
,	('English', 2, 92)
,	('English', 3, 88)
,	('English', 4, 88)
,	('English', 5, 86)
,	('English', 6, 94)
,	('English', 7, 84)
,	('English', 8, 78)
,	('English', 9, 96)
--,	('English', 10, 80)
;

SELECT * 
FROM dbo.ScoreCards
ORDER BY Subject ASC, Score ASC;


/*
-------------------------------------------------------------------------------
분포 함수 이해
*/	
SELECT 
	Subject, StudentID, Score
,	하위순위 = RANK() OVER(PARTITION BY Subject ORDER BY Score ASC)

,	[백분위(PERCENT_RANK())] = PERCENT_RANK() OVER(
											PARTITION BY Subject ORDER BY Score ASC) 

,	[누적분포율(CUME_DIST)] = CUME_DIST() OVER(
											PARTITION BY Subject ORDER BY Score ASC)

,	[백분위수(PERCENTILE_CONT(0.5))] = PERCENTILE_CONT(0.5) 
											WITHIN GROUP (ORDER BY Score ASC) 
											OVER(PARTITION BY Subject )

,	[백분위수(PERCENTILE_DISC(0.5))] = PERCENTILE_DISC(0.5) 
											WITHIN GROUP (ORDER BY Score ASC) 
											OVER(PARTITION BY Subject )

FROM dbo.ScoreCards;



/*
-------------------------------------------------------------------------------
예제 - 분포 함수 (급여 백분위)
*/	
USE tempdb;
GO

IF OBJECT_ID('dbo.Salary', 'U') IS NOT NULL
	DROP TABLE dbo.Salary;	
GO

CREATE TABLE dbo.Salary
(
   부서		varchar(10)
,	사원		varchar(10)
,	지급일		date
,	월급		money
);
GO

INSERT dbo.Salary
VALUES
	('전산', '김일님', '20150525', 4500000)
,	('전산', '박이님', '20150525', 4200000)
,	('전산', '차삼님', '20150525', 3500000)
,	('전산', '이사님', '20150525', 5500000)
,	('전산', '최오님', '20150525', 4800000)
,	('전산', '명육님', '20150525', 4200000)
,	('전산', '공칠님', '20150525', 4500000)
,	('영업', '김일씨', '20150525', 6500000)
,	('영업', '박이씨', '20150525', 5500000)
,	('영업', '차삼씨', '20150525', 4500000)
,	('영업', '이사씨', '20150525', 3500000)
,	('영업', '최오씨', '20150525', 2500000)
,	('영업', '명육씨', '20150525', 4500000)
,	('영업', '공칠씨', '20150525', 5500000)
,	('영업', '강팔씨', '20150525', 6500000)
;
-- TRUNCATE TABLE dbo.Salary;

SELECT
	부서, 사원, 월급
FROM dbo.Salary
WHERE 지급일 = '20150525'
ORDER BY 부서 ASC, 월급 ASC;


/*
-------------------------------------------------------------------------------
급여 백분위
*/	
SELECT
	부서, 사원, 월급
,	하위순위 = RANK() OVER(
								PARTITION BY 부서 ORDER BY 월급 ASC)
,	[PERCENT_RANK()] = PERCENT_RANK() OVER(
								PARTITION BY 부서 ORDER BY 월급 ASC) 
,	[PERCENTILE_CONT(0.5)] = PERCENTILE_CONT(0.5) 
								WITHIN GROUP (ORDER BY 월급 ASC) 
								OVER(PARTITION BY 부서 )
,	[PERCENTILE_DISC(0.5)] = PERCENTILE_DISC(0.5) 
								WITHIN GROUP (ORDER BY 월급 ASC) 
								OVER(PARTITION BY 부서 )
,	[CUME_DIST] = CUME_DIST() OVER(
								PARTITION BY 부서 ORDER BY 월급 ASC)
FROM dbo.Salary
WHERE 지급일 = '20150525'
ORDER BY 부서 ASC, 월급 ASC;



/*
*******************************************************************************
예제 - 분석 함수
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
누적 집계 
*/
/*
기존 방식 - Self Join
*/
USE Northwind;
GO

SELECT 
	d1.OrderID, d1.ProductID
,	Amount = (d1.Quantity * d1.UnitPrice)
,	AmountRunning = (SELECT SUM(d2.Quantity * d2.UnitPrice)
							FROM dbo.[Order Details] AS d2
							WHERE d2.OrderID = d1.OrderID
								AND d2.ProductID <= d1.ProductID
				)
FROM dbo.[Order Details] AS d1
WHERE d1.OrderID <= 10250
ORDER BY d1.OrderID ASC, d1.ProductID ASC
;


/*
분석 함수 사용
*/
SELECT 
	d1.OrderID, d1.ProductID
,	Amount = (d1.Quantity * d1.UnitPrice)
,	AmountRunning = SUM(d1.Quantity * d1.UnitPrice) 
                     OVER (PARTITION BY OrderID
                           ORDER BY ProductID)
FROM dbo.[Order Details] AS d1
WHERE d1.OrderID <= 10250
ORDER BY d1.OrderID ASC, d1.ProductID ASC
;



/*
*******************************************************************************
집계함수 - 정합성 이슈 예문
*******************************************************************************
*/
SELECT
	CustomerID
,	SalesYear = YEAR(OrderDate)
,	OrderDate = CAST(OrderDate AS date)
,	Freight
	-- YEAR(OrderDate)의 경우 
,	FreightSumYearRows = SUM(Freight) OVER(PARTITION BY CustomerID
													ORDER BY YEAR(OrderDate) ASC, OrderId ASC  -- 유일성 고려
													ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
	-- OrderDate는 유일값
,	FreightSumDateRows = SUM(Freight) OVER(PARTITION BY CustomerID
													ORDER BY OrderDate ASC
													ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM dbo.Orders

ORDER BY CustomerID ASC, SalesYear ASC, OrderDate ASC




/*
*******************************************************************************
PIVOT & UNPIVOT
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
PIVOT 구현
*/
/*
데이터 이해
*/
SELECT 
	EmployeeID
,	OrderYear = YEAR(OrderDate)
,	Orders = COUNT(OrderDate)
FROM dbo.Orders AS o
GROUP BY EmployeeID, YEAR(OrderDate)
ORDER BY EmployeeID;


/*
------------------------------------------------------------------------------
예제-1) 사원별-년도별 주문수량 - PIVOT 으로
*/
WITH OrdersPerYear
AS
(	
	SELECT EmployeeID, OrderYear = YEAR(OrderDate) 
	FROM dbo.Orders
) 
SELECT EmployeeID, [1996], [1997], [1998]
FROM OrdersPerYear
PIVOT (	COUNT(OrderYear) 
			FOR OrderYear IN ([1996], [1997], [1998])
		) AS PV
ORDER BY EmployeeID;


	/*
	Q) 전통방식으로 GROUP BY + CASE 문을 사용한다면
	*/
	SELECT 
		EmployeeID
	,	[1996] = COUNT(CASE WHEN OrderYear = 1996 THEN 1 END)
	,	[1997] = COUNT(CASE WHEN OrderYear = 1997 THEN 1 END)
	,	[1998] = COUNT(CASE WHEN OrderYear = 1998 THEN 1 END)
	FROM dbo.Orders AS o
	CROSS APPLY (SELECT OrderYear = YEAR(OrderDate)) AS y
	GROUP BY EmployeeID
	ORDER BY EmployeeID;


/*
------------------------------------------------------------------------------
예제-2) 고객별/월별(1~12월) 매출 현황
*/
WITH OrderPerMonth
AS
(
	SELECT CustomerID, OrderMonth = MONTH(OrderDate)
	FROM dbo.Orders
)
SELECT
	CustomerID
,  [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12]
FROM OrderPerMonth
PIVOT 
(
	COUNT(OrderMonth) 
	FOR OrderMonth	IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS p
;



/*
-------------------------------------------------------------------------------
UNPIVOT 구현
*/
/*
개념적 풀이

데이터 준비 - 크로스탭
*/
WITH OrdersPerYear 
AS
(	
	SELECT EmployeeID, OrderYear = YEAR(OrderDate) 
	FROM dbo.Orders
)
SELECT EmployeeID, [1996], [1997], [1998]
INTO #EmpOrders
FROM OrdersPerYear
PIVOT (	COUNT(OrderYear) 
			FOR OrderYear IN ([1996], [1997], [1998])
		) AS PV
ORDER BY EmployeeID;

SELECT * FROM dbo.#EmpOrders ORDER BY EmployeeID;



/*
예제-1) 개념적 풀이 - <열 수 만큼 "행 복제> 

A) UNION 으로 푸는 경우
*/
SELECT EmployeeID, OrderYear = 1996, Orders = [1996] FROM dbo.#EmpOrders
UNION ALL
SELECT EmployeeID, 1997, [1997] FROM dbo.#EmpOrders
UNION ALL
SELECT EmployeeID, 1998, [1998] FROM dbo.#EmpOrders
ORDER BY EmployeeID ASC, OrderYear ASC
;


/*
개념적 풀이 - <열 수 만큼 "행 복제> 

B) JOIN을 이용한 행 복제(Cartesian Product)로 푼 경우
*/
SELECT e.EmployeeID
,	OrderYear = 1995 + n.Seq
,	Orders = (CASE n.Seq WHEN 1 THEN e.[1996] 
								WHEN 2 THEN e.[1997]
								WHEN 3 THEN e.[1998] 
								END)
FROM #EmpOrders AS e
CROSS JOIN (VALUES (1), (2), (3)) AS n(Seq)
ORDER BY e.EmployeeID ASC, OrderYear ASC;


/*
2) 예제 - 크로스탭 UNPIVOT
*/
/*
UNPIVOT
*/
WITH OrdersPerYear
AS
(
	SELECT EmployeeID, [1996], [1997], [1998] FROM #EmpOrders
)
SELECT
	EmployeeID, OrderYear, Orders
FROM OrdersPerYear
UNPIVOT 
(
	Orders FOR OrderYear IN ([1996], [1997], [1998])
) AS UnPV
ORDER BY EmployeeID;


	/*
	단순 집계와 비교
	*/
	SELECT 
		EmployeeID
	,	OrderYear = YEAR(OrderDate)
	,	Orders = COUNT(OrderDate)
	FROM dbo.Orders AS o
	GROUP BY EmployeeID, YEAR(OrderDate)
	ORDER BY EmployeeID;



/*
*******************************************************************************
소계와 총계
*******************************************************************************
*/

/*
쉬운 설명을 위해 간단한 데이터 준비
*/
USE Northwind;
GO

IF OBJECT_ID('AOrders', 'U') IS NOT NULL
	DROP TABLE AOrders

SELECT *
INTO AOrders
FROM dbo.Orders
WHERE CustomerID IN ('VINET', 'CHOPS');

SELECT * FROM AOrders;


/*
-------------------------------------------------------------------------------
소계와 총계 이해 - ROLLUP 기준
*/
SELECT 
	CustomerID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY CustomerID, YEAR(OrderDate)

UNION ALL

SELECT 
	CustomerID
,	OrderYear = NULL
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY CustomerID

UNION ALL

SELECT 	
	CustomerID = NULL
,	OrderYear = NULL
,	Freight = SUM(Freight)
FROM AOrders
;

/*
연도별 소계도 추가한다면?
*/



/*
-------------------------------------------------------------------------------
ROLLUP
*/
USE Northwind;
GO

SELECT 
	CustomerID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY ROLLUP
(
	CustomerID, YEAR(OrderDate)
);


	/*
	GROUPING SETS 표현	 - 2+1 결과 셋
	*/
	SELECT 
		CustomerID
	,	OrderYear = YEAR(OrderDate)
	,	Freight = SUM(Freight)
	FROM AOrders
	GROUP BY GROUPING SETS
   (
      (CustomerID, YEAR(OrderDate))
   ,  (CustomerID)
   ,  ()
   )
	;



/*
-------------------------------------------------------------------------------
CUBE
*/
SELECT 
	CustomerID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY CUBE
(
	CustomerID, YEAR(OrderDate)
)
-- 원하는 형태로 정렬-뒤에서 다룸
ORDER BY GROUPING(CustomerID), CustomerID
	, GROUPING(YEAR(OrderDate)), YEAR(OrderDate);


	/*
	GROUPING SETS 표현	 - 2^N 결과 셋
	*/
	SELECT 
		CustomerID
	,	OrderYear = YEAR(OrderDate)
	,	Freight = SUM(Freight)
	FROM AOrders
	GROUP BY GROUPING SETS 
	(
      (CustomerID, YEAR(OrderDate))
   ,  (CustomerID)
   ,  (YEAR(OrderDate))
   ,  ()
	)
   ORDER BY GROUPING(CustomerID), CustomerID
	, GROUPING(YEAR(OrderDate)), YEAR(OrderDate);



/*
-------------------------------------------------------------------------------
GROUPING SETS
*/
/*
동적 집계
*/
SELECT 
	CustomerID
,	EmployeeID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY GROUPING SETS 
(
	(CustomerID, EmployeeID, YEAR(OrderDate))
,	(CustomerID)
,	()
)
; 


SELECT 
	CustomerID
,	EmployeeID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY GROUPING SETS 
(
	(CustomerID, EmployeeID, YEAR(OrderDate))
,	(YEAR(OrderDate))
,	()
)
; 


SELECT 
	CustomerID
,	EmployeeID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY GROUPING SETS 
(
	(CustomerID, EmployeeID, YEAR(OrderDate))
,	(CustomerID)
,	(EmployeeID)
,	(YEAR(OrderDate))
,	()
)
; 


SELECT 
	CustomerID
,	EmployeeID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY GROUPING SETS 
(
	(CustomerID)
,	(EmployeeID)
,	(YEAR(OrderDate))
,	()
)
; 


SELECT 
	CustomerID
,	EmployeeID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY GROUPING SETS 
(
	(CustomerID)
,	(EmployeeID)
,	(YEAR(OrderDate))
)
; 


/*
아래는 될까?
*/
SELECT 
	CustomerID
,	EmployeeID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY GROUPING SETS 
(
	(CustomerID)
,	()
)
; 



/*
-------------------------------------------------------------------------------
GROUPING_ID(), GROUPING() - 집계 수준 확인하기
*/ 
SELECT 
	CustomerID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
,	[GROUPING(CustomerID)] = GROUPING(CustomerID)
,	[GROUPING(YEAR(OrderDate))] = GROUPING(YEAR(OrderDate))
,	[GROUPING_ID(CustomerID, YEAR(OrderDate))] = GROUPING_ID(CustomerID, YEAR(OrderDate))
FROM AOrders
GROUP BY CUBE
(
	CustomerID, YEAR(OrderDate)
)
ORDER BY GROUPING(CustomerID), CustomerID, GROUPING(YEAR(OrderDate));




/*
-------------------------------------------------------------------------------
 예제-2-정렬하기
*/
/*
그룹핑 수준에 따라 정렬하기
*/
SELECT 
	CustomerID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY ROLLUP
(
	CustomerID, YEAR(OrderDate)
)
ORDER BY GROUPING_ID(CustomerID, YEAR(OrderDate));


/*
사용자 정의 - 그룹 열 순서로 정렬하기
*/
SELECT 
	CustomerID
,	OrderYear = YEAR(OrderDate)
,	Freight = SUM(Freight)
FROM AOrders
GROUP BY ROLLUP
(
	CustomerID, YEAR(OrderDate)
)
ORDER BY GROUPING(CustomerID), CustomerID, GROUPING(YEAR(OrderDate));



/*
-------------------------------------------------------------------------------
소계/총계 Label 출력하기 - CustomerID만 예제로
*/
SELECT 
	CustomerID
,	OrderYear = (CASE GROUPING_ID(CustomerID, OrderYear) 
							WHEN 0 THEN CAST(OrderYear AS varchar(10))
							WHEN 1 THEN '고객별 소계'
							WHEN 2 THEN CAST(OrderYear AS varchar(10))
							WHEN 3 THEN '총계'
						END)
,	Freight = SUM(Freight)
FROM AOrders
CROSS APPLY (SELECT OrderYear = YEAR(OrderDate)) AS y
GROUP BY CUBE (CustomerID, OrderYear)

ORDER BY GROUPING_ID(CustomerID, OrderYear), CustomerID, OrderYear;



/*
*******************************************************************************
End
*******************************************************************************
*/



