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
2��. Non-SARG Ʃ��
=====================================================================
*/
USE EPlanHeap;
GO

SET STATISTICS IO ON;


/*
����. ���� ���� ��� ������Ʈ

  UPDATE STATISTICS dbo.Orders;
  UPDATE STATISTICS dbo.[Order Details];
*/


/*
-------------------------------------------------------------
Non-SARG
-------------------------------------------------------------
*/

/*
���ʿ��� Į�� ����
*/
-- I/O ��
SELECT CategoryID, CategoryName FROM dbo.Categories
go

SELECT * FROM dbo.Categories
go

SELECT OrderID FROM dbo.Orders
go

SELECT OrderID, OrderDate FROM dbo.Orders
go


/*
(Index��) ���ʿ��� ������ ���
*/
SELECT OrderID, OrderDate, CustomerID 
FROM dbo.Orders
WHERE OrderID <> 10250


/*
(Index��) ���ǽ� �÷� ����
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
(Index��) ���ǽ� �÷� �Լ� ����
*/
-- 1. Substring, Left, Right
SELECT OrderID, OrderDate, CustomerID
FROM Northwind.dbo.Orders
WHERE SUBSTRING(CustomerID, 1, 3) = 'CEN'

   --���� ����
	SELECT OrderID, OrderDate, CustomerID
	FROM Northwind.dbo.Orders
	WHERE CustomerID LIKE 'CEN%'


-- 2. Convert
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE CONVERT(varchar(8), OrderDate, 112) = '19960704'

   --���� ����
	SELECT OrderID, OrderDate, CustomerID 
	FROM Northwind.dbo.Orders
	WHERE OrderDate >= '19960704' AND OrderDate < '19960705'


-- 3. datediff vs. dateadd
SELECT OrderID, ShippedDate, CustomerID
FROM Northwind.dbo.Orders
WHERE DateDiff(dd, ShippedDate, '19980506') <= 1

   --���� ����
   SELECT OrderID, ShippedDate, CustomerID 
   FROM Northwind.dbo.Orders
   WHERE ShippedDate >= DATEADD(dd, -1, '19980506')


-- 4. ISNULL
SELECT *
FROM Northwind.dbo.Orders
WHERE ISNULL(OrderDate, '19970702') = '19970702'

   --���� ����
	SELECT *
	FROM Northwind.dbo.Orders
	WHERE (OrderDate = '19970702' OR OrderDate IS NULL)
 


/*
(Index��) �Ͻ��� �� ��ȯ
*/
----------------------------------
-- char_column vs. ������
----------------------------------
SELECT stor_id, stor_name
FROM Pubs.dbo.Stores
WHERE stor_id >= 6380	-- Convert([stores].[stor_id]) = Convert([@1])

	-- vs.
	SELECT stor_id, stor_name
	FROM Pubs.dbo.Stores
	WHERE stor_id >= '6380'	



/*
(Index��) �߸��� LIKE ����
*/
-- ����
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE CustomerID LIKE 'CE%'

-- 1) ���ʿ��� LIKE
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE CustomerID LIKE 'VINET'

   SELECT OrderID, OrderDate, CustomerID 
   FROM Northwind.dbo.Orders
   WHERE CustomerID = 'VINET'

-- 2) %�� ����
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE CustomerID LIKE '%CE%'

-- 3) ���ڿ�
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE OrderID LIKE '1024%'

-- 4) ��¥�ð� ��
SELECT OrderID, OrderDate, CustomerID 
FROM Northwind.dbo.Orders
WHERE OrderDate LIKE '05% 1998%'



/*
�� �� ��
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
������ ���ȭ �̽�
------------------------------------------
*/
/*
1) Index�� ���ǿ� ���ú���
*/
USE EPlanHeap
GO

-- ���
SELECT * FROM dbo.Orders WHERE OrderID <= 10248;

-- ���ú���
DECLARE @ID int = 10248;
-- PK + = ����
SELECT * FROM dbo.Orders WHERE OrderID = @ID; 
-- �������� or Unique ���� ���� ���
SELECT * FROM dbo.Orders WHERE OrderID <= @ID; 


/*
2) Index�� ���ǿ� ����� ���� �Լ�
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

-- SQLServer2019�� TSQL_SCALAR_UDF_INLINING ��� ���� ��
OPTION (USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'));



/*
����. ���̺� ������ ����ȭ
*/
USE EPlanHeap;

-- �Ϲ� ���̺� 
SELECT TOP(5) *
FROM dbo.Orders AS o INNER JOIN dbo.[Order Details] AS d
   ON o.OrderID = d.OrderID
WHERE d.ProductID < 2
GO


-- ���̺� ����
DECLARE @Orders table (
   OrderID int PRIMARY KEY, OrderDate datetime 
);
INSERT @Orders
SELECT OrderID, OrderDate FROM Orders

SELECT TOP(5) *
FROM [Order Details]  AS d INNER JOIN @Orders AS o 
   ON o.OrderID = d.OrderID
WHERE d.ProductID <  2

-- ������Ʈ: SQL Server 2019 EE�� �ڵ� Ʃ�� ��� ���� �� ��
OPTION(USE HINT('DISABLE_DEFERRED_COMPILATION_TV'));



/*
����
*/
DROP FUNCTION IF EXISTS dbo.uf_OrderNo;
GO

