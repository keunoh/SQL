/*
-------------------------------------------------------------------------------
���� - �̵� ��� ���ϱ�

����: ������������ ������ ������ Window Function�� �̿��� �ڵ�� ���ۼ�	
*/

/*
�غ�
*/
USE Northwind;
GO

SELECT 
	d1.OrderID,	d1.Quantity, d1.UnitPrice
FROM dbo.[Order Details] AS d1
WHERE d1.OrderID <= 10260;



/*
-------------------------------------------------------------------------------
���� - �̵� ��� ���ϱ�

����: ������������ ������ ������ Window Function�� �̿��� �ڵ�� ���ۼ�	
*/
SELECT
	d1.OrderID
,	Amount
,	AmountSlide =

FROM 

;

