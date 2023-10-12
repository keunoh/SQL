set autotrace off;

select /*+ ordered use_hash(e) */
    d.dept_no, d.dept_name, e.emp_no, e.emp_name
from dept d, emp e
where d.dept_no = e.dept_no;

SELECT * FROM TABLE(dbms_xplan.display);

explain plan for
select emp_no, emp_name, sal
    , (select /*+ unnest */ d.dept_name from dept d where d.dept_no = e.dept_no) dname
from emp e
where sal >= 2000;

explain plan for
select dept_no, dept_name
    , to_number(substr(sal, 1, 7)) avg_sal
    , to_number(substr(sal, 8, 7)) min_sal
    , to_number(substr(sal, 15)) max_sal
from (
    select /*+ unnest */ 
          d.dept_no, d.dept_name
        , (select lpad(avg(sal), 7) || lpad(min(sal), 7) || max(sal) from emp where dept_no = d.dept_no) sal
    from dept d
    where d.dept_loc = 'CHICAGO'
);
SELECT * FROM TABLE(dbms_xplan.display);

select    
      to_number(substr(sal, 1, 7)) avg_sal
    , to_number(substr(sal, 8, 7)) min_sal
    , to_number(substr(sal, 15)) max_sal
from (
    select lpad(avg(100), 7) || lpad(min(200), 7) || max(300) as sal from dual
);

select dept_name, rowid from dept where rownum <= 1;

alter system set optimizer_mode = all_rows;
alter session set optimizer_mode = all_rows;

explain plan for
select /*+ first_rows(1) */ * from dept;
SELECT * FROM TABLE(dbms_xplan.display);

select /*+ FULL(a) */ *
from 아파트매물 a
where :CITY in ('서울시', '경기도')
and 도시 = :CITY
union all
select /*+ INDEX(a IDX01) */ *
from 아파트매물 a
where :CITY not in ('서울시', '경기도')
and 도시 = :CITY;

select * from table(dbms_xplan.display);
explain plan for
select dept_no, avg_sal
from (
    select dept_no, avg(sal) avg_sal
    from emp
    group by dept_no
)a
where dept_no = '30';

select * from table(dbms_xplan.display);
explain plan FOR
select b.dept_no, b.dept_name, a.avg_sal
from (
    select dept_no, avg(sal) avg_sal
    from emp
    group by dept_no
    ) a
    , dept b
where a.dept_no = b.dept_no
and b.dept_no = '30';


select * from table(dbms_xplan.display);
explain plan for
select *
from (
        select dept_no, avg(sal)
        from emp
        where dept_no = '10'
        group by dept_no
    ) e1,
    (
        select dept_no, min(sal), max(sal)
        from emp
        group by dept_no 
    ) e2
where e1.dept_no = e2.dept_no;

select * from table(dbms_xplan.display);
explain plan for
select d.dept_no, d.dept_name, e.avg_sal
from dept d
    , (select /*+ no_merge push_pred */
            dept_no, avg(sal) avg_sal
        from emp
        group by dept_no) e
where d.dept_no = e.dept_no(+);

select * from table(dbms_xplan.display);
explain plan for
select d.dept_no, d.dept_name
    , (select avg(sal) from emp where dept_no = d.dept_no) avg_sal
    , (select min(sal) from emp where dept_no = d.dept_no) min_sal
    , (select max(sal) from emp where dept_no = d.dept_no) max_sal
from dept d;


select * from table(dbms_xplan.display);
explain plan for
select dept_no, dept_name
    , to_number(substr(sal, 1, 7)) avg_sal
    , to_number(substr(sal, 8, 7)) min_sal
    , to_number(substr(sal, 15)) max_sal
from (
    select /*+ no_merge */ d.dept_no, d.dept_name
        , (select lpad(avg(sal), 7) || lpad(min(sal), 7) || max(sal)
            from emp
            where dept_no = d.dept_no) sal
    from dept d
);

select * from table(dbms_xplan.display);
explain plan for
select *
from dept d, emp e
where d.dept_no = e.dept_no
and e.dept_no = '10'
and e.emp_name = 'kal';

alter table emp add
constraint fk_deptno foreign key(dept_no)
references dept(dept_no);

select * from table(dbms_xplan.display);
explain plan for
select e.emp_no, e.dept_no
from emp e, dept d
where e.dept_no = d.dept_no(+);

select * from table(dbms_xplan.display);
explain plan for
select /*+ use_concat */ *
from emp
where sal = 1000 
or emp_no = '10';

select * from table(dbms_xplan.display);
explain plan for
select sal from emp
minus
select sal from emp
where dept_no = '10';

select * from table(dbms_xplan.display);
explain plan for
select sum(sal), max(sal), min(sal) from emp;

select * from table(dbms_xplan.display);
explain plan for
select * from emp order by sal desc;

select * from table(dbms_xplan.display);
explain plan for
select dept_no, emp_name, sum(sal), min(sal), max(sal)
from emp
group by dept_no, emp_name;

