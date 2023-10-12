/*
-------------------------------------------------------------------------------
과제 - 재귀 CTE - 메뉴/상위 노드 검색

내용: Menu 테이블에서 MenuID = 6을 기준으로 최상위 메뉴까지 이동하면서,
	각 메뉴의 이름을 '/' 문자로 결합해 출력한다. 단 메뉴 이름의 출력순서는
	상위메뉴 순서로 하며 결과는 다음과 같다.

*/
/*
준비
*/
USE tempdb;
GO

IF OBJECT_ID('dbo.Menus', 'U') IS NOT NULL
	DROP TABLE dbo.Menus
GO

SELECT *
INTO dbo.Menus
FROM (VALUES
	('A', 1, NULL) 
,	('B', 2, 1)
,	('C', 3, 2)
,	('D', 4, 3)
,	('E', 5, 2) 
,	('F', 6, 2) 
) AS Menus(Name, MenuID, ParentMenuID);

-- 전체 데이터
SELECT * FROM dbo.Menus;


/*
-------------------------------------------------------------------------------
과제

	MenuID      ParentMenuID lvl         MenuPath
	----------- ------------ ----------- ---------------------------------------
	6           2            0           F
	2           1            1           B/F
	1           NULL         2           A/B/F

*/
WITH MenuPath (MenuID, ParentMenuID, lvl, MenuPath)
AS
(
	SELECT 
	FROM dbo.Menus AS m
	WHERE MenuID = 6

	UNION ALL

	SELECT 
	FROM dbo.Menus AS m

)
SELECT *
FROM MenuPath AS p
;


