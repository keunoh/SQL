/*
------------------------------------------------------------------------------
���� - CASE - Histogram �����ϱ�

����:
 
1) ������ �� �ֹ������� [39����/40-79/80-119/120�̻�] 4���� ����ǥ�� ���

2) ������ ������ ���� ��� '��' ���ڷ� ���

------------------------------------------------------------------------------
*/
/*
�غ�
*/
USE Northwind;
GO

-- ������ �� �ֹ�����
SELECT 
	ShipCountry
,	Orders = COUNT(*)
FROM dbo.Orders
GROUP BY ShipCountry;



/*
����-1
*/
	SELECT 
		ShipCountry
	,	Orders = COUNT(*)
	FROM dbo.Orders
	GROUP BY ShipCountry



/*
����-2
*/