select * from table(dbms_xplan.display);
explain plan for
select distinct dept_no from emp order by dept_no;

select * from table(dbms_xplan.display);
explain plan for
select /*+ ordered use_merge(d) */ *
from emp e, dept d
where e.dept_no = d.dept_no;

select * from table(dbms_xplan.display);
explain plan for
select emp_no, emp_name, dept_no, row_number() over(order by sal)
from emp;

select * from table(dbms_xplan.display);
explain plan for
select emp_no, emp_name from emp where dept_no = '10'
union
select emp_no, emp_name from emp where dept_no = '20';

select * from table(dbms_xplan.display);
explain plan for
select emp_no, emp_name
from emp
where dept_no = '10'
order by emp_name desc;

select * from table(dbms_xplan.display);
explain plan for
select emp_no, sum(sal)
from emp
group by emp_no;

-- INDEX [주문일자 + 주문번호]
select nvl(max(주문번호), 0) + 1
from 주문
where 주문일자 = :주문일자;

-- 1번 쿼리
select lpad(상품번호, 30) || lpad(상품명, 30) || lpad(고객ID, 10)
    || lpad(고객명, 20) || to_char(주문일시, 'yyyymmdd hh24:mi:ss')
from 주문상품
where 주문일시 between :start and :end
order by 상품번호;

-- 2번 쿼리
select lpad(상품번호, 30) || lpad(상품명, 30) || lpad(고객ID, 10)
    || lpad(고객명, 20) || to_char(주문일시, 'yyyymmdd hh24:mi:ss')
from (
    select 상품번호, 상품명, 고객ID, 고객명, 주문일시
    from 주문상품
    where 주문일시 between :start and :end
    order by 상품번호
);

create index dept_no_loc on dept(dept_no, dept_loc);

select * from table(dbms_xplan.display);
explain plan for
select * 
from (
    select /*+ INDEX(dept dept_no_loc) */ *
    from dept
    where dept_no = '10'
    and dept_loc = 'SEOUL'
    order by dept_loc
)
where rownum <= 10;

-- TOP N Sort 알고리즘이 작동하지 못 하는 경우
select *
from (
        select rownum no, 거래일시, 체결건수, 체결수량, 거래대금
        from (select 거래일시, 체결건수, 체결수량, 거래대금
                from 시간별종목거래
                where 종목코드 = 'KR123456'
                and 거래일시 >= '20080304'
                order by 거래일시
                )
        where rownum <= 100        
    )
where no between 91 and 100;

select 고객ID, 변경순번, 전화번호, 주소, 자녀수
from (select 고객ID, 변경순번
            , max(변경순번) over (partition by 고객ID) 마지막변경순번
        from 고객변경이력)
where 변경순번 = 마지막변경순번;
-- 위보다는 아래
select 고객ID, 변경순번, 전화번호, 주소, 자녀수
from (select 고객ID, 변경순번
            , rank() over (partition by 고객ID order by 변경순번) rnum
        from 고객변경이력)
where rnum = 1;

-- COUNT STOP KEY 궁여지책 이용
SELECT 장비번호, 장비명
    , SUBSTR(최종이력, 1, 8) 최종변경일자
    , TO_NUMBER(SUBSTR(최종이력, 9, 4)) 최종변경순번
    , SUBSTR(최종이력, 13) 최종상태코드
FROM (
    SELECT 장비번호, 장비명
    , (SELECT /*+ INDEX_DESC(X 상태변경이력_PK) */
            변경일자 || LPAD(변경순번, 4) || 상태코드
        FROM 상태변경이력 X
        WHERE 장비번호 = P.장비번호
          AND ROWNUM <=1) 최종이력
    FROM 장비 P
    WHERE 장비구분코드 = 'A001'
);

-- 조건절 PUSHING, 12C버전부터 적용가능
SELECT 장비번호, 장비명
    , SUBSTR(최종이력, 1, 8) 최종변경일자
    , TO_NUMBER(SUBSTR(최종이력, 9, 4)) 최종변경순번
    , SUBSTR(최종이력, 13) 최종상태코드
FROM (
    SELECT 장비번호, 장비명
        , (SELECT 변경일자 || LPAD(변경순번, 4) || 상태코드
            FROM (SELECT 변경일자, 변경순번, 상태코드
                    FROM 상태변경이력
                    WHERE 장비번호 = P.장비번호
                    ORDER BY 변경일자 DESC, 변경순번 DESC)
            WHERE ROWNUM <= 1) 최종이력
    FROM 장비 P
    WHERE 장비구분코드 = 'A001'
);

alter session set workarea_size_policy = manual;
alter session set sort_area_size = 10485760;

alter table dept NOLOGGING;

update 주문 set 상태코드 = '9999'
where 주문일시 < to_date('20000101', 'yyyymmdd');

-- Oracle
create table 주문_임시 as select * from 주문;
alter table 주문 drop constraint 주문_pk;
truncate table 주문;

insert into 주문(고객번호, 주문일시, 상태코드)
select 고객번호, 주문일시
    , (case when 주문일시 >= to_date('20000101', 'yyyymmdd') then '9999' else status end) 상태코드
