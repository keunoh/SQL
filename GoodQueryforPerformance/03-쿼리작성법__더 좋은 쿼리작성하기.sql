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
3장. 더 좋은 쿼리 작성하기
=====================================================================
*/
USE Northwind
GO

SET STATISTICS IO ON

/*
-------------------------------------------------------------
IN vs. BETWEEN
-------------------------------------------------------------
*/
-- IN 이해
-- Nonclustered Index(PK, OrderID)
SELECT * 
FROM EPlanHeap.dbo.Orders 
WHERE OrderID IN (10248, 10249, 10250, 10251
					 , 10252, 10253)
GO

-- BETWEEN 이해
SELECT * 
FROM EPlanHeap.dbo.Orders 
WHERE OrderID BETWEEN 10248 AND 10253
GO



/*
-------------------------------------------------------------
TOP + ORDER BY 절 주의
*/
SELECT TOP(5) Quantity, OrderID, ProductID
FROM EPlan.dbo.[Order Details]
ORDER BY Quantity DESC;

   SELECT TOP(12) Quantity, OrderID, ProductID
   FROM EPlan.dbo.[Order Details]
   ORDER BY Quantity DESC--, OrderID ASC;



/*
-------------------------------------------------------------
집계함수와 GROUP BY
-------------------------------------------------------------
*/

/*
-------------------------------------------------------------
COUNT vs. EXISTS
*/
USE EPlan
GO

CREATE INDEX IX_OD_Quantity
ON EPlan.dbo.[Order Details] (Quantity)
GO

-- I/O 비교
IF (SELECT COUNT(*) 
	FROM Eplan.dbo.[Order Details] 
	WHERE Quantity > 50) > 0

  PRINT '있을까 없을까?'
GO

IF EXISTS (SELECT * 
		FROM Eplan.dbo.[Order Details] 
		WHERE Quantity > 50)

  PRINT '있을까 없을까?'


-- 정리
DROP INDEX IX_OD_Quantity ON EPlan.dbo.[Order Details];



/*
-------------------------------------------------------------
NULL 고려한 집계 연산
*/
USE EPlan
GO

CREATE INDEX IX_BigOrders_Freight
ON EPlan.dbo.BigOrders (Freight)
GO


SELECT SUM(Freight) FROM dbo.BigOrders
GO
SELECT SUM(Freight) FROM dbo.BigOrders
WHERE Freight IS NOT NULL
GO

SELECT MIN(Freight) FROM dbo.BigOrders;
GO
SELECT MIN(Freight) FROM dbo.BigOrders
WHERE Freight IS NOT NULL


DROP INDEX IX_BigOrders_Freight ON EPlan.dbo.BigOrders;



/*
불필요한 GROUP BY 열 제거
*/
SELECT c.CustomerID, CompanyName, COUNT(*)
FROM dbo.Customers AS c INNER JOIN dbo.Orders AS o
		ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, CompanyName
GO

SELECT c.CustomerID, MAX(CompanyName), COUNT(*)
FROM dbo.Customers AS c INNER JOIN dbo.Orders AS o
		ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID



/*
-------------------------------------------------------------
UNION vs. UNION ALL
-------------------------------------------------------------
*/
SELECT firstname, city
 FROM Northwind.dbo.Employees
UNION
SELECT companyname, city
 FROM Northwind.dbo.Customers
GO

SELECT firstname, city
 FROM Northwind.dbo.Employees
UNION ALL
SELECT companyname, city
 FROM Northwind.dbo.Customers



/*
-------------------------------------------------------------
UPDATE SET 
-------------------------------------------------------------
*/
DECLARE @OrderDate datetime;

BEGIN TRAN
   SELECT @@trancount;

   UPDATE dbo.Orders
   SET @OrderDate = OrderDate = OrderDate + 365
   WHERE OrderID = 10248;

   SELECT @OrderDate;

ROLLBACK


/*
-------------------------------------------------------------
DML OUTPUT
*/
BEGIN TRAN
   SELECT @@trancount;

   UPDATE dbo.Orders
   SET OrderDate = OrderDate + 365
   OUTPUT 'inserted', inserted.*, 'deleted', deleted.*
   WHERE OrderID = 10248;

ROLLBACK



/*
-------------------------------------------------------------
JOIN
-------------------------------------------------------------
*/
/*
-------------------------------------------------------------
재미난 퀴즈
-------------------------------------------------------------
*/
SELECT *
FROM dbo.Orders AS o 
INNER JOIN dbo.[Order Details] AS d
   ON o.OrderID = d.OrderID
WHERE o.OrderID <= 10249

SELECT *
FROM dbo.Orders AS o 
INNER JOIN dbo.[Order Details] AS d
   ON o.OrderID = d.OrderID
WHERE d.OrderID <= 10249


/*
-------------------------------------------------------------
중첩 반복(Nested Loop) JOIN 기본
*/
CREATE INDEX IX_BigOrders_CustomerID
ON dbo.BigOrders(CustomerID);
GO

SELECT c.CustomerID, c.CompanyName, o.OrderID, o.OrderDate
FROM dbo.Customers AS c INNER JOIN dbo.BigOrders AS o
    ON c.CustomerID = o.CustomerID
WHERE c.CustomerID IN ('VINET', 'VICTE');



