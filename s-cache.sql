<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "https://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.kaltz.commonmoney.money.mapper.CacheOpMapper">

    <!-- 조정그룹ID 채번 -->
    <select id="getAdjtGrpId" resultType="String">
        SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(TB_MONY_ADJT_GRP_SQ01.NEXTVAL, 4, 0) SEQ FROM DUAL
    </select>

    <!-- 은행거래고유번호 채번 -->
    <select id="getBankTrxUnqNo" resultType="String">
        SELECT 'M202201890' || 'U' || LPAD(TB_API_TRX_ITM_SQ02.NEXTVAL, 9, 0) SEQ FROM DUAL
    </select>

    <!-- 거래일련번호 채번 -->
    <select id="selectTrxSno" resultType="String">
        SELECT TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || LPAD(TL_MONY_TRX_LOG_SQ01.NEXTVAL, 6, 0) SEQ
    </select>

    <!-- 회원상태, 등록계좌 존재유무 조회 -->
    <select id="selectMbrRegAcnt" parameterType="com.kaltz.commonmoney.money.vo.MonyDfraDepoPVO" resultType="com.kaltz.commonmoney.money.vo.MbrRegAcntRVO">
        SELECT
            A.KFTC_USER_SNO, A.CUST_KRN_NM, A.BIRTH, A.SERT_NO, A.SERT_NO_ERR_CNT,
            B.FNTC_UTL_NO, SCP.DEC_STR('KEY1', B.ACNT_NO) AS ACNT_NO, B.INST_ID,
            (SELECT INST_CD FROM TB_FNC_INST WHERE INST_ID = B.INST_ID) AS INST_CD
        FROM TB_MBR_INFO A
        LEFT JOIN TB_REG_ACNT B
            ON (A.MBR_NO    = B.MBR_NO
            AND B.USE_YN    = 'Y')
        WHERE A.MBR_NO      = #{mbrNo}
        AND A.MBR_ST_CD     = '00'
        <!-- 개인적 튜닝
         어차피 두 개의 데이터가 존재하는지 여부를 따지려면 INNER 조인으로 처리해도 되지 않을까?
        SELECT
              A.KFTC_USER_SNO
            , A.CUST_KRN_NM
            , A.BIRTH
            , A.SERT_NO
            , A.SERT_NO_ERR_CNT
            , B.FNTC_UTL_NO
            , SCP.DEC_STR('KEY1', B.ACNT_NO) AS ACNT_NO
            , B.INST_ID
            , (SELECT INST_CD FROM TB_FNC_INST WHERE INST_ID = B.INST_ID) AS INST_CD
        FROM TB_MBR_INFO A
            INNER JOIN TB_REG_ACNT B
                ON A.MBR_NO = B.MBR_NO
                AND B.USE_YN = 'Y'
        WHERE A.MBR_NO = #{mbrNo}
        AND A.MBR_ST_CD = '00' -->
    </select>

    <!-- 최초결제여부 및 리워드지급여부 조회 -->
    <select id="selectFsPaymRewd" parameterType="com.kaltz.commonmoney.money.vo.MonyDfraDepoPVO" resultType="com.kaltz.commonmoney.money.vo.FsPaymRewdRVO">
        SELECT
            A.CNT, MONY_TRX_CNT, NVL(B.REWD_AMT, 0) REWD_AMT
        FROM (
            SELECT COUNT(*) AS CNT
            FROM TB_MONY_TRX
            WHERE MBR_NO = #{mbrNo}
            AND TRX_CL_CD = '10'
        ) A
        LEFT JOIN
        (
            SELECT
            CASE WHEN #{trxAmt} >= DISB_STD_AMT
                 THEN CASE WHEN #{trxAmt}/RESV_RATE >= MAX_DISB_AMT
                      THEN MAX_DISB_AMT
                      ELSE #{trxAmt}/RESV_RATE
                 END
                 ELSE 0
             END REWD_AMT
        FROM TB_REWD_SET
        WHERE SVC_CL_CD = '520'
        AND USE_YN = 'Y'
        <![CDATA[AND APLY_STA_DT <= TO_CHAR(SYSDATE, 'YYYYMMDD') AND APLY_END_DT >= TO_CHAR(SYSDATE, 'YYYYMMDD')
        ORDER BY FS_ORT_DTL_DTM DESC
        FETCH FIRST 1 ROW ONLY) B ON 1=1]]>
    </select>

    <!-- 중복 거래고유번호 조회 -->
    <select id="selectDupTrxUnqNoInq" parameterType="com.kaltz.commonmoney.money.vo.MonyDfraDepoPVO" resultType="Integer">
        SELECT
            COUNT(*) CNT
        FROM TB_MONY_TRX
        WHERE TRX_UNQ_NO = #{trxUnqNo}
        AND ACC_CL_CD = #{accClCl}
        AND TRX_CL_CD = #{trxClCd}
    </select>

    <!-- 중복 은행거래고유번호 조회 -->
    <select id="selectDupTranIdInq" parameterType="com.kaltz.commonmoney.money.vo.MonyDfraDepoPVO" resultType="Integer">
        SELECT
            COUNT(*) CNT
        FROM TL_MONY_TRX_LOG
        WHERE BANK_TRX_UNQ_NO = #{tranId}
    </select>

    <!-- 이상거래 조회 -->
    <select id ="selectStngMonyTrxInq" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO" resultType="Integer">
        SELECT /* common.money.mapper.CacheOpMapper.selectStngMonyTrxInq */
        COUNT(*) CNT
        FROM TB_MONY_TRX
        WHERE MBR_NO 		= #{mbrNo}
        AND TRX_AMT 		= #{trxAmt}
        AND TRX_CL_CD		= #{trxClCd}
        AND MONY_TYP_CD	= #{monyTypCd}
        AND TRX_DT > SYSDATE - INTERVAL '1' MINUTE AND TRX_DT <![CDATA[<=]]> SYSDATE
        AND CNCL_DT NOT IN ('1')
    </select>

    <!-- 이요기관계좌정보 조회 -->
    <select id="selectLsRecpAcntInfo" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO" resultType="com.kaltz.common.money.vo.LsRecpAcntRVO">
        SELECT /* common.money.mapper.CacheOpMapper.selectLsRecpAcntInfo */
        *
        FROM (
        SELECT
        A.USIS_CD, B.INST_ID, B.PRMS_ACNT_ACC_CL_CD, B.PRMS_ACNT_ACC_NO,
        B.DFRA_ACNT_PRN_VAL, B.DEPO_TFMY_ENCT_PHR_CTT, B.ACNT_ALIAS_NM
        FROM TB_USIS_INFO A
        LEFT JOIN TB_USIS_REG_ACNT B
        ON A.USIS_CD = B.USIS_CD
        WHERE B.RAR_CL_CD = #{usisRarClCd}
        ORDER BY B.ACNT_REG_SEQ DESC
        )
        WHERE ROWNUM = 1
    </select>

    <!-- 머니지급거래 조회 -->
    <select id="selectDisbMonyTrx" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO" resultType="com.kaltz.common.money.vo.MonyDisbRVO">
        SELECT  /* common.money.mapper.CacheOpMapper.selectDisbMonyTrx */
        TRX_SNO, TRX_DT, TRX_AMT, CNCL_CL_CD
        FROM TB_MONY_TRX
        WHERE TRX_UNQ_NO 	= #{orglTrxUnqNo}
        AND TRX_CL_CD	= #{orglTrxClCd}
        AND MBR_NO 		= #{mbrNo}
    </select>

    <!-- 머니거래 등록 -->
    <insert id="insertMonyTrx" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO">
        INSERT INTO TB_MONY_TRX ( /* common.money.mapper.CacheOpMapper.insertMonyTrx */
        TRX_SNO, TRX_DT, FNTC_UTL_NO, ATA_CARD_NO, MBR_NO,
        RAR_CL_CD, MONY_TYP_CD, RECH_TYP_CD,
        TRX_CL_CD, ACC_CL_CD, TRX_TM, TRX_AMT, MCHT_BIZC_CD, MCHT_NO,
        MCHT_NM, AVL_PRD, TRX_UNQ_NO, ORGL_TRX_UNQ_NO,
        ORGL_TRX_DT, ORGL_TRX_AMT, CNCL_CL_CD,
        FS_ORT_EMP_NO, FS_ORT_DTL_DTM, FS_ORT_TRX_NM, LS_ORT_EMP_NO, LS_ORT_DTL_DTM, LS_ORT_TRX_NM
        ) VALUES (
        #{trxSno}, TO_DATE(#{tranDtime}, 'YYYYMMDD') + (SYSDATE - TRUNC(SYSDATE)), #{fntcUtlNo}, #{ataCardNo}, #{mbrNo},
        #{rarClCd}, #{monyTypCd}, #{rechTypCd},
        #{trxClCd}, #{accClCd}, TO_CHAR(SYSDATE, 'HH24MISS'), #{trxAmt}, #{mchtBizcCd}, #{mchtNo},
        #{mchtNm}, #{avlPrd}, #{trxUnqNo}, #{orglTrxUnqNo},
        #{orglTrxDt}, #{orglTrxAmt}, #{cnclClCd},
        #{fsOrtEmpNo}, SYSTIMESTAMP, #{fsOrtTrxNm},
        #{lsOrtEmpNo}, SYSTIMESTAMP, #{lsOrtTrxNm}
        )
    </insert>

    <!-- 머니거래로그 등록 -->
    <insert id="insertMonyTrxLog" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO">
        INSERT INTO TL_MONY_TRX_LOG ( /* common.money.mapper.CacheOpMapper.insertMonyTrxLog */
        TRX_SNO, TRX_DT, FNTC_UTL_NO, BANK_TRX_UNQ_NO, MBR_NO,
        ATA_CARD_NO, RAR_CL_CD, MONY_TYP_CD, RECH_TYP_CD, TRX_CL_CD,
        ACC_CL_CD, TRX_TM, TRX_AMT,
        ORGL_TRX_UNQ_NO, ORGL_TRX_DT, ORGL_TRX_AMT,
        MCHT_NO, MCHT_NM, TRX_UNQ_NO, TRX_CHNL_CD, RPS_CD, RPS_MSG,
        REM_RECH_MONY, REM_RESV_MONY, REWD_STD_VAL,
        FS_ORT_EMP_NO, FS_ORT_DTL_DTM, FS_ORT_TRX_NM,
        LS_ORT_EMP_NO, LS_ORT_DTL_DTM, LS_ORT_TRX_NM
        )
        VALUES (
        #{trxSno}, TO_DATE(#{tranDtime}, 'YYYYMMDD') + (SYSDATE - TRUNC(SYSDATE)), #{fntcUtlNo}, #{tranId}, #{mbrNo},
        #{ataCardNo}, #{rarClCd}, #{monyTypCd}, #{rechTypCd}, #{trxClCd},
        #{accClCd}, TO_CHAR(SYSDATE, 'HH24MISS'), #{trxAmt},
        #{orglTrxUnqNo}, #{orglTrxDt}, #{orglTrxAmt},
        #{mchtNo}, #{mchtNm}, #{trxUnqNo}, #{trxChnlCd}, #{rpsCd}, #{rpsMsg},
        #{remRechMony}, #{remResvMony}, #{rewdStdVal},
        #{fsOrtEmpNo}, SYSTIMESTAMP, #{fsOrtTrxNm},
        #{lsOrtEmpNo}, SYSTIMESTAMP, #{lsOrtTrxNm}
        )
    </insert>

    <!-- 처리대상머니 조회 -->
    <select id="selectOpObjMonyInq" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO" resultType="com.kaltz.common.money.vo.MmByDedtObjInqRVO">
        SELECT /* common.money.mapper.CacheOpMapper.selectOpObjMonyInq */
        Y.MBR_NO, Y.MONY_TYP_CD, Y.OCCR_YM, Y.AVL_PRD, Y.ACCM_RECH_MONY, Y.DEDT_MONY AS REM_MONY,
        CASE
        WHEN Y.DEDT_RSLT = 0
        THEN Y.ACCM_RECH_MONY
        ELSE Y.ACCM_RECH_MONY - Y.DEDT_MONY
        END REST_MONY
        FROM (
        SELECT X.MBR_NO, X.MONY_TYP_CD, X.OCCR_YM, X.AVL_PRD, X.ACCM_RECH_MONY, X.RECH_MONY, X.DEDT_MONY,
        SUM(X.DEDT_RSLT) OVER (ORDER BY X.MBR_NO, X.MONY_TYP_CD, X.OCCR_YM, X.AVL_PRD, X.ACCM_RECH_MONY, X.RECH_MONY, X.DEDT_RSLT) DEDT_RSLT
        FROM (
        SELECT MBR_NO, MONY_TYP_CD, OCCR_YM, AVL_PRD, ACCM_RECH_MONY,
        SUM(ACCM_RECH_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, OCCR_YM, AVL_PRD) RECH_MONY,
        SUM(ACCM_RECH_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, OCCR_YM, AVL_PRD) - #{trxAmt} DEDT_MONY,
        CASE
        WHEN SUM(ACCM_RECH_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, OCCR_YM, AVL_PRD) - #{trxAmt} > 0
        THEN 1 ELSE 0 END DEDT_RSLT
        FROM TB_MM_BY_USE_POSS_MONY
        WHERE MBR_NO 		= #{mbrNo}
        <if test="mchtBizcCd != null and mchtBizcCd != ''">
            AND MONY_TYP_CD =
            CASE WHEN (SELECT ADDT_CD_VAL FROM TB_CM_CD WHERE CM_CD = 'MCHT_BIZC_CD' AND USE_YN = 'Y' AND CD_VAL = #{mchtBizcCd}) > 10
            THEN 'M001'
            ELSE MONY_TYP_CD
            END
        </if>
        <if test='trxClCd == "50"'>
            AND MONY_TYP_CD = 'M001'
        </if>
        ) X
        ) Y
        WHERE Y.DEDT_RSLT <![CDATA[<=]]> 1
        AND CASE
        WHEN Y.DEDT_RSLT = 0
        THEN Y.ACCM_RECH_MONY
        ELSE Y.ACCM_RECH_MONY - Y.DEDT_MONY END > 0
    </select>

    <!-- 사용가능 머니 조회 -->
    <select id ="selectUsePossMony" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO" resultType="com.kaltz.common.money.vo.UsePossMonyRVO">
        SELECT /* common.money.mapper.CacheOpMapper.selectUsePossMony */
        MONY_TYP_CD, SUM(USE_POSS_MONY) USE_POSS_MONY,
        COALESCE(
        CASE WHEN (SELECT ADDT_CD_VAL FROM TB_CM_CD WHERE CM_CD = 'MCHT_BIZC_CD' AND USE_YN = 'Y' AND CD_VAL = #{mchtBizcCd}) > 10
        THEN CASE WHEN MONY_TYP_CD = 'M001' THEN 'Y' ELSE 'N' END
        END, 'Y') USE_POSS_YN
        FROM TB_USE_POSS_MONY
        WHERE MBR_NO = #{mbrNo}
        GROUP BY MONY_TYP_CD
    </select>

    <!-- 머니 입금내역 등록 -->
    <insert id="insertMonyDepoItm" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO">
        INSERT INTO TB_MONY_DEPO_ITM ( /* common.money.mapper.CacheOpMapper.insertMonyDepoItm */
        DEPO_TRX_SNO, TRX_DT, MBR_NO, MONY_TYP_CD,
        AVL_PRD, TRX_AMT, RAR_MONY, REM_MONY,
        FS_ORT_EMP_NO, FS_ORT_DTL_DTM, FS_ORT_TRX_NM,
        LS_ORT_EMP_NO, LS_ORT_DTL_DTM, LS_ORT_TRX_NM
        )
        VALUES (
        #{trxSno}, TO_DATE(#{tranDtime}, 'YYYYMMDD') + (SYSDATE - TRUNC(SYSDATE)), #{mbrNo}, #{monyTypCd},
        #{avlPrd}, #{trxAmt}, #{rarMony}, #{remMony},
        #{fsOrtEmpNo}, SYSTIMESTAMP, #{fsOrtTrxNm},
        #{lsOrtEmpNo}, SYSTIMESTAMP, #{lsOrtTrxNm}
        )
    </insert>

    <!-- 머니 입금내역 수정 -->
    <update id="updateMonyDepoItm" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO">
        MERGE INTO TB_MONY_DEPO_ITM A /* common.money.mapper.CacheOpMapper.updateMonyDepoItm */
        USING (
        SELECT Y.DEPO_TRX_SNO, Y.TRX_DT, Y.MBR_NO, Y.MONY_TYP_CD, Y.AVL_PRD, Y.TRX_AMT,
        CASE WHEN Y.DEDT_RSLT = 0 THEN Y.REM_MONY ELSE Y.REM_MONY - Y.DEDT_MONY END RAR_MONY,
        Y.REM_MONY - CASE WHEN Y.DEDT_RSLT = 0 THEN Y.REM_MONY ELSE Y.REM_MONY - Y.DEDT_MONY END REM_MONY,
        Y.DEDT_MONY, Y.DEDT_RSLT
        FROM (
        SELECT X.DEPO_TRX_SNO, X.TRX_DT, X.MBR_NO, X.MONY_TYP_CD, X.AVL_PRD, X.TRX_AMT, X.REM_MONY, X.ACCM_MONY, X.DEDT_MONY,
        SUM(X.DEDT_RSLT) OVER (ORDER BY X.MBR_NO, X.MONY_TYP_CD, X.AVL_PRD, X.ACCM_MONY) DEDT_RSLT
        FROM (
        SELECT DEPO_TRX_SNO, TRX_DT, MBR_NO, MONY_TYP_CD, AVL_PRD, TRX_AMT, REM_MONY,
        SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, DEPO_TRX_SNO, AVL_PRD) ACCM_MONY,
        SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, DEPO_TRX_SNO, AVL_PRD) - #{trxAmt} DEDT_MONY,
        CASE WHEN SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, DEPO_TRX_SNO, AVL_PRD) - #{trxAmt} > 0 THEN 1 ELSE 0 END DEDT_RSLT
        FROM TB_MONY_DEPO_ITM
        WHERE MBR_NO = #{mbrNo}
        <if test="mchtBizcCd != null and mchtBizcCd != ''">
            AND MONY_TYP_CD =
            CASE WHEN (SELECT ADDT_CD_VAL FROM TB_CM_CD WHERE CM_CD = 'MCHT_BIZC_CD' AND USE_YN = 'Y' AND CD_VAL = #{mchtBizcCd}) > 10
            THEN 'M001'
            ELSE MONY_TYP_CD
            END
        </if>
        <if test='trxClCd == "50"'>
            AND MONY_TYP_CD = 'M001'
        </if>
        AND REM_MONY > 0
        ) X
        ) Y
        WHERE Y.DEDT_RSLT <![CDATA[<=]]> 1 AND CASE WHEN Y.DEDT_RSLT = 0 THEN Y.REM_MONY ELSE Y.REM_MONY - Y.DEDT_MONY END > 0
        ) B
        ON (A.DEPO_TRX_SNO = B.DEPO_TRX_SNO AND A.TRX_DT = B.TRX_DT)
        WHEN MATCHED THEN
        UPDATE SET
        A.RAR_MONY = B.RAR_MONY,
        A.REM_MONY = B.REM_MONY,
        A.LS_ORT_EMP_NO 	= #{lsOrtEmpNo},
        A.LS_ORT_DTL_DTM 	= SYSTIMESTAMP,
        A.LS_ORT_TRX_NM 	= #{lsOrtTrxNm}
    </update>

    <!-- 회수 처리대상머니 조회 -->
    <select id="selectRecoOpObjMonyInq" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO" resultType="com.kaltz.common.money.vo.MmByDedtObjInqRVO">
        SELECT /* common.money.mapper.CacheOpMapper.selectRecoOpObjMonyInq */
        Y.DEPO_TRX_SNO, Y.TRX_DT, Y.MBR_NO, Y.MONY_TYP_CD, Y.AVL_PRD, Y.TRX_AMT,
        CASE WHEN Y.DEDT_RSLT = 0 THEN  ABS(Y.REM_MONY) ELSE ABS(Y.REM_MONY - Y.REST_MONY) END RAR_MONY,
        Y.REM_MONY - CASE WHEN Y.DEDT_RSLT = 0 THEN Y.REM_MONY ELSE Y.REM_MONY - Y.REST_MONY END REM_MONY,
        Y.REST_MONY, Y.DEDT_RSLT
        FROM (
        SELECT X.DEPO_TRX_SNO, X.TRX_DT, X.MBR_NO, X.MONY_TYP_CD, X.AVL_PRD, X.TRX_AMT, X.REM_MONY, X.ACCM_MONY, X.REST_MONY,
        SUM(X.REST_RSLT) OVER (ORDER BY X.MBR_NO, X.MONY_TYP_CD, X.TRX_DT, X.AVL_PRD, X.ACCM_MONY) DEDT_RSLT
        FROM (
        SELECT DEPO_TRX_SNO, TRX_DT, MBR_NO, MONY_TYP_CD, AVL_PRD, TRX_AMT, REM_MONY,
        SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, AVL_PRD) ACCM_MONY,
        SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, AVL_PRD) + #{trxAmt} REST_MONY,
        CASE WHEN SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, AVL_PRD) + #{trxAmt} > 0 THEN 0 ELSE 1 END REST_RSLT
        FROM TB_MONY_DEPO_ITM
        WHERE MBR_NO = #{mbrNo}
        AND REM_MONY <![CDATA[<]]> 0
        ) X
        ) Y
        WHERE Y.DEDT_RSLT <![CDATA[<=]]> 1
    </select>

    <!-- 머니 회수머니 입금내역 상쇄 -->
    <update id="updateRepoMonyDepoItm" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO">
        MERGE INTO TB_MONY_DEPO_ITM A /* common.money.mapper.CacheOpMapper.updateRepoMonyDepoItm */
        USING (
        SELECT Y.DEPO_TRX_SNO, Y.TRX_DT, Y.MBR_NO, Y.MONY_TYP_CD, Y.AVL_PRD,
        Y.TRX_AMT,
        CASE WHEN Y.DEDT_RSLT = 0 THEN  ABS(Y.REM_MONY) ELSE ABS(Y.REM_MONY - Y.REST_MONY) END RAR_MONY,
        Y.REM_MONY - CASE WHEN Y.DEDT_RSLT = 0 THEN Y.REM_MONY ELSE Y.REM_MONY - Y.REST_MONY END REM_MONY,
        Y.REST_MONY, Y.DEDT_RSLT
        FROM (
        SELECT X.DEPO_TRX_SNO, X.TRX_DT, X.MBR_NO, X.MONY_TYP_CD, X.AVL_PRD, X.TRX_AMT, X.REM_MONY, X.ACCM_MONY, X.REST_MONY,
        SUM(X.REST_RSLT) OVER (ORDER BY X.MBR_NO, X.MONY_TYP_CD, X.TRX_DT, X.AVL_PRD, X.ACCM_MONY) DEDT_RSLT
        FROM (
        SELECT DEPO_TRX_SNO, TRX_DT, MBR_NO, MONY_TYP_CD, AVL_PRD, TRX_AMT, REM_MONY,
        SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, AVL_PRD) ACCM_MONY,
        SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, AVL_PRD) + #{trxAmt} REST_MONY,
        CASE WHEN SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, AVL_PRD) + #{trxAmt} > 0 THEN 0 ELSE 1 END REST_RSLT
        FROM TB_MONY_DEPO_ITM
        WHERE MBR_NO = #{mbrNo}
        AND REM_MONY <![CDATA[<]]> 0
        ) X
        ) Y
        WHERE Y.DEDT_RSLT <![CDATA[<=]]> 1
        ) B
        ON (A.DEPO_TRX_SNO = B.DEPO_TRX_SNO AND A.TRX_DT = B.TRX_DT)
        WHEN MATCHED THEN
        UPDATE SET
        A.RAR_MONY = B.RAR_MONY,
        A.REM_MONY = B.REM_MONY,
        A.LS_ORT_EMP_NO 	= #{lsOrtEmpNo},
        A.LS_ORT_DTL_DTM 	= SYSTIMESTAMP,
        A.LS_ORT_TRX_NM 	= #{lsOrtTrxNm}
    </update>

    <!-- 머니 출금내역 등록 -->
    <insert id="insertUseMonyDfraItm" parameterType="com.kaltz.common.money.vo.MonyDfraDepoPVO">
        INSERT INTO TB_MONY_DFRA_ITM ( /* common.money.mapper.CacheOpMapper.insertUseMonyDfraItm */
        USE_TRX_SNO, DEPO_TRX_SNO, TRX_DT,
        MBR_NO, MONY_TYP_CD, DEPO_TRX_DT,
        AVL_PRD, USE_MONY, ORGL_TRX_SNO, CNCL_CL_CD,
        FS_ORT_EMP_NO, FS_ORT_DTL_DTM, FS_ORT_TRX_NM,
        LS_ORT_EMP_NO, LS_ORT_DTL_DTM, LS_ORT_TRX_NM
        )
        SELECT #{trxSno} USE_TRX_SNO, Y.DEPO_TRX_SNO, SYSDATE TRX_DT,
        Y.MBR_NO, Y.MONY_TYP_CD, Y.TRX_DT,
        Y.AVL_PRD, CASE WHEN Y.DEDT_RSLT = 0 THEN Y.REM_MONY ELSE Y.REM_MONY - Y.DEDT_MONY END RAR_MONY,
        '' ORGL_TRX_SNO, '0' CNCL_CL_CD,
        #{fsOrtEmpNo} FS_ORT_EMP_NO, SYSTIMESTAMP FS_ORT_DTL_DTM, #{fsOrtTrxNm} FS_ORT_TRX_NM,
        #{lsOrtEmpNo} LS_ORT_EMP_NO, SYSTIMESTAMP LS_ORT_DTL_DTM, #{lsOrtTrxNm} LS_ORT_TRX_NM
        FROM (
        SELECT X.DEPO_TRX_SNO, X.TRX_DT, X.MBR_NO, X.MONY_TYP_CD, X.AVL_PRD, X.TRX_AMT, X.REM_MONY, X.ACCM_MONY, X.DEDT_MONY,
        SUM(X.DEDT_RSLT) OVER (ORDER BY X.MBR_NO, X.MONY_TYP_CD, X.AVL_PRD, X.ACCM_MONY) DEDT_RSLT
        FROM (
        SELECT DEPO_TRX_SNO, TRX_DT, MBR_NO, MONY_TYP_CD, AVL_PRD, TRX_AMT, REM_MONY,
        SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, DEPO_TRX_SNO, AVL_PRD) ACCM_MONY,
        SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, DEPO_TRX_SNO, AVL_PRD) - #{trxAmt} DEDT_MONY,
        CASE WHEN SUM(REM_MONY) OVER(ORDER BY MBR_NO, MONY_TYP_CD, TRX_DT, DEPO_TRX_SNO, AVL_PRD) - #{trxAmt} > 0 THEN 1 ELSE 0 END DEDT_RSLT
        FROM TB_MONY_DEPO_ITM
        WHERE MBR_NO = #{mbrNo}
        <if test="mchtBizcCd != null and mchtBizcCd != ''">
            AND MONY_TYP_CD =
            CASE WHEN (SELECT ADDT_CD_VAL FROM TB_CM_CD WHERE CM_CD = 'MCHT_BIZC_CD' AND USE_YN = 'Y' AND CD_VAL = #{mchtBizcCd}) > 10
            THEN 'M001'
            ELSE MONY_TYP_CD
            END
        </if>
        <if test='trxClCd == "50"'>
            AND MONY_TYP_CD = 'M001'
        </if>
        AND REM_MONY > 0
        ) X
        ) Y
        WHERE Y.DEDT_RSLT <![CDATA[<=]]> 1
        AND CASE WHEN Y.DEDT_RSLT = 0
        THEN Y.REM_MONY
        ELSE Y.REM_MONY - Y.DEDT_MONY
        END > 0
    </insert>

    <!-- 배치용 기 조정거래 및 회원존재 유무 조회 -->
    <select id="selectBatchAdjtMbrInfo" parameterType="com.kaltz.common.money.vo.CacheAdjustDVO" resultType="com.kaltz.common.money.vo.CacheAdjustRVO">
        SELECT /* common.money.mapper.CacheOpMapper.selectBatchAdjtMbrInfo */
        COUNT(A.MBR_NO) AS MBR_CNT
        , COUNT(B.MBR_NO) AS ADJT_CNT
        FROM TB_MBR_INFO A
        LEFT JOIN TB_MONY_ADJT B
        ON (B.MBR_NO = A.MBR_NO
        AND	B.ADJT_GRP_ID 	= #{adjtGrpId})
        WHERE A.MBR_NO 			= #{mbrNo}
        AND A.MBR_ST_CD 	= '00'
    </select>

    <!-- 배치용 머니 조정사유 등록 -->
    <insert id="insertMonyAdjtBatch" parameterType="com.kaltz.common.money.vo.CacheAdjustDVO">
        INSERT INTO TB_MONY_ADJT ( /* common.money.mapper.CacheOpMapper.insertMonyAdjtBatch */
        TRX_SNO, REG_DT, MBR_NO, ADJT_GRP_ID, ADJT_CL_CD, ADJT_OBJ_CD, ADJT_OP_ST_CD,
        ADJT_BF_RECH_MONY_AMT, ADJT_BF_RESV_MONY_AMT,
        ADJT_AF_RECH_MONY_AMT, ADJT_AF_RESV_MONY_AMT,
        ADJT_AMT, ADJT_RSN_DESC,
        FS_ORT_EMP_NO, FS_ORT_DTL_DTM, FS_ORT_TRX_NM,
        LS_ORT_EMP_NO, LS_ORT_DTL_DTM, LS_ORT_TRX_NM
        )
        VALUES (
        #{trxSno}, SYSDATE, #{mbrNo}, #{adjtGrpId}, #{adjtClCd}, #{adjtObjCd}, #{adjtOpStCd},
        #{adjtBfRechMonyAmt}, #{adjtBfResvMonyAmt},
        #{adjtAfRechMonyAmt}, #{adjtAfResvMonyAmt},
        #{adjtAmt}, #{adjtRsnDesc},
        #{fsOrtEmpNo}, SYSTIMESTAMP, #{fsOrtTrxNm},
        #{lsOrtEmpNo}, SYSTIMESTAMP, #{lsOrtTrxNm}
        )
    </insert>

    <!-- 계정처리 순번 조회 -->
    <select id="selectAccOpItmSeq" resultType = "string">
        SELECT /* common.money.mapper.CacheOpMapper.selectAccOpItmSeq */
        TB_ACC_OP_ITM_SQ01.NEXTVAL SEQ
        FROM DUAL
    </select>

    <!-- 계정처리내역 등록 -->
    <insert id="insertAccOpItm" parameterType="com.kaltz.common.money.vo.AccountOpItmPVO">
        INSERT INTO TB_ACC_OP_ITM ( /* common.money.mapper.CacheOpMapper.insertAccOpItm */
        ACC_OP_SEQ, ACC_OP_DT, ACC_OP_DTL_SNO, ACC_CL_CD,
        IO_CL_CD, ACC_OP_DTM, RAR_AMT,
        ACCTN_OP_CL_CD, MCHT_NM, ACC_OP_VAL, MBR_NO, RAR_OP_SNO,
        FS_ORT_EMP_NO, FS_ORT_DTL_DTM, FS_ORT_TRX_NM,
        LS_ORT_EMP_NO, LS_ORT_DTL_DTM, LS_ORT_TRX_NM
        )
        VALUES (
        #{accOpSeq}, TRUNC(SYSTIMESTAMP, 'DD'), #{accOpDtlSno}, #{accClCd},
        #{ioClCd}, TO_CHAR(SYSDATE, 'HH24MISS'), #{rarAmt},
        #{acctnOpClCd}, #{mchtNm}, #{accOpVal}, #{mbrNo}, #{rarOpSno},
        #{fsOrtEmpNo}, SYSTIMESTAMP, #{fsOrtTrxNm},
        #{lsOrtEmpNo}, SYSTIMESTAMP, #{lsOrtTrxNm}
        )
    </insert>
</mapper>
