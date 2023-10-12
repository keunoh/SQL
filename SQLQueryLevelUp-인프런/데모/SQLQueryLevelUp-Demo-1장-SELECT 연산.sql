/*
*********************************************************************
SQL Query Level Up - SELECT 연산

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
쿼리
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
쿼리 - 논리적인 처리 순서 

	--> SELECT/WHERE/ORDER BY의 순서 확인
*/
SELECT o.OrderID, Orders = YEAR(o.OrderDate)
FROM dbo.Orders AS o
ORDER BY Orders DESC
;




/*
*******************************************************************************
일괄 처리 (Batch)
*******************************************************************************
*/
/*
로컬변수 참조
*/
DECLARE @i int = 10
SELECT @i;

DECLARE @i int = 20
SELECT @i;


/*
변경된 개체 참조 
*/
/*
CREATE는?
*/
CREATE TABLE YKM(a int);
SELECT a FROM YKM;

/*
ALTER는?
*/
ALTER TABLE YKM 
	ADD b int

SELECT a, b FROM YKM;


/*
컴파일 오류
*/
SELECT TOP(1) OrderID, OrderDate FROM Northwind.dbo.Orders;

SELECT TOP(1) PID FROM Northwind.dbo.Products;


/*
런타임 오류
*/
/*
1) 산술 오류
*/
SELECT TOP(1) OrderID FROM Northwind.dbo.Orders;

SELECT 1 / 0;

SELECT TOP(1) ProductID FROM Northwind.dbo.Products;


/*
2) 제약조건 오류
*/
SELECT TOP(1) OrderID FROM Northwind.dbo.Orders;

UPDATE TOP(1) Northwind.dbo.Products
SET UnitPrice = -1;

SELECT TOP(1) ProductID FROM Northwind.dbo.Products;


/*
3) 데이터 형 변환 오류
*/
SELECT TOP(1) OrderID FROM Northwind.dbo.Orders;

UPDATE TOP(1) Northwind.dbo.Products
SET ProductName += CAST(80 AS int);

SELECT TOP(1) ProductID FROM Northwind.dbo.Products;


/*
EXEC 사용
*/
sp_help 

sp_help 'sp_help'


/*
SSMS에서 지시어 변경
*/
SELECT 10;
GO


/*
반복 수행
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
변수 값의 처리는 순차? 일괄?
*/
DECLARE @i int = 0, @j int = 0, @k int = 0;

SELECT TOP(1) @i = SupplierID, @j = @i + 10, @k = @j + 100
FROM dbo.Products
WHERE SupplierID = 1;

SELECT @i, @j, @k;


	-- 검색과 할당을 함께하면?
	SELECT TOP(1) SupplierID, @j = @i + 10, @k = @j + 100
	FROM dbo.Products;


/*
-------------------------------------------------------------------------------
스칼라 변수에 2건 이상의 행 할당은?
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
문자열 누적식
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
XML 활용
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
STRING_AGG() 활용 - 2017+
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
FORMAT 함수 일반 (.NET Format) - 성능 부하 고려
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
-- 기타 포맷은 이후에서 다룸



/*
*******************************************************************************
숫자
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
예제 - bit masking
*/
-- POWER(2진수, (자리수-1))
SELECT POWER(2, (1-1));
SELECT POWER(2, (2-1));
SELECT POWER(2, (3-1));
SELECT POWER(2, (4-1));
SELECT POWER(2, (5-1));
SELECT POWER(2, (6-1));
SELECT POWER(2, (7-1));
SELECT POWER(2, (8-1));


/*
8bit(1byte) 전체는 255(tinyint)
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
& 연산자 - 특정 bit의 Masking 확인 - 동일한 자리값을 가진다.
*/
SELECT 
	(CASE 10 & 1 WHEN 1 THEN ' 1st bit' ELSE '' END )
+	(CASE 10 & 2 WHEN 2 THEN ' 2nd bit' ELSE '' END )
+	(CASE 10 & 4 WHEN 4 THEN ' 3rd bit' ELSE '' END )
+	(CASE 10 & 8 WHEN 8 THEN ' 4th bit' ELSE '' END )
;


