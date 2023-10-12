/*
*********************************************************************
SW �����ڸ� ���� ���� ���� ���� �ۼ���

�ۼ���: ������ (jskim@sqlroad.com)
        (��)������ ��ǥ������Ʈ/�̻�
        Microsoft Data Platform MVP


���⿡ ���� �ڵ�� �������� ���� ���� ���ؼ� �����Ǵ� ���̸� 
�� �� � �����̳� å�ӵ� �����ϴ�. �׽�Ʈ�� ������ ������ � �뵵��
�ڵ带 ����� ��� ���Ǹ� ���մϴ�.

*********************************************************************
*/

/*
=====================================================================
4��. Ŀ��, ��, �Լ�
=====================================================================
*/
USE EPlan
GO

SET STATISTICS IO ON


/*
------------------------------------------------------------
Cursor ��� ���� ����
-------------------------------------------------------------
*/
-- 1) Cursor�� �̿��� Pivoting
SET NOCOUNT ON
GO

IF OBJECT_ID('tempdb.dbo.#Order_Cnt') IS NOT NULL
	DROP TABLE #Order_Cnt

CREATE TABLE #Order_Cnt (
  EmpID  int
, Emp_Cnt  int
, France   int
, Germany  int
, Argentina   int
)

DECLARE EmployeeInfo CURSOR
FOR SELECT DISTINCT EmployeeID FROM dbo.Orders

OPEN EmployeeInfo

DECLARE @EmployeeID int
FETCH NEXT FROM EmployeeInfo INTO @EmployeeID
WHILE @@FETCH_STATUS = 0
BEGIN
  
	INSERT #Order_Cnt
	SELECT 
			@EmployeeID
	  , Emp_Cnt = (SELECT COUNT(EmployeeID) 
	                FROM dbo.Orders    
	                WHERE EmployeeID = @EmployeeID
	                  AND ShipCountry IN ('France', 'Germany', 'Argentina') )

	  , [France] = ( SELECT COUNT(EmployeeID) 
	                 FROM dbo.Orders   
	                 WHERE EmployeeID = @EmployeeID
							AND ShipCountry = 'France' )
	
	  , [Germany] = (SELECT COUNT(EmployeeID) 
	                 FROM dbo.Orders   
	                 WHERE EmployeeID = @EmployeeID
							AND ShipCountry = 'Germany' )  
	
	  , [Argentina] = (SELECT COUNT(EmployeeID) 
	                 FROM dbo.Orders 
	                 WHERE EmployeeID = @EmployeeID
							AND ShipCountry = 'Argentina' )  

  FETCH NEXT FROM EmployeeInfo INTO @EmployeeID
END

CLOSE EmployeeInfo
DEALLOCATE EmployeeInfo

SELECT * FROM #Order_Cnt
ORDER BY EmpID;

SET NOCOUNT OFF
GO


/*
2) T-SQL: CASE + GROUP BY�� ������ ���
*/
SELECT EmployeeID
	, EmpCnt = COUNT(EmployeeID)
	, [France]= COUNT(CASE ShipCountry WHEN 'France' THEN 1 END)
	, [Germany] = COUNT(CASE ShipCountry WHEN 'Germany' THEN 1 END)
	, [Argentina] = COUNT(CASE ShipCountry WHEN 'Argentina' THEN 1 END)
FROM Orders 
WHERE 
	ShipCountry IN ('France', 'Germany', 'Argentina')
GROUP BY EmployeeID
ORDER BY EmployeeID;


/*
3) T-SQL: PIVOT ���� ������ ���
*/
SELECT EmployeeID
	, EmpCnt = [France]+[Germany]+[Argentina]
	, [France], [Germany], [Argentina]
FROM (
	SELECT EmployeeID, ShipCountry 
	FROM Orders
) AS Orders
PIVOT (
	COUNT(ShipCountry) FOR ShipCountry IN ([France], [Germany], [Argentina])
) AS Pivots
ORDER BY EmployeeID;



/*
-------------------------------------------------------------
--  Row to Column
-------------------------------------------------------------
*/
SELECT CustomerID
FROM Northwind.dbo.Orders
WHERE OrderID <= 10250;


-- STRING_AGG() Ȱ�� - 2017+
SELECT STRING_AGG(CustomerID, ',') AS CustomerIDs 
FROM Northwind.dbo.Orders
WHERE OrderID <= 10250;



/*
-------------------------------------------------------------
Curosr �ɼ� ����
*/
USE Northwind;
GO

ALTER TABLE Products
  ADD ProductTotalQty int 
GO


/*
1) �⺻ Cursor
*/
DECLARE ProductQty CURSOR
FOR SELECT ProductID, Quantity FROM dbo.[Order Details]

OPEN ProductQty

DECLARE @ProductID int, @Quantity int
FETCH NEXT FROM ProductQty INTO @ProductID, @Quantity
WHILE @@FETCH_STATUS = 0
BEGIN
    
   UPDATE Products
   SET ProductTotalQty = ISNULL(ProductTotalQty, 0) + @Quantity
   WHERE ProductID = @ProductID

   FETCH NEXT FROM ProductQty INTO @ProductID, @Quantity
END

CLOSE ProductQty
DEALLOCATE ProductQty
GO

