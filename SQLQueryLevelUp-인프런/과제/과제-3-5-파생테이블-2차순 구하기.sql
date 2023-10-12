/*
-------------------------------------------------------------------------------
���� - 2���� ���ϱ�

����: Products ���̺��� �� CategoryID���� �� ��°�� ���� ������ ����Ѵ�.

*/
/*
�غ�
*/
USE Northwind;
GO

SELECT CategoryID, UnitPrice, ProductID
FROM dbo.Products
ORDER BY CategoryID ASC, UnitPrice DESC;



/*
-------------------------------------------------------------------------------
����

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



