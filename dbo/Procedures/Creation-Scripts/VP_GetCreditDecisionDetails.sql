SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetCreditDecisionDetails]
(
@OpportunityNumber NVARCHAR(40) = NULL
)
AS
BEGIN
SELECT
CD.DecisionName AS DecisionName,
CD.DecisionDate AS DecisionDate,
CD.DecisionStatus AS Status,
CD.StatusDate AS StatusDate,
CD.ExpiryDate AS ExpirationDate,
CD.ApprovedAmount_Amount As ApprovedAmount_Amount,
CD.ApprovedAmount_Currency As ApprovedAmount_Currency,
CD.DecisionComments As DecisionComments,
CD.IsActive
FROM Opportunities O
JOIN CreditProfiles CP on O.Id = CP.OpportunityId
JOIN CreditDecisions CD on CP.Id = CD.CreditProfileId
WHERE CP.Status!='Inactivate'
AND CD.IsActive = 1
AND O.Number = @OpportunityNumber
END

GO
