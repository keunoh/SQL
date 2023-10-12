/*
*********************************************************************
SQL Query Level Up - Join

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
조인의 목적(용도)
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
비 관계 열 복제

Ex. 제품 총 평균가 대비 제품 단가별 편차
*/
/*
원시 데이터 이해
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
쿼리 요구사항 - AVG() 하나만 구할 수도 있고, 두 개 이상의 집계가 필요할 수도 있다.
*/
SELECT
	ProductID
,	UnitPrice

/* 아래 두 가지 열 값을 생성 */
,	av.AvgPrice
,	av.AvgPrice - UnitPrice
FROM 
	dbo.[Order Details] As od
CROSS JOIN (SELECT AvgPrice = AVG(UnitPrice) FROM dbo.[Order Details] AS od) AS av
WHERE
	OrderID <= 10250;


/*
-------------------------------------------------------------------------------
전체 행 복제 (행을 원하는 수 만큼 복제)

Ex. 소계(Subtotal) 출력
*/
/*
원시 데이터 이해 - 영업사원별(1, 2), 국가별(< 'C'), 주문수
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
쿼리 요구사항-1 - 원시 데이터 행 집합을 2세트로 만들기(복사본 1세트)
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
쿼리 요구사항-2 
	- 1 세트는 원시 데이터 그대로 출력
	- 또 한 세트는 사원별 전체 ShipCountry에 소계(SUM) 출력
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
(A-B) + (A∩B) or (B-A) + (A∩B)
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
NULL 값 생성과 차집합 의미 이해하기
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
	('0001', '인사')
,	('0002', '회계')
,	('0003', '영업1팀')
,	('0004', '구매1팀')
,	('0005', '생산1팀')
,	('0006', 'DBA팀');

INSERT Emps
VALUES 
	(1, '0001')
,	(2, '0002')
,	(3, '0004')
,	(4, NULL)
,	(5, '0005')
,	(6, '0006');


/*
(A-B) + (B-A) + (A∩B)
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
동일 그룹내 비교 - 같은 성을 가진 다른 작가 찾기
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
BETWEEN 조인 - 특정 구간 행 복제
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
순환관계 모델 - 자기참조
*/
/*
원시 데이터 
*/
SELECT 
	EmployeeID, ReportsTo, LastName, FirstName 
FROM 
	dbo.Employees
ORDER BY 
	ReportsTo, EmployeeID;


/*
조직관계도
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
전일 매출 - 데이터 준비
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
전일 매출 비교
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
조인 조건 vs. 검색 조건
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
		AND o.CustomerID IS NULL	/* 이 조건의 위치를 어디에 둘 것인가? */



/*
*******************************************************************************
집합 연산
*******************************************************************************
*/
/*
데이터 준비
*/
IF OBJECT_ID('LeftInput', 'U') IS NOT NULL DROP TABLE dbo.LeftInput;
IF OBJECT_ID('RightInput', 'U') IS NOT NULL DROP TABLE dbo.RightInput;

SELECT * INTO dbo.LeftInput
FROM (VALUES (1), (2), (2), (NULL)) AS dt(value);

SELECT * INTO dbo.RightInput
FROM (VALUES (2), (2), (3), (4), (NULL), (NULL)) AS dt(value);

	/*
	-- EXCEPT에 대한 NULL 결과를 비교하고자 할 때
	SELECT * INTO dbo.RightInput
	FROM (VALUES (2), (2), (3), (4)) AS dt(value);
	*/


/*
*******************************************************************************
교집합
*******************************************************************************
*/
SELECT ID = Value FROM dbo.LeftInput
SELECT Value FROM dbo.RightInput;

/*
-------------------------------------------------------------------------------
1) 교집합 결과 이해
2) NULL값 결과 확인 
3) ALL이 지원되나?
*/
SELECT ID = Value FROM dbo.LeftInput
INTERSECT
SELECT Value FROM dbo.RightInput;


/*
-------------------------------------------------------------------------------
ORDER BY 절은 전체 결과 기준으로만 가능(기본문법)
*/
SELECT ID = Value FROM dbo.LeftInput
INTERSECT
SELECT Value FROM dbo.RightInput
ORDER BY Value DESC;



/*
*******************************************************************************
합집합
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
개별 정렬 조건(ORDER BY or TOP)을 처리하고 싶다면
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
차집합
*******************************************************************************
*/
-- 위에서 RightInput 새로 입력

/*
-------------------------------------------------------------------------------
1) 차집합 결과 이해
2) NULL값 결과 확인 
3) ALL이 지원되나?
*/
SELECT Value FROM dbo.LeftInput
SELECT Value FROM dbo.RightInput;

-- A - B (참고. NULL값이 A만 존재하는 경우에는 포함됨 - 위에서 테이블 생성)
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


