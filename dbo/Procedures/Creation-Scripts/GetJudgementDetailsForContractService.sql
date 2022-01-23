SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetJudgementDetailsForContractService]
(
@ContractSequenceNumber nvarchar(50)
)
AS
BEGIN
DECLARE @ContractId BigInt
SET @ContractId = (Select Id from Contracts With (NoLock) where SequenceNumber = @ContractSequenceNumber)
SELECT
@ContractSequenceNumber SequenceNumber
,CourtFilings.CaseNumber
,CourtFilingActions.LegalAction
,[Judgements].[Status]
,[Judgements].[JudgementDate]
,[Judgements].[Amount_Amount]
,[Judgements].[Amount_Currency]
,[Judgements].[Fees_Amount]
,[Judgements].[Fees_Currency]
,[Judgements].[TotalAmount_Amount]
,[Judgements].[TotalAmount_Currency]
,[Judgements].[InterestRate]
,[Judgements].[InterestGrantedFromDate]
,[Judgements].[ExpirationDate]
,[Judgements].[RenewalDate]
,[Judgements].[IsActive]
,[Judgements].[JudgementNumber]
,[Judgements].Id [JudgementId]
FROM [dbo].[Judgements]
LEFT JOIN CourtFilings ON Judgements.CourtFilingId = CourtFilings.Id
LEFT JOIN CourtFilingActions ON Judgements.CourtFilingActionId = CourtFilingActions.Id
WHERE Judgements.ContractId = @ContractId
ORDER BY IsActive DESC , JudgementDate DESC
END

GO
