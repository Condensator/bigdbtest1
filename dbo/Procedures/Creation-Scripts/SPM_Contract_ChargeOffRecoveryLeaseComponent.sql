SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



 
 
CREATE   PROC [dbo].[SPM_Contract_ChargeOffRecoveryLeaseComponent] 
AS
BEGIN
DECLARE @IsGainPresent BIT = 0
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
BEGIN
	SET @IsGainPresent = 1	
END

	UPDATE TGT
	SET TGT.ChargeOffRecoveryLeaseComponent = SRC.ChargeOffRecovery_LeaseComponent_Table,
	    TGT.ChargeOffRecoveryNonLeaseComponent = SRC.ChargeOffRecovery_NonLeaseComponent_Table
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			Select 
				ec.ContractId,
				IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00))  AS [ChargeOffRecovery_LeaseComponent_Table],
				IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) AS [ChargeOffRecovery_NonLeaseComponent_Table]
			FROM
				##Contract_EligibleContracts ec WITH (NOLOCK)
				LEFT JOIN ##Contract_PaidReceivables pr WITH (NOLOCK) ON pr.ContractId = ec.ContractId
				LEFT JOIN ##Contract_ChargeOffInfo coi WITH (NOLOCK) ON coi.ContractId = ec.ContractId
		) SRC
		ON TGT.Id = SRC.ContractId
END

GO
