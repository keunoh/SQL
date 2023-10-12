/*
-------------------------------------------------------------------------------
과제 - 이동 평균 구하기

내용: 각 주문에서 이전 2개의 주문을 포함 최근 3개 주문에 대한 평균을 구한다.
		
*/
/*
준비
*/
USE Northwind;
GO


/*
과제

OrderID     Amount                AmountSliding
----------- --------------------- ---------------------
10248       440.00                440.00
10249       1863.40               1151.70
10250       1813.00               1372.1333
10251       670.80                1449.0666
10252       3730.00               2071.2666
10253       1444.80               1948.5333
*/
SELECT 
	d1.OrderID
,	Amount = SUM(d1.Quantity * d1.UnitPrice)
,	AmountSliding = (						
			)
FROM dbo.[Order Details] AS d1
WHERE d1.OrderID <= 10260
GROUP BY d1.OrderID
ORDER BY d1.OrderID;



