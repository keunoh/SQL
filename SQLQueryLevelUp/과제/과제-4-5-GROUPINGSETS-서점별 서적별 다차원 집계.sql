/*
-------------------------------------------------------------------------------
과제 - 서점/서적별 다차원 집계

내용: stor_name/title/payterms 열을 GROUP BY 기준으로 SUM(qty)을 구하되,
	stor_name/title 을 기준으로 소계와 전체 총계를 출력한다.
	정렬 순서는 아래와 같이 출력되도록 조정한다.

*/
/*
준비
*/
USE pubs;
GO


/*
-------------------------------------------------------------------------------
과제 - 서점/서적별 다차원 집계
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
