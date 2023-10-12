/*
-------------------------------------------------------------------------------
과제-기존 열에 일렬번호 달기

내용: SetNumber 테이블의 ID 열에 1~10까지 일련번호가 저장되도록 UPDATE 문을 완성
*/

/*
준비
*/
USE tempdb;
GO


IF OBJECT_ID('dbo.SetNumber', 'U') IS NOT NULL
  DROP TABLE dbo.SetNumber
GO

CREATE TABLE dbo.SetNumber 
(
	ID		int
,	Name	varchar(10)
)

INSERT dbo.SetNumber (ID, Name)
SELECT TOP(10) 0, LEFT(Name, 10) FROM sys.objects;

SELECT * FROM dbo.SetNumber;


/*
과제

	참고) UPDATE SET절의 특별한 동작을 이해하기 위한 목적임.
		실제론 순번 기준에 대한 일관성을 만족하지 못하고 있으므로 다른 방법을 고려하는 것이 좋음.
*/
DECLARE @i int = 0;

UPDATE dbo.SetNumber
	SET	/* Complete code here */


-- 확인용
SELECT * FROM dbo.SetNumber;



/*
-------------------------------------------------------------------------------
옵션 과제) Name 열 정렬 기준으로 ID열에 1~10까지 일련번호 할당하는 UPDATE 문 완성
*/
WITH Number AS
(
)
UPDATE Number 
SET ID = Seq;


-- 확인
SELECT * FROM dbo.SetNumber
ORDER BY Name;
