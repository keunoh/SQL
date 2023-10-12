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
1��. �⺻ �������
=====================================================================
*/
USE EPlanHeap;
GO


/*
---------------------------------------------------------------------
���� ��ȹ���� Index ��� ���� Ȯ��
Page IO �� Ȯ��
---------------------------------------------------------------------
*/
-- �׷��� "���� �����ȹ ����"
SELECT s.SupplierID, p.ProductID, p.ProductName, p.UnitPrice 
FROM dbo.Suppliers AS s INNER JOIN dbo.Products AS p
  ON s.SupplierID = p.SupplierID
WHERE p.SupplierID = 2


-- Page IO �� Ȯ��
SET STATISTICS IO ON;



/*
---------------------------------------------------------------------
��ȯ��Ģ, ���չ�Ģ
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
��¥�ð� ��� ����, char vs. varchar ����
---------------------------------------------------------------------
*/
DECLARE @d datetime = '20210615 23:59:59.999'
SELECT @d;


/*
���ڿ� ��. char vs. varchar 
*/
DECLARE @varchar varchar(8), @char char(8)
SELECT @varchar = 'sql   ', @char = 'sql   '

IF ( @varchar = 'sql' ) 
	PRINT '����'

IF ( @char = 'sql' ) 
	PRINT '����'

IF ( @varchar = @char )
	PRINT '����'



/*
---------------------------------------------------------------------
���� ���� vs. �˻� ����
---------------------------------------------------------------------
*/
SELECT 
	o.OrderID, o.CustomerID, * 
FROM
	dbo.Customers AS c
LEFT JOIN
	dbo.Orders AS o ON c.CustomerID = o.CustomerID
	AND o.CustomerID IS NULL	/* �� ������ ��ġ�� ��� �� ���ΰ�? */
WHERE
	c.CustomerID IN ('FISSA', 'PARIS', 'ANTON')
		



/*
---------------------------------------------------------------------
�ǹ̿���
---------------------------------------------------------------------
*/
USE Northwind;
GO


/*
---------------------------------------------------------------------
�ǹ� ���� - ��� ����
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
		ISNULL(OrderID, 0) = 10250;	-- ���� ����


	SELECT
		OrderID, ProductID
	FROM 
		dbo.[Order Details]
	WHERE 
		Quantity < 0;	-- CHECK (Quantity>(0))


		EXEC sp_helpconstraint N'dbo.[Order Details]';


/*
---------------------------------------------------------------------
�ǹ� ���� - �Ͻ����� or ���� �ݺ� or ����� ���ǽ� ����
---------------------------------------------------------------------
*/
SELECT 
	OrderDate
FROM 
	dbo.Orders
WHERE 
	ShipVia > 4 OR ShipVia > 2;


	/*
	�׸��� ��
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


	-- ������ SQL�� ǥ���ϸ�
	SELECT OrderID, OrderDate
	FROM dbo.Orders
	WHERE OrderID IN (SELECT DISTINCT val
							FROM (
								VALUES (10248), (10250), (10250), (10250)
							) AS d(val));


/*
---------------------------------------------------------------------
�ǹ� ���� - ���ʿ��� DISTINCT
---------------------------------------------------------------------
*/
SELECT DISTINCT 
	CustomerID, CompanyName, ContactName
FROM 
	dbo.Customers;


/*
---------------------------------------------------------------------
�ǹ� ���� - ��� �� ��� Ȥ�� ���ʿ��� * ���
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
�ǹ� ���� - wildcard ���� LIKE ������ (���� ����� ����)
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
�ǹ� ���� - ���ʿ��ϰ� ������ EXISTS (SELECT select-list)
---------------------------------------------------------------------
*/
IF EXISTS (SELECT DISTINCT OrderDate 
				FROM dbo.Orders
				WHERE OrderID <= 10260)
	SELECT 'OK'


   

/*
---------------------------------------------------------------------
�ǹ� ���� - ���ʿ��� ORDER BY �Ӽ�(��)

	ORDER BY C1, ..., Cn

	* ���� C1, ..., C(n-1)������ UNIQUE �ϴٸ� Cn�� ���ʿ�
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
�� �� ����
*/

	/*
	Ȥ��

	WHERE ProductName LIKE '%'
	����.
	WHERE ProductName IS NOT NULL
	*/


/*
�ǹ� ����) ��ȿ������ HAVING
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
�ǹ� ����) ��ȿ������ UNION --> UNION ALL�� ��ü ����
				(�� ����� �ߺ� �����Ͱ� ���ٸ�)
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
�ǹ� ���� - ���ʿ��� ���� ���̺�
---------------------------------------------------------------------
*/
SELECT 
	o.OrderID, o.OrderDate
FROM 
	EPlan.dbo.BigOrders AS o					-- �ڽ�
INNER JOIN EPlan.dbo.Customers AS c			-- �θ�
	ON o.CustomerID = c.CustomerID	      -- �������Ἲ
WHERE 
	o.OrderID = 10250;


   
/*
---------------------------------------------------------------------
�ǹ� ���� - NOT IN�� NULL
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
���-�ǹ̿��� ����
---------------------------------------------------------------------
*/
--�������� �� �߸��� �ܺ� �� ����
SELECT 
	OrderDate
FROM 
	dbo.Orders
WHERE 
	OrderID IN (SELECT OrderID FROM dbo.Customers);


-- ���ϴ� ����ΰ�?
SELECT 50 OrderID
FROM dbo.Orders
WHERE CustomerID = 'QUICK'
ORDER BY OrderDate;


--INNER ���ο� �ش��ϴ� OUTER ���� --> �� ���� ���̽�
SELECT
	m.EmployeeID AS RptsTo, m.LastName, e.EmployeeID, e.Title
FROM 
	dbo.Employees As m
LEFT JOIN 
	dbo.Employees AS e ON m.EmployeeID = e.ReportsTo
WHERE 
	e.Title = 'Sales Manager';



/*
��~
*/









