/*
-------------------------------------------------------------------------------
���� - ����/������ ������ ����

����: stor_name/title/payterms ���� GROUP BY �������� SUM(qty)�� ���ϵ�,
	stor_name/title �� �������� �Ұ�� ��ü �Ѱ踦 ����Ѵ�.
	���� ������ �Ʒ��� ���� ��µǵ��� �����Ѵ�.

*/
/*
�غ�
*/
USE pubs;
GO


/*
-------------------------------------------------------------------------------
���� - ����/������ ������ ����
*/
SELECT 
	st.stor_name
,	ti.title
,	sa.payterms
,	totalqty = SUM(sa.qty)
FROM dbo.sales AS sa
INNER JOIN dbo.stores AS st
	ON sa.stor_id = st.stor_id
INNER JOIN dbo.titles AS ti
	ON sa.title_id = ti.title_id
GROUP BY ......
ORDER BY ......
;