/*
Masking 결과 확인 - 원하는 bit 전체가 1인 경우 or 그 중 일부가 1인 경우
*/
SELECT 10 & 10, 8 & 10;


/*
-------------------------------------------------------------------------------
Bitmap 으로 구성된 Integer 열에 대한 Masking 예제
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
바이너리 vs. 문자 변환 지원
*/
SELECT
  	CONVERT(VARCHAR(8)  , 0x53514C  , 1) AS [Bin to Char 1]
, 	CONVERT(VARBINARY(3), '0x53514C', 1) AS [Char to Bin 1]
, 	CONVERT(VARCHAR(6)  , 0x53514C  , 2) AS [Bin to Char 2]
, 	CONVERT(VARBINARY(3), '53514C'  , 2) AS [Char to Bin 2]
;



/*
-------------------------------------------------------------------------------
정수
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
bigint 상수가 있을까? 

--> BOL 참조, "bigint 데이터 사용" | "bigint 상수 지정"
*/
SELECT TOP(1) * 
FROM dbo.bigTable
WHERE id = 6000000000;



/*
bigint 전용 함수
*/
SELECT COUNT_BIG(id) FROM dbo.bigTable;
SELECT ROWCOUNT_BIG();

DROP TABLE dbo.bigTable;



/*
-------------------------------------------------------------------------------
실수
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
DECLARE @m money = ￦5779.5779;
SELECT @m;
GO

SELECT *
FROM 
(VALUES
	(1, CAST(5779 AS money))
,	(2, CAST(￦5779 AS money))
) AS d(id, value)
WHERE value = 5779;


/*
-------------------------------------------------------------------------------
천단위 ,(comma) 데이터 포맷팅
*/
SELECT CONVERT(varchar(30), CAST(1234.56 AS money), 0);
SELECT CONVERT(varchar(30), CAST(1234.56 AS money), 1);
SELECT CONVERT(varchar(30), CAST(1234.56 AS money), 2);

SELECT FORMAT(1234.56, '#,#0.00');




/*
-------------------------------------------------------------------------------
반올림, 올림, 반내림, 내림
*/
DECLARE @d1 decimal(18, 4) = 3456.1234;
DECLARE @d2 decimal(18, 4) = 4567.5555;
DECLARE @d3 decimal(18, 4) = 5678.0;

SELECT @d1, @d2, @d3;

/*
소수 자리수 반올림
*/
SELECT ROUND(@d1, 2), ROUND(@d2, 2), ROUND(@d3, 2);

	-- 혹은 일반적인 반올림은 그냥 형 변환하면 됨
	SELECT CAST(@d1 AS decimal(18, 2)), CAST(@d2 AS decimal(18, 2));


/*
소수 자리수 올림
*/
DECLARE @r decimal(8, 4) = 0.004;
SELECT @d1 + @r, @d2 + @r, @d3 + @r;
SELECT ROUND(@d1 + @r, 2), ROUND(@d2 + @r, 2), ROUND(@d3 + @r, 2);


/*
소수 자리수 내림 - ROUND(, , 1)
*/
SELECT ROUND(@d1, 2, 1), ROUND(@d2, 2, 1), ROUND(@d3, 2, 1);



DECLARE @d1 decimal(18, 4) = 3456.1234;
DECLARE @d2 decimal(18, 4) = 4567.5555;
DECLARE @d3 decimal(18, 4) = 5678.0;

SELECT @d1, @d2, @d3;
/*
정수 자리수 반올림
*/
SELECT ROUND(@d1, -3), ROUND(@d2, -3);


/*
정수 올림 - 크거나 같은 최소 정수
*/
SELECT CEILING(@d1), CEILING(@d2), CEILING(@d3);

/*
정수 내림 - 작거나 같은 최대 정수
*/
SELECT FLOOR(@d1), FLOOR(@d2), FLOOR(@d3);




/*
-------------------------------------------------------------------------------
0 숫자 채우기 방법들
*/
/*
일반 문자열 함수-1. CONCAT() 활용
*/
SELECT CONCAT('00000000', 1024);
SELECT RIGHT(CONCAT('00000000', 1024), 8);

