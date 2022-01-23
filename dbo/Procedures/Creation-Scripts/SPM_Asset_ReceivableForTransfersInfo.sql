SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE   PROC [dbo].[SPM_Asset_ReceivableForTransfersInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	ContractId
	,EffectiveDate
	,IsFromContract
	,ReceivableForTransferType
	,ContractType
	,CAST((RetainedPercentage / 100) as decimal (16,2)) RetainedPortion
	,CAST((1 - (CAST((RetainedPercentage / 100) as decimal (16,2)))) as decimal (16,2)) ParticipatedPortion
	,LeaseFinanceId AS SyndicationLeaseFinanceId INTO ##Asset_ReceivableForTransfersInfo
FROM 
	ReceivableForTransfers 
WHERE
	ApprovalStatus = 'Approved';

CREATE NONCLUSTERED INDEX IX_ReceivableForTransfersInfo_ContractId ON ##Asset_ReceivableForTransfersInfo(ContractId);			

END

GO
