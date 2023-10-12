/*
-------------------------------------------------------------------------------
과제 - 행 열 바꾸기 (행열 전치/이항)

내용: 아래와 같은 R1~R3, C1~C3의 값을 서로 바꾸어 출력하기

--> 원본
R  C1	C2	C3
----------
R1	1	5	1
R2	8	4	3
R3	2	2	9

--> 출력 결과
C	R2	R2	R3
----------
C1	1	8	2
C2	5	4	2
C3	1	3	9

*/
/*
준비하기
*/
USE tempdb;
GO

DROP TABLE RowCols;

CREATE TABLE RowCols (
    R varchar(10), C1 int, C2 int, C3 int
);
GO

INSERT RowCols 
VALUES ('R1' ,1 ,5 ,1)
    , ('R2' ,8 ,4 ,3)
    , ('R3' ,2 ,2 ,9)
GO


/*
과제
*/
SELECT *
FROM RowCols
;