/*
일반 문자열 함수-2. STR() 활용
*/
SELECT STR(1024, 8, 0);		-- 전체 길이, 소숫점 이하 자리 수 지정 가능
SELECT REPLACE(STR(1024, 8, 0), ' ', '0');	-- space:32

/*
FORMAT 함수-2
*/
SELECT FORMAT(1024, '00000000');

/*
쿼리에 적용 시
*/
SELECT RIGHT(CONCAT('00000000', OrderID), 8)
FROM Northwind.dbo.Orders;
GO

SELECT FORMAT(OrderID, '00000000')
FROM Northwind.dbo.Orders;



/*
*******************************************************************************
문자
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
고정 길이 vs. 가변 길이
*/

/*
-------------------------------------------------------------------------------
후행 공백 동작 char vs. varchar
*/
CREATE TABLE #charTest (c char(10), v varchar(10));
INSERT #charTest VALUES 
	('SQL', 'SQL')
,	('SQL       ', 'SQL       ')
,	('SQL 1     ', 'SQL 1     ');

/*
후행 공백 확인
*/
SELECT c + '|', v + '|'
FROM #charTest

/*
일반 비교 연산자와 char vs. varchar
*/
SELECT c, v
FROM #charTest
WHERE c = 'SQL'	-- char 열

SELECT c, v
FROM #charTest
WHERE v = 'SQL'	-- varchar 열,


/*
그렇다면 RTRIM()이 필요한가?
*/
SELECT c, v
FROM #charTest
WHERE c = RTRIM('SQL       ')

SELECT c, v
FROM #charTest
WHERE v = RTRIM('SQL       ')


/*
LIKE 연산자와 char vs. varchar
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
정리
*/
DROP TABLE #charTest


/*
-------------------------------------------------------------------------------
일반 문자 vs. UNICODE 문자
*/
EXEC sp_help N'sp_helpindex';
EXEC sp_helpindex N'dbo.Orders';




/*
*******************************************************************************
날짜시간
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
예제 - 날짜시간 작업
*******************************************************************************
*/
/*
-------------------------------------------------------------------------------
1) 출력 형식
*/
DECLARE @now datetime = GETDATE();

SELECT CONVERT(varchar(30), @now, 102);
SELECT CONVERT(varchar(30), @now, 112);	-- 세계표준
SELECT CONVERT(varchar(30), @now, 111);
SELECT CONVERT(varchar(30), @now, 120);

SELECT FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff');


/*
-------------------------------------------------------------------------------
2) 당일(1일) 검색 - 아래는 형식만 참조
*/
/*
방법-1. 직접 범위 연산자 사용
*/
SELECT *
--FROM <실제 테이블>
WHERE OrderDate >= '20150701' AND OrderDate < DATEADD(d, 1, '20150701');


/*
방법-2. BETWEEN을 사용 시 주의
*/
SELECT *, @today, DATEADD(ms, -3, DATEADD(d, 1, @today))
--FROM <실제 테이블>
WHERE OrderDate BETWEEN '20150701' AND '20150701 23:59:59.997';



/*
-------------------------------------------------------------------------------
3) 현재 월의 1일 구하기-1
*/
DECLARE @now datetime = GETDATE();
SELECT CAST(DATEADD(m, DATEDIFF(m, 0, @now), 0) AS date) 
	
	SELECT DATEDIFF(m, 0, @now), DATEADD(m, DATEDIFF(m, 0, @now), 0)

/*
현재 월의 1일 구하기-2
*/
SELECT CAST(@now - DATEPART(DAY, @now) + 1 AS date)

/*
현재 월의 1일 구하기-3
*/
SELECT CAST(CONVERT(char(6), @now, 112) + '01' AS date);



/*
-------------------------------------------------------------------------------
4) 월별 일수 구하기
*/
/*
EOMONTH 사용
*/
DECLARE @now DATE = GETDATE();

SELECT 
	당월 = EOMONTH(@now)
,	전월 = EOMONTH(@now, -1)
,	명월 = EOMONTH(@now, 1);

-- 최종 일수 확인
SELECT DATEPART(DAY, EOMONTH(GETDATE()));


