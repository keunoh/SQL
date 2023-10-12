/*
-------------------------------------------------------------------------------
과제 #1 - Rank 구하기

내용: Self Join을 이용해서 Rank와 Dense_Rank를 구한다.

	- Ranking: 동률처리 (1, 2, 2, 4,...) 
	- Dense Ranking: 동률처리 (1, 2, 2, 3, ...)
*/
/*
데이터 준비
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
과제
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





