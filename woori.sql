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