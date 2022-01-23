SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Contract_AdditionalFeeIncome]
AS
BEGIN

	UPDATE TGT 
	SET AdditionalFeeIncome = SRC.AdditionalCharges
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
			SELECT Sum(AC.Amount_Amount) AS AdditionalCharges, CB.Id AS ContractId 
			FROM 
			AdditionalCharges AC WITH (NOLOCK)
			INNER JOIN LeaseFinanceAdditionalCharges LFAC WITH (NOLOCK)  ON AC.Id = LFAC.AdditionalChargeId  AND AC.IsActive=1
			INNER JOIN Leasefinances LF WITH (NOLOCK) ON LF.Id = LFAC.LeaseFinanceId AND LF.IsCurrent =1
			INNER JOIN ##ContractMeasures CB ON CB.Id = LF.ContractId
     		GROUP BY CB.Id
			) SRC
	ON (TGT.Id = SRC.ContractId)  
END

GO