/*
-------------------------------------------------------------
Outer Join - 조인 순서 유도
*/
SELECT s.SupplierID, p.ProductID, p.ProductName, p.UnitPrice 
FROM dbo.Suppliers AS s INNER JOIN dbo.Products AS p
  ON s.SupplierID = p.SupplierID
WHERE p.SupplierID = 2


SELECT s.SupplierID, p.ProductID, p.ProductName, p.UnitPrice 
FROM dbo.Suppliers AS s RIGHT OUTER JOIN dbo.Products AS p
  ON s.SupplierID = p.SupplierID
WHERE p.SupplierID = 2



/*
-------------------------------------------------------------
예제 - 언제 Subquery를 사용할 것인가?
-------------------------------------------------------------
*/
USE EPlan

-- 기본 조인
SELECT DISTINCT c.CompanyName
FROM dbo.Customers AS c INNER JOIN dbo.BigOrders AS o
ON c.CustomerID = o.CustomerID
GO


-- 서브쿼리
SELECT c.CompanyName
FROM dbo.Customers AS c
WHERE EXISTS (SELECT *
   FROM dbo.BigOrders AS o
   WHERE c.CustomerID = o.CustomerID)



/*
---------------------------------------------------------------------
파생테이블(인라인 뷰), CTE, APPLY
---------------------------------------------------------------------
*/
/*
예제 - SELECT절 Subquery 중복 IO
*/
SELECT OrderID
,  (
   SELECT COUNT(*) FROM dbo.[Order Details] AS d
   WHERE d.OrderID = o.OrderID
   ) AS OrderCnt
,  (
    SELECT SUM(Quantity) FROM dbo.[Order Details] AS d
   WHERE d.OrderID = o.OrderID
   ) AS QuantitySum

FROM dbo.Orders AS o
WHERE OrderID = 10248;


/*
---------------------------------------------------------------------
1) 파생테이블(인라인 뷰)을 이용한 경우
---------------------------------------------------------------------
*/
SELECT o.OrderID, OrderCnt, QuantitySum
FROM dbo.Orders AS o
LEFT JOIN (
   SELECT OrderID
      ,  COUNT(*) AS OrderCnt
      ,  SUM(Quantity) AS QuantitySum
   FROM dbo.[Order Details] AS d
   GROUP BY OrderID
   ) AS d
ON d.OrderID = o.OrderID
WHERE o.OrderID = 10248;



/*
---------------------------------------------------------------------
2) CTE를 이용한 경우
---------------------------------------------------------------------
*/
WITH ODSum(OrderID, OrderCnt, QuantitySum)
AS
(
   SELECT OrderID
      ,  COUNT(*)
      ,  SUM(Quantity) 
   FROM dbo.[Order Details] AS d
   GROUP BY OrderID
)
SELECT o.OrderID, OrderCnt, QuantitySum
FROM dbo.Orders AS o
LEFT JOIN ODSum AS d
	ON d.OrderID = o.OrderID
WHERE o.OrderID = 10248;



/*
---------------------------------------------------------------------
3) (CROSS|OUTER) APPLY를 활용한 방법
---------------------------------------------------------------------
*/
SELECT o.OrderID, OrderCnt, QuantitySum
FROM dbo.Orders AS o
OUTER APPLY (
   SELECT 
         COUNT(*) AS OrderCnt
      ,  SUM(Quantity) AS QuantitySum
   FROM dbo.[Order Details] AS d
   WHERE d.OrderID = o.OrderID
   ) AS d
WHERE o.OrderID = 10248;



/*
----------------------------------------------------------------------------
CASE 내 Subquery 문제
*/
SELECT
	OrderID, 
	CASE (SELECT Country FROM dbo.Customers cu WHERE cu.CustomerID = oh.CustomerID) 
		WHEN 'Germany' THEN 'Germany'    
		WHEN 'Mexico' THEN 'Mexico'
		WHEN 'UK' THEN 'UK'
		ELSE 'N/A'    
	END
FROM dbo.Orders AS oh
WHERE OrderID <= 10250;


/*
권장 - Subquery 내 CASE
*/
SELECT
	OrderID, 
	(SELECT CASE Country 
				WHEN 'Germany' THEN 'Germany'    
				WHEN 'Mexico' THEN 'Mexico'
				WHEN 'UK' THEN 'UK'
				ELSE 'N/A'    
			END	
	FROM dbo.Customers cu 
	WHERE cu.CustomerID = oh.CustomerID) AS Country
FROM dbo.Orders AS oh
WHERE OrderID <= 10250;


/*
-------------------------------------------------------------
CTE 재귀호출
*/
/*
SELECT EmployeeID, ReportsTo, * FROM dbo.Employees;
*/
WITH RCTE
AS 
(
   SELECT e.EmployeeID, e.ReportsTo, e.Title
   FROM dbo.Employees AS e
   WHERE e.EmployeeID = 9

   UNION ALL

   SELECT e.EmployeeID, e.ReportsTo, e.Title
   FROM dbo.Employees AS e INNER JOIN RCTE AS r
      ON e.EmployeeID = r.ReportsTo
)
SELECT *
FROM RCTE;


/*
-------------------------------------------------------------
잠금 차단 고려 – 두 가지 선택지
-------------------------------------------------------------
*/
