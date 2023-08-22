# 쿼리작성법

1. 성능과 유지관리 고려
   - JOIN, ORDER BY, WITH ROLLUP 등
   - 사라지는 구문들은 사용배제
       - SELECT * 
       - FROM dbo.Orders AS o
       - INNER JOIN dbo.[Order Details] AS d
       - ON o.OrderID = d.OrderID

2. WHERE 절 작성 순서는 상관이 없이 Optimizer가 판단해서 해준다.
   - 수학에서 A + B = B + A 인 것처럼 

3. FROM 절 작성 순서도 Optimizer 판단에 의해서 성능이 좋은 쪽으로 JOIN 한다.
   - INNER JOIN 사용할 때는 고민하지 않아도 되고, OUTER JOIN은 다르다.

4. 스키마 이름 지정
   - 되도록 스키마도 함께 작성해주는 것이 좋다.
   - 개체 유일성
   - db.schema.object
   - schema 생략 시 ID 사용 
   - SELECT * FROM dbo.A, EXEC dbo.up_Orders

5. 코드에서 임의/매개변수 쿼리의 호출 식별자 달기
   - 주석에 호출 모듈 설명 달기

6. 의미 오류(Semantic Error)
   - IS NULL 조건을 지정할 때 이미 NOT NULL 컬럼이거나, PK라면 의미가 없는 조건절
   - CHECK(Quantity > 0)인 컬럼 상황에서 WHERE Quantity < 0 는 의미 없는 조건걸
   - SELECT OrderDate, CustomerID FROM dbo.Orders WHERE CustomerID = 'QUICK';
     - 이미 CustomerID = 'QUICK'라는게 명확하므로 SELECT 절에 쓰지 않는 것이 좋다.
   - EXISTS 안에 SELECT 절은 옵티마이저의 관심 밖이다. 즉, 관계없음
   - NOT IN (NULL) -> SubQuery 안의 결과가 한 건이라도 NULL이라면 이 조건은 확인불가가 되어서 외부 쿼리의SELECT 결과가 나오지 않는다.
   - OUTER JOIN을 할 때 기준테이블을 WHERE 조건절에 적어주어야 한다. OUTER JOIN되는 테이블을 조건절에 적어주면 의미없는 OUTER JOIN이 된다.