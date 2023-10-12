/*
*********************************************************************
SQL Query Level Up - Subquery

작성자: 김정선 (jskim@sqlroad.com)
        (주)씨퀄로 대표컨설턴트/이사


여기에 사용된 코드와 정보들은 단지 데모를 위해서 제공되는 것이며 
그 외 어떤 보증이나 책임도 없습니다. 테스트나 개발을 포함해 특정 용도로
아래 코드를 사용할 경우 주의를 요합니다.

*********************************************************************
*/
USE Northwind
GO


/*
*******************************************************************************
서브쿼리
*******************************************************************************
*/

/*
*******************************************************************************
중첩 (스칼라) 서브쿼리
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
비교연산자와 둘 이상의 반환 값
*/
SELECT 
	ProductID
,	UnitPrice
,	AvgPrice = (SELECT UnitPrice FROM dbo.[Order Details])
FROM	dbo.[Order Details] As od
WHERE	OrderID <= 10250;



/*
-------------------------------------------------------------------------------
중첩 서브쿼리 - IN - 중복값, NULL 값
*/
SELECT 
	Region, * 
FROM	dbo.Customers
WHERE	Region IN ('WA', 'WA', 'SP', NULL)
;	



/*
-------------------------------------------------------------------------------
중첩 서브쿼리 - IN 서브쿼리
*/
-- distinct 연산자
SELECT CompanyName
FROM dbo.Customers
WHERE	CustomerID IN (SELECT CustomerID 
							FROM dbo.Orders 
							WHERE ShipCountry = 'USA')
ORDER BY	CompanyName
;	


-- 집계
SELECT c.CompanyName
FROM dbo.Customers AS c
WHERE CustomerID IN (
							SELECT CustomerID
							FROM dbo.Orders AS o
							GROUP BY o.CustomerID
							HAVING COUNT(*) > 20
							);


-- UNION 
SELECT c.CompanyName
FROM dbo.Customers AS c
WHERE CustomerID IN (
							SELECT CustomerID
							FROM dbo.Orders AS o
							WHERE o.EmployeeID = 5

							-- 아래는 예제용일 뿐 실제론 이렇게 작성할 필요가 없죠^^
							UNION
							SELECT CustomerID
							FROM dbo.Orders AS o
							INNER JOIN dbo.[Order Details] AS d
								ON o.OrderID = d.OrderID
							WHERE d.ProductID = 1 AND Quantity >= 50
							);



/*
-------------------------------------------------------------------------------
NOT IN은 어떻게 처리되나?
*/
SELECT 
	Region, * 
FROM	dbo.Customers
WHERE	Region NOT IN ('SP', 'WA')
;	



/*
*******************************************************************************
상관 서브쿼리
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
SELECT 절
*/
-- 코드명 결합 (부모 테이블 참조)
SELECT
	CustomerID
,	CompanyName = (SELECT CompanyName 
						FROM dbo.Customers AS c
						WHERE c.CustomerID = o.CustomerID)
,	Freight
FROM dbo.Orders AS o
WHERE o.OrderDate >= DATEADD(dd, -7, '19980510');


-- 집계값 결합
SELECT
	CustomerID
,	Freight
,	AvgFreight = (
						SELECT AVG(Freight)
						FROM dbo.Orders AS a
						WHERE a.CustomerID = o.CustomerID
						)
FROM dbo.Orders AS o
WHERE o.OrderDate >= DATEADD(dd, -7, '19980510');



/*
-------------------------------------------------------------------------------
WHERE 비교연산자
*/
SELECT c.CompanyName
FROM dbo.Customers AS c
WHERE 20 < (
					SELECT COUNT(*)
					FROM dbo.Orders AS o
					WHERE o.CustomerID = c.CustomerID
				);


/*
-------------------------------------------------------------------------------
EXISTS, IN, (NOT EXISTS, NOT IN에 대해서는 "차집합 구현 예제"에서 다룸)
*/
SELECT c.CompanyName
FROM dbo.Customers AS c
WHERE c.Country = 'Sweden' 
	AND EXISTS (SELECT 1 
						FROM dbo.Orders AS o
						WHERE o.CustomerID = c.CustomerID
							AND o.EmployeeID IN (2, 3, 4));


