# 쿼리작성법

1. 성능과 유지관리 고려
- JOIN, ORDER BY, WITH ROLLUP 등
- 사라지는 구문들은 사용배제
    - SELECT * 
    - FROM dbo.Orders AS o
    - INNER JOIN dbo.[Order Details] AS d
    - ON o.OrderID = d.OrderID;