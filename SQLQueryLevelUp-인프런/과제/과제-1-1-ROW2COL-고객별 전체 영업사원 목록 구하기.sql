/*
------------------------------------------------------------------------------
���� - ROW-TO-COLUMN

����: 	��ü ���� ���� �ŷ� ��� ������� ��ü �ڵ带 ','�� �����ؼ� �ϳ��� ��(column)�� ���
		��, �ߺ� EmployeeID�� �ϳ��� ���, �ֹ� ������ NULL�� ���
------------------------------------------------------------------------------
*/
USE Northwind;
GO


SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE CustomerID = 'FRANS';



/*
����-1. 
*/
SELECT 
	CustomerID
,	EmpList = 
FROM dbo.Customers AS c
ORDER BY EmpList;


/*
����-2.
*/





