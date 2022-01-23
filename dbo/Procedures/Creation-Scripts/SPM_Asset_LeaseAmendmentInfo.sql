SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_LeaseAmendmentInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 C.Id AS ContractId
	,lam.OriginalLeaseFinanceId   
	,lam.CurrentLeaseFinanceId
	,lam.AmendmentDate  INTO ##Asset_LeaseAmendmentInfo
FROM 
	Contracts C
INNER JOIN
	LeaseFinances lf ON C.Id = lf.ContractId
INNER JOIN
	LeaseAmendments lam ON lam.CurrentLeaseFinanceId = lf.Id
    AND lam.AmendmentType = 'Renewal' AND lam.LeaseAmendmentStatus = 'Approved'

CREATE NONCLUSTERED INDEX IX_ContractId ON ##Asset_LeaseAmendmentInfo(ContractId);

END

GO
