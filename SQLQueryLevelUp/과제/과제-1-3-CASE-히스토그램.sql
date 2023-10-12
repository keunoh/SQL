/*
------------------------------------------------------------------------------
과제 - CASE - Histogram 생성하기

내용:
 
1) 국가별 총 주문수량을 [39이하/40-79/80-119/120이상] 4개의 분포표로 출력

2) 분포별 개수를 숫자 대신 '■' 문자로 출력

------------------------------------------------------------------------------
*/
/*
준비
*/
USE Northwind;
GO

-- 국가별 총 주문수량
SELECT 
	ShipCountry
,	Orders = COUNT(*)
FROM dbo.Orders
GROUP BY ShipCountry;



/*
과제-1
*/
	SELECT 
		ShipCountry
	,	Orders = COUNT(*)
	FROM dbo.Orders
	GROUP BY ShipCountry



/*
과제-2
*/



