SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_RenewalDetails]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  
	SELECT LA.ContractId
		,MAX(LAM.CurrentLeaseFinanceId) AS RenewalFinanceId
		,NULL AS LeaseIncomeId
	INTO ##Contract_RenewalDetails
	FROM ##Contract_LeaseAmendment LA
	    INNER JOIN LeaseFinances LF  ON LF.ContractId = LA.ContractId AND LA.IsRenewal >= 1
		INNER JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
		INNER JOIN LeaseAmendments LAM  ON LF.Id = LAM.CurrentLeaseFinanceId
			AND LAM.AmendmentType = 'Renewal' AND LAM.LeaseAmendmentStatus = 'Approved'
	GROUP BY LA.ContractId;

	CREATE NONCLUSTERED INDEX IX_RenewalDetailsContractId ON ##Contract_RenewalDetails(ContractId);

END

GO
