SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreditFactSheetReport]
(
@CreditProfileId BIGINT,
@PartyId BigInt,
@IrrBusRpt NVARCHAR(20),
@LWVendor NVARCHAR(20)
)
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON
SELECT CreditProfiles.Id AS CreditProfileId,MAX(OFACRequests.Id) AS OFACRequestId into  #OFACRequestTempTable
FROM
OFACRequests
INNER JOIN CreditProfileOFACRequests
ON OFACRequests.Id = CreditProfileOFACRequests.OFACRequestId
AND CreditProfileOFACRequests.IsActive = 1
INNER JOIN CreditProfiles
ON CreditProfileOFACRequests.CreditProfileId =CreditProfiles.Id
WHERE CreditProfiles.Id = @CreditProfileId
GROUP BY CreditProfiles.Id
SELECT CreditProfiles.Id AS CreditProfileId,MAX(OFACHits.Id) AS OFACHitId into  #OFACTempTable
FROM
OFACHits
INNER JOIN CreditProfileOFACHits
ON OFACHits.Id = CreditProfileOFACHits.OFACHitId
AND CreditProfileOFACHits.IsActive = 1
INNER JOIN CreditProfiles
ON CreditProfileOFACHits.CreditProfileId =CreditProfiles.Id
WHERE CreditProfiles.Id = @CreditProfileId
GROUP BY CreditProfiles.Id
SELECT CreditProfileId AS CreditProfileId,MAX(Amount_Amount) AS MaxExhibitAmount INTO #ApprovedStructureTempTable
FROM CreditApprovedStructures
WHERE CreditApprovedStructures.IsActive = 1 AND CreditProfileId = @CreditProfileId
GROUP BY CreditProfileId
SELECT WorkItems.Id,WorkItems.ActionName,Users.FullName,WorkItems.CreatedTime,WorkItems.UpdatedTime,TransactionInstances.EntityId INTO #WorkItemTempTable  FROM WorkItems
INNER JOIN TransactionInstances
ON WorkItems.TransactionInstanceId = TransactionInstances.Id
INNER JOIN Users
ON WorkItems.OwnerUserId = Users.Id
WHERE TransactionInstances.EntityId = @CreditProfileId AND TransactionInstances.EntityName = 'CreditProfile'
SELECT WorkItems.Id,WorkItems.ActionName,Users.FullName,WorkItems.CreatedTime,WorkItems.UpdatedTime,@CreditProfileId AS EntityId INTO #WorkItemTempTableForEntered  FROM WorkItems
INNER JOIN TransactionInstances
ON WorkItems.TransactionInstanceId = TransactionInstances.Id
INNER JOIN Users
ON WorkItems.OwnerUserId = Users.Id
INNER JOIN CreditProfiles
ON TransactionInstances.EntityId = CreditProfiles.OpportunityId
WHERE CreditProfiles.Id  = @CreditProfileId AND TransactionInstances.EntityName = 'Opportunity'
;WITH CTE_PartyContact
AS
(
SELECT TOP 1  PhoneNumber1,MailingAddressId
FROM PartyContacts
INNER JOIN PartyAddresses
ON PartyContacts.MailingAddressId = PartyAddresses.Id
AND PartyAddresses.IsActive = 1 AND IsMain = 1
AND PartyContacts.IsActive=1
INNER JOIN Parties
ON PartyAddresses.PartyId = Parties.Id
WHERE  Parties.Id = @PartyId
)
,CTE_CreditOFACRequests
AS
(
SELECT #OFACRequestTempTable.CreditProfileId,OFACRequests.ResponseType,OFACRequests.ResponseDate,OFACRequests.Id as OFACRequestId
FROM OFACRequests
INNER JOIN #OFACRequestTempTable
ON OFACRequests.Id = #OFACRequestTempTable.OFACRequestId
)
,CTE_CreditDecision
AS
(
SELECT TOP 1 ExpiryDate,CreditProfileId,BusinessAdditionalCollateral,PrincipalAdditionalCollateral,StandardCollateral
,SecurityDepositAmount_Amount,SecurityDepositAmount_Currency,WriteUp,DecisionDocumentation,CreditDecisions.Id,CreditDecisions.DecisionStatus
FROM CreditDecisions
WHERE CreditDecisions.IsActive = 1 AND CreditDecisions.CreditProfileId = @CreditProfileId
ORDER BY Id DESC
)
,CTE_CreditOFACHits
AS
(
SELECT #OFACTempTable.CreditProfileId,OFACHits.Status,OFACHits.DecisionTime,OFACHits.Id as OFACHitId
FROM OFACHits
INNER JOIN #OFACTempTable
ON OFACHits.Id = #OFACTempTable.OFACHitId
)
,CTE_ApprovedStructure
AS
(
SELECT
CreditApprovedStructures.Amount_Amount
,CreditApprovedStructures.Amount_Currency AS ExhibitAmountCurrency
,CreditApprovedStructures.InceptionRentFactor
,CreditApprovedStructures.PaymentFrequency
,CreditApprovedStructures.Term
,CreditApprovedStructures.CustomerExpectedResidual_Amount
,CreditApprovedStructures.CustomerExpectedResidual_Currency
,CreditApprovedStructures.CreditProfileId
FROM
(SELECT MAX(CreditApprovedStructures.Id) AS CreditApprovedStructureId,CreditApprovedStructures.CreditProfileId FROM #ApprovedStructureTempTable
INNER JOIN CreditApprovedStructures
ON #ApprovedStructureTempTable.CreditProfileId = CreditApprovedStructures.CreditProfileId
AND #ApprovedStructureTempTable.MaxExhibitAmount = CreditApprovedStructures.Amount_Amount
AND CreditApprovedStructures.IsActive = 1
WHERE CreditApprovedStructures.CreditProfileId = @CreditProfileId
GROUP BY CreditApprovedStructures.CreditProfileId)  A1
INNER JOIN CreditApprovedStructures
ON CreditApprovedStructures.Id = A1.CreditApprovedStructureId
AND CreditApprovedStructures.IsActive = 1
)
,CTE_ThirdParties
AS
(
SELECT Parties.PartyName AS ThirdPartyName,Parties.LastFourDigitUniqueIdentificationNumber AS ThirdPartyTaxId, CreditProfileThirdPartyRelationships.CreditProfileId  FROM CreditProfileThirdPartyRelationships
INNER JOIN CustomerThirdPartyRelationships
ON CreditProfileThirdPartyRelationships.ThirdPartyRelationshipId = CustomerThirdPartyRelationships.Id
INNER JOIN Parties
ON CustomerThirdPartyRelationships.ThirdPartyId = Parties.id
WHERE CreditProfileId=@CreditProfileId AND CustomerThirdPartyRelationships.IsActive = 1 AND CreditProfileThirdPartyRelationships.IsActive=1 AND CustomerThirdPartyRelationships.RelationshipType != 'VendorRecourse'
UNION
SELECT PartyContacts.FullName AS ThirdPartyName,Partycontacts.LastFourDigitSocialSecurityNumber AS ThirdPartyTaxId, CreditProfileThirdPartyRelationships.CreditProfileId  FROM CreditProfileThirdPartyRelationships
INNER JOIN CustomerThirdPartyRelationships
ON CreditProfileThirdPartyRelationships.ThirdPartyRelationshipId = CustomerThirdPartyRelationships.Id
INNER JOIN Partycontacts
ON CustomerThirdPartyRelationships.ThirdPartyContactId = PartyContacts.Id
WHERE CreditProfileId=@CreditProfileId AND CustomerThirdPartyRelationships.IsActive = 1 AND CreditProfileThirdPartyRelationships.IsActive=1 AND Partycontacts.IsActive = 1 AND CustomerThirdPartyRelationships.RelationshipType != 'VendorRecourse'
)
,CTE_CreditBureauRequest
AS
(
SELECT TOP 1 CASE WHEN CreditBureauConfigs.Code='I' THEN NULL ELSE CreditBureauConfigs.Code END AS CustomerCreditBureau
,CASE WHEN CreditRatingCode='I' THEN NULL ELSE CreditRatingCode END AS CreditRatingCode
,CASE WHEN SicCode='I' THEN NULL ELSE SicCode END AS SicCode
,CASE WHEN CurrentManagementControlYear='I' THEN NULL ELSE CurrentManagementControlYear END AS CurrentManagementControlYear
,CASE WHEN BusinessReportTimeAsCurrentOwner='I' THEN NULL ELSE BusinessReportTimeAsCurrentOwner END AS BusinessReportTimeAsCurrentOwner
,CASE WHEN BankruptciesIndicatorCode='I' THEN NULL ELSE BankruptciesIndicatorCode END AS BankruptciesIndicatorCode
,CASE WHEN BankruptcyRelationshipIndicatorCode='I' THEN NULL ELSE BankruptcyRelationshipIndicatorCode END AS BankruptcyRelationshipIndicatorCode
,JudgmentsIndicatorCode
,LiensIndicatorCode
,OutOfBusinessIndicatorCode
,SuitsIndicatorCode
,CASE WHEN AbnormalBusinessReportIndicatorCode='I' THEN @IrrBusRpt ELSE AbnormalBusinessReportIndicatorCode END AS AbnormalBusinessReportIndicatorCode
,NoTradeIndicatorCode
,CASE WHEN BusinessBureauScore='I' THEN NULL ELSE BusinessBureauScore END AS BusinessBureauScore
,CASE WHEN CompositePaydexCurrent12MonthAverageAmount='I' THEN NULL ELSE CompositePaydexCurrent12MonthAverageAmount END AS CompositePaydexCurrent12MonthAverageAmount
,CASE WHEN CompositePaydexPrior12MonthAverageAmount='I' THEN NULL ELSE CompositePaydexPrior12MonthAverageAmount END AS CompositePaydexPrior12MonthAverageAmount
,CASE WHEN PaydexFirmScore='I' THEN NULL ELSE PaydexFirmScore END AS PaydexFirmScore
,CASE WHEN ExperiencesInPaydexCalculationCount='I' THEN NULL ELSE ExperiencesInPaydexCalculationCount END AS ExperiencesInPaydexCalculationCount
,CASE WHEN NegativePaymentExperiencesCount ='I' THEN NULL ELSE NegativePaymentExperiencesCount END AS NegativePaymentExperiencesCount
,CASE WHEN SatisfactoryPaymentExperiencesCount='I' THEN NULL ELSE SatisfactoryPaymentExperiencesCount END AS SatisfactoryPaymentExperiencesCount
,CASE WHEN DelinquentPaymentExperiencesCount='I' THEN NULL ELSE DelinquentPaymentExperiencesCount END AS DelinquentPaymentExperiencesCount
,CASE WHEN SlowAndNegativePaymentExperiencesCount='I' THEN NULL ELSE SlowAndNegativePaymentExperiencesCount END AS SlowAndNegativePaymentExperiencesCount
,CASE WHEN SlowPaymentExperiencesCount='I' THEN NULL ELSE SlowPaymentExperiencesCount END AS SlowPaymentExperiencesCount
,CASE WHEN PercentSatisfactoryExperiences='I' THEN NULL ELSE PercentSatisfactoryExperiences END AS PercentSatisfactoryExperiences
,CASE WHEN PercentSlowNegativeExperiences='I' THEN NULL ELSE PercentSlowNegativeExperiences END AS PercentSlowNegativeExperiences
,CreditProfileId
,CreditBureauRequests.Id
FROM CreditBureauRequests
JOIN CreditBureauRqstBusinesses on  CreditBureauRequests.Id =CreditBureauRqstBusinesses.CreditBureauRequestId
JOIN CreditBureauConfigs on CreditBureauRqstBusinesses.CustomerCreditBureauId=CreditBureauConfigs.Id
WHERE CreditProfileId= @CreditProfileId And (CreditBureauRequests.DataRequestStatus = 'Failed' OR CreditBureauRequests.DataRequestStatus = 'NeedsReview' OR CreditBureauRequests.DataRequestStatus = 'Completed')
AND CreditBureauRqstBusinesses.IsDefault=1
ORDER BY Id DESC
)
,CTE_LCThirdPartBest_WorstScore
AS
(
SELECT MAX(CBScore) AS BestCBScore,MIN(CBScore) AS WorstCBScore,MAX(TotalScore) AS BestTotalScore,MIN(TotalScore) AS WorstTotalScore,CTE_CreditBureauRequest.Id AS CreditBureauRequestId from CreditBureauRqstConsumers
INNER JOIN CTE_CreditBureauRequest
ON CreditBureauRqstConsumers.CreditBureauRequestId = CTE_CreditBureauRequest.Id
GROUP BY CTE_CreditBureauRequest.Id
)
,CTE_SalesRep
AS
(
SELECT Users.FullName,EmployeesAssignedToLOCs.CreditProfileId FROM EmployeesAssignedToLOCs
INNER JOIN EmployeesAssignedToParties
ON EmployeesAssignedToLOCs.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
AND EmployeesAssignedToLOCs.IsActive = 1 AND EmployeesAssignedToParties.IsActive = 1
AND EmployeesAssignedToLOCs.IsPrimary =1
INNER JOIN RoleFunctions
ON EmployeesAssignedToParties.RoleFunctionId  = RoleFunctions.Id
AND RoleFunctions.IsActive = 1
INNER JOIN Users
ON EmployeesAssignedToParties.EmployeeId = Users.Id
WHERE EmployeesAssignedToLOCs.CreditProfileId = @CreditProfileId AND RoleFunctions.Id = 2 AND EmployeesAssignedToParties.PartyRole = 'Customer'
)
,CTE_EnteredBy
AS
(
SELECT TOP 1 FullName AS EnteredBy,ISNULL(UpdatedTime,CreatedTime)AS EnteredTime, EntityId FROM #WorkItemTempTableForEntered WHere ActionName = 'SubmitToCredit' OR  ActionName = 'SubmittedToCredit' ORDER BY Id DESC
)
,CTE_ApprovedBy
AS
(
SELECT TOP 1 FullName AS ApprovedBy,ISNULL(UpdatedTime,CreatedTime)AS ApprovedTime, EntityId FROM #WorkItemTempTable where ActionName = 'FinalApproval' ORDER BY Id DESC
)
,CTE_RelatedPreApprovalLOC
AS
(
SELECT CreditProfiles.Number, @CreditProfileId AS CreditProfileId FROM Proposals
INNER JOIN CreditProfiles
ON Proposals.PreApprovalLOCId = CreditProfiles.Id
WHERE Proposals.Id IN (SELECT OpportunityId FROM CreditProfiles WHERE Id =@CreditProfileId)
),
CTE_CustomerDoingBusinessAs AS
(
SELECT  TOP 1 MAX(CustomerDoingBusinessAs.Id) Id
FROM Parties
INNER JOIN Customers
ON Parties.Id = Customers.Id
LEFT JOIN CustomerDoingBusinessAs
ON Customers.Id = CustomerDoingBusinessAs.CustomerId
WHERE Parties.Id= @PartyId AND CustomerDoingBusinessAs.EffectiveDate<=CONVERT(date, getdate())
GROUP BY EffectiveDate
ORDER BY CustomerDoingBusinessAs.EffectiveDate desc
),
CTE_DoingBusinessAsName AS
(
SELECT CustomerDoingBusinessAs.DoingBusinessAsName,CustomerDoingBusinessAs.CustomerId FROM
CustomerDoingBusinessAs
JOIN CTE_CustomerDoingBusinessAs ON CustomerDoingBusinessAs.id=CTE_CustomerDoingBusinessAs.Id
)
SELECT
CreditProfiles.Number AS ApplicationNumber
,Parties.PartyName AS BusinessName
,CTE_DoingBusinessAsName.DoingBusinessAsName AS DBAName
,(PartyAddresses.AddressLine1 + CASE WHEN PartyAddresses.AddressLine2 IS NULL OR PartyAddresses.AddressLine2 = '' THEN '' ELSE ', ' + PartyAddresses.AddressLine2 END) AS Address
,PartyAddresses.City +', '+ States.ShortName + ' '+PartyAddresses.PostalCode AS CityStateZip
,CTE_PartyContact.PhoneNumber1 AS BusinessPhone
,Parties.PartyNumber AS CustomerNumber
,Parties.LastFourDigitUniqueIdentificationNumber AS FedTaxIDSSN
,CreditProfiles.ApprovedAmount_Amount AS ApproveAmount
,CreditProfiles.ApprovedAmount_Currency AS ApproveAmountCurrency
,CTE_CreditDecision.ExpiryDate AS ExpirationDate
,CASE WHEN CreditProfiles.IsCreditInLW = 0 THEN ''
WHEN CTE_CreditOFACRequests.ResponseType IN ('AlreadyPassed','Pass')
THEN CTE_CreditOFACRequests.ResponseType+' '+CASE WHEN CTE_CreditOFACRequests.ResponseDate IS NULL THEN ''
ELSE REPLACE(LEFT(CONVERT(VARCHAR(20),CTE_CreditOFACRequests.ResponseDate,101),5),'0','')+RIGHT(CONVERT(VARCHAR(20),CTE_CreditOFACRequests.ResponseDate,101),5)
END
ELSE
CASE WHEN CTE_CreditOFACHits.Status = '_' THEN ''
ELSE CTE_CreditOFACHits.Status END
+' '+ CASE WHEN CTE_CreditOFACHits.DecisionTime IS NULL THEN ''
ELSE REPLACE(LEFT(CONVERT(VARCHAR(20),CTE_CreditOFACHits.DecisionTime,101),5),'0','')+RIGHT(CONVERT(VARCHAR(20),CTE_CreditOFACHits.DecisionTime,101),5) END  END AS OFACCompliance
,CTE_CreditDecision.BusinessAdditionalCollateral
,CTE_CreditDecision.PrincipalAdditionalCollateral
,CTE_CreditDecision.StandardCollateral
,CASE WHEN OriginationSourceTypes.Id = 1 THEN Vendor.PartyName ELSE @LWVendor END AS PrimaryVendor
,CASE WHEN CTE_ApprovedStructure.InceptionRentFactor = 0 THEN null ELSE  CTE_ApprovedStructure.InceptionRentFactor*CTE_ApprovedStructure.Amount_Amount END AS LeasePayment
,CTE_ApprovedStructure.ExhibitAmountCurrency AS LeasePaymentCurrency
,CTE_ApprovedStructure.PaymentFrequency AS PaymentInterval
,CTE_ApprovedStructure.Term AS LeaseTerm
,CASE WHEN CreditApplicationPricingDetails.RequestEOTOption = '_' THEN '' ELSE CreditApplicationPricingDetails.RequestEOTOption END AS TerminationOption
,CreditProfiles.RequestedAmount_Amount AS FinancingRequestedAmount
,CreditProfiles.RequestedAmount_Currency AS FinancingRequestedAmountCurrency
,CTE_CreditDecision.SecurityDepositAmount_Amount AS SecurityDepositAmount
,CTE_CreditDecision.SecurityDepositAmount_Currency AS SecurityDepositAmountCurrency
,CTE_ApprovedStructure.CustomerExpectedResidual_Amount AS ResidualAmount
,CTE_ApprovedStructure.CustomerExpectedResidual_Currency AS ResidualAmountCurrency
,CTE_CreditDecision.WriteUp
,CTE_CreditDecision.DecisionDocumentation
,CTE_CreditDecision.Id AS DecisionId
,CTE_ThirdParties.ThirdPartyName AS RequiredPersonalGuaranteeName
,CTE_ThirdParties.ThirdPartyTaxId AS RequiredPersonalGuaranteeTaxId
,CTE_CreditBureauRequest.CreditRatingCode AS BusRptRating
,CTE_CreditBureauRequest.SicCode AS BusRptSICCode
,CTE_CreditBureauRequest.CurrentManagementControlYear AS ControlYear
,CTE_CreditBureauRequest.BusinessReportTimeAsCurrentOwner AS ScoredTimeasOwner
,CTE_CreditBureauRequest.BankruptciesIndicatorCode AS BankruptcyPresent
,CTE_CreditBureauRequest.BankruptcyRelationshipIndicatorCode AS BankruptcyRelation
,CTE_CreditBureauRequest.JudgmentsIndicatorCode AS JudgementsPresent
,CTE_CreditBureauRequest.LiensIndicatorCode AS LiensPresent
,CTE_CreditBureauRequest.OutOfBusinessIndicatorCode AS OutofBus
,CTE_CreditBureauRequest.SuitsIndicatorCode AS SuitsPresent
,CTE_CreditBureauRequest.AbnormalBusinessReportIndicatorCode AS AbnormalBusRpt
,CTE_CreditBureauRequest.NoTradeIndicatorCode AS NoTrade
,CTE_CreditBureauRequest.BusinessBureauScore AS CommercialCreditScore
,CTE_CreditBureauRequest.CompositePaydexCurrent12MonthAverageAmount AS PaydexCurr12Mos
,CTE_CreditBureauRequest.CompositePaydexPrior12MonthAverageAmount AS PaydexPrior12Mos
,CTE_CreditBureauRequest.PaydexFirmScore AS CurrentPaydex
,CTE_CreditBureauRequest.ExperiencesInPaydexCalculationCount AS ExperiencesInPaydex
,CTE_CreditBureauRequest.NegativePaymentExperiencesCount AS NegativePayExps
,CTE_CreditBureauRequest.SatisfactoryPaymentExperiencesCount AS SatisfactoryPayExps
,CTE_CreditBureauRequest.DelinquentPaymentExperiencesCount AS PastDuePayExps
,CTE_CreditBureauRequest.SlowAndNegativePaymentExperiencesCount AS SlowAndNegativePayExps
,CTE_CreditBureauRequest.SlowPaymentExperiencesCount AS SlowPayExps
,CTE_CreditBureauRequest.PercentSatisfactoryExperiences AS PctSatisfactory
,CTE_CreditBureauRequest.PercentSlowNegativeExperiences AS PctSlow
,CTE_CreditBureauRequest.CustomerCreditBureau AS BusRptCode
,CTE_SalesRep.FullName AS SalesRep
,CTE_CreditDecision.DecisionStatus AS Decision
,CTE_LCThirdPartBest_WorstScore.BestCBScore AS BestPrincipalCBScore
,CASE WHEN CTE_LCThirdPartBest_WorstScore.BestTotalScore = (SELECT Value FROM GlobalParameters WHERE Name = 'CreditScoreUndefinedIndicator' AND Category = 'CreditRAC' AND IsActive=1) THEN NULL ELSE CTE_LCThirdPartBest_WorstScore.BestTotalScore END AS BestPrincipalTotalScore
,CTE_LCThirdPartBest_WorstScore.WorstCBScore AS WorstPrincipalCBScore
,CASE WHEN CTE_LCThirdPartBest_WorstScore.WorstTotalScore = (SELECT Value FROM GlobalParameters WHERE Name = 'CreditScoreUndefinedIndicator' AND Category = 'CreditRAC' AND IsActive=1) THEN NULL ELSE CTE_LCThirdPartBest_WorstScore.WorstTotalScore END AS WorstPrincipalTotalScore
,CASE WHEN CreditProfiles.IsPreApproval = 1 THEN '' ELSE CTE_EnteredBy.EnteredBy END AS  EnteredBy
,CASE WHEN CreditProfiles.IsPreApproval = 1 THEN NULL ELSE CTE_EnteredBy.EnteredTime END AS EnteredTime
,CASE WHEN (SELECT TOP 1 IsPreApproved FROM Proposals WHERE Id = CreditProfiles.OpportunityId) = 1 THEN '' ELSE CTE_ApprovedBy.ApprovedBy END AS ApprovedBy
,CASE WHEN (SELECT TOP 1 IsPreApproved FROM Proposals WHERE Id = CreditProfiles.OpportunityId) = 1 THEN NULL ELSE CTE_ApprovedBy.ApprovedTime END AS ApprovedTime
,CASE WHEN (SELECT TOP 1 IsPreApproved FROM Proposals WHERE Id = CreditProfiles.OpportunityId) = 1 THEN CTE_RelatedPreApprovalLOC.Number ELSE '' END AS RelatedPreApprovalLineofCredit
FROM
Parties
INNER JOIN Customers
ON Parties.Id = Customers.Id
INNER JOIN CreditProfiles
ON Customers.Id = CreditProfiles.CustomerId
INNER JOIN OriginationSourceTypes
ON CreditProfiles.OriginationSourceTypeId = OriginationSourceTypes.Id
AND OriginationSourceTypes.IsActive = 1
LEFT JOIN CTE_ApprovedStructure
ON CreditProfiles.Id = CTE_ApprovedStructure.CreditProfileId
LEFT JOIN PartyAddresses
ON Parties.Id= PartyAddresses.PartyId
AND PartyAddresses.IsActive = 1 AND IsMain = 1
LEFT JOIN States
ON PartyAddresses.StateId = States.Id
AND States.IsActive = 1
LEFT JOIN CTE_PartyContact
ON PartyAddresses.Id = CTE_PartyContact.MailingAddressId
LEFT JOIN CTE_CreditDecision
ON CreditProfiles.Id = CTE_CreditDecision.CreditProfileId
LEFT JOIN CTE_CreditOFACHits
ON CreditProfiles.Id = CTE_CreditOFACHits.CreditProfileId
LEFT JOIN CTE_CreditOFACRequests
ON CreditProfiles.Id=CTE_CreditOFACRequests.CreditProfileId
LEFT JOIN Parties AS Vendor
ON CreditProfiles.OriginationSourceId = Vendor.Id
LEFT JOIN Opportunities
ON CreditProfiles.OpportunityId = Opportunities.Id
LEFT JOIN CreditApplications
ON Opportunities.Id = CreditApplications.Id
LEFT JOIN CreditApplicationPricingDetails
ON CreditApplications.Id = CreditApplicationPricingDetails.Id
LEFT JOIN CTE_ThirdParties
ON CreditProfiles.Id = CTE_ThirdParties.CreditProfileId
LEFT JOIN CTE_CreditBureauRequest
ON CreditProfiles.Id = CTE_CreditBureauRequest.CreditProfileId
LEFT JOIN CTE_SalesRep
ON CreditProfiles.Id = CTE_SalesRep.CreditProfileId
LEFT JOIN CTE_LCThirdPartBest_WorstScore
ON CTE_CreditBureauRequest.Id = CTE_LCThirdPartBest_WorstScore.CreditBureauRequestId
LEFT JOIN CTE_EnteredBy
ON CreditProfiles.Id = CTE_EnteredBy.EntityId
LEFT JOIN CTE_ApprovedBy
ON CreditProfiles.Id = CTE_ApprovedBy.EntityId
LEFT JOIN CTE_RelatedPreApprovalLOC
ON CreditProfiles.Id = CTE_RelatedPreApprovalLOC.CreditProfileId
LEFT JOIN CTE_DoingBusinessAsName
ON Customers.Id=CTE_DoingBusinessAsName.CustomerId
WHERE Parties.Id = @PartyId AND CreditProfiles.Id= @CreditProfileId
DROP TABLE #OFACTempTable
DROP TABLE #ApprovedStructureTempTable
DROP TABLE #WorkItemTempTable
DROP TABLE #WorkItemTempTableForEntered

GO
