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
1장. 기본 고려사항
=====================================================================
*/
USE EPlanHeap;
GO


/*
---------------------------------------------------------------------
실행 계획에서 Index 사용 여부 확인
Page IO 량 확인
---------------------------------------------------------------------
*/
-- 그래픽 "실제 실행계획 포함"
SELECT s.SupplierID, p.ProductID, p.ProductName, p.UnitPrice 
FROM dbo.Suppliers AS s INNER JOIN dbo.Products AS p
  ON s.SupplierID = p.SupplierID
WHERE p.SupplierID = 2


-- Page IO 량 확인
SET STATISTICS IO ON;



/*
---------------------------------------------------------------------
교환법칙, 결합법칙
---------------------------------------------------------------------
*/
/*
WHERE
*/
SELECT *
FROM dbo.[Order Details]
WHERE (Discount <> 0)
AND (10 / Discount > 0)

   -- vs.
   SELECT *
   FROM dbo.[Order Details]
   WHERE (10 / Discount > 0)
   AND (Discount <> 0)


/*
JOIN
*/
SELECT *
FROM dbo.Orders AS o 
INNER JOIN dbo.[Order Details] AS d
   ON o.OrderID = d.OrderID
WHERE o.OrderID = 10249

   -- vs.
   SELECT *
   FROM dbo.[Order Details] AS d
   INNER JOIN dbo.Orders AS o 
      ON d.OrderID = o.OrderID
   WHERE d.OrderID = 10249




/*
---------------------------------------------------------------------
날짜시간 상수 이해, char vs. varchar 이해
---------------------------------------------------------------------
*/
DECLARE @d datetime = '20210615 23:59:59.999'
SELECT @d;


/*
문자열 비교. char vs. varchar 
*/
DECLARE @varchar varchar(8), @char char(8)
SELECT @varchar = 'sql   ', @char = 'sql   '

IF ( @varchar = 'sql' ) 
	PRINT '같다'

IF ( @char = 'sql' ) 
	PRINT '같다'

IF ( @varchar = @char )
	PRINT '같다'



/*
---------------------------------------------------------------------
조인 조건 vs. 검색 조건
---------------------------------------------------------------------
*/
SELECT 
	o.OrderID, o.CustomerID, * 
FROM
	dbo.Customers AS c
LEFT JOIN
	dbo.Orders AS o ON c.CustomerID = o.CustomerID
	AND o.CustomerID IS NULL	/* 이 조건의 위치를 어디에 둘 것인가? */
WHERE
	c.CustomerID IN ('FISSA', 'PARIS', 'ANTON')
		



/*
---------------------------------------------------------------------
의미오류
---------------------------------------------------------------------
*/
USE Northwind;
GO


/*
---------------------------------------------------------------------
의미 오류 - 모순 조건
---------------------------------------------------------------------
*/
SELECT 
	OrderDate
FROM 
	dbo.Orders
WHERE 
	OrderID IS NULL;	-- PK or NOT NULL


	SELECT 
		OrderDate
	FROM 
		dbo.Orders
	WHERE 
		ISNULL(OrderID, 0) = 10250;	-- 같은 내용


	SELECT
		OrderID, ProductID
	FROM 
		dbo.[Order Details]
	WHERE 
		Quantity < 0;	-- CHECK (Quantity>(0))


		EXEC sp_helpconstraint N'dbo.[Order Details]';


/*
---------------------------------------------------------------------
의미 오류 - 암시적인 or 동의 반복 or 모순된 조건식 포함
---------------------------------------------------------------------
*/
SELECT 
	OrderDate
FROM 
	dbo.Orders
WHERE 
	ShipVia > 4 OR ShipVia > 2;


	/*
	그리고 또
	*/
	SELECT OrderDate, OrderID
	FROM dbo.Orders
	WHERE OrderID = 10248
		OR OrderID = 10250
		OR OrderID = 10250
		OR OrderID = 10250;


	SELECT OrderDate, OrderID
	FROM dbo.Orders
	WHERE OrderID IN (10248, 10250, 10250, 10250);


	-- 개념을 SQL로 표현하면
	SELECT OrderID, OrderDate
	FROM dbo.Orders
	WHERE OrderID IN (SELECT DISTINCT val
							FROM (
								VALUES (10248), (10250), (10250), (10250)
							) AS d(val));


