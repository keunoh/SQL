/*
-------------------------------------------------------------------------------
����-���� ���� �ϷĹ�ȣ �ޱ�

����: SetNumber ���̺��� ID ���� 1~10���� �Ϸù�ȣ�� ����ǵ��� UPDATE ���� �ϼ�
*/

/*
�غ�
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
����

	����) UPDATE SET���� Ư���� ������ �����ϱ� ���� ������.
		������ ���� ���ؿ� ���� �ϰ����� �������� ���ϰ� �����Ƿ� �ٸ� ����� ����ϴ� ���� ����.
*/
DECLARE @i int = 0;

UPDATE dbo.SetNumber
	SET	/* Complete code here */


-- Ȯ�ο�
SELECT * FROM dbo.SetNumber;



/*
-------------------------------------------------------------------------------
�ɼ� ����) Name �� ���� �������� ID���� 1~10���� �Ϸù�ȣ �Ҵ��ϴ� UPDATE �� �ϼ�
*/
WITH Number AS
(
)
UPDATE Number 
SET ID = Seq;


-- Ȯ��
SELECT * FROM dbo.SetNumber
ORDER BY Name;
