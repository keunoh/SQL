/*
*********************************************************************
SQL Query Level Up - SELECT ����

�ۼ���: ������ (jskim@sqlroad.com)
        (��)������ ��ǥ������Ʈ/�̻�


���⿡ ���� �ڵ�� �������� ���� ���� ���ؼ� �����Ǵ� ���̸� 
�� �� � �����̳� å�ӵ� �����ϴ�. �׽�Ʈ�� ������ ������ Ư�� �뵵��
�Ʒ� �ڵ带 ����� ��� ���Ǹ� ���մϴ�.

*********************************************************************
*/
USE Northwind;
GO


/*
*******************************************************************************
����
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
���� - ������ ó�� ���� 

	--> SELECT/WHERE/ORDER BY�� ���� Ȯ��
*/
SELECT o.OrderID, Orders = YEAR(o.OrderDate)
FROM dbo.Orders AS o
ORDER BY Orders DESC
;




/*
*******************************************************************************
�ϰ� ó�� (Batch)
*******************************************************************************
*/
/*
���ú��� ����
*/
DECLARE @i int = 10
SELECT @i;

DECLARE @i int = 20
SELECT @i;


/*
����� ��ü ���� 
*/
/*
CREATE��?
*/
CREATE TABLE YKM(a int);
SELECT a FROM YKM;

/*
ALTER��?
*/
ALTER TABLE YKM 
	ADD b int

SELECT a, b FROM YKM;


/*
������ ����
*/
SELECT TOP(1) OrderID, OrderDate FROM Northwind.dbo.Orders;

SELECT TOP(1) PID FROM Northwind.dbo.Products;


/*
��Ÿ�� ����
*/
/*
1) ��� ����
*/
SELECT TOP(1) OrderID FROM Northwind.dbo.Orders;

SELECT 1 / 0;

SELECT TOP(1) ProductID FROM Northwind.dbo.Products;


/*
2) �������� ����
*/
SELECT TOP(1) OrderID FROM Northwind.dbo.Orders;

UPDATE TOP(1) Northwind.dbo.Products
SET UnitPrice = -1;

SELECT TOP(1) ProductID FROM Northwind.dbo.Products;


/*
3) ������ �� ��ȯ ����
*/
SELECT TOP(1) OrderID FROM Northwind.dbo.Orders;

UPDATE TOP(1) Northwind.dbo.Products
SET ProductName += CAST(80 AS int);

SELECT TOP(1) ProductID FROM Northwind.dbo.Products;


/*
EXEC ���
*/
sp_help 

sp_help 'sp_help'


/*
SSMS���� ���þ� ����
*/
SELECT 10;
GO


/*
�ݺ� ����
*/
CREATE TABLE #test_go (a int IDENTITY(1, 1));
GO

INSERT #test_go DEFAULT VALUES;
GO 10

SELECT * FROM #test_go;
DROP TABLE #test_go;





/*
*******************************************************************************
<SELECT-list>
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
���� ���� ó���� ����? �ϰ�?
*/
DECLARE @i int = 0, @j int = 0, @k int = 0;

SELECT TOP(1) @i = SupplierID, @j = @i + 10, @k = @j + 100
FROM dbo.Products
WHERE SupplierID = 1;

SELECT @i, @j, @k;


	-- �˻��� �Ҵ��� �Բ��ϸ�?
	SELECT TOP(1) SupplierID, @j = @i + 10, @k = @j + 100
	FROM dbo.Products;


/*
-------------------------------------------------------------------------------
��Į�� ������ 2�� �̻��� �� �Ҵ���?
*/
DECLARE @c nvarchar(100);
SET @c = '';

		SELECT CustomerID
		FROM Northwind.dbo.Orders
		WHERE OrderID <= 10250
		ORDER BY CustomerID ASC;

SELECT @c = CustomerID
FROM Northwind.dbo.Orders
WHERE OrderID <= 10250
ORDER BY CustomerID ASC;

SELECT @c;



/*
*******************************************************************************
ROW-TO-COLUMN
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
���ڿ� ������
*/
SELECT CustomerID
FROM Northwind.dbo.Orders
WHERE OrderID <= 10250;
GO


DECLARE @c nvarchar(100);
SET @c = '';

SELECT @c = @c + ',' + CustomerID
FROM Northwind.dbo.Orders
WHERE OrderID <= 10250;

SELECT STUFF(@c, 1, 1, ''), @c;


/*
-------------------------------------------------------------------------------
XML Ȱ��
*/
SELECT CustomerID
FROM Northwind.dbo.Orders
WHERE OrderID <= 10250
FOR XML PATH('');

SELECT ',' + CustomerID
FROM Northwind.dbo.Orders
WHERE OrderID <= 10250
FOR XML PATH('');