/*
이전 방법-1
*/
SELECT CAST(DATEADD(m, DATEDIFF(m, 0, GETDATE()) + 1, 0) - 1 AS date);


/*
이전 방법-2
*/
SELECT DATEADD(d, -1, DATEADD(m, 1, CONVERT(char(6), GETDATE(), 112) + '01'));




/*
-------------------------------------------------------------------------------
5) 현재 월의 일자(day), 주중(weekday), 주차(week) 구하기
*/
-- 아래 날짜는 수동으로 수정
DECLARE @BOMonth date = '20210901';

WHILE @BOMonth < EOMONTH('20210925')
BEGIN
	SELECT 
			DATEPART(day, @BOMonth)
		,	DATEPART(weekday, @BOMonth)
		,	DATEDIFF(week, '20210901', @BOMonth) + 1;	-- (1)부터 표시하면 보기 좋아서^^

	--SET @i += 1;
	SET @BOMonth = DATEADD(d, 1, @BOMonth);
END





/*
*******************************************************************************
SQL Server 2012 새로운 함수
*/
/*
-------------------------------------------------------------------------------
TRY_CONVERT() - 변환 실패시 오류 대신 NULL 반환
*/
SELECT CONVERT(int, 100), CONVERT(int, 'abc');

SELECT TRY_CONVERT(int, 100), TRY_CONVERT(int, 'abc');


/*
오류 데이터 처리용
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
일반 방식
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
TRY_PARSE(): TRY_CONVERT()와 동일
*/
--정상적인 경우
SELECT PARSE('05/07/01' AS DATE USING 'ko-KR');
--변환 오류
SELECT PARSE('09/26/12' AS DATE USING 'ko-KR');

--오류 시 NULL 반환
SELECT TRY_PARSE('09/26/12' AS DATE USING 'ko-KR');



/*
-------------------------------------------------------------------------------
CHOOSE: Access 처럼
*/
-- 구분코드에 따라 해당 데이터 출력
DECLARE @Gubun int = 1, @CodeA int = 10, @CodeB int = 30;
SELECT CHOOSE(@Gubun, @CodeA, @CodeB);

SET @Gubun = 2;
SELECT CHOOSE(@Gubun, @CodeA, @CodeB);


/*
-------------------------------------------------------------------------------
IIF: Access 처럼
*/
SELECT IIF(1 = 2, '같다', '다르다');


/*
-------------------------------------------------------------------------------
CONCAT - 기존 '+' 연산자는 NULL 연산시 결과 NULL
*/
SELECT TOP(5) 
	ShipCity, ShipRegiON, ShipCountry
,	CONStringOri = ShipCity + ', ' + ShipRegion + ', ' + ShipCountry
,	CONStringNew = CONCAT(ShipCity, ', ' + ShipRegion, ', ' + ShipCountry)
FROM Northwind.dbo.Orders;


/*
-------------------------------------------------------------------------------
%FROMPARTS: 각 날짜 시간 타입에 대해 정수 부분으로 값을 구성
*/
SELECT
	DATEFROMPARTS(2012, 09, 26)
,	DATETIME2FROMPARTS(2012, 09, 26, 22, 02, 37, 1, 3) -- 마지막은 ms 정밀도 자리수
,	TIMEFROMPARTS(22, 02, 37, 1, 7)


/*
-------------------------------------------------------------------------------
LOG: 기존에서 향상된 기능
*/
-- LOG()는 자연로그
SELECT LOG(10);
SELECT LOG(100), 2 * LOG(10);
SELECT LOG(100) / LOG(10);

-- 새로운 LOG(number, base) 함수
SELECT LOG(100, 10);



/*
*******************************************************************************
NULL
*******************************************************************************
*/
USE Northwind;
GO

/*
NULL과 연산
*/
SELECT 100 + NULL;
SELECT 'ABC' + NULL;

/*
비교연산자와 NULL
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
IN, NOT IN과 NULL
*/
SELECT *
FROM dbo.Suppliers
WHERE Region IN ('LA', 'OR', NULL);

SELECT *
FROM dbo.Suppliers
WHERE Region NOT IN ('LA', 'OR', NULL);


/*
논리연산자와 NULL
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
NULL 정렬
*/
SELECT Region
FROM dbo.Suppliers
ORDER BY Region ASC;