-- EXIST 대신 집계함수 사용한 경우
SELECT c.CompanyName
FROM dbo.Customers AS c
WHERE	c.Country = 'Sweden' 
	AND 0 < (SELECT COUNT(*)
				FROM dbo.Orders AS o
				WHERE o.CustomerID = c.CustomerID
					AND o.EmployeeID IN (2, 3, 4));


	/*
	EXISTS()에는 무엇을 사용해야 하나요?
	*/
	-- 0으로 나누기
	SELECT 1 / 0;

	-- 오류가 발생할까?
	IF EXISTS (SELECT 1 / 0 FROM dbo.Employees)
		SELECT 'OK';



/*
EXIST 대신 IN 사용
*/
SELECT c.CompanyName
FROM dbo.Customers AS c
WHERE
	c.Country = 'Sweden' 
AND c.CustomerID IN (SELECT o.CustomerID
							FROM dbo.Orders AS o
							WHERE o.CustomerID = c.CustomerID
							   AND o.EmployeeID IN (2, 3, 4));



/*
-------------------------------------------------------------------------------
HAVING과 상관 서브쿼리 - 그룹별 최대값/최소값 출력
*/
SELECT
	o.EmployeeID
,	o.ShipCountry
,	OrderCount = COUNT(*)
FROM dbo.Orders AS o
GROUP BY o.EmployeeID, o.ShipCountry
HAVING COUNT(*) = 
	(
		SELECT TOP(1) OrderCount = COUNT(*)
		FROM	dbo.Orders AS o2
		WHERE	o2.EmployeeID = o.EmployeeID
		GROUP BY o2.EmployeeID,	o2.ShipCountry
		ORDER BY	OrderCount DESC
	)
ORDER BY	o.EmployeeID;




/*
-------------------------------------------------------------------------------
예제-1) Row Number(행 번호) 달기 
	- 과제를 위한 힌트 (Self Join으로 Ranking 구하기도 참조)
*/
-- OrderID = PK, 유일값이 존재
SELECT TOP(10)
	OrderID
,	Rownum = (SELECT COUNT(*)
					FROM dbo.Orders n
					WHERE n.OrderID <= o.OrderID
				)
FROM dbo.Orders AS o
ORDER BY OrderID ASC;



/*
-------------------------------------------------------------------------------
예제-2) 그룹별 상위 N건 검색
	- 과제를 위한 힌트
*/
SELECT d.Orderid, d.Productid, d.Quantity
FROM dbo.[Order Details] AS d
WHERE ProductID IN (1, 2) 
	AND OrderID IN (
							SELECT TOP(10) OrderID
							FROM [Order Details] AS r 
							WHERE r.ProductID = d.ProductID 
							ORDER BY r.Quantity DESC
						)
ORDER BY ProductID, Quantity DESC;



/*
*******************************************************************************
서브쿼리 주의사항
*******************************************************************************
*/
/*
---------------------------------------------------------------------
예제-1) NOT IN과 정합성
*/
SELECT 'OK'
WHERE '왕눈이' NOT IN ('브라보콘', '쌍쌍바', NULL)

	-- 왜 다른가? 어떻게 바뀌는가?
	SELECT 'OK'
	WHERE '왕눈이' <> '브라보콘'	-- T or F?
		AND '왕눈이' <> '쌍쌍바'
		AND '왕눈이' <> NULL			-- T or F?, ->>> Unknown


	-- 그럼 어떻게 처리해야하나? --> 성능 문제 예제에서 다룸


/*
-------------------------------------------------------------------------------
예제-2) 내부 테이블에 없는 열 참조 시
*/
SELECT * 
FROM dbo.Orders
WHERE OrderID IN (SELECT OrderID 
						FROM dbo.Customers);

SELECT * 
FROM dbo.Orders
WHERE OrderID IN (SELECT OrderID 
						FROM dbo.Customers 
						WHERE Customerid = Customerid);


/*
-------------------------------------------------------------------------------
만일 아래 명령이 UPDATE/DELETE 였다면? - 실제 사례

결론) 서브쿼리 내에서는 반드시 해당 테이블 별칭 지정
*/
SELECT * 
FROM dbo.Orders
WHERE OrderID IN (SELECT OrderID   -- 테이블 별칭 지정하기
						FROM dbo.Customers AS c);



