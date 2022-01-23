SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	


CREATE   PROC [dbo].[SPM_Contract_EligibleContracts]
As
Begin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT C.Id as ContractId, LF.Id as LeaseFinanceID , InterimRentBillingType, LFD.MaturityDate,  C.SyndicationType,
		CAST('_' AS VARCHAR(50)) AS [AccountingTreatment], LFD.LeaseContractType, CASE WHEN LFD.IsOverTermLease = 1 THEN 1 ELSE 0 END AS IsOverTermLease
	INTO ##Contract_EligibleContracts  
	FROM Contracts C  
		INNER JOIN LeaseFinances LF  ON LF.ContractId = C.Id  
		INNER JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id  
		INNER JOIN ##ContractMeasures CB ON CB.Id = LF.ContractId
	WHERE LF.IsCurrent = 1 AND (C.Status = 'FullyPaid' OR C.Status = 'Commenced' OR C.Status = 'FullyPaidOff')  
	
	CREATE NONCLUSTERED INDEX IX_EligibleContractContractId ON ##Contract_EligibleContracts(ContractId) Include (LeaseContractType); 

End

GO