from 주문_임시;

alter table 주문 add constraint 주문_pk primary key(고객번호, 주문일시);
create index 주문_idx1 on 주문(주문일시, 상태코드);

-- 대량 데이터 delete
create table 주문_임시
as
select * from 주문
where 주문일시 >= to_date('20000101', 'yyyymmdd');

alter table emp drop constraint 주문_pk;
drop index 주문_idx1;
truncate table 주문;

insert into 주문
select * from 주문_임시;

alter table 주문_add constraint 주문_pk primary key(고객번호, 주문일시);
create index 주문_idx1 on 주문(주문일시, 상태코드);

-- 조인 내포 UPDATE 튜닝
update 고객
set (최종거래일시, 최근거래금액) = (select max(거래일시), sum(거래금액)
                                from 거래
                                where 고객번호 = 고객.고객번호
                                and 거래일시 >= trunc(add_months(sysdate, -1)))
where exists (select 'x'
                from 거래
                where 고객번호 = 고객.고객번호
                and 거래일시 >= trunc(add_months(sysdate, -1)));

-- ORACLE 수정 가능 조인 뷰 활용
UPDATE
    (SELECT C.최종거래일시, C.최근거래금액, T.거래일시, T.거래금액
        FROM (SELECT 고객번호, MAX(거래일시) 거래일시, SUM(거래금액) 거래금액
                FROM 거래
                WHERE 거래일시 >= TRUNC(ADD_MONTHS(SYSDATE, -1))
                GROUP BY 고객번호) T
            , 고객 C
        WHERE T.고객번호 = C.고객번호)
SET 최종거래일시 = 거래일시
    , 최근거래금액 = 거래금액;
    
SELECT * FROM DEPT;
-- 기본 UPDATE -> 테이블 자리에 조인 뷰를 넣을 수 있다.
UPDATE DEPT SET DEPT_LOC = 'HANAM2';

-- 조인 뷰 2
UPDATE
    (SELECT T.주문연락처, T.배송지주소, C.고객연락처, T.고객주소
        FROM 거래 T, 고객 C
        WHERE T.고객번호 = C.고객번호
        AND T.거래일시 >= TRUNC(SYSDATE)
        AND T.거래검증코드 = 'INVLD')
SET 주문연락처 = 고객연락처
    , 배송지주소 = 고객주소;

-- ORACLE MERGE 문 활용
MERGE INTO 고객 T USING 고객변경분 S ON (T.고객번호 = S.고객번호)
WHEN MATCHED THEN UPDATE
    SET T.고객번호 = S.고객번호, T.고객명 = S.고객명, T.이메일 = S.이메일
WHEN NOT MATCHED THEN INSERT 
    (고객번호, 고객명, 이메일, ...) VALUES
    (S.고객번호, S.고객명, S.이메일, ...);

MERGE INTO 고객 C
USING (SELECT 고객번호, MAX(거래일시) 거래일시, SUM(거래금액) 거래금액
        FROM 거래
        WHERE 거래일시 >= TRUNC(ADD_MONTHS(SYSDATE, -1))
        GROUP BY 고객번호) T
ON (C.고객번호 = T.고객번호)
WHEN MATCHED THEN UPDATE SET C.최종거래일시 = T.거래일시
                            , C.최근거래금액 = T.거래금액; 
                            
select /*+ driving_stie(b) */ channel_id, sum(quantity_sold) authentity_cold
from order a, sales@lk_sales b
where a.order_date between :1 and :2
and b.order_no = a.order_no
group by channel_id;

create or replace function date_to_char(p_dt date) return varchar2
as 
begin
    return to_char(p_dt, 'yyyy/mm/dd hh24:mi:ss');
end;
/

select date_to_char(sysdate) from dual;

create or replace function day_test(p_date varchar2) return varchar2
as
    l_date varchar2(8);
begin
    l_date := to_char(to_date(p_date, 'yyyymmdd'), 'yyyymmdd'); -- 일자 오류 시, exception
    if l_date > to_char(trunc(sysdate), 'yyyymmdd') then
        return 'xxxxxxxx'; -- 미래일자로 입력된 주문 데이터
    end if;
    for i in (select sal from emp where sal = l_date)
    loop
        return 'xxxxxxxx'; -- 휴무일에 입력된 주문데이터
    end loop;
    return l_date; -- 정상적인 주문데이터
exception
    when others then return '00000000'; -- 오류데이터
end;

select day_test('20230606') from dual;
--
select 'hello' from dual;

create table daily
as
select trunc(sysdate - rownum + 1) d_date, to_char(trunc(sysdate - rownum + 1), 'yyyymmdd') c_date
from dual
where rownum <= (trunc(sysdate) - trunc(add_months(sysdate, - (12 * 50)), 'yy') + 1);

select * from daily;

select * from 주문 o
where not exists (select 'x' from 일자 where c_date = o.주문일자)
or exists (select 'x' from 휴무일 where 휴무일자 = o.주문일자);

