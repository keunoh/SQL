/*
-------------------------------------------------------------------------------
���� - �׷캰 ���� N���� ���ϱ�

����: APPLY + TOP(N)(Ȥ�� OFFSET FETCH)�� �̿��ؼ� Customer 10�� ���� �ֽ� �ֹ� 3�Ǿ� ��ȯ

*/
/*
������ �غ�
*/
USE Northwind;
GO


/*
����
*/
SELECT c.CustomerID, c.CompanyName, o.OrderDate, o.OrderID
FROM dbo.Customers AS c
;


