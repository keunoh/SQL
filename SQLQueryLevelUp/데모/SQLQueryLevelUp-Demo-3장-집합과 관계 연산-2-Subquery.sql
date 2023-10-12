/*
*********************************************************************
SQL Query Level Up - Subquery

�ۼ���: ������ (jskim@sqlroad.com)
        (��)������ ��ǥ������Ʈ/�̻�


���⿡ ���� �ڵ�� �������� ���� ���� ���ؼ� �����Ǵ� ���̸� 
�� �� � �����̳� å�ӵ� �����ϴ�. �׽�Ʈ�� ������ ������ Ư�� �뵵��
�Ʒ� �ڵ带 ����� ��� ���Ǹ� ���մϴ�.

*********************************************************************
*/
USE Northwind
GO


/*
*******************************************************************************
��������
*******************************************************************************
*/

/*
*******************************************************************************
��ø (��Į��) ��������
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
�񱳿����ڿ� �� �̻��� ��ȯ ��
*/
SELECT 
	ProductID
,	UnitPrice
,	AvgPrice = (SELECT UnitPrice FROM dbo.[Order Details])
FROM	dbo.[Order Details] As od
WHERE	OrderID <= 10250;



/*
-------------------------------------------------------------------------------
��ø �������� - IN - �ߺ���, NULL ��
*/
SELECT 
	Region, * 
FROM	dbo.Customers
WHERE	Region IN ('WA', 'WA', 'SP', NULL)
;	



/*
-------------------------------------------------------------------------------
��ø �������� - IN ��������
*/
-- distinct ������
SELECT CompanyName
FROM dbo.Customers
WHERE	CustomerID IN (SELECT CustomerID 
							FROM dbo.Orders 
							WHERE ShipCountry = 'USA')
ORDER BY	CompanyName
;	


-- ����
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

							-- �Ʒ��� �������� �� ������ �̷��� �ۼ��� �ʿ䰡 ����^^
							UNION
							SELECT CustomerID
							FROM dbo.Orders AS o
							INNER JOIN dbo.[Order Details] AS d
								ON o.OrderID = d.OrderID
							WHERE d.ProductID = 1 AND Quantity >= 50
							);



/*
-------------------------------------------------------------------------------
NOT IN�� ��� ó���ǳ�?
*/
SELECT 
	Region, * 
FROM	dbo.Customers
WHERE	Region NOT IN ('SP', 'WA')
;	



/*
*******************************************************************************
��� ��������
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
SELECT ��
*/
-- �ڵ�� ���� (�θ� ���̺� ����)
SELECT
	CustomerID
,	CompanyName = (SELECT CompanyName 
						FROM dbo.Customers AS c
						WHERE c.CustomerID = o.CustomerID)
,	Freight
FROM dbo.Orders AS o
WHERE o.OrderDate >= DATEADD(dd, -7, '19980510');


-- ���谪 ����
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
WHERE �񱳿�����
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
EXISTS, IN, (NOT EXISTS, NOT IN�� ���ؼ��� "������ ���� ����"���� �ٷ�)
*/
SELECT c.CompanyName
FROM dbo.Customers AS c
WHERE c.Country = 'Sweden' 
	AND EXISTS (SELECT 1 
						FROM dbo.Orders AS o
						WHERE o.CustomerID = c.CustomerID
							AND o.EmployeeID IN (2, 3, 4));


-- EXIST ��� �����Լ� ����� ���
SELECT c.CompanyName
FROM dbo.Customers AS c
WHERE	c.Country = 'Sweden' 
	AND 0 < (SELECT COUNT(*)
				FROM dbo.Orders AS o
				WHERE o.CustomerID = c.CustomerID
					AND o.EmployeeID IN (2, 3, 4));


	/*
	EXISTS()���� ������ ����ؾ� �ϳ���?
	*/
	-- 0���� ������
	SELECT 1 / 0;

	-- ������ �߻��ұ�?
	IF EXISTS (SELECT 1 / 0 FROM dbo.Employees)
		SELECT 'OK';



