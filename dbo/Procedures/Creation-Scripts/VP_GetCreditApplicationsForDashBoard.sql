SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetCreditApplicationsForDashBoard]
(
@IsProgramVendor BIT,
@CurrentVendorId BIGINT
,@LegalEntityName NVARCHAR(100)
)
AS
SELECT DISTINCT
O.Id AS CreditApplicationId
,O.Number AS CreditApplicationNumber
,CA.SubmittedToCreditDate AS SubmissionDate
,CASE WHEN CA.IsFromVendorPortal = 0 THEN @LegalEntityName ELSE U.FullName END AS SubmittedBy
,PC.FullName AS VendorSalesRep
,CAPD.CreditApplicationAmount_Amount AS RequestedAmount_Amount
,CAPD.CreditApplicationAmount_Currency AS RequestedAmount_Currency
,P.PartyName AS CustomerName
,CD.DecisionStatus AS CreditDecisionStatus
,ISNULL(CD.ApprovedAmount_Amount,0) AS ApprovedAmount_Amount
,ISNULL(CD.ApprovedAmount_Currency,'USD') AS ApprovedAmount_Currency
,CD.ExpiryDate AS ExpirationDate
,CA.IsFromVendorPortal
,CA.Status AS CreditAppStatus
,ISNULL(CD.IsActive,0) IsActive
,STUFF((SELECT distinct ','+ Contract.SequenceNumber
FROM  CreditProfiles CreditProfile
JOIN CreditApprovedStructures CreditApprovedStructure ON CreditProfile.Id = CreditApprovedStructure.CreditProfileId
JOIN Contracts Contract ON CreditApprovedStructure.Id = Contract.CreditApprovedStructureId
AND Contract.Status NOT IN ('Cancelled','Inactive')
WHERE O.ID= CreditProfile.OpportunityId
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'') SequenceNumber
FROM Opportunities O
JOIN CreditApplications CA ON O.Id = CA.Id
JOIN CreditApplicationPricingDetails CAPD ON CA.Id=CAPD.Id
JOIN Parties P ON O.CustomerId=P.Id
JOIN Users U ON CA.CreatedById= U.Id
LEFT JOIN PartyContacts PC ON CA.VendorContactId=PC.Id
LEFT JOIN CreditProfiles CP ON O.Id = CP.OpportunityId
LEFT JOIN CreditDecisions CD ON CP.Id =CD.CreditProfileId
LEFT JOIN LegalEntities LE ON O.LegalEntityId = LE.Id
WHERE CA.Status!='Pending'
AND CA.Status!='InActive'
AND (CP.Status IS NULL OR CP.Status!='Inactivate')
AND ((@IsProgramVendor=1
AND (O.OriginationSourceId = @CurrentVendorId
OR (O.OriginationSourceId IN(SELECT VendorId FROM ProgramsAssignedToAllVendors
WHERE IsAssigned = 1 AND ProgramVendorId =  @CurrentVendorId)AND CA.VendorId=  @CurrentVendorId))
)OR (@IsProgramVendor=0 AND (O.OriginationSourceId = @CurrentVendorId))
)

GO
