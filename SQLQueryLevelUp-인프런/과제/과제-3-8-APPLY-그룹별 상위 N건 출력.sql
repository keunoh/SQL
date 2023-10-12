/*
-------------------------------------------------------------------------------
과제 - 그룹별 상위 N개행 구하기

내용: APPLY + TOP(N)(혹은 OFFSET FETCH)를 이용해서 Customer 10명에 대한 최신 주문 3건씩 반환

*/
/*
데이터 준비
*/
USE Northwind;
GO


/*
과제
*/
SELECT c.CustomerID, c.CompanyName, o.OrderDate, o.OrderID
FROM dbo.Customers AS c
;