/*
---------------------------------------------------------------------
의미 오류 - 불필요한 DISTINCT
---------------------------------------------------------------------
*/
SELECT DISTINCT 
	CustomerID, CompanyName, ContactName
FROM 
	dbo.Customers;


/*
---------------------------------------------------------------------
의미 오류 - 상수 열 출력 혹은 불필요한 * 사용
---------------------------------------------------------------------
*/
SELECT 
	OrderDate, CustomerID
FROM 
	dbo.Orders
WHERE 
	CustomerID = 'QUICK';

   
/*
---------------------------------------------------------------------
의미 오류 - wildcard 없는 LIKE 연산자 (공백 고려는 제외)
---------------------------------------------------------------------
*/
SELECT 
	OrderID, OrderDate, CustomerID
FROM 
	dbo.Orders
WHERE 
	CustomerID LIKE N'QUICK';


/*
---------------------------------------------------------------------
의미 오류 - 불필요하게 복잡한 EXISTS (SELECT select-list)
---------------------------------------------------------------------
*/
IF EXISTS (SELECT DISTINCT OrderDate 
				FROM dbo.Orders
				WHERE OrderID <= 10260)
	SELECT 'OK'


   

/*
---------------------------------------------------------------------
의미 오류 - 불필요한 ORDER BY 속성(열)

	ORDER BY C1, ..., Cn

	* 만일 C1, ..., C(n-1)까지가 UNIQUE 하다면 Cn은 불필요
---------------------------------------------------------------------
*/
SELECT 
	OrderID, ProductID, UnitPrice
FROM 
	dbo.[Order Details] 
ORDER BY 
	OrderID, ProductID, UnitPrice;



/*
=====================================================================
그 외 유형
*/

	/*
	혹은

	WHERE ProductName LIKE '%'
	동등.
	WHERE ProductName IS NOT NULL
	*/


/*
의미 오류) 비효율적인 HAVING
*/
SELECT 
	ShipCountry, COUNT(*)
FROM 
	dbo.Orders
GROUP BY 
	ShipCountry
HAVING 
	ShipCountry IN ('USA', 'Switzerland')



/*
의미 오류) 비효율적인 UNION --> UNION ALL로 대체 가능
				(두 결과의 중복 데이터가 없다면)
*/
SELECT 
	OrderID, OrderDate
FROM 
	dbo.Orders
WHERE 
	OrderID <= 10250
UNION 
SELECT 
	OrderID, OrderDate
FROM 
	dbo.Orders
WHERE 
	OrderID >= 11070;



/*
---------------------------------------------------------------------
의미 오류 - 불필요한 조인 테이블
---------------------------------------------------------------------
*/
SELECT 
	o.OrderID, o.OrderDate
FROM 
	EPlan.dbo.BigOrders AS o					-- 자식
INNER JOIN EPlan.dbo.Customers AS c			-- 부모
	ON o.CustomerID = c.CustomerID	      -- 참조무결성
WHERE 
	o.OrderID = 10250;


   
/*
---------------------------------------------------------------------
의미 오류 - NOT IN과 NULL
---------------------------------------------------------------------
*/
SELECT 
	e.EmployeeID
FROM 
	dbo.Employees AS e
WHERE 
	e.EmployeeID NOT IN (SELECT m.ReportsTo 
								FROM dbo.Employees AS m);


/*
---------------------------------------------------------------------
사례-의미오류 샘플
---------------------------------------------------------------------
*/
--서브쿼리 내 잘못된 외부 열 참조
SELECT 
	OrderDate
FROM 
	dbo.Orders
WHERE 
	OrderID IN (SELECT OrderID FROM dbo.Customers);


-- 원하는 결과인가?
SELECT 50 OrderID
FROM dbo.Orders
WHERE CustomerID = 'QUICK'
ORDER BY OrderDate;


--INNER 조인에 해당하는 OUTER 조인 --> 참 많은 케이스
SELECT
	m.EmployeeID AS RptsTo, m.LastName, e.EmployeeID, e.Title
FROM 
	dbo.Employees As m
LEFT JOIN 
	dbo.Employees AS e ON m.EmployeeID = e.ReportsTo
WHERE 
	e.Title = 'Sales Manager';



/*
끝~
*/









