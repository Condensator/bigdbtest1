SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
CREATE   PROC [dbo].[SPM_Contract_ChargeOffInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
BEGIN
		SELECT EC.ContractId
			 , SUM(CASE
					   WHEN co.IsRecovery = 0
					   THEN co.LeaseComponentAmount_Amount
					   ELSE 0.00
				   END) [ChargeOffExpense_LC_Table]
			 , SUM(CASE
					   WHEN co.IsRecovery = 0
					   THEN co.NonLeaseComponentAmount_Amount
					   ELSE 0.00
				   END) [ChargeOffExpense_NLC_Table]
			 , SUM(CASE
					   WHEN co.IsRecovery = 1
					   THEN co.LeaseComponentAmount_Amount * (-1)
					   ELSE 0.00
				   END) [ChargeOffRecovery_LC_Table]
			 , SUM(CASE
					   WHEN co.IsRecovery = 1
					   THEN co.NonLeaseComponentAmount_Amount * (-1)
					   ELSE 0.00
				   END) [ChargeOffRecovery_NLC_Table]
			 ,SUM(CASE
					 WHEN co.IsRecovery = 1
					 THEN co.LeaseComponentGain_Amount * (-1)   
				  END) AS GainOnRecovery_LC_Table	
			 , SUM(CASE
					 WHEN co.IsRecovery = 1
					 THEN co.NonLeaseComponentGain_Amount * (-1)   
				  END) AS GainOnRecovery_NLC_Table						INTO ##Contract_ChargeOffInfo
		FROM ##Contract_EligibleContracts ec
			 INNER JOIN ChargeOffs co ON co.ContractId = ec.ContractId
		WHERE co.IsActive = 1
			  AND co.Status = 'Approved'
			  AND co.PostDate IS NOT NULL
		GROUP BY ec.ContractId;

END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN

INSERT INTO ##Contract_ChargeOffInfo
	SELECT EC.ContractId
		 , SUM(CASE
				   WHEN co.IsRecovery = 0
				   THEN co.ChargeOffAmount_Amount
				   ELSE 0.00
			   END) AS [ChargeOffExpense_LC_Table]
		 , 0.00 AS [ChargeOffExpense_NLC_Table]
		 , SUM(CASE
				   WHEN co.IsRecovery = 1
				   THEN co.ChargeOffAmount_Amount * (-1)
				   ELSE 0.00
			   END) AS [ChargeOffRecovery_LC_Table]		
		 , 0.00 AS [ChargeOffRecovery_NLC_Table]
		 , 0.00 AS GainOnRecovery_LC_Table	
		 , 0.00 AS GainOnRecovery_NLC_Table					
	FROM ##Contract_EligibleContracts ec
		 INNER JOIN ChargeOffs co ON co.ContractId = ec.ContractId
	WHERE co.IsActive = 1
		  AND co.Status = 'Approved'
		  AND co.PostDate IS NOT NULL
	GROUP BY ec.ContractId
END
	
	CREATE NONCLUSTERED INDEX IX_ChargeoffInfo_ContractId ON ##Contract_ChargeOffInfo(ContractId);
END

GO
