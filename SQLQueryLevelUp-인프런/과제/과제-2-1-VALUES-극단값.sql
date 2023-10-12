/*
-------------------------------------------------------------------------------
과제 - 극단값 구하기(다중 열 목록에서 집계 작업)

내용: 	주문별 MAX(OrderDate, RequiredDate, ShippedDate)가 출력되도록 
		코드를 완성하시오 (샘플로 5건만).
*/
USE Northwind;
GO


/*
과제
*/
SELECT TOP(5)
	OrderID
,	OrderDate, RequiredDate, ShippedDate
,	Greatest_LastDate = /* complete code here for MAX(OrderDate, RequiredDate, ShippedDate) */

FROM dbo.Orders
;
