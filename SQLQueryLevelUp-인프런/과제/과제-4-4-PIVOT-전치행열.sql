/*
-------------------------------------------------------------------------------
���� - �� �� �ٲٱ� (�࿭ ��ġ/����)

����: �Ʒ��� ���� R1~R3, C1~C3�� ���� ���� �ٲپ� ����ϱ�

--> ����
R  C1	C2	C3
----------
R1	1	5	1
R2	8	4	3
R3	2	2	9

--> ��� ���
C	R2	R2	R3
----------
C1	1	8	2
C2	5	4	2
C3	1	3	9

*/
/*
�غ��ϱ�
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
����
*/
SELECT *
FROM RowCols
;