create table order_detail(order_no number, order_date varchar2(8), customer_id varchar2(5))
partition by range(order_date) (
      partition p2009_q1 values less than ('20200101')
    , partition p2009_q2 values less than ('20200301')
    , partition p2009_q3 values less than ('20200501')
    , partition p2009_q4 values less than ('20200701')
    , partition p2009_q5 values less than ('20200901')
    , partition p9999_max values less than (MAXVALUE)
);

create table order_detail2(order_no number, order_date varchar2(8), customer_id varchar2(5))
partition by range(order_date)
subpartition by hash(customer_id) subpartitions 8
( partition p2009_p1 values less than('20090401')
, partition p2009_p2 values less than('20090601')
, partition p2009_p3 values less than('20090801')
, partition p2009_p4 values less than('20091001')
, partition p2009_p5 values less than('20091201')
, partition p2009_mx values less than(MAXVALUE));

select /*+ full(o) parallel(o, 4) */
    count(*) 주문건수, sum(주문수량) 주문수량, sum(주문금액) 주문금액
from 주문 o
where 주문일시 between '20100101' and '20101231';

select /*+ index_ffs(o, 주문_idx) parallel_index(o, 주문_idx, 4) */
    count(*) 주문건수
from 주문 o
where 주문일시 between '20100101' and '20101231';

select * from table(dbms_xplan.display);
explain plan for
select /*+ ordered use_hash(e) full(e) parallel(e 4) */
    count(*), min(sal), max(sal), avg(sal), sum(sal)
from dept d, emp e
where d.dept_no = e.dept_no
and d.dept_loc = 'SEOUL';

INSERT INTO 월별요금납부실적
 (고객번호, 납입월, 지로, 자동이체, 신용카드, 핸드폰, 인터넷)
SELECT 고객번호, 납입월
    , NVL(SUM(CASE WHEN 납입방법코드 = 'A' THEN 납입금액 END), 0) 지로
    , NVL(SUM(CASE WHEN 납입방법코드 = 'B' THEN 납입금액 END), 0) 자동이체
    , NVL(SUM(CASE WHEN 납입방법코드 = 'C' THEN 납입금액 END), 0) 신용카드
    , NVL(SUM(CASE WHEN 납입방법코드 = 'D' THEN 납입금액 END), 0) 핸드폰
    , NVL(SUM(CASE WHEN 납입방법코드 = 'E' THEN 납입금액 END), 0) 인터넷
FROM 월별납입방법별집계
WHERE 납입월 = '200903'
GROUP BY 고객번호, 납입월;

select rownum no from dual connect by level <=100;

select * 
from dept a
    , (select rownum no
        from dual
        connect by level <= 3)b;

insert into dept values(2, 'program', 'seoul');

select a.카드상품분류
    , (case when b.no = 1 then a.고객등급 else '소계' end) as 고객등급
    , sum(a.거래금액) as 거래금액
from (select 카드.카드상품분류 as 카드상품분류
            , 고객.고객등급 as 고객등급
            , sum(거래금액) as 거래금액
        from 카드월실적, 카드, 고객
        where 실적년월 = '201008'
        and 카드.카드번호 = 카드월실적.카드번호
        and 고객.고객번호 = 카드.고객번호
        group by 카드.카드상품분류, 고객.고객등급) a
    , copy_t b
where b.no <= 2
group by a.카드상품분류, b.no, (case when b.no = 1 then a.고객등급 else '소계' end);

select 상품, 연월, nvl(sum(계획수량), 0) as 계획수량, nvl(sum(실적수량), 0) as 실적수량
from (
    select 상품, 계획연월 as 연월, 계획수량, to_number(null) as 실적수량
    from 부서별판매계획
    where 계획연월 between '200901' and '200903'
    union all
    select 상품, 판매연월, to_number(null), 판매수량
    from 채널별판매실적
    where 판매연월 between '200901' and '200903'
) a
group by 상품, 연월;

select to_number('1') from dual;

SELECT *
FROM (
    SELECT ROWNUM NO, 거래일시, 체결건수
        , 체결수량, 거래대금, COUNT(*) OVER() CNT
      FROM (
        SELECT 거래일시, 체결건수, 체결수량, 거래대금
        FROM 시간별종목거래
        WHERE 종목코드 = :isu_cd -- 사용자가 입력한 종목코드
        AND 거래일시 >= :trd_time
        ORDER BY 거래일시
    )
    WHERE ROWNUM <= :page * pgsize + 1
)
WHERE NO BETWEEN (:page - 1) * :pgsize + 1 AND :pgsize * :page;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
EXPLAIN PLAN FOR
SELECT *
FROM (
    SELECT ROWNUM NO, DEPT_NO, DEPT_NAME, DEPT_LOC, COUNT(*) OVER() CNT
    FROM (
        SELECT DEPT_NO, DEPT_NAME, DEPT_LOC
        FROM DEPT
        ORDER BY DEPT_NO
    )
    WHERE ROWNUM <= 2
)
WHERE NO BETWEEN 1 AND 1;