/*
-------------------------------------------------------------------------------
STRING_AGG() Ȱ�� - 2017+
*/
SELECT STRING_AGG(CustomerID, ',') AS CustomerIDs 
FROM Northwind.dbo.Orders
WHERE OrderID <= 10250;

SELECT 
	STRING_AGG(ISNULL(Region, 'N/A'), ',') AS Regions
,	STRING_AGG (Region, ',')
FROM Northwind.dbo.Employees;

SELECT 
	ReportsTo AS Boss
,	STRING_AGG (EmployeeID, '-') WITHIN GROUP (ORDER BY Title ASC) AS empid
FROM Northwind.dbo.Employees
GROUP BY ReportsTo;



/*
*******************************************************************************
FORMAT �Լ� �Ϲ� (.NET Format) - ���� ���� ���
*******************************************************************************
*/
DECLARE @d datetime = GETDATE();

SELECT FORMAT(@d, 'dddd', 'ko-KR');

SELECT FORMAT(@d, N'D'), FORMAT(@d, N'D', N'en-US')

SELECT FORMAT(28000000, 'C');
SELECT FORMAT(28000000, 'C', 'en-US');

SELECT FORMAT(1234.56, '+#0.00;-#0.00;0');
SELECT FORMAT(0, '+#0.00;-#0.00;Zero');
SELECT FORMAT(-1234.56, '+#0.00;-#0.00;Zero');
-- ��Ÿ ������ ���Ŀ��� �ٷ�



/*
*******************************************************************************
����
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
bit 
*/
SELECT TOP(5) * FROM pubs.dbo.authors
WHERE Contract = 1;

SELECT TOP(5) * FROM pubs.dbo.authors
WHERE Contract = CAST(2 AS bit);

SELECT TOP(5) * FROM pubs.dbo.authors
WHERE Contract = CAST('true' AS bit);

SELECT TOP(5) * FROM pubs.dbo.authors
WHERE Contract = CAST('false' AS bit);


/*
-------------------------------------------------------------------------------
���� - bit masking
*/
-- POWER(2����, (�ڸ���-1))
SELECT POWER(2, (1-1));
SELECT POWER(2, (2-1));
SELECT POWER(2, (3-1));
SELECT POWER(2, (4-1));
SELECT POWER(2, (5-1));
SELECT POWER(2, (6-1));
SELECT POWER(2, (7-1));
SELECT POWER(2, (8-1));


/*
8bit(1byte) ��ü�� 255(tinyint)
*/
SELECT POWER(2, 0)
	+ POWER(2, 1) 
	+ POWER(2, 2) 
	+ POWER(2, 3)
	 
	+ POWER(2, 4) 
	+ POWER(2, 5) 
	+ POWER(2, 6) 
	+ POWER(2, 7) 


/*
& ������ - Ư�� bit�� Masking Ȯ�� - ������ �ڸ����� ������.
*/
SELECT 
	(CASE 10 & 1 WHEN 1 THEN ' 1st bit' ELSE '' END )
+	(CASE 10 & 2 WHEN 2 THEN ' 2nd bit' ELSE '' END )
+	(CASE 10 & 4 WHEN 4 THEN ' 3rd bit' ELSE '' END )
+	(CASE 10 & 8 WHEN 8 THEN ' 4th bit' ELSE '' END )
;


/*
Masking ��� Ȯ�� - ���ϴ� bit ��ü�� 1�� ��� or �� �� �Ϻΰ� 1�� ���
*/
SELECT 10 & 10, 8 & 10;


/*
-------------------------------------------------------------------------------
Bitmap ���� ������ Integer ���� ���� Masking ����
*/
SELECT 
	name, status
,	CASE status & POWER(2, (2-1)) WHEN 0 THEN '' ELSE 'Unique' END
,	CASE status & POWER(2, (5-1)) WHEN 0 THEN '' ELSE 'Clustered' END
,	CASE status & POWER(2, (12-1)) WHEN 0 THEN '' ELSE 'PK' END
,	CASE status & POWER(2, (13-1)) WHEN 0 THEN '' ELSE 'UQ' END
FROM AdventureWorks.sys.sysindexes
WHERE Rows > 0
	AND id > 100
	AND indid >= 1;



/*
-------------------------------------------------------------------------------
���̳ʸ� vs. ���� ��ȯ ����
*/
SELECT
  	CONVERT(VARCHAR(8)  , 0x53514C  , 1) AS [Bin to Char 1]
, 	CONVERT(VARBINARY(3), '0x53514C', 1) AS [Char to Bin 1]
, 	CONVERT(VARCHAR(6)  , 0x53514C  , 2) AS [Bin to Char 2]
, 	CONVERT(VARBINARY(3), '53514C'  , 2) AS [Char to Bin 2]
;



