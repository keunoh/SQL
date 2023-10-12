/*
*********************************************************************
SQL Query Level Up - Join

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
������ ����(�뵵)
*******************************************************************************
*/


/*
*******************************************************************************
CROSS JOIN
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
Cartesian Product
*/
SELECT * FROM (VALUES (1, 'A'), (2, 'B'), (3, 'B')) AS t1 (A, B);
SELECT * FROM (VALUES ('DB', 100)) AS t2 (C, D);


SELECT 
	*
FROM 
	(VALUES (1, 'A'), (2, 'B'), (3, 'B')) AS t1 (A, B)
CROSS JOIN 
	(VALUES ('DB', 100)) AS t2 (C, D);



/*
-------------------------------------------------------------------------------
�� ���� �� ����

Ex. ��ǰ �� ��հ� ��� ��ǰ �ܰ��� ����
*/
/*
���� ������ ����
*/
SELECT 
	ProductID
,	UnitPrice
FROM 
	dbo.[Order Details] As od
WHERE
	OrderID <= 10250;

SELECT AvgPrice = AVG(UnitPrice) FROM dbo.[Order Details] AS od;


/*
���� �䱸���� - AVG() �ϳ��� ���� ���� �ְ�, �� �� �̻��� ���谡 �ʿ��� ���� �ִ�.
*/
SELECT
	ProductID
,	UnitPrice

/* �Ʒ� �� ���� �� ���� ���� */
,	av.AvgPrice
,	av.AvgPrice - UnitPrice
FROM 
	dbo.[Order Details] As od
CROSS JOIN (SELECT AvgPrice = AVG(UnitPrice) FROM dbo.[Order Details] AS od) AS av
WHERE
	OrderID <= 10250;


/*
-------------------------------------------------------------------------------
��ü �� ���� (���� ���ϴ� �� ��ŭ ����)

Ex. �Ұ�(Subtotal) ���
*/
/*
���� ������ ���� - ���������(1, 2), ������(< 'C'), �ֹ���
*/
SELECT 
	EmployeeID, ShipCountry, OrderCount = COUNT(*)
FROM 
	dbo.Orders AS od
WHERE 
	EmployeeID IN (1, 2) AND ShipCountry < 'C'
GROUP BY 
	EmployeeID, ShipCountry
ORDER BY 
	EmployeeID, ShipCountry;


/*
���� �䱸����-1 - ���� ������ �� ������ 2��Ʈ�� �����(���纻 1��Ʈ)
*/
SELECT 
	CopyNo, EmployeeID, ShipCountry, OrderCount = COUNT(*)
FROM 
	dbo.Orders AS od
CROSS JOIN 
   (VALUES (1), (2)) AS n(CopyNo)
WHERE 
	EmployeeID IN (1, 2) AND ShipCountry < 'C'
GROUP BY 
	CopyNo, EmployeeID, ShipCountry
ORDER BY 
	CopyNo, EmployeeID, ShipCountry;



/*
���� �䱸����-2 
	- 1 ��Ʈ�� ���� ������ �״�� ���
	- �� �� ��Ʈ�� ����� ��ü ShipCountry�� �Ұ�(SUM) ���
*/
SELECT 
	EmployeeID
,  ShipCountry = (CASE WHEN CopyNo = 1 THEN ShipCountry
		                  ELSE NULL END)
,	OrderCount = COUNT(*)
FROM 
	dbo.Orders AS o
CROSS JOIN
	(VALUES (1), (2)) AS n(CopyNo)
WHERE 
	EmployeeID IN (1, 2) AND ShipCountry < 'C'
GROUP BY 
	EmployeeID, (CASE WHEN CopyNo = 1 THEN ShipCountry
							ELSE NULL END)
ORDER BY 
	EmployeeID;



/*
*******************************************************************************
INNER JOIN
*******************************************************************************
*/



/*
*******************************************************************************
OUTER JOIN
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
(A-B) + (A��B) or (B-A) + (A��B)
*/
SELECT 
	* 
FROM
	dbo.Customers AS c
WHERE
	NOT EXISTS (SELECT 1 
					FROM dbo.Orders AS d
					WHERE	d.CustomerID = c.CustomerID)
	AND c.CustomerID IN ('FISSA', 'PARIS', 'ANTON');


SELECT 
	o.OrderID, * 
FROM
	dbo.Customers AS c
INNER JOIN
	dbo.Orders AS o ON c.CustomerID = o.CustomerID
WHERE
	c.CustomerID IN ('FISSA', 'PARIS', 'ANTON');



/*
-------------------------------------------------------------------------------
NULL �� ������ ������ �ǹ� �����ϱ�
*/
SELECT 
	o.OrderID, o.CustomerID, * 
FROM
	dbo.Customers AS c
LEFT JOIN
	dbo.Orders AS o ON c.CustomerID = o.CustomerID