SELECT Region
FROM dbo.Suppliers
ORDER BY Region DESC;


/*
NULL 집계
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
활용 예 - 배타적 OR 관계 열
*/
CREATE TABLE dbo.급여
(
	사원코드	int
,	시급		money
,	주급		money
,	월급		money
);

INSERT dbo.급여
VALUES 
	(1, \30000, NULL, NULL)
,	(2, NULL, \1100000, NULL)
,	(3, NULL, NULL, \4000000)
;

SELECT 사원코드, COALESCE(시급 * 8 * 20, 주급 * 4, 월급)
FROM dbo.급여;

DROP TABLE dbo.급여;



/*
-------------------------------------------------------------------------------
활용 예 - NULLIF로 여집합 구하기
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
활용 예 - 평균구할 때 - 0으로 나누기 오류 처리
*/
	SELECT TOP(10) UnitPrice, Quantity, Discount
	FROM dbo.[Order Details];

SELECT (UnitPrice * Quantity) / Discount
FROM dbo.[Order Details];

/*
여러가지 해결 방안들
*/
SELECT (UnitPrice * Quantity) / (CASE WHEN Discount = 0 THEN 1 ELSE Discount END)
FROM dbo.[Order Details];

SELECT (UnitPrice * Quantity) / ISNULL(NULLIF(Discount, 0), 1)
FROM dbo.[Order Details];

SELECT (UnitPrice * Quantity) / COALESCE(NULLIF(Discount, 0), 1)
FROM dbo.[Order Details];




/*
*******************************************************************************
CASE 문
*******************************************************************************
*/

/*
-------------------------------------------------------------------------------
데이터 형식 - 우선 순위
-------------------------------------------------------------------------------
*/
SELECT 1 + '2';
GO

SELECT 1 + 'A';
GO

SELECT 1 + '20150707';


/*
-------------------------------------------------------------------------------
참고 및 주의 사항
*/
/*
1) 데이터 형식이 다른 경우
*/
DECLARE @now datetime = '2015-7-7';

/*
아래 결과는?
*/
SELECT
	CASE LEN(DATEPART(month, @now))
		WHEN 1 THEN '0' + CONVERT(char(1), DATEPART(month, @now))
		WHEN 2 THEN DATEPART(month, @now)
	END;



/*
2) ELSE 절 생략한 경우
*/
SELECT 
	ProductID
,	SUM(CASE WHEN Quantity > 50 THEN (Quantity * UnitPrice) ELSE 0 END) 
,	SUM(CASE WHEN Quantity > 50 THEN (Quantity * UnitPrice) END)
FROM dbo.[Order Details]
GROUP BY ProductID;



/*
산술식인 경우
*/
SELECT 
   CASE 
      WHEN value <= 0 THEN 0 
      WHEN value <= 10 THEN 100 / value 
   END -- ELSE 절 없음
FROM (VALUES
	(0), (1), (11)	
) AS d(value) ;


/*
3) 집계를 포함한 경우 - 아래 코드에서는 0으로 나누기 오류 발생 가능

참고) CASE, WHEH, THEN 중 어느 위치냐에 따라 혹은 옵션에 따라 달라짐.
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
예제 - CASE
*/
USE Northwind;
GO

/*
1) 단순 예제 - 데이터 이해
*/
SELECT TOP(10) ProductID, UnitsInStock 
FROM dbo.Products;

/* 
(요구사항)

각 제품별 UnitsInStock 의 값이 
	- 20보다 작거나 값으면 '재고 부족'
	- 50보다 작으면 '주문 요망'
	- ELSE '재고' 라고 
	 
새로운 컬럼으로 출력
*/
SELECT 
	ProductID, UnitsInStock
,	State = (CASE 
					WHEN UnitsInStock <= 20 THEN '재고 부족'
					WHEN UnitsInStock < 50 THEN '주문 요망'
					ELSE '재고' 
				END) 
FROM dbo.Products;



/*
2) Pivoting - 데이터 이해
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
(요구사항)
	- 제품별(행-그룹) 
	- 년도별(PIVOT 열) : 집계 데이터(열값-집계) 출력
*/
SELECT 
	ProductID
	-- 2) 열 단위, 3) 열값 집계