/*
-------------------------------------------------------------------------------
����
*/
DECLARE @t tinyint = 255;
GO
DECLARE @s smallint = 32767;
GO
DECLARE @i int = 2147483647;
GO

DECLARE @t tinyint = 255 + 1;
GO
DECLARE @s smallint = 32767 + 1;
GO
DECLARE @i int = 2147483647 + 1;
GO



/*
-------------------------------------------------------------------------------
bigint
*/
SELECT id = CAST(id AS bigint) 
INTO dbo.bigTable
FROM (VALUES (6000000000)) AS d(id);


/*
bigint ����� ������? 

--> BOL ����, "bigint ������ ���" | "bigint ��� ����"
*/
SELECT TOP(1) * 
FROM dbo.bigTable
WHERE id = 6000000000;



/*
bigint ���� �Լ�
*/
SELECT COUNT_BIG(id) FROM dbo.bigTable;
SELECT ROWCOUNT_BIG();

DROP TABLE dbo.bigTable;



/*
-------------------------------------------------------------------------------
�Ǽ�
*/
/*
-------------------------------------------------------------------------------
float, real
*/
SELECT fvalue, rvalue, fvalue - rvalue
FROM 
(VALUES 
   (CAST(6.9 AS float), CAST(6.9 AS real))
) AS d(fvalue, rvalue);



/*
-------------------------------------------------------------------------------
Money
*/
DECLARE @m money = ��5779.5779;
SELECT @m;
GO

SELECT *
FROM 
(VALUES
	(1, CAST(5779 AS money))
,	(2, CAST(��5779 AS money))
) AS d(id, value)
WHERE value = 5779;


/*
-------------------------------------------------------------------------------
õ���� ,(comma) ������ ������
*/
SELECT CONVERT(varchar(30), CAST(1234.56 AS money), 0);
SELECT CONVERT(varchar(30), CAST(1234.56 AS money), 1);
SELECT CONVERT(varchar(30), CAST(1234.56 AS money), 2);

SELECT FORMAT(1234.56, '#,#0.00');




/*
-------------------------------------------------------------------------------
�ݿø�, �ø�, �ݳ���, ����
*/
DECLARE @d1 decimal(18, 4) = 3456.1234;
DECLARE @d2 decimal(18, 4) = 4567.5555;
DECLARE @d3 decimal(18, 4) = 5678.0;

SELECT @d1, @d2, @d3;

/*
�Ҽ� �ڸ��� �ݿø�
*/
SELECT ROUND(@d1, 2), ROUND(@d2, 2), ROUND(@d3, 2);

	-- Ȥ�� �Ϲ����� �ݿø��� �׳� �� ��ȯ�ϸ� ��
	SELECT CAST(@d1 AS decimal(18, 2)), CAST(@d2 AS decimal(18, 2));


/*
�Ҽ� �ڸ��� �ø�
*/
DECLARE @r decimal(8, 4) = 0.004;
SELECT @d1 + @r, @d2 + @r, @d3 + @r;
SELECT ROUND(@d1 + @r, 2), ROUND(@d2 + @r, 2), ROUND(@d3 + @r, 2);


/*
�Ҽ� �ڸ��� ���� - ROUND(, , 1)
*/
SELECT ROUND(@d1, 2, 1), ROUND(@d2, 2, 1), ROUND(@d3, 2, 1);



DECLARE @d1 decimal(18, 4) = 3456.1234;
DECLARE @d2 decimal(18, 4) = 4567.5555;
DECLARE @d3 decimal(18, 4) = 5678.0;

SELECT @d1, @d2, @d3;
/*
���� �ڸ��� �ݿø�
*/
SELECT ROUND(@d1, -3), ROUND(@d2, -3);


/*
���� �ø� - ũ�ų� ���� �ּ� ����
*/
SELECT CEILING(@d1), CEILING(@d2), CEILING(@d3);

/*
���� ���� - �۰ų� ���� �ִ� ����
*/
SELECT FLOOR(@d1), FLOOR(@d2), FLOOR(@d3);




/*
-------------------------------------------------------------------------------
0 ���� ä��� �����
*/
/*
�Ϲ� ���ڿ� �Լ�-1. CONCAT() Ȱ��
*/
SELECT CONCAT('00000000', 1024);
SELECT RIGHT(CONCAT('00000000', 1024), 8);

/*
�Ϲ� ���ڿ� �Լ�-2. STR() Ȱ��
*/
SELECT STR(1024, 8, 0);		-- ��ü ����, �Ҽ��� ���� �ڸ� �� ���� ����
SELECT REPLACE(STR(1024, 8, 0), ' ', '0');	-- space:32