/*
*******************************************************************************
파생 테이블(Derived Table)
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
예제-1) 기본 구문
*/
SELECT *			-- Intellisense 상태에서 열 이름 기술해 볼 것
FROM 
(
	SELECT ProductID, QuantitySum = SUM(Quantity)
	FROM dbo.[Order Details] AS d
	WHERE ProductID IN (1, 2, 3)
	GROUP BY ProductID	
) AS p;


	/*
	ORDER BY 만 존재 시 오류
	*/
	SELECT *
	FROM 
	(
		SELECT ProductID, QuantitySum = SUM(Quantity)
		FROM dbo.[Order Details] AS d
		WHERE ProductID IN (1, 2, 3)
		GROUP BY ProductID
		ORDER BY ProductID
	) AS p;


/*
-------------------------------------------------------------------------------
예제-2) Products 테이블에서 제품별 단가와 같은 Category의 평균단가 출력
*/
SELECT CategoryID, UnitPriceAvg = AVG(UnitPrice)
FROM dbo.Products
GROUP BY CategoryID;


SELECT
	p.ProductID, p.UnitPrice, p.CategoryID, c.UnitPriceAvg
FROM dbo.Products AS p
INNER JOIN	(
					SELECT CategoryID, UnitPriceAvg = AVG(UnitPrice)
					FROM dbo.Products
					GROUP BY CategoryID
				) AS c
ON p.CategoryID = c.CategoryID
ORDER BY p.ProductID;


/*
-------------------------------------------------------------------------------
예제-3) Products 테이블에서 매출액 상위 5위(Quantity * UnitPrice)의 제품에 대한
	제품 단가를 20% 인하
*/
-- 상위 5위 제품
SELECT TOP(5) ProductID, AmountSum = SUM(Quantity * UnitPrice)
FROM dbo.[Order Details]
GROUP BY ProductID
ORDER BY AmountSum DESC;

-- 1위 제품 단가 기록, 비교용
SELECT ProductID, UnitPrice, UnitPrice * 0.8
FROM dbo.Products
WHERE ProductID = 38;

/*
Tip.
 - 아래 Tx는 필요한 경우 ROLLBACK용
 - UPDATE 대신 SELECT로 먼저 내용 확인 후 UPDATE 하면 보다 안전
*/
BEGIN TRAN

	UPDATE p
	SET p.UnitPrice = p.UnitPrice * 0.8
		-- 아래 OUTPUT은 확인용
		OUTPUT deleted.ProductID, deleted.UnitPrice, inserted.UnitPrice
	FROM dbo.Products AS p
	INNER JOIN (
					SELECT TOP(5) ProductID, AmountSum = SUM(Quantity * UnitPrice)
					FROM dbo.[Order Details]
					GROUP BY ProductID
					ORDER BY AmountSum DESC
					) AS t
		ON p.ProductID = t.ProductID;

--	COMMIT TRAN

IF @@trancount > 0 ROLLBACK TRAN
SELECT @@trancount;



/*
-------------------------------------------------------------------------------
예제-4) UNION을 포함한 파생테이블 --> 아래는 형식을 표현하는 예제용 
*/
SELECT
	*
FROM 
(
	SELECT Flag = 1, Name = '단가', Data = UnitPrice 
	FROM dbo.[Order Details]
	WHERE UnitPrice IS NOT NULL
		AND OrderID <= 10250
	UNION ALL
	SELECT Flag = 2, '수량', Data = Quantity 
	FROM dbo.[Order Details]
	WHERE Quantity IS NOT NULL
		AND OrderID <= 10250
) AS o
;


/*
-------------------------------------------------------------------------------
예제-5) 중첩 파생테이블 - Paging 쿼리 예제 (TOP + TOP 방식)

전제 - BigOrders가 NC Index일 경우
*/
USE Northwind
GO

DECLARE @PageNo int = 10, @PageSize int = 10;

/*
Step-1. 10번째 page x 10건씩 전체 데이터
*/
SELECT TOP (@PageNo * @PageSize)
	o.OrderID, o.OrderDate, o.CustomerID
FROM 
	dbo.BigOrders AS o
ORDER BY 
	o.OrderID DESC


/*
Step-2. 뒤집기 - 마지막 page의 10건
*/
SELECT TOP (@PageSize)
	*
FROM 
(
	SELECT TOP (@PageNo * @PageSize)
		o.OrderID, o.OrderDate, o.CustomerID
	FROM 
		dbo.BigOrders AS o
	ORDER BY 
		o.OrderID DESC
) AS o
ORDER BY 
	OrderID ASC


/*
Step-Last. 다시 뒤집기 - 원래 정렬순서대로
*/
SELECT TOP (@PageSize)
	*
