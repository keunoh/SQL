/*
-------------------------------------------------------------------------------
과제 - 2차순 구하기

내용: Products 테이블에서 각 CategoryID별로 두 번째로 높은 가격을 출력한다.

*/
/*
준비
*/
USE Northwind;
GO

SELECT CategoryID, UnitPrice, ProductID
FROM dbo.Products
ORDER BY CategoryID ASC, UnitPrice DESC;



/*
-------------------------------------------------------------------------------
과제

	CategoryID  NextPrice
	----------- ---------------------
	1           46.00
	2           40.00
	3           49.30
	4           38.00
	5           33.25
	6           97.00
	7           45.60
	8           31.00
*/
SELECT p.CategoryID, NextPrice = MAX(p.UnitPrice)
FROM (	
	SELECT 
	FROM dbo.Products
	GROUP BY 
) m 
WHERE 
GROUP BY
;



