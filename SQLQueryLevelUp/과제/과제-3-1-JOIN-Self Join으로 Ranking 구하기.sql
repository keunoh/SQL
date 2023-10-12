/*
-------------------------------------------------------------------------------
���� #1 - Rank ���ϱ�

����: Self Join�� �̿��ؼ� Rank�� Dense_Rank�� ���Ѵ�.

	- Ranking: ����ó�� (1, 2, 2, 4,...) 
	- Dense Ranking: ����ó�� (1, 2, 2, 3, ...)
*/
/*
������ �غ�
*/
USE tempdb;
GO

IF OBJECT_ID('dbo.Sales', 'U') IS NOT NULl
	DROP TABLE dbo.Sales;
GO

CREATE TABLE dbo.Sales
(
	SalesYMD	date				PRIMARY KEY
,	Amount		decimal(18, 0)
);

INSERT dbo.Sales
VALUES
	('20150101', 3000)
,	('20150102', 2500)
,	('20150103', 1500)
,	('20150104', 4500)
,	('20150105', 3500)
,	('20150106', 2500);

SELECT * FROM dbo.Sales;



/*
-------------------------------------------------------------------------------
����
*/
/*
Rank
*/
SELECT
	s1.SalesYMD
,	s1.Amount
,	[Rank] = 
FROM
	dbo.Sales AS s1
;


/*
Dense Rank
*/
SELECT
	s1.SalesYMD
,	s1.Amount
,	DenseRank = 
FROM
	dbo.Sales AS s1
;





