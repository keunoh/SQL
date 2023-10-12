/*
-------------------------------------------------------------------------------
과제 - NULL 매개변수 제외하기

내용: IN 절에 나열된 매개변수에서 NULL 값은 제외하고 검색하도록 변경하시오.

*/
USE Northwind;
GO


/*
과제
*/
DECLARE  
	@OrderID1 int = 10250
,	@OrderID2 int = 10257
,	@OrderID3 int = NULL
,	@OrderID4 int = NULL
,	@OrderID5 int = NULL

SELECT OrderID, OrderDate, CustomerID
FROM dbo.Orders
WHERE OrderID IN (@OrderID1, @OrderID2, @OrderID3, @OrderID4, @OrderID5) 
;