FROM
(
	SELECT TOP (@PageSize)
		*
	FROM 
		(
			SELECT TOP (@PageNo * @PageSize)
				o.OrderID, o.OrderDate, o.CustomerID
			FROM 
				dbo.BigOrders AS o
			ORDER BY 
				o.OrderID DESC
		) AS o
	ORDER BY 
		OrderID ASC
) AS o
ORDER BY 
	o.OrderID DESC;



/*
*******************************************************************************
CTE
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
예제-1) 기본 구문
*/
WITH OrderAggr
AS
(
	SELECT CustomerID, EmployeeID, OrderCount = COUNT(*)
	FROM dbo.Orders
	GROUP BY CustomerID, EmployeeID
)
SELECT *		-- Intellisense 상태에서 열 이름 기술해 볼 것
FROM OrderAggr
ORDER BY CustomerID ASC;



/*
-------------------------------------------------------------------------------
예제-2) CTE + UPDATE
*/
-- 1위 제품 단가 기록, 비교용
SELECT ProductID, UnitPrice, UnitPrice * 0.8
FROM dbo.Products
WHERE ProductID = 38;


/*
Tip.
 - 아래 Tx는 필요한 경우 ROLLBACK용
 - UPDATE 대신 SELECT로 먼저 내용 확인 후 UPDATE 하면 보다 안전
*/
BEGIN TRAN

	/* ; 필요 */
	;WITH ProductAmount 
	AS
	(
		SELECT TOP(5) ProductID, AmountSum = SUM(Quantity * UnitPrice)
		FROM dbo.[Order Details]
		GROUP BY ProductID
		ORDER BY AmountSum DESC
	)
	UPDATE p
	SET p.UnitPrice = p.UnitPrice * 0.8
		-- 아래 OUTPUT은 확인용
		OUTPUT deleted.ProductID, deleted.UnitPrice, inserted.UnitPrice
	FROM dbo.Products AS p
	INNER JOIN ProductAmount AS t
		ON p.ProductID = t.ProductID;

	--COMMIT TRAN

IF @@trancount > 0 ROLLBACK TRAN
SELECT @@trancount;



/*
-------------------------------------------------------------------------------
예제-3) 다중 CTE(jskim: 중첩 CTE) - Paging (TOP + TOP)
*/
DECLARE @PageNo int = 10, @PageSize int = 10;

WITH OrderPages
AS 
(
	SELECT TOP (@PageNo * @PageSize)
		o.OrderID, o.OrderDate, o.CustomerID 
	FROM dbo.BigOrders AS o
	ORDER BY o.OrderID DESC
),
OrderPage AS
(
	SELECT TOP (@PageSize)
		*
	FROM OrderPages
	ORDER BY OrderID ASC
)
SELECT TOP (@PageSize)
	o.OrderID, o.OrderDate, o.CustomerID
FROM OrderPage AS o
ORDER BY o.OrderID DESC;


/*
또 다른 형태의 다중 CTE
*/
WITH OrderEmployeeUK
AS
(
	SELECT OrderID
	FROM dbo.Orders AS o
	WHERE o.EmployeeID IN (SELECT e.EmployeeID 
								FROM dbo.Employees AS e
								WHERE Country = 'UK')
),
OrderCustomerUK
AS
(
	SELECT OrderID
	FROM dbo.Orders AS o
	WHERE o.CustomerID IN (SELECT c.CustomerID
								FROM dbo.Customers AS c
								WHERE Country = 'UK')
)
SELECT o.*
FROM OrderEmployeeUK AS e
INNER JOIN OrderCustomerUK AS c
	ON e.OrderID = c.OrderID
INNER JOIN dbo.Orders AS o
	ON o.OrderID = c.OrderID;



/*
-------------------------------------------------------------------------------
예제-4) CTE 구문 장점(Self Join) - 전월 매출 비교
*/
WITH MonthlySales 
AS
(
	SELECT OrderMonth = MONTH(OrderDate), Amount = SUM(Quantity * UnitPrice)
	FROM dbo.Orders AS o
	INNER JOIN dbo.[Order Details] AS d
		ON o.OrderID = d.OrderID
	WHERE OrderDate >= '19960101' AND OrderDate < '19970101'
	GROUP BY MONTH(OrderDate)
)
SELECT 
	cur.OrderMonth
,	CurAmount = cur.Amount
,	PrvAmount = prv.Amount
,	AmountGrowth = (cur.Amount - ISNULL(prv.Amount, 0))
FROM MonthlySales AS cur
LEFT JOIN MonthlySales AS prv
	ON prv.OrderMonth = (cur.OrderMonth - 1)