,	y1996 = SUM(CASE WHEN YEAR(OrderDate) <= 1996 THEN Quantity END)
,	y1997 = SUM(CASE WHEN YEAR(OrderDate) = 1997 THEN Quantity END)
,	y1998 = SUM(CASE WHEN YEAR(OrderDate) >= 1998 THEN Quantity END)

FROM dbo.[Order Details] AS d 
INNER JOIN dbo.Orders AS o
	ON d.OrderID = o.OrderID
GROUP BY ProductID	-- 1) 행 그룹
ORDER BY ProductID;


/*
3) 그룹별 정렬 - 데이터 이해
*/
SELECT pub_name, state 
FROM pubs.dbo.publishers
ORDER BY state ASC;


/*
(요구사항)
state(출판사 소재지) 열을 오름차순으로 정렬하되
NULL 값은 맨 뒤에 출력
*/
SELECT pub_name, state 
FROM pubs.dbo.publishers
ORDER BY (CASE 
				WHEN state is null THEN 1
			   ELSE 0 
			 END) ASC, state ASC;



/*
4) 조건별 열 UPDATE - 데이터 이해
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
(요구사항)
주문번호에 따라 OrderDate/RequiredDate 열을 현재날짜로 업데이트

참고) 구현에 초점을 맞춘 예제입니다.
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
변수와 서브쿼리
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
ORDER BY 절과 TOP의 정합성 문제 - 동률처리
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
RANDOM 관련 함수
*/
-- 1) RAND ([seed])
SELECT RAND();

	-- RAND()는 쿼리 당 1번 호출 (행 단위가 아니라)
	SELECT TOP(5) object_id
	FROM sys.objects
	ORDER BY RAND();

	-- BOL: "지정된 초기값에 대해 반환된 결과는 항상 동일합니다"
	SELECT RAND(5);

	-- BOL: "한 연결에 대해 지정된 초기값을 사용하면 모든 후속은 최초 RAND()를 바탕으로 생성"
	SELECT RAND(5), RAND(), RAND();	-- 반복 실행했을 때

-- 최종 1 ~ 최대값
SELECT CAST(RAND() * 1000 AS int) + 1


-- 2)
SELECT NEWID();

-- CHECKSUM은 -21억 ~ 21억까지의(int) 해시값 반환
SELECT CHECKSUM(NEWID());

-- 최종: 1 ~ 최대값
DECLARE @maxN int = 10000;
SELECT ABS(CHECKSUM(NEWID())) % @maxN + 1;



/*
-------------------------------------------------------------------------------
SELECT 결과 RANDOM 정렬
*/
SELECT TOP(5) OrderID
FROM dbo.Orders
ORDER BY CHECKSUM(NEWID());



/*
-------------------------------------------------------------------------------
RANDOM 데이터 생성하기 - RAND()
*/
SET NOCOUNT ON;

-- table 변수 예제
DECLARE @Rnd TABLE (ID int);

DECLARE @i int, @j int = 0;
WHILE @j < 1000
BEGIN
	SELECT @i = CAST(RAND() * 1000 AS int) + 1;
	INSERT @Rnd SELECT @i

	SET @j += 1;
END

-- 랜덤 값 분포도 확인
SELECT COUNT(CASE WHEN ID <= 200 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 201 AND 400 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 401 AND 600 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 601 AND 800 THEN 1 END)
,	COUNT(CASE WHEN ID BETWEEN 801 AND 1000 THEN 1 END)
FROM @Rnd;

-- 최소, 중간, 최대값 확인
SELECT ID FROM @Rnd WHERE ID IN (1, 500, 1000);

-- 중복값 확인
SELECT ID, COUNT(*)
FROM @Rnd 
GROUP BY ID
HAVING COUNT(ID) >= 4;


/*
-------------------------------------------------------------------------------
RANDOM 데이터 생성하기 - NEWID()
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
TABLESAMPLE 기능
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
		REPEATABLE (200); -- seed 값은 충분히 차이가 나는 큰 값으로 사용



/*
*******************************************************************************
End
*******************************************************************************
*/

