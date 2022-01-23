SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE   PROC [dbo].[SPM_Contract_PaidReceivables]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT  r.EntityId AS ContractId
		   ,SUM(ISNULL(r.GainAmount_LC, 0.00)) [ChargeOffGainOnRecovery_LeaseComponent_Table]
		   ,SUM(ISNULL(r.GainAmount_NLC, 0.00)) AS [ChargeOffGainOnRecovery_NonLeaseComponent_Table]		INTO ##Contract_PaidReceivables
	FROM ##Contract_ReceiptApplicationReceivableDetails r
		LEFT JOIN ##Contract_ChargeOff co ON r.EntityId = co.ContractId
	WHERE r.ReceiptStatus IN ('Completed','Posted')
		  AND r.ReceivableType IN ('CapitalLeaseRental')
	GROUP BY r.EntityId;

CREATE NONCLUSTERED INDEX IX_Id ON ##Contract_PaidReceivables(ContractId);

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
BEGIN

MERGE ##Contract_PaidReceivables pd
	USING
		(SELECT 
			r.EntityId AS ContractId
			,SUM(ISNULL(r.GainAmount_LC, 0.00)) AS OtherGainAmount_LC_Table
			,SUM(ISNULL(r.GainAmount_NLC, 0.00)) AS OtherGainAmount_NLC_Table
		FROM ##Contract_ReceiptApplicationReceivableDetails r
			  LEFT JOIN ##Contract_ChargeOff cod ON cod.ContractId = r.EntityId
		WHERE r.ReceiptStatus IN ('Completed','Posted')
			  AND r.ReceivableType NOT IN ('CapitalLeaseRental') 
		GROUP BY r.EntityId) sr
	ON (sr.ContractId = pd.ContractId)
	WHEN MATCHED
	THEN UPDATE
		SET ChargeOffGainOnRecovery_LeaseComponent_Table += sr.OtherGainAmount_LC_Table +  sr.OtherGainAmount_NLC_Table
	WHEN NOT MATCHED
		THEN
			INSERT(ContractId,[ChargeOffGainOnRecovery_LeaseComponent_Table], [ChargeOffGainOnRecovery_NonLeaseComponent_Table])
			VALUES(sr.ContractId, sr.OtherGainAmount_LC_Table +  sr.OtherGainAmount_NLC_Table, 0.00);
	
	UPDATE sord SET ChargeOffGainOnRecovery_LeaseComponent_Table += ChargeOffGainOnRecovery_NonLeaseComponent_Table
				  , ChargeOffGainOnRecovery_NonLeaseComponent_Table = 0.00
	FROM ##Contract_PaidReceivables sord
	WHERE ChargeOffGainOnRecovery_NonLeaseComponent_Table != 0.00
END

END

GO