/*
-------------------------------------------------------------------------------
예제-5) 매 5th 주문마다 할인.

	할인 조건은, 이전 4개 주문의 총액(AmountPrevious) 기준으로 
		AmountPrevious < 10000.0 이면 5%
		AmountPrevious < 15000.0 이면 10%
		그 이상이면 20%
*/
/*
기초 데이터 확인 - 예제에서는 한 고객(QUICK)만 대상으로 처리
*/
SELECT d.OrderID
	, Amount = SUM(d.Quantity * d.UnitPrice)
	, Seq = ROW_NUMBER() OVER(ORDER BY d.OrderID ASC)
FROM dbo.Orders AS o
INNER JOIN dbo.[Order Details] As d
	ON o.OrderID = d.OrderID
WHERE o.CustomerID = 'QUICK'
GROUP BY d.OrderID


/*
1-참고. 이전에 임시 Table를 활용한 경우
*/
SELECT d.OrderID
	, Amount = SUM(d.Quantity * d.UnitPrice)
	, Seq = ROW_NUMBER() OVER(ORDER BY d.OrderID ASC)
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
,	DiscountRate = (CASE 
							WHEN AmoutPrevious < 10000.0 THEN 0.05
							WHEN AmoutPrevious < 15000.0 THEN 0.1
							ELSE 0.2
							END)
,	AmoutPrevious
FROM (
	SELECT 
		OrderID
	,	Amount
	,	AmoutPrevious = (SELECT SUM(sc.Amount)
								FROM #CustOrders AS sc
								WHERE sc.Seq >= (c.Seq - 4)
									AND sc.Seq < c.Seq
		)
	FROM #CustOrders AS c
	WHERE c.Seq % 5 = 0
) AS c

DROP TABLE #CustOrders;


/*
-------------------------------------------------------------------------------
2) CTE를 활용한 경우
*/
WITH CustOrders 
AS 
(
	SELECT d.OrderID
		, Amount = SUM(d.Quantity * d.UnitPrice)
		, Seq = ROW_NUMBER() OVER(ORDER BY d.OrderID ASC)
	FROM dbo.Orders AS o
	INNER JOIN dbo.[Order Details] As d
		ON o.OrderID = d.OrderID
	WHERE o.CustomerID = 'QUICK'
	GROUP BY d.OrderID
)
SELECT 
	OrderID
,	Amount
,	DiscountRate = (CASE WHEN AmoutPrevious < 10000.0 THEN 0.05
								WHEN AmoutPrevious < 15000.0 THEN 0.1
								ELSE 0.2
						END)
,	AmoutPrevious
FROM (
	SELECT 
		OrderID
	,	Amount
	,	AmoutPrevious = (SELECT SUM(sc.Amount)
								FROM CustOrders AS sc
								WHERE sc.Seq >= (c.Seq - 4)
									AND sc.Seq < c.Seq
		)
	FROM CustOrders  AS c
	WHERE c.Seq % 5 = 0
) AS c



/*
*******************************************************************************
재귀 CTE
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
예제-1) 재귀 CTE - 조직 차트
*/
/*
기초 데이터 이해
*/
-- 계층 구조 모델 데이터
SELECT EmployeeID, ReportsTo, * FROM dbo.Employees;

-- (1) Anchor Member
SELECT EmployeeID, ReportsTo FROM Employees WHERE ReportsTo IS NULL

-- (2) Recursive Member
SELECT EmployeeID, ReportsTo FROM Employees WHERE ReportsTo = 2
--UNION ALL
SELECT EmployeeID, ReportsTo FROM Employees WHERE ReportsTo IN (1, 3, 4, 5, 8)
--UNION ALL
SELECT EmployeeID, ReportsTo FROM Employees WHERE ReportsTo IN (6, 7, 9)


/*
1-1) 하위 노드 검색
*/
WITH Organize
AS
(
	SELECT e.EmployeeID, e.ReportsTo
	FROM dbo.Employees AS e
	WHERE ReportsTo IS NULL

	UNION ALL

	SELECT e.EmployeeID, e.ReportsTo
	FROM dbo.Employees AS e
	INNER JOIN Organize AS o
		ON e.ReportsTo = o.EmployeeID
)
SELECT *
FROM Organize AS o;