/*
FORMAT �Լ�-2
*/
SELECT FORMAT(1024, '00000000');

/*
������ ���� ��
*/
SELECT RIGHT(CONCAT('00000000', OrderID), 8)
FROM Northwind.dbo.Orders;
GO

SELECT FORMAT(OrderID, '00000000')
FROM Northwind.dbo.Orders;



/*
*******************************************************************************
����
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
���� ���� vs. ���� ����
*/

/*
-------------------------------------------------------------------------------
���� ���� ���� char vs. varchar
*/
CREATE TABLE #charTest (c char(10), v varchar(10));
INSERT #charTest VALUES 
	('SQL', 'SQL')
,	('SQL       ', 'SQL       ')
,	('SQL 1     ', 'SQL 1     ');

/*
���� ���� Ȯ��
*/
SELECT c + '|', v + '|'
FROM #charTest

/*
�Ϲ� �� �����ڿ� char vs. varchar
*/
SELECT c, v
FROM #charTest
WHERE c = 'SQL'	-- char ��

SELECT c, v
FROM #charTest
WHERE v = 'SQL'	-- varchar ��,


/*
�׷��ٸ� RTRIM()�� �ʿ��Ѱ�?
*/
SELECT c, v
FROM #charTest
WHERE c = RTRIM('SQL       ')

SELECT c, v
FROM #charTest
WHERE v = RTRIM('SQL       ')


/*
LIKE �����ڿ� char vs. varchar
*/
--char
SELECT c = c + '|' FROM #charTest 
WHERE c LIKE 'SQL %'

SELECT c = c + '|' FROM #charTest 
WHERE c LIKE 'SQL%'


--varchar
SELECT v = v + '|' FROM #charTest 
WHERE v LIKE 'SQL %'

SELECT v = v + '|' FROM #charTest 
WHERE v LIKE 'SQL%'


/*
����
*/
DROP TABLE #charTest


/*
-------------------------------------------------------------------------------
�Ϲ� ���� vs. UNICODE ����
*/
EXEC sp_help N'sp_helpindex';
EXEC sp_helpindex N'dbo.Orders';




/*
*******************************************************************************
��¥�ð�
*******************************************************************************
*/
DECLARE @now datetime = 0;
SELECT @now;
GO

DECLARE @now datetime = GETDATE()
	, @now2 datetime2 = SYSDATETIME();

SELECT GETDATE(), SYSDATETIME(), @now, @now2;
GO

DECLARE @now date = GETDATE()
	,@now2 time(7) = SYSDATETIME()
	,@now3 time(3) = SYSDATETIME();

SELECT @now, @now2, @now3;
GO



/*
*******************************************************************************
���� - ��¥�ð� �۾�
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
1) ��� ����
*/
DECLARE @now datetime = GETDATE();

SELECT CONVERT(varchar(30), @now, 102);
SELECT CONVERT(varchar(30), @now, 112);	-- ����ǥ��
SELECT CONVERT(varchar(30), @now, 111);
SELECT CONVERT(varchar(30), @now, 120);

SELECT FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff');


/*
-------------------------------------------------------------------------------
2) ����(1��) �˻� - �Ʒ��� ���ĸ� ����
*/
/*
���-1. ���� ���� ������ ���
*/
SELECT *
--FROM <���� ���̺�>
WHERE OrderDate >= '20150701' AND OrderDate < DATEADD(d, 1, '20150701');


/*
���-2. BETWEEN�� ��� �� ����
*/
SELECT *, @today, DATEADD(ms, -3, DATEADD(d, 1, @today))
--FROM <���� ���̺�>
WHERE OrderDate BETWEEN '20150701' AND '20150701 23:59:59.997';



/*
-------------------------------------------------------------------------------
3) ���� ���� 1�� ���ϱ�-1
*/
DECLARE @now datetime = GETDATE();
SELECT CAST(DATEADD(m, DATEDIFF(m, 0, @now), 0) AS date) 
	
	SELECT DATEDIFF(m, 0, @now), DATEADD(m, DATEDIFF(m, 0, @now), 0)

/*
���� ���� 1�� ���ϱ�-2
*/
SELECT CAST(@now - DATEPART(DAY, @now) + 1 AS date)

/*
���� ���� 1�� ���ϱ�-3
*/
SELECT CAST(CONVERT(char(6), @now, 112) + '01' AS date);



/*
-------------------------------------------------------------------------------
4) ���� �ϼ� ���ϱ�
*/
/*
EOMONTH ���
*/
DECLARE @now DATE = GETDATE();

SELECT 
	��� = EOMONTH(@now)
,	���� = EOMONTH(@now, -1)
,	��� = EOMONTH(@now, 1);