/*
EXIST ��� IN ���
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
HAVING�� ��� �������� - �׷캰 �ִ밪/�ּҰ� ���
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
����-1) Row Number(�� ��ȣ) �ޱ� 
	- ������ ���� ��Ʈ (Self Join���� Ranking ���ϱ⵵ ����)
*/
-- OrderID = PK, ���ϰ��� ����
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
����-2) �׷캰 ���� N�� �˻�
	- ������ ���� ��Ʈ
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
�������� ���ǻ���
*******************************************************************************
*/
/*
---------------------------------------------------------------------
����-1) NOT IN�� ���ռ�
*/
SELECT 'OK'
WHERE '�մ���' NOT IN ('�����', '�ֹֽ�', NULL)

	-- �� �ٸ���? ��� �ٲ�°�?
	SELECT 'OK'
	WHERE '�մ���' <> '�����'	-- T or F?
		AND '�մ���' <> '�ֹֽ�'
		AND '�մ���' <> NULL			-- T or F?, ->>> Unknown


	-- �׷� ��� ó���ؾ��ϳ�? --> ���� ���� �������� �ٷ�


/*
-------------------------------------------------------------------------------
����-2) ���� ���̺� ���� �� ���� ��
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
���� �Ʒ� ����� UPDATE/DELETE ���ٸ�? - ���� ���

���) �������� �������� �ݵ�� �ش� ���̺� ��Ī ����
*/
SELECT * 
FROM dbo.Orders
WHERE OrderID IN (SELECT OrderID   -- ���̺� ��Ī �����ϱ�
						FROM dbo.Customers AS c);



/*
*******************************************************************************
�Ļ� ���̺�(Derived Table)
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
����-1) �⺻ ����
*/
SELECT *			-- Intellisense ���¿��� �� �̸� ����� �� ��
FROM 
(
	SELECT ProductID, QuantitySum = SUM(Quantity)
	FROM dbo.[Order Details] AS d
	WHERE ProductID IN (1, 2, 3)
	GROUP BY ProductID	
) AS p;


	/*
	ORDER BY �� ���� �� ����
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
����-2) Products ���̺��� ��ǰ�� �ܰ��� ���� Category�� ��մܰ� ���
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
����-3) Products ���̺��� ����� ���� 5��(Quantity * UnitPrice)�� ��ǰ�� ����
	��ǰ �ܰ��� 20% ����
*/
-- ���� 5�� ��ǰ
SELECT TOP(5) ProductID, AmountSum = SUM(Quantity * UnitPrice)
FROM dbo.[Order Details]
GROUP BY ProductID
ORDER BY AmountSum DESC;

-- 1�� ��ǰ �ܰ� ���, �񱳿�
SELECT ProductID, UnitPrice, UnitPrice * 0.8
FROM dbo.Products
WHERE ProductID = 38;

/*
Tip.
 - �Ʒ� Tx�� �ʿ��� ��� ROLLBACK��
 - UPDATE ��� SELECT�� ���� ���� Ȯ�� �� UPDATE �ϸ� ���� ����
*/
BEGIN TRAN

	UPDATE p
	SET p.UnitPrice = p.UnitPrice * 0.8
		-- �Ʒ� OUTPUT�� Ȯ�ο�
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
����-4) UNION�� ������ �Ļ����̺� --> �Ʒ��� ������ ǥ���ϴ� ������ 
*/
SELECT
	*
FROM 
(
	SELECT Flag = 1, Name = '�ܰ�', Data = UnitPrice 
	FROM dbo.[Order Details]
	WHERE UnitPrice IS NOT NULL
		AND OrderID <= 10250
	UNION ALL
	SELECT Flag = 2, '����', Data = Quantity 
	FROM dbo.[Order Details]
	WHERE Quantity IS NOT NULL
		AND OrderID <= 10250
) AS o
;


/*
-------------------------------------------------------------------------------
����-5) ��ø �Ļ����̺� - Paging ���� ���� (TOP + TOP ���)

���� - BigOrders�� NC Index�� ���
*/
USE Northwind
GO

DECLARE @PageNo int = 10, @PageSize int = 10;

/*
Step-1. 10��° page x 10�Ǿ� ��ü ������
*/
SELECT TOP (@PageNo * @PageSize)
	o.OrderID, o.OrderDate, o.CustomerID