/*
1-2) 노드 수준 추적
*/
WITH Organize
AS
(
	SELECT e.EmployeeID, e.ReportsTo, Lvl = 0 
	FROM dbo.Employees AS e
	WHERE ReportsTo IS NULL

	UNION ALL

	SELECT e.EmployeeID, e.ReportsTo, Lvl = Lvl + 1
	FROM dbo.Employees AS e
	INNER JOIN Organize AS o
		ON e.ReportsTo = o.EmployeeID
)
SELECT *
FROM Organize AS o
-- 특정 수준으로 제한할 경우
WHERE Lvl <= 1;


	WITH Organize
	AS
	(
		SELECT e.EmployeeID, e.ReportsTo, Lvl = 0 
		FROM dbo.Employees AS e
		WHERE ReportsTo IS NULL

		UNION ALL

		SELECT e.EmployeeID, e.ReportsTo, Lvl = Lvl + 1
		FROM dbo.Employees AS e
		INNER JOIN Organize AS o
			ON e.ReportsTo = o.EmployeeID
	)
	SELECT *
	FROM Organize AS o
	-- 혹은 재귀 호출 수준을 제한, 초과 시 오류 530 발생
	OPTION (MAXRECURSION 1);



/*
1-3) 계층 구조 정렬 방법 중의-1
*/
WITH Organize
AS
(
	SELECT e.EmployeeID, e.ReportsTo, Lvl = 0, SortBy = CAST(e.EmployeeID AS varbinary(1000))
	FROM dbo.Employees AS e
	WHERE ReportsTo IS NULL

	UNION ALL

	SELECT e.EmployeeID, e.ReportsTo, Lvl + 1, CAST(SortBy + CAST(e.EmployeeID AS binary(5)) AS varbinary(1000))
	FROM dbo.Employees AS e
	INNER JOIN Organize AS o
		ON e.ReportsTo = o.EmployeeID
)
SELECT 
	o.EmployeeID
,	o.ReportsTo
,	Lvl, Sortby
FROM Organize AS o
ORDER BY SortBy


/*
1-4) 계층 구조 모양 만들기
*/
WITH Organize
AS
(
	SELECT e.EmployeeID, e.ReportsTo, Lvl = 0, SortBy = CAST(e.EmployeeID AS varbinary(1000))
	FROM dbo.Employees AS e
	WHERE ReportsTo IS NULL

	UNION ALL

	SELECT e.EmployeeID, e.ReportsTo, Lvl + 1, CAST(SortBy + CAST(e.EmployeeID AS binary(5)) AS varbinary(1000))
	FROM dbo.Employees AS e
	INNER JOIN Organize AS o
		ON e.ReportsTo = o.EmployeeID
)
SELECT 
	-- 보기 좋게^^
	REPLICATE('....', Lvl) + CAST(o.EmployeeID AS varchar(5))
,	Lvl
,	Sortby
FROM Organize AS o
ORDER BY SortBy;



/*
-------------------------------------------------------------------------------
예제-2) 재귀호출 CTE - Calender 데이터 생성
*/
DECLARE @BOMonth date = '20210901';

WITH Calendar AS 
(
	--anchor
	SELECT YMD = @BOMonth
	UNION ALL
	--recursive
	SELECT DATEADD(day, 1, YMD)
	FROM Calendar
	WHERE YMD < DATEADD(day, -1, DATEADD(month, 1, @BOMonth))	-- 월의 마지막일
)
SELECT 
	YMD
,	Day = DATEPART(day, YMD)
,	DayofWeek = DATEPART(weekday, YMD)
,	WeekofMonth = DATEDIFF(week, @BOMonth, YMD) + 1	-- 보기 좋게 하려고^^
FROM Calendar;



/*
*******************************************************************************
APPLY
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
예제-1) Cartesian Product
*/
SELECT 
	*
FROM 
	(VALUES ('A'), ('B')) AS P(c)
CROSS JOIN 
	(VALUES (1), (2), (3)) AS C(n)
;

/*
APPLY로 표현하면
*/
SELECT 
	*
FROM 
	(VALUES ('A'), ('B')) AS P(c)
CROSS APPLY
	(VALUES (1), (2), (3)) AS C(n)
;


/*
-------------------------------------------------------------------------------
예제-2) SELECT절 전처리기
*/
-- 전처리 필요한 경우
SELECT TOP(5)
	OrderID,	OrderYear = YEAR(OrderDate), OrderYear2 = OrderYear + 1