-- ���� �ϼ� Ȯ��
SELECT DATEPART(DAY, EOMONTH(GETDATE()));


/*
���� ���-1
*/
SELECT CAST(DATEADD(m, DATEDIFF(m, 0, GETDATE()) + 1, 0) - 1 AS date);


/*
���� ���-2
*/
SELECT DATEADD(d, -1, DATEADD(m, 1, CONVERT(char(6), GETDATE(), 112) + '01'));




/*
-------------------------------------------------------------------------------
5) ���� ���� ����(day), ����(weekday), ����(week) ���ϱ�
*/
-- �Ʒ� ��¥�� �������� ����
DECLARE @BOMonth date = '20210901';

WHILE @BOMonth < EOMONTH('20210925')
BEGIN
	SELECT 
			DATEPART(day, @BOMonth)
		,	DATEPART(weekday, @BOMonth)
		,	DATEDIFF(week, '20210901', @BOMonth) + 1;	-- (1)���� ǥ���ϸ� ���� ���Ƽ�^^

	--SET @i += 1;
	SET @BOMonth = DATEADD(d, 1, @BOMonth);
END





/*
*******************************************************************************
SQL Server 2012 ���ο� �Լ�
*/
/*
-------------------------------------------------------------------------------
TRY_CONVERT() - ��ȯ ���н� ���� ��� NULL ��ȯ
*/
SELECT CONVERT(int, 100), CONVERT(int, 'abc');

SELECT TRY_CONVERT(int, 100), TRY_CONVERT(int, 'abc');


/*
���� ������ ó����
*/
USE tempdb;

IF OBJECT_ID('dbo.OrderHist', 'U') IS NOT NULL DROP TABLE dbo.OrderHist;
  
CREATE TABLE dbo.OrderHist
(
  id			int,
  OrderDate	varchar(30)
);

INSERT INTO dbo.OrderHist(id, OrderDate) VALUES
  (1, '20171224'),
  (2, '2017, 12, 25'),
  (3, '2017 12 26'),
  (4, '2017-12/27');


/*
�Ϲ� ���
*/
SELECT id, OrderDate
FROM dbo.OrderHist
WHERE CAST(OrderDate AS date) >= '20171224';

/*
TRY
*/
SELECT id, TRY_CONVERT(date, OrderDate) AS val
FROM dbo.OrderHist
WHERE TRY_CONVERT(date, OrderDate)  >= '20171224';



/*
-------------------------------------------------------------------------------
TRY_PARSE(): TRY_CONVERT()�� ����
*/
--�������� ���
SELECT PARSE('05/07/01' AS DATE USING 'ko-KR');
--��ȯ ����
SELECT PARSE('09/26/12' AS DATE USING 'ko-KR');

--���� �� NULL ��ȯ
SELECT TRY_PARSE('09/26/12' AS DATE USING 'ko-KR');



/*
-------------------------------------------------------------------------------
CHOOSE: Access ó��
*/
-- �����ڵ忡 ���� �ش� ������ ���
DECLARE @Gubun int = 1, @CodeA int = 10, @CodeB int = 30;
SELECT CHOOSE(@Gubun, @CodeA, @CodeB);

SET @Gubun = 2;
SELECT CHOOSE(@Gubun, @CodeA, @CodeB);


/*
-------------------------------------------------------------------------------
IIF: Access ó��
*/
SELECT IIF(1 = 2, '����', '�ٸ���');


/*
-------------------------------------------------------------------------------
CONCAT - ���� '+' �����ڴ� NULL ����� ��� NULL
*/
SELECT TOP(5) 
	ShipCity, ShipRegiON, ShipCountry
,	CONStringOri = ShipCity + ', ' + ShipRegion + ', ' + ShipCountry
,	CONStringNew = CONCAT(ShipCity, ', ' + ShipRegion, ', ' + ShipCountry)
FROM Northwind.dbo.Orders;


/*
-------------------------------------------------------------------------------
%FROMPARTS: �� ��¥ �ð� Ÿ�Կ� ���� ���� �κ����� ���� ����
*/
SELECT
	DATEFROMPARTS(2012, 09, 26)
,	DATETIME2FROMPARTS(2012, 09, 26, 22, 02, 37, 1, 3) -- �������� ms ���е� �ڸ���
,	TIMEFROMPARTS(22, 02, 37, 1, 7)


/*
-------------------------------------------------------------------------------
LOG: �������� ���� ���
*/
-- LOG()�� �ڿ��α�
SELECT LOG(10);
SELECT LOG(100), 2 * LOG(10);
SELECT LOG(100) / LOG(10);

-- ���ο� LOG(number, base) �Լ�
SELECT LOG(100, 10);