FROM 
	dbo.BigOrders AS o
ORDER BY 
	o.OrderID DESC


/*
Step-2. ������ - ������ page�� 10��
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
Step-Last. �ٽ� ������ - ���� ���ļ������
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
����-1) �⺻ ����
*/
WITH OrderAggr
AS
(
	SELECT CustomerID, EmployeeID, OrderCount = COUNT(*)
	FROM dbo.Orders
	GROUP BY CustomerID, EmployeeID
)
SELECT *		-- Intellisense ���¿��� �� �̸� ����� �� ��
FROM OrderAggr
ORDER BY CustomerID ASC;



/*
-------------------------------------------------------------------------------
����-2) CTE + UPDATE
*/
-- 1�� ��ǰ �ܰ� ���, �񱳿�
SELECT ProductID, UnitPrice, UnitPrice * 0.8
FROM dbo.Products
WHERE ProductID = 38;


/*
Tip.
 - �Ʒ� Tx�� �ʿ��� ��� ROLLBACK��
 - UPDATE ��� SELECT�� ���� ���� Ȯ�� �� UPDATE �ϸ� ���� ����
*/
BEGIN TRAN

	/* ; �ʿ� */
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
		-- �Ʒ� OUTPUT�� Ȯ�ο�
		OUTPUT deleted.ProductID, deleted.UnitPrice, inserted.UnitPrice
	FROM dbo.Products AS p
	INNER JOIN ProductAmount AS t
		ON p.ProductID = t.ProductID;

	--COMMIT TRAN

IF @@trancount > 0 ROLLBACK TRAN
SELECT @@trancount;



/*
-------------------------------------------------------------------------------
����-3) ���� CTE(jskim: ��ø CTE) - Paging (TOP + TOP)
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
�� �ٸ� ������ ���� CTE
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
����-4) CTE ���� ����(Self Join) - ���� ���� ��
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
����-5) �� 5th �ֹ����� ����.

	���� ������, ���� 4�� �ֹ��� �Ѿ�(AmountPrevious) �������� 
		AmountPrevious < 10000.0 �̸� 5%
		AmountPrevious < 15000.0 �̸� 10%
		�� �̻��̸� 20%
*/
/*
���� ������ Ȯ�� - ���������� �� ��(QUICK)�� ������� ó��
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
1-����. ������ �ӽ� Table�� Ȱ���� ���
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
2) CTE�� Ȱ���� ���
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
��� CTE
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
����-1) ��� CTE - ���� ��Ʈ
*/
/*
���� ������ ����
*/
-- ���� ���� �� ������
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
1-1) ���� ��� �˻�
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
1-2) ��� ���� ����
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
-- Ư�� �������� ������ ���
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
	-- Ȥ�� ��� ȣ�� ������ ����, �ʰ� �� ���� 530 �߻�
	OPTION (MAXRECURSION 1);



/*
1-3) ���� ���� ���� ��� ����-1
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
1-4) ���� ���� ��� �����
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
	-- ���� ����^^
	REPLICATE('....', Lvl) + CAST(o.EmployeeID AS varchar(5))
,	Lvl
,	Sortby
FROM Organize AS o
ORDER BY SortBy;



/*
-------------------------------------------------------------------------------
����-2) ���ȣ�� CTE - Calender ������ ����
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
	WHERE YMD < DATEADD(day, -1, DATEADD(month, 1, @BOMonth))	-- ���� ��������
)
SELECT 
	YMD
,	Day = DATEPART(day, YMD)
,	DayofWeek = DATEPART(weekday, YMD)
,	WeekofMonth = DATEDIFF(week, @BOMonth, YMD) + 1	-- ���� ���� �Ϸ���^^
FROM Calendar;



/*
*******************************************************************************
APPLY
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
����-1) Cartesian Product
*/
SELECT 
	*
FROM 
	(VALUES ('A'), ('B')) AS P(c)
CROSS JOIN 
	(VALUES (1), (2), (3)) AS C(n)
;

