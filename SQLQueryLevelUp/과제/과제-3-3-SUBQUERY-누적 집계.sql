/*
-------------------------------------------------------------------------------
���� - ���� ���� ���ϱ�

����: �ֹ���/��ǰ�� �Ǹűݾװ� �ֹ��� ���� �Ǹűݾ��� ����Ѵ�.

*/
/*
�غ�
*/
USE Northwind;
GO

SELECT 
	OrderID, ProductID
,	Amount = Quantity * UnitPrice
FROM dbo.[Order Details] AS d1
WHERE OrderID <= 10250;


/*
-------------------------------------------------------------------------------
����

OrderID     ProductID   Amount                AmountRunning
----------- ----------- --------------------- ---------------------
10248       11          168.00                168.00
10248       42          98.00                 266.00
10248       72          174.00                440.00
10249       14          167.40                167.40
10249       51          1696.00               1863.40
10250       41          77.00                 77.00
10250       51          1484.00               1561.00
10250       65          252.00                1813.00

*/
SELECT 
	d1.OrderID, d1.ProductID
,	Amount = 
,	AmountRunning = 

FROM dbo.[Order Details] AS d1
WHERE d1.OrderID <= 10250
ORDER BY d1.OrderID ASC, d1.ProductID ASC
;