-- NEXT 버튼 클릭 시
SELECT 거래일시, 체결건수, 체결수량, 거래대금
FROM (
    SELECT 거래일시, 체결건수, 체결수량, 거래대금
    FROM 시간별종목거래 A
    WHERE :페이지이동 = 'NEXT'
    AND 종목코드 = :ISU_CD
    AND 거래일시 >= :TRD_TIME
    ORDER BY 거래일시
)
WHERE ROWNUM <= 11;

-- PREV 버튼 클릭 시
SELECT 거래일시, 체결건수, 체결수량, 거래대금
FROM (
    SELECT 거래일시, 체결건수, 체결수량, 거래대금
    FROM 시간별종목거래 A
    WHERE :페이지이동 = 'PREV'
    AND 종목코드 = :ISU_CD
    AND 거래일시 <= :TRD_TIME
    ORDER BY 거래일시 DESC
)
WHERE ROWNUM <= 11
ORDER BY 거래일시;

-- UNION ALL 활용 페이징처리
SELECT 거래일시, 체결건수, 체결수량, 거래대금
FROM (
    SELECT 거래일시, 체결건수, 체결수량, 거래대금
    FROM 시간별종목거래
    WHERE :페이지이동 = 'NEXT'
    AND 종목코드 = :isu_cd
    AND 거래일시 >= :trd_time
    ORDER BY 거래일시
)
WHERE ROWNUM <= 11
UNION ALL
SELECT 거래일시, 체결건수, 체결수량, 거래대금
FROM (
    SELECT 거래일시, 체결건수, 체결수량, 거래대금
    FROM 시간별종목거래
    WHERE :페이지이동 = 'PREV'
    AND 종목코드 = :isu_cd
    AND 거래일시 <= :trd_time
    ORDER BY 거래일시
)
WHERE ROWNUM <= 11
ORDER BY 거래일시;

-- INDEX [일련번호 + 상태코드]
select 일련번호, 측정값
    , (select /*+ index_desc(장비측정 장비측정_idx) */ 상태코드
         from 장비측정
        where 일련번호 <= o.일련번호
          and 상태코드 is not null
          and rownum <= 1) 상태코드
from 장비측정 o
order by 일련번호;

select 일련번호, 측정값
    , last_value(상태코드 ignore nulls) over(order by 일련번호 rows between unbounded preceding and current row) 상태코드
from 장비측정
order by 일련번호;

-- With 구문 활용
with 위험고객카드 as (select 카드.카드번호, 고객.고객번호
                      from 고객, 카드
                      where 고객.위험고객여부 = 'Y'
                      and 고객.고객번호 = 카드발급.고객번호)
select v.*
from (
    select  a.카드번호 as 카드번호
          , sum(a.거래금액) as 거래금액
          , null as 현금서비스잔액
          , null as 해외거래금액
    from 카드거래내역 a
        , 위험고객카드 b
    where 조건
    group by a.카드번호
    union all
    select a.카드번호
        , null 
        , sum(amt)
        , null
    from (
        select a.카드번호 as 카드번호
            , sum(a.거래금액) as amt
        from 현금거래내역 a
            , 위험고객카드 b
        where 조건
        group by a.카드번호
        union all
        select a.카드번호
            , sum(a.결제금액) * -1
        from 현금결제내역 a
            , 위험고객카드 b
        where 조건
        group by a.카드번호
        ) a
    group by a.카드번호
    union all
    select a.카드번호
        , null 
        , null
        , sum(a.거래금액)
    from 해외거래내역 a
        , 위험고객카드 b
    where 조건
    group by a.카드번호
) v;

set lock_timeout 2000;

select * from t for update wait 3;
commit;

set transaction isolation level read committed;
commit;
set transaction isolation leven snapshot;

-- INDEX : [상담결과코드 + 상담원ID + 상담일자]로 SORT 연산 생략 가능
SELECT 상담원ID, COUNT(*) 상담건수
FROM 상담
WHERE 상담결과코드 = 'RS01'
AND 상담일자 < TRUNC(SYSDATE, 'MM')
GROUP BY 상담원ID;

/* 인덱스 변경 -> 계약_X2 : [상품번호 + 계약일자]
FILTER
    NESTED LOOPS (SEMI)
        TABLE ACCESS (BY INDEX ROWID) OF '상품' (TABLE)
            INDEX (RANGE SCAN) OF '상품_X1'
        INDEX (RANGE SCAN) OF '계약_X2'
*/
SELECT /*+ LEADING(P) */ P.상품번호, P.상품명, P.상품가격, P.상품분류코드
FROM 상품 P
WHERE P.상품유형코드 = :PCLSCD
AND EXISTS (SELECT /*+ UNNEST NL_SJ */ 'X'
            FROM 계약 C
            WHERE C.상품번호 = P.상품번호
            AND C.계약일자 >= TRUNC(ADD_MONTHS(SYSDATE, -12)));