FROM dbo.Orders
WHERE OrderYear2 >= 1997;

-- APPLY 전처리
SELECT TOP(5)
	OrderID,	OrderYear, OrderYear2
FROM dbo.Orders AS o
   CROSS APPLY (VALUES (YEAR(OrderDate))) AS y(OrderYear)
   CROSS APPLY (VALUES (y.OrderYear + 1)) AS y2(OrderYear2)
WHERE OrderYear2 >= 1997;



/*
-------------------------------------------------------------------------------
예제-3) 원시 데이터와 다중 집계 결과 결합
*/
SELECT o.OrderID, o.CustomerID, OrderCnt, QuantitySum
FROM dbo.Orders AS o
CROSS APPLY (
   SELECT 
         COUNT(*) AS OrderCnt
      ,  SUM(Quantity) AS QuantitySum
   FROM dbo.[Order Details] AS d
   WHERE d.OrderID = o.OrderID
   ) AS d
WHERE o.OrderID IN (10248, 10250);




/*
-------------------------------------------------------------------------------
예제-4) 전/후 행 비교 연산
*/
SELECT o.CustomerID
,	BeforeDate, OrderDate
,	OrderDayPeriod = DATEDIFF(dd, b.BeforeDate, o.OrderDate)
FROM dbo.Orders AS o
OUTER APPLY 
	(
		SELECT TOP(1) BeforeDate = b.OrderDate
		FROM dbo.Orders AS b
		WHERE b.CustomerID = o.CustomerID
			AND b.OrderDate < o.OrderDate
		ORDER BY b.OrderDate DESC
	) AS b

WHERE o.CustomerID IN ('FRANK');



/*
-------------------------------------------------------------------------------
예제-5) 테이블 값 함수 호출 
*/
/*
일반 함수
*/
DROP FUNCTION dbo.uf_CustomerTopOrders
GO

CREATE FUNCTION dbo.uf_CustomerTopOrders
(@CustomerID nchar(5), @Ncount int) 
RETURNS table
AS
RETURN
(
   SELECT TOP(@Ncount)
		OrderID, OrderDate, EmployeeID
   FROM dbo.Orders As o
   WHERE o.CustomerID = @CustomerID
	ORDER BY OrderDate DESC
)
GO

SELECT c.CompanyName, o.OrderID, o.OrderDate, o.EmployeeID
FROM dbo.Customers AS c
OUTER APPLY dbo.uf_CustomerTopOrders(c.CustomerID, 3) AS o
WHERE c.CustomerID IN ('QUICK', 'BONAP');



/*
*******************************************************************************
차집합 구현 예제들
*******************************************************************************
*/

/*
1. NOT IN
2. NOT IN + 상관서브쿼리
3. NOT EXISTS + 상관서브쿼리
4. 상관 서브쿼리 + IS NULL
5. OUTER JOIN + IS NULL
6. OUTER APPLY + IS NULL 
7. EXCEPT + (생략됨) 서브쿼리(혹은JOIN) 
*/

/*
차집합 테스트 쿼리
*/
USE Northwind;
GO

-- 1.NOT IN
SELECT * FROM dbo.Customers AS c
WHERE CustomerID NOT IN (SELECT CustomerID FROM dbo.Orders)



-- 2.NOT IN + 상관서브쿼리
SELECT * FROM dbo.Customers AS c
WHERE CustomerID NOT IN (SELECT CustomerID FROM dbo.Orders AS o
									WHERE o.CustomerID = c.CustomerID)



-- 3.NOT EXISTS + 상관서브쿼리 
SELECT * FROM dbo.Customers AS c
WHERE NOT EXISTS (SELECT CustomerID 
						FROM dbo.Orders AS o
						WHERE o.CustomerID = c.CustomerID)


-- 4.상관서브쿼리 + (TOP 1) + IS NULL
SELECT * FROM dbo.Customers AS c
WHERE (SELECT TOP 1 CustomerID FROM dbo.Orders AS o
				WHERE o.CustomerID = c.CustomerID) IS NULL


-- 5.OUTER JOIN + IS NULL
SELECT c.* FROM dbo.Customers AS c
LEFT JOIN dbo.Orders AS o
	ON c.CustomerID = o.CustomerID
WHERE o.CustomerID IS NULL


-- 6.OUTER APPLY + IS NULL
SELECT * 
FROM dbo.Customers c 
OUTER APPLY (SELECT TOP 1 CustomerID FROM dbo.Orders o
							WHERE o.CustomerID = c.CustomerID) o
