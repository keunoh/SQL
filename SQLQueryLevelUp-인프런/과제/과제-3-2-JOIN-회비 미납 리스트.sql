/*
-------------------------------------------------------------------------------
���� - ����

����: ��ü ȸ���� �̳� ȸ��/ȸ�� ����Ʈ ���

*/
/*
�غ�
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
	���� ������
*/
INSERT Members VALUES (1, '����ȣ');
INSERT Members VALUES (2, '�躴��');
INSERT Members VALUES (3, '����');

INSERT MemberFee VALUES (1, '1��ȸ��', 20000);
INSERT MemberFee VALUES (2, '2������ȸ��', 10000);

INSERT PayLists VALUES (1, 1, '20041224');
INSERT PayLists VALUES (1, 2, '20041225');
INSERT PayLists VALUES (2, 2, '20041225');


/*
-------------------------------------------------------------------------------
����

	MemberID    FeeID       FeeName
	----------- ----------- --------------------
	2           1           1��ȸ��
	3           1           1��ȸ��
	3           2           2������ȸ��
*/
SELECT 
	MemberID, FeeID, FeeName
FROM 
(
) AS f
WHERE 