/*
APPLY�� ǥ���ϸ�
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
����-2) SELECT�� ��ó����
*/
-- ��ó�� �ʿ��� ���
SELECT TOP(5)
	OrderID,	OrderYear = YEAR(OrderDate), OrderYear2 = OrderYear + 1
FROM dbo.Orders
WHERE OrderYear2 >= 1997;

-- APPLY ��ó��
SELECT TOP(5)
	OrderID,	OrderYear, OrderYear2
FROM dbo.Orders AS o
   CROSS APPLY (VALUES (YEAR(OrderDate))) AS y(OrderYear)
   CROSS APPLY (VALUES (y.OrderYear + 1)) AS y2(OrderYear2)
WHERE OrderYear2 >= 1997;



/*
-------------------------------------------------------------------------------
����-3) ���� �����Ϳ� ���� ���� ��� ����
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
����-4) ��/�� �� �� ����
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
����-5) ���̺� �� �Լ� ȣ�� 
*/
/*
�Ϲ� �Լ�
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
������ ���� ������
*******************************************************************************
*/

/*
1. NOT IN
2. NOT IN + �����������
3. NOT EXISTS + �����������
4. ��� �������� + IS NULL
5. OUTER JOIN + IS NULL
6. OUTER APPLY + IS NULL 
7. EXCEPT + (������) ��������(Ȥ��JOIN) 
*/

/*
������ �׽�Ʈ ����
*/
USE Northwind;
GO

-- 1.NOT IN
SELECT * FROM dbo.Customers AS c
WHERE CustomerID NOT IN (SELECT CustomerID FROM dbo.Orders)



-- 2.NOT IN + �����������
SELECT * FROM dbo.Customers AS c
WHERE CustomerID NOT IN (SELECT CustomerID FROM dbo.Orders AS o
									WHERE o.CustomerID = c.CustomerID)



-- 3.NOT EXISTS + ����������� 
SELECT * FROM dbo.Customers AS c
WHERE NOT EXISTS (SELECT CustomerID 
						FROM dbo.Orders AS o
						WHERE o.CustomerID = c.CustomerID)


-- 4.����������� + (TOP 1) + IS NULL
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



-- 7.EXCEPT + (������) ��������(Ȥ�� JOIN)
SELECT c.CustomerID FROM dbo.Customers c
EXCEPT
SELECT o.CustomerID FROM dbo.Orders o



/*
*******************************************************************************
���� �Լ�
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
ROW_NUMBER
*/
/*
1) ����
*/
SELECT TOP(20)
	OrderID
,	OrderDate
,	RowNo = ROW_NUMBER() OVER(ORDER BY OrderID ASC)
FROM dbo.Orders
ORDER BY OrderID ASC;

	/* 
	-- Tip. ���� ������ �ʿ� ���� ���
	ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
	or
	ROW_NUMBER() OVER(ORDER BY (SELECT 0))
	*/


/*
2) �׷캰(Partition) ����
*/
SELECT
	SupplierID
,	ProductID
,	RowNo = ROW_NUMBER() OVER(PARTITION BY SupplierID 
										ORDER BY ProductID ASC)
FROM dbo.Products;



/*
3) ���� ���� ��ȣ ã��
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
4) Paging ����
*/
DECLARE @PageNo int = 2, @PageSize int = 20;

-- �ֱ� �ֹ���ȣ ��
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
����) ���������� �̿��ؼ� �� ��ȣ �ޱ�� - Join, Subquery �������� �ٷ�
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
	- ������ Tile(Bucket, Group)�� ��� ���� �յ��ϰ� �Է�
	- ���� ���� ������ First-Tile-First�� �Է�
*/
/*
�׷�ȭ) SELECT 9 / 4, 9 % 4	-- 4-tile, 2-rows in each, 1-remainders
*/
DECLARE @num_tiles int = 4;

SELECT 
	EmpID = EmployeeID, Title, BirthDate
,	num_tiles = NTILE(@num_tiles) 
							OVER(ORDER BY Title DESC, BirthDate DESC)
FROM dbo.Employees;
GO

/*
��Ƽ�Ǻ� Tile
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
Paging ����
*/
DECLARE @PageNo int = 2, @PageSize int = 20;

-- �ֱ� �ֹ���ȣ ��
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