WHERE o.CustomerID IS NULL



-- 7.EXCEPT + (생략됨) 서브쿼리(혹은 JOIN)
SELECT c.CustomerID FROM dbo.Customers c
EXCEPT
SELECT o.CustomerID FROM dbo.Orders o



/*
*******************************************************************************
순위 함수
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
ROW_NUMBER
*/
/*
1) 순번
*/
SELECT TOP(20)
	OrderID
,	OrderDate
,	RowNo = ROW_NUMBER() OVER(ORDER BY OrderID ASC)
FROM dbo.Orders
ORDER BY OrderID ASC;

	/* 
	-- Tip. 정렬 조건이 필요 없는 경우
	ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
	or
	ROW_NUMBER() OVER(ORDER BY (SELECT 0))
	*/


/*
2) 그룹별(Partition) 순번
*/
SELECT
	SupplierID
,	ProductID
,	RowNo = ROW_NUMBER() OVER(PARTITION BY SupplierID 
										ORDER BY ProductID ASC)
FROM dbo.Products;



/*
3) 연속 구간 번호 찾기
*/
IF OBJECT_ID('dbo.LineNumbers', 'U') IS NOT NULL
	DROP TABLE dbo.LineNumbers
GO

CREATE TABLE dbo.LineNumbers
(
	No	int PRIMARY KEY
)

INSERT LineNumbers
VALUES
	(1),	(2),	(3)
,	(10),	(11)
,	(13)
,	(16),	(17),	(18)
;

SELECT * FROM dbo.LineNumbers;

SELECT MIN(No), MAX(No)
FROM (
	SELECT 
		No, Gap = No - ROW_NUMBER() OVER(ORDER BY No ASC)
	FROM dbo.LineNumbers
) AS l
GROUP BY Gap
;


/*
4) Paging 쿼리
*/
DECLARE @PageNo int = 2, @PageSize int = 20;

-- 최근 주문번호 순
WITH Paging AS 
(
	SELECT  
		OrderID, OrderDate, CustomerID, EmployeeID
	,	RowNum = ROW_NUMBER() OVER(ORDER BY OrderID DESC)
	FROM dbo.Orders
)
SELECT 
	d.OrderID, d.OrderDate, d.CustomerID, d.EmployeeID, d.RowNum
FROM Paging AS d
WHERE RowNum > ((@PageNo - 1) * @PageSize)
	AND RowNum <= (@PageNo * @PageSize)
ORDER BY RowNum ASC
;



/*
참고) 서브쿼리를 이용해서 행 번호 달기는 - Join, Subquery 과제에서 다룸
*/




/*
-------------------------------------------------------------------------------
RANK, DENSE_RANK
*/
SELECT 
	ProductID
,	UnitPrice
,	Rank = RANK() OVER(ORDER BY UnitPrice DESC)
,	DenseRank = DENSE_RANK() OVER(ORDER BY UnitPrice DESC)
FROM dbo.Products;



/*
-------------------------------------------------------------------------------
NTILE - 
	- 지정된 Tile(Bucket, Group)에 대상 행을 균등하게 입력
	- 남는 행이 있으면 First-Tile-First로 입력
*/
/*
그룹화) SELECT 9 / 4, 9 % 4	-- 4-tile, 2-rows in each, 1-remainders
*/
DECLARE @num_tiles int = 4;

SELECT 
	EmpID = EmployeeID, Title, BirthDate
,	num_tiles = NTILE(@num_tiles) 
							OVER(ORDER BY Title DESC, BirthDate DESC)
FROM dbo.Employees;
GO

/*
파티션별 Tile
*/
DECLARE @num_tiles int = 4;

SELECT 
	EmpID = EmployeeID,	Title, BirthDate
,	num_tiles = NTILE(@num_tiles) OVER(PARTITION BY Title
													ORDER BY BirthDate DESC)
FROM dbo.Employees;





/*
*******************************************************************************
OFFSET FETCH
*******************************************************************************
*/
/*
Paging 쿼리
*/
DECLARE @PageNo int = 2, @PageSize int = 20;

-- 최근 주문번호 순
SELECT OrderID, OrderDate, CustomerID, EmployeeID
FROM dbo.Orders
ORDER BY OrderID DESC
OFFSET (@PageNo - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY
;



/*
*******************************************************************************
End
*******************************************************************************
*/

