SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE   PROC [dbo].[SPM_Contract_AccrualDetails_OL]
As
Begin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 	SELECT
		EC.ContractId
		,MAX(NC.Id) AS NonAccrualId
		,MAX(RAC.Id) AS ReAccrualId
		,MAX(RAC.ReAccrualDate) AS ReAccrualDate
		,MAX(NC.NonAccrualDate) AS NonAccrualDate
	INTO ##Contract_AccrualDetails_OL
	FROM ##Contract_EligibleContracts EC
		LEFT JOIN NonAccrualContracts NC ON NC.ContractId = EC.ContractId
		LEFT JOIN NonAccruals NA ON NC.NonAccrualId = NA.Id
			AND NC.IsActive = 1
			AND NA.Status = 'Approved'
		LEFT JOIN ReAccrualContracts RAC ON RAC.ContractId = EC.ContractId
		LEFT JOIN ReAccruals RC ON RAC.ReAccrualId = RC.Id
			AND RAC.IsActive = 1
			AND RC.Status = 'Approved'
   WHERE EC.LeaseContractType = 'Operating'
	GROUP BY EC.ContractId;

	CREATE NONCLUSTERED INDEX IX_AccrualDetailsContractId ON ##Contract_AccrualDetails_OL(ContractId);
END

GO
