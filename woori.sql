-- VAN-Fee1
SELECT 
       A.MTMS_DT
		 , A.SWMP_VAN_CD
		 , A.SWMP_FROT_ISCD
		 , SUM(DECODE(A.WMP_dcme_APV_TRN_DSCD || A.SWMP_APV_PRC_RSCD || A.NTW_CAN_YN, '100N', 1, 0)) AS APV_CNT -- 승인건수
		 , SUM(DECODE(A.WMP_dcme_APV_TRN_DSCD || A.SWMP_APV_PRC_RSCD || A.NTW_CAN_YN, '200N', 1, '300N', 1, 0)) AS CNCL_CNT -- 취소건수
		 , SUM(DECODE(A.WMP_dcme_APV_TRN_DSCD || A.SWMP_APV_PRC_RSCD || A.NTW_CAN_YN
                  , '100N'
                  , (SELECT CASE X.SWMP_VAN_UTZF_DSCD WHEN '01' THEN X.SWMP_VAN_UTZF_AM
																																	 ELSE ROUND(TRUNC(A.SWMP_TRN_AM * X.SWMP_VAN_UTZF_AM / 100, 2), 1) 
                             END
                       FROM MY_TABLE X
                      WHERE X.SWMP_VAN_CD = A.SWMP_VAN_CD)
										, 0
                   )
            ) AS FXRT_APV_UTZF_SUM_AM -- 승인이용료
  FROM MY_TABLE2 A
 WHERE 1 = 1
   AND A.FTLS_RLY_ISCD = :ftlsRlyIscd
 GROUP BY A.MTMS_DT, A.SWMP_VAN_CD, A.SWMP_FROT_ISCD


-- Trailer SUM Case
SELECT SUM(DECODE(SWMP_DCME_APV_TRN_DSCD, '1', 1, 0)) AS APV_CNT -- 승인건수
     , SUM(DECODE(SWMP_VAN_UTZF_DSCD, '1', SWMP_VAN_UTZF_AM, ROUND(TRUNC(SWMP_TRN_AM * SWMP_VAN_UTZF_AM, 2), 1)))
  FROM MY_TABLE
 WHERE 1 = 1
   AND MTMS_DT BETWEEN '20251001' AND '20251031'

-- CASE Query -> 재미있는 쿼리인데 구분값을 하드코딩해주고
-- 프로그램소스에서 그에따라 분기처리해서 SUM 값을 하나만 가져오는 방식

SELECT 'CTUP' AS TRN_DIS
		 ,  SUM(SUBSTRB(TLM_ALL_TXT, 88, 18)) AS AM_SUM
  FROM MY_TABLE
 WHERE cond1 = :input
   AND 구분코드 = '21'
   AND 구분코드 = :input2
 GROUP BY 1
 UNION ALL
SELECT 'CTUPCNT'
     , COUNT(*)
  FROM MY_TABLE
 WHERE cond1 = :input 
   AND 구분코드 = '21'
   AND 구분코드 = :input2
 GROUP BY 1
 UNION ALL
SELECT 'PSNC'
     , SUM(SUBSTRB(TLM_ALL_TXT, 1, 19))
  FROM MY_TABLE
 WHERE cond1 = :input
   AND 구분코드 = '14'
   AND 구분코드 = :input2
 GROUP BY 1
..... 쭉쭉

-- 프로그램에서는 만약 구분코드값이 'CTUPCNT' 면
-- 해당 컬럼에 값을 SET
-- 그리고 input2값이 들어오기 때문에 해당건만 SQL에서 나올거임
-- 즉 최대 row 2개(건수, 총금액)
-- 그래서 for문을 하더라도 사실상 최대 2건인 셈
for i {
	if(Out.C_TrnDis[ll_Tnum] == 'CTUP') {
			LNT2NUM(BIZOT->n_AmSum1, Out.l_AmSum[ll_Tnum]);
	}
}