WHERE
	c.CustomerID IN ('FISSA', 'PARIS', 'ANTON');


SELECT 
	o.OrderID, o.CustomerID, * 
FROM
	dbo.Customers AS c
LEFT JOIN
	dbo.Orders AS o ON c.CustomerID = o.CustomerID
WHERE
	c.CustomerID IN ('FISSA', 'PARIS', 'ANTON')
		AND o.CustomerID IS NULL;



/*
-------------------------------------------------------------------------------
FULL OUTER JOIN
*/
CREATE TABLE dbo.Depts 
(
	DeptCode	char(4)	PRIMARY KEY
,	DeptName	varchar(20)
);

CREATE TABLE dbo.Emps
(
	EmpID		int	PRIMARY KEY
,	DeptCode	char(4)
);

INSERT Depts
VALUES
	('0001', '�λ�')
,	('0002', 'ȸ��')
,	('0003', '����1��')
,	('0004', '����1��')
,	('0005', '����1��')
,	('0006', 'DBA��');

INSERT Emps
VALUES 
	(1, '0001')
,	(2, '0002')
,	(3, '0004')
,	(4, NULL)
,	(5, '0005')
,	(6, '0006');


/*
(A-B) + (B-A) + (A��B)
*/
SELECT * 
FROM dbo.Depts AS d 
WHERE NOT EXISTS (SELECT 1 
						FROM dbo.Emps AS e 
						WHERE e.DeptCode = d.DeptCode);

SELECT * 
FROM dbo.Emps AS e
WHERE NOT EXISTS (SELECT 1 
						FROM dbo.Depts AS d 
						WHERE e.DeptCode = d.DeptCode);

SELECT * 
FROM dbo.Emps AS e
INNER JOIN dbo.Depts AS d ON e.DeptCode = d.DeptCode;


/*
FULL OUTER JOIN
*/
SELECT * 
FROM dbo.Emps AS e
FULL JOIN dbo.Depts AS d ON e.DeptCode = d.DeptCode;




/*
-------------------------------------------------------------------------------
OUTER or INNER?
*/
SELECT 
	o.OrderID, * 
FROM
	dbo.Customers AS c
LEFT JOIN
	dbo.Orders AS o ON c.CustomerID = o.CustomerID
WHERE
	o.OrderID <= 10250;



/*
*******************************************************************************
Self Joins & Non-equal(equi) Joins
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
���� �׷쳻 �� - ���� ���� ���� �ٸ� �۰� ã��
*/
SELECT 
	a1.au_lname, COUNT(au_id)
FROM 
	Pubs.dbo.Authors AS a1
GROUP BY 
	a1.au_lname
HAVING 
	COUNT(a1.au_lname) >= 2;


SELECT  
	a1.au_lname,	a1.au_fname
,	a1.au_id
FROM 
	Pubs.dbo.Authors AS a1
INNER JOIN
	Pubs.dbo.Authors AS a2 ON a1.au_lname = a2.au_lname
WHERE
	a1.au_id <> a2.au_id;



/*
-------------------------------------------------------------------------------
BETWEEN ���� - Ư�� ���� �� ����
*/
IF OBJECT_ID('dbo.PhoneNumber', 'U') IS NOT NULL
	DROP TABLE dbo.PhoneNumber
GO
CREATE TABLE dbo.PhoneNumber (p1 int, p2 int)
GO

INSERT INTO PhoneNumber (p1, p2)
VALUES (3, 5),	(6, 10)
GO

SELECT * FROM PhoneNumber;

WITH N1(Seq) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1)
   , N2(Seq) AS (SELECT 1 FROM N1 CROSS JOIN N1 AS n)
   , N3(Seq) AS (SELECT 1 FROM N2 CROSS JOIN N2 AS n)
   , Numbers(Seq) AS (SELECT ROW_NUMBER() OVER(ORDER BY n.Seq) FROM N3 CROSS JOIN N3 AS n) -- 6561 rows
SELECT Seq, p1, p2
FROM PhoneNumber AS p
INNER JOIN Numbers n 
	ON n.Seq BETWEEN p.p1 AND p.p2;



/*
-------------------------------------------------------------------------------
��ȯ���� �� - �ڱ�����
*/
/*
���� ������ 
*/
SELECT 
	EmployeeID, ReportsTo, LastName, FirstName 
FROM 
	dbo.Employees
ORDER BY 
	ReportsTo, EmployeeID;


/*
�������赵
*/
SELECT  
	SeniorID = e1.EmployeeID, Senior = e1.FirstName
,	JuniorID = e2.EmployeeID, Junior = e2.FirstName
FROM 
	dbo.Employees AS e1
INNER JOIN
	dbo.Employees AS e2 ON e2.ReportsTo = e1.EmployeeID
ORDER BY 
	e1.ReportsTo;



