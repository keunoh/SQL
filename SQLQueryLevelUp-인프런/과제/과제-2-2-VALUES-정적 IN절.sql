/*
-------------------------------------------------------------------------------
���� - NULL �Ű����� �����ϱ�

����: IN ���� ������ �Ű��������� NULL ���� �����ϰ� �˻��ϵ��� �����Ͻÿ�.

*/
USE Northwind;
GO


/*
����
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