/*
FILTER
    TABLE ACCESS (BY INDEX ROWID) OF '상품'
        INDEX (RANGE SCAN) OF '상품_X1'
    FILTER
        INDEX (RANGE SCAN) OF '계약_X2'
*/
SELECT P.상품번호, P.상품명, P.상품가격, P.상품분류코드
FROM 상품 P
WHERE P.상품유형코드 = :PCLSCD
AND EXISTS (SELECT /*+ NO_UNNEST */ 'X'
            FROM 계약 C
            WHERE C.상품번호 = P.상품번호
            AND C.계약일자 >= TRUNC(ADD_MONTHS(SYSDATE, -12)));

/*
주문에서 읽은 1,000만 건보다 데이터 건수도 적고, 조인 키에 중복 값도 없으므로
해시 맵 Build Input으로는 최적의 조건
<1안> 
1) 인덱스 추가
주문상품_X1 : [상품코드 + 주문번호]
2) 힌트 추가
/+ LEADING(P) USE_HASH(O) FULL(O) INDEX(P 주문상품_X1) /
<2안>
/+ LEADING(P) USE_HASH(O) FULL(O) INDEX_FFS(P 주문상품_PK) /
*/

-- 페이징 처리 패턴
SELECT 계약번호, 상품코드, 계약일시, 계약금액
FROM (
    SELECT ROWNUM AS RNUM, C.*
    FROM (
        SELECT 계약번호, 상품코드, 계약일시, 계약금액
        FROM 계약
        WHERE 지점ID = :BRCH_ID
        AND 계약일시 >= TRUNC(SYSDATE - 7)
        ORDER BY 계약일시 DESC
    ) C
    WHERE ROWNUM <= (:PAGE * 10)
)
WHERE RNUM >= (:PAGE - 1) * 10 + 1;

SELECT MAX(변경일시)
FROM 상품변경이력
WHERE 상품번호 = 'Z1123'
AND 변경일시 >= TRUNC(ADD_MONTHS(SYSDATE, -12))
AND 변경구분코드 = 'C2');

-- FIRST ROW (MIN/MAX) 안되니까
-- INDEX : [상품번호 + 변경구분코드 + 변경일시]
SELECT 변경일시
FROM (
    SELECT 변경일시
     FROM 상품변경이력
    WHERE 상품번호 = 'ZE367'
      AND 변경구분코드 = 'C2'
    ORDER BY 변경일시 DESC
)
WHERE ROWNUM <= 1;

-- 2021년 3월에 변경 상품변경이력 중 최종데이터
SELECT 상품번호, 변경일시
FROM (
    SELECT 상품번호, 변경일시, 변경구분코드
        , ROW_NUMBER() OVER (PARTITION BY 상품번호 ORDER BY 변경일시 DESC) NO
     FROM 상품변경이력
    WHERE 변경일시 >= TO_DATE('20210301' , 'YYYYMMDD')
      AND 변경일시 < TO_DATE('20210401', 'YYYYMMDD')
)
WHERE NO = 1
  AND 변경구분코드 = 'C2';

-- [2안]
SELECT 상품번호, MAX(변경일시) 변경일시
FROM 상품변경이력
WHERE 변경일시 BETWEEN '20210301' AND '20210331'
GROUP BY 상품번호
HAVING MAX(변경구분코드) KEEP (DENSE_RANK LAST ORDER BY 변경일시) = 'C2';

-- 상품할인율 [최적화 X], 인덱스 : [상품번호 + 기준일자 + 변경순번]
SELECT B.기준일자, B.할인율
  FROM (
    SELECT 기준일자, MAX(변경순번) 변경순번
      FROM 상품할인율
     WHERE 상품번호 = 'R0014'
       AND 기준일자 BETWEEN '20210301' AND '20210331'
     GROUP BY 기준일자) A, 상품할인율 B
WHERE A.기준일자 = B.기준일자
  AND A.변경순번 = B.변경순번
  AND B.상품번호 = 'R0014'
ORDER BY B.기준일자;

-- 모범 1안, 인덱스 : [상품번호 + 기준일자 + 변경순번]
SELECT 기준일자, 할인율
  FROM (
    SELECT 기준일자, 할인율
        ,  ROW_NUMBER() OVER(PARTITION BY 기준일자 ORDER BY 변경순번 DESC) NO
      FROM 상품할인율
     WHERE 상품번호 = 'R0014'
       AND 기준일자 BETWEEN '20210301' AND '20210331'
    )
WHERE NO = 1
ORDER BY 기준일자;

-- 2안, 인덱스 : [상품번호 + 기준일자 + 변경순번]
SELECT 기준일자
    ,  MAX(할인율) KEEP (DENSE_RANK LAST ORDER BY 변경순번) 할인율
  FROM 상품할인율
 WHERE 상품번호 = 'R0014'
   AND 기준일자 BETWEEN '20210301' AND '20210331'
 GROUP BY 기준일자
 ORDER BY 기준일자;
 