/*
-------------------------------------------------------------------------------
���� ���� - ������ �غ�
*/
IF OBJECT_ID('dbo.Sales', 'U') IS NOT NULl
	DROP TABLE dbo.Sales;
GO

CREATE TABLE dbo.Sales
(
	SalesYMD	date				PRIMARY KEY
,	Amount		decimal(18, 0)
);

INSERT dbo.Sales
VALUES
	('20150101', 3000)
,	('20150102', 2500)
,	('20150103', 1500)
,	('20150104', 4500)
,	('20150105', 3500)
,	('20150106', 2500);


/*
-------------------------------------------------------------------------------
���� ���� ��
*/
SELECT
	s1.*, s2.*
,	diff = s1.Amount - s2.Amount
FROM
	dbo.Sales AS s1
LEFT JOIN
	dbo.Sales AS s2 ON DATEADD(dd, -1, s1.SalesYMD) = s2.SalesYMD
ORDER BY
	s1.SalesYMD;



/*
*******************************************************************************
���� ���� vs. �˻� ����
*******************************************************************************
*/
SELECT 
	o.OrderID, o.CustomerID, * 
FROM
	dbo.Customers AS c
LEFT JOIN
	dbo.Orders AS o ON c.CustomerID = o.CustomerID
WHERE
	c.CustomerID IN ('FISSA', 'PARIS', 'ANTON')
		AND o.CustomerID IS NULL	/* �� ������ ��ġ�� ��� �� ���ΰ�? */



/*
*******************************************************************************
���� ����
*******************************************************************************
*/
/*
������ �غ�
*/
IF OBJECT_ID('LeftInput', 'U') IS NOT NULL DROP TABLE dbo.LeftInput;
IF OBJECT_ID('RightInput', 'U') IS NOT NULL DROP TABLE dbo.RightInput;

SELECT * INTO dbo.LeftInput
FROM (VALUES (1), (2), (2), (NULL)) AS dt(value);

SELECT * INTO dbo.RightInput
FROM (VALUES (2), (2), (3), (4), (NULL), (NULL)) AS dt(value);

	/*
	-- EXCEPT�� ���� NULL ����� ���ϰ��� �� ��
	SELECT * INTO dbo.RightInput
	FROM (VALUES (2), (2), (3), (4)) AS dt(value);
	*/


/*
*******************************************************************************
������
*******************************************************************************
*/
SELECT ID = Value FROM dbo.LeftInput
SELECT Value FROM dbo.RightInput;

/*
-------------------------------------------------------------------------------
1) ������ ��� ����
2) NULL�� ��� Ȯ�� 
3) ALL�� �����ǳ�?
*/
SELECT ID = Value FROM dbo.LeftInput
INTERSECT
SELECT Value FROM dbo.RightInput;


/*
-------------------------------------------------------------------------------
ORDER BY ���� ��ü ��� �������θ� ����(�⺻����)
*/
SELECT ID = Value FROM dbo.LeftInput
INTERSECT
SELECT Value FROM dbo.RightInput
ORDER BY Value DESC;



/*
*******************************************************************************
������
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
UNION vs. UNION ALL
*/
SELECT Value FROM dbo.LeftInput
UNION 
SELECT Value FROM dbo.RightInput
;

SELECT Value FROM	dbo.LeftInput
UNION ALL
SELECT Value FROM dbo.RightInput
;

	

/*
-------------------------------------------------------------------------------
���� ���� ����(ORDER BY or TOP)�� ó���ϰ� �ʹٸ�
*/
SELECT LorR = 'L', Value
FROM dbo.LeftInput
ORDER BY	Value ASC

UNION ALL

SELECT 'R', Value
FROM dbo.RightInput
ORDER BY	Value * (-1) ASC
;


SELECT 
	*
, (CASE LorR WHEN 1 THEN (Value) ELSE (Value * -1) END)
FROM (
	SELECT LorR = 1, Value
	FROM dbo.LeftInput

	UNION	ALL

	SELECT 2, Value
	FROM dbo.RightInput
) AS dt
ORDER BY
	LorR ASC, 
	(CASE LorR WHEN 1 THEN (Value) ELSE (Value * -1) END) ASC
;



/*
*******************************************************************************
������
*******************************************************************************
*/
-- ������ RightInput ���� �Է�

/*
-------------------------------------------------------------------------------
1) ������ ��� ����
2) NULL�� ��� Ȯ�� 
3) ALL�� �����ǳ�?
*/
SELECT Value FROM dbo.LeftInput
SELECT Value FROM dbo.RightInput;

-- A - B (����. NULL���� A�� �����ϴ� ��쿡�� ���Ե� - ������ ���̺� ����)
SELECT Value FROM dbo.LeftInput
EXCEPT
SELECT Value FROM dbo.RightInput

-- B - A
SELECT Value FROM dbo.RightInput
EXCEPT
SELECT Value FROM dbo.LeftInput



/*
*******************************************************************************
End
*******************************************************************************
*/