-- Ȯ��
SELECT ProductTotalQty, * FROM dbo.Products;


/*
2) Local + FAST_FORWARD
*/
DECLARE ProductQty CURSOR LOCAL FAST_FORWARD -- FAST_FORWARD or FORWARD_ONLY STATIC READ_ONLY
FOR SELECT ProductID, Quantity FROM dbo.[Order Details]

OPEN ProductQty

DECLARE @ProductID int, @Quantity int
FETCH NEXT FROM ProductQty INTO @ProductID, @Quantity
WHILE @@FETCH_STATUS = 0
BEGIN
    
   UPDATE Products
   SET ProductTotalQty = ProductTotalQty + @Quantity
   WHERE ProductID = @ProductID

   FETCH NEXT FROM ProductQty INTO @ProductID, @Quantity
END

CLOSE ProductQty
DEALLOCATE ProductQty
GO

-- ����
ALTER TABLE Products
  DROP COLUMN ProductTotalQty;



/*
-------------------------------------------------------------
View
-------------------------------------------------------------
*/
USE Northwind
GO

/*
�� - ���� ��
*/
CREATE OR ALTER VIEW dbo.vi_Orders
AS
SELECT o.OrderID, o.CustomerID, o.OrderDate, e.LastName
  ,  c.CompanyName, c.Address
FROM dbo.Customers AS c 
  INNER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID
  INNER JOIN dbo.Employees AS e
    ON e.EmployeeID = o.EmployeeID
GO

-- View vs. Join
SELECT OrderID, CustomerID, OrderDate
FROM dbo.vi_Orders
GO

SELECT o.OrderID, o.CustomerID, o.OrderDate
FROM dbo.Orders AS o


/*
�� - View ������ Index �� ���� ����
*/
CREATE OR ALTER VIEW dbo.vTest
AS
SELECT OrderID
   ,  CONVERT(varchar(10), OrderDate, 112) AS OrderDay
   ,  OrderDate
FROM dbo.Orders
GO

SELECT *
FROM dbo.vTest A
WHERE OrderDay = '19960704';



/*
-------------------------------------------------------------
User Defined Function
-------------------------------------------------------------
*/
/*
-------------------------------------------------------------
Scalar Function ����
*/
USE Northwind
GO

CREATE OR ALTER FUNCTION dbo.fn_OrderSum
( @ProductID int )
RETURNS int
AS
BEGIN
  RETURN (
    SELECT SUM(Quantity)
    FROM [Order Details]
    WHERE ProductID = @ProductID
  )
END
GO


/*
  �������� ��ü I/O ��
*/
SELECT SUM(Quantity)
    FROM [Order Details]
    WHERE ProductID = 1

--'Order Details' ���̺�. ��ĵ �� 1, ���� �б� �� 11, ������ �б� �� 0, �̸� �б� �� 0.

/*
SELECT ������ �Լ� ȣ�� �� I/O
*/
SELECT ProductName, dbo.fn_OrderSum(ProductID)
FROM dbo.Products
WHERE ProductID <= 5
--���̺� 'Products'. �˻� �� 1, ���� �б� �� 2, ������ �б� �� 1, �̸� �б� �� 0, LOB ���� �б� �� 0, LOB ������ �б� �� 0, LOB �̸� �б� �� 0.

--/* SQL Server 2019 "TSQL_SCALAR_UDF_INLINING" ��� ���� ����
OPTION(USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'))  
--*/


/*
vs. �Լ����� �������� ���� ó���� ���
*/
SELECT ProductName
  , ( SELECT SUM(Quantity)
       FROM [Order Details] d 
       WHERE d.ProductID = p.ProductID )
FROM dbo.Products AS p
WHERE ProductID <= 5

/*
�Ʒ� ����� �����ȹ�� ���̺� ������ ���� �޶���
*/
--���̺� 'Order Details'. ��ĵ �� 5, ���� �б� 55, ���� �б� 0, ������ ���� �б� 0, �̸� �б� �б� 0, ������ ���� �̸� �б� �б� 0, lob ���� �б� 0, lob ���� �б� 0, lob ������ ���� �б� 0, lob �̸� �б� �б� 0, lob ������ ���� �̸� �б� �б� 0.
--���̺� 'Products'. ��ĵ �� 1, ���� �б� 2, ���� �б� 0, ������ ���� �б� 0, �̸� �б� �б� 0, ������ ���� �̸� �б� �б� 0, lob ���� �б� 0, lob ���� �б� 0, lob ������ ���� �б� 0, lob �̸� �б� �б� 0, lob ������ ���� �̸� �б� �б� 0.



/*
-------------------------------------------------------------
Inline Table-Valued Function 
*/
CREATE OR ALTER FUNCTION dbo.if_Orders
( @date datetime )
RETURNS table
AS
RETURN 
    SELECT CustomerID, EmployeeID, COUNT(*) AS Cnt
    FROM   dbo.Orders
    WHERE  OrderDate >= @date
    GROUP BY CustomerID, EmployeeID
GO

SELECT * FROM dbo.if_Orders ('19980506');


/*
-------------------------------------------------------------
����
*/
DROP FUNCTION IF EXISTS dbo.fn_OrderSum;
DROP FUNCTION IF EXISTS dbo.if_Orders;