-- 20번. 인덱스 : [상품번호 + 기준일자 + 변경순번]
SELECT X.할인율
FROM (
    SELECT 할인율
      FROM 상품할인율
     WHERE 상품번호 = 'R0014'
     ORDER BY 기준일자 DESC, 변경순번 DESC
) X
WHERE X.ROWNUM <= 1;
-- 21번. 인덱스 : [상품번호 + 변경일자 + 변경일련번호 + 변경구분코드]
-- IN-LIST는 필터로 풀어줘야함

-- 22번. 인덱스 장비 : [장비번호], 상태변경이력 : [장비번호 + 변경일자 + 변경순번] 
-- 모범1안
SELECT 장비번호, 장비명
    , SUBSTR(최종이력, 13) 최종상태코드
    , SUBSTR(최종이력, 1, 8) 최종변경일자
    , SUBSTR(최종이력, 9 ,4) 최종변경순번
FROM (
    SELECT 장비번호, 장비명
        ,  (SELECT 변경일자 || LPAD(변경순번, 4) || 상태코드
            FROM (
                SELECT 변경일자, 변경순번, 상태코드
                FROM 상태변경이력
                WHERE 장비번호 = P.장비번호
                ORDER BY 변경일자 DESC, 변경순번 DESC)
            WHERE ROWNUM <= 1) 최종이력
    FROM 장비 P
    WHERE 장비구분코드 = 'A001'
)

-- 모범 2안
SELECT P.장비번호, P.장비명
    ,  H.상태코드, H.변경일자, H.변경순번
FROM 장비 P, 상태변경이력 H
WHERE P.장비번호 = H.장비번호
AND P.장비구분코드 = 'A001'
AND (H.변경일자, H.변경순번) = (SELECT 변경일자, 변경순번
                                FROM ( 
                                    SELECT 변경일자, 변경순번
                                    FROM 상태변경이력
                                    WHERE 장비번호 = P.장비번호
                                    ORDER BY 변경일자 DESC, 변경순번 DESC)
                                WHERE ROWNUM <= 1);
                                
/* 성능개선하기
DELETE FROM TARGET_T;
COMMIT;
ALTER SESSION ENABLE PARALLEL DML;

INSERT /+ APPEND / INTO TARGET_T T1
SELECT /+ FULL(T2) PARALLEL(T2 4) / *
FROM SOURCE_T T2;
COMMIT;
ALTER SESSION DISABLE PARALLEL DML;
*/
TRUNCATE TABLE TARGET_T;
ALTER TABLE TARGET_T MODIFY CONSTRAINT TARGET_T_PK DISABLE DROP INDEX;
ALTER SESSION TARGET_T NOLOGGING;

INSERT /*+ PARALLEL(T1 4) */ INTO TARGET_T T1
SELECT /*+ FULL(T2) PARALLEL(T2 4) */ *
FROM SOURCE_T T2;
COMMIT;

ALTER TABLE TARGET_T MODIFY CONSTRAINT TARGET_T_PK ENABLE NOVALIDATE;
ALTER TABLE TARGET_T LOGGING;
ALTER SESSION DISABLE PARALLEL DML;

/* 성능 개선 */
CREATE TABLE MYTAB_TEMP
NOLOGGING -- 추가
AS
SELECT C0 AS ID, C1, C2, C3
    , (CASE WHEN C1 < TRUNC(SYSDATE) THEN C4 + 1 ELSE C4 END) AS C4
FROM YUOURTAB@RDS
WHERE C0 IS NOT NULL
AND C5 > 0;

DECLARE
    V_CNT NUMBER;
BEGIN
    -- ID에 중복값이 있는지 확인
    SELECT COUNT(*) INTO V_CNT
    FROM (SELECT ID
            FROM MYTAB_TEMP
            GROUP BY ID
            HAVING COUNT(*) > 1);
    
    IF V_CNT > 0 THEN
        INSERT_LOG (SYSDATE, 'INSERT MYTAB_TEMP', 'FAIL', '중복 데이터');
    ELSE
        -- 배치 프로그램을 재실행할 경우를 대비하기 위한 DELETE (보통 0건 삭제)
        DELETE FROM MYTAB WHERE DT = TO_CHAR(SYSDATE, 'YYYYMMDD');
        
        INSERT INTO MYTAB(DT, ID, C1, C2, C3, C4)
        SELECT TO_CHAR(SYSDATE, 'YYYYMMDD'), A.* FROM MYTAB_TEMP A;
    
        V_CNT := SQL%ROWCOUNT;
        INSERT_LOG (SYSDATE, 'INSERT MYTAB_TEMP', 'SUCCESS', V_CNT || ' ROWS');
    END IF;
    
    COMMIT;
END;
/
DROP TABLE MYTAB_TEMP;

/*
UPDATE OF '고객'
    TABLE ACCESS (FULL) OF '고객'  (TABLE)
    TABLE ACCESS (BY INDEX ROWID) OF '고객'  (TABLE)
        INDEX (UNIQUE SCAN) OF '고객번호_PK' (INDEX(UNIQUE))
*/
-- 1.
UPDATE 고객 C
    SET 법정대리인_연락처 = NVL((SELECT 연락처 FROM 고객 WHERE 고객번호 = C.법정대리인_고객번호), C.법정대리인_연락처)