/*
*******************************************************************************
NULL
*******************************************************************************
*/
USE Northwind;
GO

/*
NULL�� ����
*/
SELECT 100 + NULL;
SELECT 'ABC' + NULL;

/*
�񱳿����ڿ� NULL
*/
SELECT *
FROM dbo.Suppliers
WHERE Region = NULL;

SELECT *
FROM dbo.Suppliers
WHERE Region <> NULL;

/*
IS NULL, IS NOT NULL
*/
SELECT *
FROM dbo.Suppliers
WHERE Region IS NULL;

SELECT *
FROM dbo.Suppliers
WHERE Region IS NOT NULL;


/*
IN, NOT IN�� NULL
*/
SELECT *
FROM dbo.Suppliers
WHERE Region IN ('LA', 'OR', NULL);

SELECT *
FROM dbo.Suppliers
WHERE Region NOT IN ('LA', 'OR', NULL);


/*
�������ڿ� NULL
*/
SELECT *
FROM dbo.Suppliers
WHERE SupplierID = 1
	OR SupplierID = 2
	OR SupplierID = NULL;

SELECT *
FROM dbo.Suppliers
WHERE SupplierID <> 1
	AND SupplierID <> 2

	AND SupplierID <> NULL;


/*
NULL ����
*/
SELECT Region
FROM dbo.Suppliers
ORDER BY Region ASC;

SELECT Region
FROM dbo.Suppliers
ORDER BY Region DESC;


/*
NULL ����
*/
SELECT Region, COUNT(*)
FROM dbo.Suppliers
GROUP BY Region;



/*
*******************************************************************************
ISNULL, COALESCE, NULLIF
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
Ȱ�� �� - ��Ÿ�� OR ���� ��
*/
CREATE TABLE dbo.�޿�
(
	����ڵ�	int
,	�ñ�		money
,	�ֱ�		money
,	����		money
);

INSERT dbo.�޿�
VALUES 
	(1, \30000, NULL, NULL)
,	(2, NULL, \1100000, NULL)
,	(3, NULL, NULL, \4000000)
;

SELECT ����ڵ�, COALESCE(�ñ� * 8 * 20, �ֱ� * 4, ����)
FROM dbo.�޿�;

DROP TABLE dbo.�޿�;



/*
-------------------------------------------------------------------------------
Ȱ�� �� - NULLIF�� ������ ���ϱ�
*/
SELECT 
	COUNT(*)
,	COUNT(CASE WHEN EmployeeID <> 2 THEN 1 END)
FROM dbo.Orders
	
SELECT 
	COUNT(*)
,	COUNT(NULLIF(EmployeeID, 2))
FROM dbo.Orders



/*
-------------------------------------------------------------------------------
Ȱ�� �� - ��ձ��� �� - 0���� ������ ���� ó��
*/
	SELECT TOP(10) UnitPrice, Quantity, Discount
	FROM dbo.[Order Details];

SELECT (UnitPrice * Quantity) / Discount
FROM dbo.[Order Details];

/*
�������� �ذ� ��ȵ�
*/
SELECT (UnitPrice * Quantity) / (CASE WHEN Discount = 0 THEN 1 ELSE Discount END)
FROM dbo.[Order Details];

SELECT (UnitPrice * Quantity) / ISNULL(NULLIF(Discount, 0), 1)
FROM dbo.[Order Details];

SELECT (UnitPrice * Quantity) / COALESCE(NULLIF(Discount, 0), 1)
FROM dbo.[Order Details];




/*
*******************************************************************************
CASE ��
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
������ ���� - �켱 ����
-------------------------------------------------------------------------------
*/
SELECT 1 + '2';
GO

SELECT 1 + 'A';
GO

SELECT 1 + '20150707';


/*
-------------------------------------------------------------------------------
���� �� ���� ����
*/
/*
1) ������ ������ �ٸ� ���
*/
DECLARE @now datetime = '2015-7-7';

/*
�Ʒ� �����?
*/
SELECT
	CASE LEN(DATEPART(month, @now))
		WHEN 1 THEN '0' + CONVERT(char(1), DATEPART(month, @now))
		WHEN 2 THEN DATEPART(month, @now)
	END;



/*
2) ELSE �� ������ ���
*/
SELECT 
	ProductID
,	SUM(CASE WHEN Quantity > 50 THEN (Quantity * UnitPrice) ELSE 0 END) 
,	SUM(CASE WHEN Quantity > 50 THEN (Quantity * UnitPrice) END)
FROM dbo.[Order Details]
GROUP BY ProductID;



/*
������� ���
*/
SELECT 
   CASE 
      WHEN value <= 0 THEN 0 
      WHEN value <= 10 THEN 100 / value 
   END -- ELSE �� ����
FROM (VALUES
	(0), (1), (11)	
) AS d(value) ;


/*
3) ���踦 ������ ��� - �Ʒ� �ڵ忡���� 0���� ������ ���� �߻� ����

����) CASE, WHEH, THEN �� ��� ��ġ�Ŀ� ���� Ȥ�� �ɼǿ� ���� �޶���.
*/
SELECT 
   CASE 
      WHEN MIN(value) <= 0 THEN 0
      WHEN MAX(1 / value) <= 10 THEN 1
   END 
FROM (VALUES
	(0), (1), (11)
) AS d(value) ;



/*
-------------------------------------------------------------------------------
���� - CASE
*/
USE Northwind;
GO

/*
1) �ܼ� ���� - ������ ����
*/
SELECT TOP(10) ProductID, UnitsInStock 
FROM dbo.Products;

/* 
(�䱸����)

�� ��ǰ�� UnitsInStock �� ���� 
	- 20���� �۰ų� ������ '��� ����'
	- 50���� ������ '�ֹ� ���'
	- ELSE '���' ��� 
	 
���ο� �÷����� ���
*/
SELECT 
	ProductID, UnitsInStock
,	State = (CASE 
					WHEN UnitsInStock <= 20 THEN '��� ����'
					WHEN UnitsInStock < 50 THEN '�ֹ� ���'
					ELSE '���' 
				END) 
FROM dbo.Products;



/*
2) Pivoting - ������ ����
*/
SELECT 
	ProductID
,	OrderDate = YEAR(OrderDate)
,	Quantity
FROM dbo.[Order Details] AS d 
INNER JOIN dbo.Orders AS o
	ON d.OrderID = o.OrderID
ORDER BY ProductID;


/*
(�䱸����)
	- ��ǰ��(��-�׷�) 
	- �⵵��(PIVOT ��) : ���� ������(����-����) ���
*/
SELECT 
	ProductID
	-- 2) �� ����, 3) ���� ����
,	y1996 = SUM(CASE WHEN YEAR(OrderDate) <= 1996 THEN Quantity END)
,	y1997 = SUM(CASE WHEN YEAR(OrderDate) = 1997 THEN Quantity END)
,	y1998 = SUM(CASE WHEN YEAR(OrderDate) >= 1998 THEN Quantity END)

FROM dbo.[Order Details] AS d 
INNER JOIN dbo.Orders AS o
	ON d.OrderID = o.OrderID
GROUP BY ProductID	-- 1) �� �׷�
ORDER BY ProductID;


/*
3) �׷캰 ���� - ������ ����
*/
SELECT pub_name, state 
FROM pubs.dbo.publishers
ORDER BY state ASC;


/*
(�䱸����)
state(���ǻ� ������) ���� ������������ �����ϵ�
NULL ���� �� �ڿ� ���
*/
SELECT pub_name, state 
FROM pubs.dbo.publishers
ORDER BY (CASE 
				WHEN state is null THEN 1
			   ELSE 0 
			 END) ASC, state ASC;



/*
4) ���Ǻ� �� UPDATE - ������ ����
*/
/*
UPDATE 
	dbo.Orders
SET 
	OrderDate = GETDATE()
WHERE 
	OrderID = 10250;

UPDATE 
	dbo.Orders
SET 
	RequiredDate = GETDATE()
WHERE 
	OrderID = 10251;
GO
*/


/*
(�䱸����)
�ֹ���ȣ�� ���� OrderDate/RequiredDate ���� ���糯¥�� ������Ʈ

����) ������ ������ ���� �����Դϴ�.
*/
BEGIN TRAN

	UPDATE 
		dbo.Orders
	SET 
		OrderDate = (CASE OrderID WHEN 10250 THEN GETDATE() ELSE OrderDate END)
	,	RequiredDate = (CASE OrderID WHEN 10251 THEN GETDATE() ELSE RequiredDate END)
	WHERE 
		OrderID IN (10250, 10251);

	SELECT * FROM dbo.Orders WHERE OrderID IN (10250, 10251);

ROLLBACK



/*
*******************************************************************************
TOP
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
������ ��������
*/
DECLARE @TOP int = 5;

SELECT TOP(@TOP) *
FROM dbo.[Order Details]
ORDER BY Quantity DESC;


SELECT TOP(SELECT AVG(Quantity) FROM dbo.[Order Details]) 
	*
FROM dbo.[Order Details]
ORDER BY Quantity DESC;



/*
-------------------------------------------------------------------------------
TIES
*/
SELECT TOP(5) *
FROM dbo.[Order Details]
ORDER BY Quantity DESC;

SELECT TOP(5) WITH TIES *
FROM dbo.[Order Details]
ORDER BY Quantity DESC;



