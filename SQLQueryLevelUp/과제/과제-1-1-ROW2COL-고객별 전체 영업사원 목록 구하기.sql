/*
------------------------------------------------------------------------------
과제 - ROW-TO-COLUMN

내용: 	전체 고객에 대해 거래 담당 영업사원 전체 코드를 ','로 구분해서 하나의 열(column)로 출력
		단, 중복 EmployeeID는 하나만 출력, 주문 없으면 NULL로 출력
------------------------------------------------------------------------------
*/
USE Northwind;
GO


SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE CustomerID = 'FRANS';



/*
과제-1. 
*/
SELECT 
	CustomerID
,	EmpList = 
FROM dbo.Customers AS c
ORDER BY EmpList;


/*
과제-2.
*/