WHERE 성인여부 = 'N';
-- 2.
UPDATE 고객 C
    SET 법정대리인_연락처 = (SELECT 연락처 FROM 고객 WHERE 고객번호 = C.법정대리인_고객번호)
WHERE C.성인여부 = 'N'
AND EXISTS (SELECT /*_ UNNEST NL_SJ */ 'X' FROM 고객 WHERE 고객번호 =  C.법정대리인_고객번호);

-- 3. 모범 1안
UPDATE (
    SELECT /*+ LEADING(C) USE_NL(P) INDEX(C 고객_X3) INDEX(P 고객_PK) */
        C.법정대리인_연락처, P.연락처
    FROM 고객 C, 고객 P
    WHERE C.성인여부 = 'N'
    AND C.법정대리인_고객번호 IS NOT NULL
    AND P.고객번호 = C.법정대리인_고객번호
    AND P.연락처 <> C.법정대리인_연락처
)
SET 법정대리인_연락처 = 연락처;

-- 4. 모범 2안
MERGE /*+ LEADING(C) USE_NL(P) INDEX(C 고객_X3) INDEX(P 고객_PK) */ INTO 고객 C
USING 고객 P
    ON ( C.성인여부 = 'N'
        AND C.법정대리인_고객번호 IS NOT NULL
        AND P.고객번호 = C.법정대리인_고객번호)
WHEN MATCHED THEN UPDATE
SET C.법정대리인_연락처 = P.연락처
WHERE C.법정대리인_연락처 <> P.연락처;

-- Q.
UPDATE 상품재고 T
    SET T.품절유지일 =
        NVL((SELECT TRUNC(SYSDATE) - TO_DATE(MAX(A.변경일자), 'YYYYMMDD')
               FROM 상품재고이력 A, 상품재고 B
               WHERE A.상품번호 = B.상품번호
               AND B.업체코드 = 'Z'
               AND B.가용재고량 = 0
               AND NVL(B.가상재고수량, 0) <= 0
               AND A.상품번호 = T.상품번호)
            , T.품절유지일)
    WHERE T.업체코드 = 'Z'
    AND T.가용재고량 = 0
    AND NVL(T.가상재고수량, 0) <= 0;

MERGE INTO 상품재고 T
USING 상품재고이력 A, 상품재고 B
    ON (A.상품번호 = B.상품번호
        AND B.업체코드 = 'Z'
        AND B.가용재고량 = 0
        AND NVL(B.가상재고수량, 0) <= 0
        AND A.상품번호 = T.상품번호)
WHEN MATCHED THEN UPDATE
SET T.품절유지일 = TRUNC(SYSDATE) - TO_DATE(MAX(A.변경일자), 'YYYYMMDD');

-- 모범 1안
UPDATE /*+ LEADING(T) */ 상품재고 T
    SET T.품절유지일 = (SELECT TRUNC(SYSDATE) - TO_DATE(MAX(변경일자), 'YYYYMMDD') FROM 상품재고이력 WHERE 상품번호 = T.상품번호)
WHERE T.업체코드 = 'Z'
AND T.가용재고량 = 0
AND NVL(T.가상재고수량, 0) <= 0
AND EXISTS (SELECT /*+ NL_SJ UNNEST */ 'X' FROM 상품재고이력 WHERE 상품번호 = T.상품번호);
-- 모범 2안
UPDATE /*+ LEADING(T) */ 상품재고 T
    SET T.품절유지일 = (SELECT TRUNC(SYSDATE) - TO_DATE(MAX(A.변경일자), 'YYYYMMDD') FROM ( SELECT 변경일자 FROM 상품재고이력 WHERE 상품번호 = T.상품번호 ORDER BY 변경일자 DESC) A WHERE ROWNUM <= 1)
WHERE T.업체코드 = 'Z'
AND T.가용재고량 = 0
AND NVL(T.가상재고수량, 0) <= 0
AND EXISTS (SELECT /*+ NL_SJ UNNEST */ 'X' FROM 상품재고이력 WHERE 상품번호 = T.상품번호); 
-- 모범 3안
MERGE INTO 상품재고 X
USING (
    SELECT /*+ LEADING(A) NO_MERGE(B) USE_NL(B) PUSH_PRED(B) */ A.상품번호, B.신규_품질유지일
    FROM 상품재고 A
        , (SELECT 상품번호, (TRUNC(SYSDATE) - TO_DATE(MAX(변경일자), 'YYYYMMDD')) 신규_품절유지일 FROM 상품재고이력 GROUP BY 상품번호) B
    WHERE A.업체코드 = 'Z'
    AND A.가용재고량 = 0
    AND NVL(A.가상재고수량, 0) <= 0
    AND A.상품번호 = B.상품번호
    AND A.품절유지일 <> B.신규_품절유지일
) Y 
ON (X.상품번호 = Y.상품번호)
WHEN MATCHED THEN UPDATE SET X.품절유지일 = Y.신규_품절유지일;