/*
-------------------------------------------------------------------------------
PERCENT
*/
SELECT COUNT(*) * 0.04 FROM dbo.[Order Details];

SELECT TOP(4) PERCENT *
FROM dbo.[Order Details]
ORDER BY Quantity DESC;



/*
-------------------------------------------------------------------------------
ORDER BY ���� TOP�� ���ռ� ���� - ����ó��
*/
SELECT TOP(5) *
FROM dbo.[Order Details]
ORDER BY Quantity DESC;

SELECT TOP(5) *
FROM dbo.[Order Details]
ORDER BY Quantity DESC, Discount ASC;




/*
*******************************************************************************
RANDOM
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
RANDOM ���� �Լ�
*/
-- 1) RAND ([seed])
SELECT RAND();

	-- RAND()�� ���� �� 1�� ȣ�� (�� ������ �ƴ϶�)
	SELECT TOP(5) object_id
	FROM sys.objects
	ORDER BY RAND();

	-- BOL: "������ �ʱⰪ�� ���� ��ȯ�� ����� �׻� �����մϴ�"
	SELECT RAND(5);

	-- BOL: "�� ���ῡ ���� ������ �ʱⰪ�� ����ϸ� ��� �ļ��� ���� RAND()�� �������� ����"
	SELECT RAND(5), RAND(), RAND();	-- �ݺ� �������� ��

-- ���� 1 ~ �ִ밪
SELECT CAST(RAND() * 1000 AS int) + 1


-- 2)
SELECT NEWID();

-- CHECKSUM�� -21�� ~ 21�������(int) �ؽð� ��ȯ
SELECT CHECKSUM(NEWID());

-- ����: 1 ~ �ִ밪
DECLARE @maxN int = 10000;
SELECT ABS(CHECKSUM(NEWID())) % @maxN + 1;



/*
-------------------------------------------------------------------------------
SELECT ��� RANDOM ����
*/
SELECT TOP(5) OrderID
FROM dbo.Orders
ORDER BY CHECKSUM(NEWID());



/*
-------------------------------------------------------------------------------
RANDOM ������ �����ϱ� - RAND()
*/
SET NOCOUNT ON;

-- table ���� ����
DECLARE @Rnd TABLE (ID int);

DECLARE @i int, @j int = 0;
WHILE @j < 1000
BEGIN
	SELECT @i = CAST(RAND() * 1000 AS int) + 1;
	INSERT @Rnd SELECT @i

	SET @j += 1;
END

-- ���� �� ������ Ȯ��
SELECT COUNT(CASE WHEN ID <= 200 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 201 AND 400 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 401 AND 600 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 601 AND 800 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 801 AND 1000 THEN 1 END)
FROM @Rnd;

-- �ּ�, �߰�, �ִ밪 Ȯ��
SELECT ID FROM @Rnd WHERE ID IN (1, 500, 1000);

-- �ߺ��� Ȯ��
SELECT ID, COUNT(*)
FROM @Rnd 
GROUP BY ID
HAVING COUNT(ID) >= 4;


/*
-------------------------------------------------------------------------------
RANDOM ������ �����ϱ� - NEWID()
*/
DECLARE @Rnd TABLE (ID int);

DECLARE @i int, @j int = 0;
WHILE @j < 1000
BEGIN
	SELECT @i = ABS(CHECKSUM(NEWID())) % 1000 + 1;
	INSERT @Rnd SELECT @i

	SET @j += 1;
END

SELECT COUNT(CASE WHEN ID <= 200 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 201 AND 400 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 401 AND 600 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 601 AND 800 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 801 AND 1000 THEN 1 END)
FROM @Rnd;

SELECT ID FROM @Rnd WHERE ID IN (1, 500, 1000);

SELECT ID, COUNT(*)
FROM @Rnd 
GROUP BY ID
HAVING COUNT(ID) >= 4;


SET NOCOUNT OFF;



/*
*******************************************************************************
TABLESAMPLE ���
*******************************************************************************
*/
SELECT TOP(20) *
FROM dbo.Orders TABLESAMPLE(200 ROWS);


/*
-------------------------------------------------------------------------------
REPEATABLE
*/
DECLARE @top int = 5;

SELECT TOP(@top) *
FROM dbo.Orders TABLESAMPLE(200 ROWS)
	REPEATABLE (100);

	SELECT TOP(@top) *
	FROM dbo.Orders TABLESAMPLE(200 ROWS)
		REPEATABLE (100);

	SELECT TOP(@top) *
	FROM dbo.Orders TABLESAMPLE(200 ROWS)
		REPEATABLE (200); -- seed ���� ����� ���̰� ���� ū ������ ���



/*
*******************************************************************************
End
*******************************************************************************
*/

