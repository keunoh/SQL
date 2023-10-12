/*
-------------------------------------------------------------------------------
과제 - 조인

내용: 전체 회원의 미납 회원/회비 리스트 출력

*/
/*
준비
*/
USE tempdb;
GO

CREATE TABLE dbo.Members (
	MemberID int PRIMARY KEY
,	MemberName varchar(8)
)

CREATE TABLE dbo.MemberFee (
	FeeID		int PRIMARY KEY
,	FeeName	varchar(20)
,	Fee		money
)

CREATE TABLE dbo.PayLists (
	MemberID int
,	FeeID		int 
,	Day		datetime
	PRIMARY KEY (MemberID, FeeID)
)

/*
	예제 데이터
*/
INSERT Members VALUES (1, '박찬호');
INSERT Members VALUES (2, '김병현');
INSERT Members VALUES (3, '최희섭');

INSERT MemberFee VALUES (1, '1월회비', 20000);
INSERT MemberFee VALUES (2, '2월야유회비', 10000);

INSERT PayLists VALUES (1, 1, '20041224');
INSERT PayLists VALUES (1, 2, '20041225');
INSERT PayLists VALUES (2, 2, '20041225');


/*
-------------------------------------------------------------------------------
과제

	MemberID    FeeID       FeeName
	----------- ----------- --------------------
	2           1           1월회비
	3           1           1월회비
	3           2           2월야유회비
*/
SELECT 
	MemberID, FeeID, FeeName
FROM 
(
) AS f
WHERE 

