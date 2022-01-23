SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateActivity]
(@UserId                  BIGINT,
@ModuleIterationStatusId BIGINT,
@CreatedTime             DATETIMEOFFSET,
@MigrateActivity         BIT = 0,
@ProcessedRecords        BIGINT OUTPUT,
@FailedRecords           BIGINT OUTPUT
)
AS
BEGIN
DECLARE @ErrorLogs ErrorMessageList;

DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , NULL

UPDATE stgActivity  SET IsFailed=0  WHERE IsMigrated = 0

CREATE TABLE #FailedProcessingLogs
([Id]      BIGINT NOT NULL,
[ActivityId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgActivity
WHERE IsMigrated = 0
);

UPDATE A Set R_PortfolioId = P.Id
	FROM stgActivity A
	INNER JOIN Portfolios P ON UPPER(A.PortfolioName) = UPPER(P.Name)
	WHERE P.IsActive = 1 AND A.IsMigrated = 0 AND A.IsFailed = 0 

UPDATE A Set R_OwnerUserId = U.Id
	FROM stgActivity A
	INNER JOIN Users U ON UPPER(A.OwnerUserLoginName) = UPPER(U.LoginName)
	WHERE U.ApprovalStatus = 'Approved' AND A.IsMigrated = 0 AND A.IsFailed = 0 AND A.OwnerUserLoginName IS NOT NULL

UPDATE A Set R_OwnerGroupId = U.Id
	FROM stgActivity A
	INNER JOIN UserGroups U ON UPPER(A.OwnerUserGroupName) = UPPER(U.Name)
	WHERE U.IsActive = 1 AND  A.IsMigrated = 0 AND A.IsFailed = 0 AND A.OwnerUserGroupName IS NOT NULL

UPDATE A Set R_ActivityTypeId = ATP.Id
	FROM stgActivity A
	INNER JOIN ActivityTypes ATP ON UPPER(A.ActivityType) = UPPER(ATP.Type)
	WHERE ATP.IsActive = 1 AND A.IsMigrated = 0 AND A.IsFailed = 0 AND ATP.TransactionTobeInitiatedId IS NOT NULL AND ATP.Type IN ('AgencyPlacement','Bankruptcy','Receivership','LegalPlacement')

UPDATE A Set R_StatusId = ASCS.Id
	FROM stgActivity A
	INNER JOIN ActivityStatusConfigs ASCS ON UPPER(A.Status) = UPPER(ASCS.Status)
	WHERE ASCS.IsActive = 1 AND A.IsMigrated = 0 AND A.IsFailed = 0 AND ASCS.Status IN ('Pending','Completed')

UPDATE A Set R_CurrencyId = C.Id
	FROM stgActivity A
    INNER JOIN CurrencyCodes CC ON UPPER(A.CurrencyCode) = UPPER(CC.ISO)
	INNER JOIN Currencies C ON C.CurrencyCodeId = CC.Id
	WHERE C.IsActive = 1 AND A.IsMigrated = 0 AND A.IsFailed = 0 AND A.CurrencyCode IS NOT NULL

UPDATE A Set R_LegalStatusId = CASE WHEN P.LegalReliefType = 'Bankruptcy' AND Chapter = 'Chapter11'
                                              THEN (SELECT Id FROM LegalStatusConfigs WHERE IsActive = 1 AND LegalStatus = 'Chapter 11 Bankruptcy')
											  WHEN P.LegalReliefType = 'Bankruptcy' AND Chapter = 'Chapter12'
                                              THEN (SELECT Id FROM LegalStatusConfigs WHERE IsActive = 1 AND LegalStatus = 'Chapter 12 Bankruptcy')
											  WHEN P.LegalReliefType = 'Bankruptcy' AND Chapter = 'Chapter13'
                                              THEN (SELECT Id FROM LegalStatusConfigs WHERE IsActive = 1 AND LegalStatus = 'Chapter 13 Bankruptcy')
											  WHEN P.LegalReliefType = 'Bankruptcy' AND Chapter = 'Chapter15'
                                              THEN (SELECT Id FROM LegalStatusConfigs WHERE IsActive = 1 AND LegalStatus = 'Chapter 15 Bankruptcy')
											   WHEN P.LegalReliefType = 'Bankruptcy' AND (Chapter = 'Chapter7' OR Chapter = 'Chapter7NoAsset')
                                              THEN (SELECT Id FROM LegalStatusConfigs WHERE IsActive = 1 AND LegalStatus = 'Chapter 7 Bankruptcy')
                                              WHEN P.LegalReliefType = 'Receivership'
                                              THEN (SELECT Id FROM LegalStatusConfigs WHERE IsActive = 1 AND LegalStatus = 'Active Receivership')
                                              END
    FROM stgActivity A
    INNER JOIN stgLegalRelief P ON A.Id = P.Id
    WHERE A.IsMigrated = 0

UPDATE A Set R_LegalStatusId = CASE WHEN P.PlacementType = 'Agency'
                                              THEN (SELECT Id FROM LegalStatusConfigs WHERE IsActive = 1 AND LegalStatus = 'Assigned To Agency')
                                              WHEN P.PlacementType = 'Legal'
                                              THEN (SELECT Id FROM LegalStatusConfigs WHERE IsActive = 1 AND LegalStatus = 'Assigned To Legal')
                                              END
    FROM stgActivity A
    INNER JOIN stgAgencyLegalPlacement P ON A.Id = P.Id
    WHERE A.IsMigrated = 0

--Legal Relief
UPDATE LR Set R_CourtId = C.Id
	FROM stgLegalRelief LR
	INNER JOIN stgActivity A ON LR.Id = A.Id
	INNER JOIN Courts C ON UPPER(LR.CourtName) = UPPER(C.CourtName)
	WHERE C.IsActive = 1 AND  A.IsMigrated = 0 

UPDATE LR Set R_StateId = S.Id
	FROM stgLegalRelief LR
	INNER JOIN stgActivity A ON LR.Id = A.Id
	INNER JOIN States S ON UPPER(LR.StateShortName) = UPPER(S.ShortName)
	WHERE S.IsActive =1 AND LR.LegalReliefType = 'Receivership' AND  A.IsMigrated = 0 

UPDATE LRPC Set R_StateId = S.Id
	FROM stgLegalRelief LR
	INNER JOIN stgActivity A ON LR.Id = A.Id
	INNER JOIN stgLegalReliefProofOfClaim LRPC ON LR.Id = LRPC.LegalReliefId
    INNER JOIN States S ON UPPER(LRPC.StateShortName) = UPPER(S.ShortName)
	WHERE S.IsActive = 1 AND A.IsMigrated = 0 


--Activity Common Validation
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Invalid Activity Legal Status for the specified Activity Type'
FROM stgActivity Activity
where IsMigrated = 0 AND R_LegalStatusId IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Activity.Id,@ModuleIterationStatusId,'Activity Type should be active and valid'
from stgActivity Activity
where IsMigrated = 0 AND R_ActivityTypeId IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Invalid Currency Code'
FROM stgActivity Activity
where IsMigrated = 0 AND R_CurrencyId IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Invalid Portfolio Name'
FROM stgActivity Activity
where IsMigrated = 0 AND R_PortfolioId IS NULL

Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Activity.Id,@ModuleIterationStatusId,'Status should be active and valid'
from stgActivity Activity
where IsMigrated = 0 AND R_StatusId IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Please enter Owner User Login Name'
FROM stgActivity Activity
where IsMigrated = 0 AND Activity.IsFollowUpRequired = 1 AND Activity.OwnerUserLoginName IS NULL AND  R_OwnerUserId IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Invalid Owner User Login Name'
FROM stgActivity Activity
where IsMigrated = 0  AND Activity.OwnerUserLoginName IS NOT NULL AND  R_OwnerUserId IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Please enter Follow Up Date'
FROM stgActivity Activity
where IsMigrated = 0 AND Activity.IsFollowUpRequired = 1 AND FollowUpDate IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Invalid Owner User Group Name'
FROM stgActivity Activity
LEFT JOIN UserGroups UserGroups ON UPPER(UserGroups.Name) = UPPER(Activity.OwnerUserGroupName)
where IsMigrated = 0 AND Activity.OwnerUserGroupName IS NOT NULL AND UserGroups.Id IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Please provide Person Contacted/Contact Reference only if Customer Contacted is true'
FROM stgActivity Activity
where IsMigrated = 0 AND IsCustomerContacted = 0 AND PersonContactedUniqueIdentifier IS NOT NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Atleast one contract must be selected for Activity'
FROM stgActivity Activity
LEFT JOIN stgActivityContractDetail ActivityContract on Activity.Id = ActivityContract.ActivityId
where IsMigrated = 0 AND ActivityContract.Id IS  NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Please provide Closing comments only if Close Follow Up is required'
FROM stgActivity Activity
where IsMigrated = 0 AND Activity.CloseFollowUp = 0 AND Activity.ClosingComments IS NOT NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Please provide Followup Date only if Follow Up is required'
FROM stgActivity Activity
where IsMigrated = 0 AND Activity.IsFollowUpRequired = 0 AND Activity.FollowUpDate IS NOT NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Please provide Chapter'
FROM stgActivity Activity
where IsMigrated = 0 AND Activity.ActivityType = 'Bankruptcy' AND (Chapter IS NULL OR Chapter = '_')

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'LegalReliefIntention is not valid.Please provide Legal Relief Intention'
FROM stgActivity Activity
INNER JOIN stgActivityContractDetail contract ON Activity.Id = contract.ActivityId
where IsMigrated = 0 AND Activity.ActivityType IN ('Bankruptcy','Receivership') AND (contract.LegalReliefIntention IS NULL OR contract.LegalReliefIntention = '_')

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Please provide Legal Relief Intention Date'
FROM stgActivity Activity
INNER JOIN stgActivityContractDetail contract ON Activity.Id = contract.ActivityId
where IsMigrated = 0 AND Activity.ActivityType IN ('Bankruptcy','Receivership') AND contract.LegalReliefIntentionDate IS NULL 

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Please provide Legal Relief Intention/Legal Relief Intention Date only for Receivership and Bankruptcy type'
FROM stgActivity Activity
INNER JOIN stgActivityContractDetail contract ON Activity.Id = contract.ActivityId
where IsMigrated = 0 AND  Activity.ActivityType IN ('AgencyPlacement','LegalPlacement') AND ((contract.LegalReliefIntention IS NOT NULL AND contract.LegalReliefIntention <> '_')  OR contract.LegalReliefIntentionDate IS NOT NULL)

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Please provide Chapter only for Bankruptcy'
FROM stgActivity Activity
where IsMigrated = 0 AND  Activity.ActivityType <> 'Bankruptcy' AND Chapter IS NOT NULL AND Chapter <> '_'

--Placement
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Incorrect Placement Status'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement P ON A.Id = P.Id
WHERE A.IsMigrated = 0 AND  P.Status NOT IN ('PendingPlacement','FirstPlacement','SecondPlacement','ThirdPlacement')

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Please provide Collection Agency/Attorney Number'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND CollectionAgencyNumberOrAttorneyNumber IS NULL AND AP.Status IN ('FirstPlacement','SecondPlacement','ThirdPlacement')

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Date of Placement should not be greater than system date'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND DateOfPlacement > GETDATE()

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Please enter Placement Purpose'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND PlacementPurpose IS NULL AND PlacementType = 'Legal' AND AP.Status IN ('FirstPlacement','SecondPlacement','ThirdPlacement')

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Please enter Legal Relief Record Number'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND LegalReliefRecordNumber IS NULL AND PlacementType = 'Legal' AND PlacementPurpose  IN ('Bankruptcy','Receivership') AND AP.Status IN ('FirstPlacement','SecondPlacement','ThirdPlacement')

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Legal Relief Record Number is not applicable For PlacementPurpose : Litigation'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND LegalReliefRecordNumber IS NOT NULL  AND PlacementType = 'Legal' AND PlacementPurpose  IN ('Litigation')

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Legal Relief Record Number is not applicable For Agency Placement Type'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND LegalReliefRecordNumber IS NOT NULL  AND PlacementType = 'Agency'

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Placement Purpose is not applicable For Agency Placement Type'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND PlacementPurpose IS NOT NULL AND PlacementPurpose <> '_'  AND PlacementType = 'Agency'

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Fee is not applicable For Legal Placement Type'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND Fee_Amount IS NOT NULL AND Fee_Amount <> 0.00  AND PlacementType = 'Legal'

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Fee is not applicable For Contigency Agency Placement Type'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND Fee_Amount IS NOT NULL AND Fee_Amount <> 0.00  AND FeeStructure = 'Contingency' AND PlacementType = 'Agency'

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Fee Structure is not applicable For Legal Placement Type'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND FeeStructure IS NOT NULL AND  FeeStructure <> '_'  AND PlacementType = 'Legal'

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'ContingencyPercentage is not applicable For Legal Placement Type'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND ContingencyPercentage IS NOT NULL AND ContingencyPercentage <> 0 AND PlacementType = 'Legal' 

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'ContingencyPercentage is applicable for Fee structure of type Contingency of Agency Legal Placement '
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND ContingencyPercentage IS NOT NULL AND ContingencyPercentage <> 0 AND FeeStructure <> 'Contingency' AND PlacementType = 'Agency' 

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Fee Currency cannot be null/empty. Please enter valid Currency'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
LEFT JOIN Currencies C ON AP.Fee_Currency = C.Name
WHERE IsMigrated = 0 AND C.Id IS NULL 

--Legal Relief
INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Invalid Court Name'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND CourtName IS NOT NULL AND R_CourtId IS NULL

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Invalid State Name'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Receivership' AND StateShortName IS NOT NULL AND R_StateId IS NULL

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Legal Relief type cannot be null'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType IS NULL

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Status cannot be null'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LR.Status IS NULL

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT LR.Id,@ModuleIterationStatusId,'LegalRelief ProofOfClaim Status cannot be null'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
INNER JOIN stgLegalReliefProofOfClaim POC ON LR.Id = POC.LegalReliefId
WHERE IsMigrated = 0 AND POC.Status IS NULL

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT LR.Id,@ModuleIterationStatusId,'Invalid State Name For Legal Relief POC'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
INNER JOIN stgLegalReliefProofOfClaim POC ON LR.Id = POC.LegalReliefId
WHERE IsMigrated = 0 AND POC.StateShortName IS NOT NULL AND POC.R_StateId IS NULL 

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT LR.Id,@ModuleIterationStatusId,'Please provide Proof Of Contract'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
INNER JOIN stgLegalReliefProofOfClaim POC ON LR.Id = POC.LegalReliefId
LEFT JOIN stgLegalReliefPOCContract PC ON  POC.Id = PC.LegalReliefProofOfClaimId
WHERE IsMigrated = 0 AND POC.Id IS NOT NULL AND PC.Id IS NULL

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Please enter Filing Date'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND FilingDate IS NULL AND ((LR.Status = 'Active'  AND LegalReliefType = 'Receivership') OR (LR.Status <> '_'  AND LegalReliefType = 'Bankruptcy'))

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'The Filing Date should not be greater than system date.'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND FilingDate IS NOT NULL AND FilingDate > GETDATE()

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT LR.Id,@ModuleIterationStatusId,'Please enter Proof Of Claim Number'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
INNER JOIN stgLegalReliefProofOfClaim POC ON LR.Id = POC.LegalReliefId
WHERE IsMigrated = 0 AND POC.ClaimNumber IS NULL

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'POC Deadline Date Should be greater than or equal to the Filing Date'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND FilingDate IS NOT NULL AND POCDeadlineDate IS NOT NULL AND POCDeadlineDate < FilingDate

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Reaffirmation Date Should be greater than or equal to the Filing Date'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND FilingDate IS NOT NULL AND ReaffirmationDate IS NOT NULL AND ReaffirmationDate < FilingDate

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Confirmation Date Should be greater than or equal to the Filing Date.'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND FilingDate IS NOT NULL AND ConfirmationDate IS NOT NULL AND ConfirmationDate < FilingDate

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Address1/Address2/AddressLine3/Neighborhood is applicable either for Legal Relief type Receivership or if Trustee Appointed is true for type Bankruptcy'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Bankruptcy' AND  TrusteeAppointed = 0
 AND  (Address1 IS NOT NULL OR Address2 IS NOT NULL OR AddressLine3 IS NOT NULL OR Neighborhood IS NOT NULL)

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'SubdivisionOrMunicipality/Zip/City/StateShortName is applicable for Legal Relief type Receivership or if Trustee Appointed is true for type Bankruptcy'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Bankruptcy' AND  TrusteeAppointed = 0 AND (SubdivisionOrMunicipality IS NOT  NULL OR Zip IS NOT NULL OR City IS NOT NULL OR StateShortName IS NOT NULL)

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'OfficePhone/CellPhone/EMailId/Fax Number is applicable for Bankruptcy if Trustee Appointed is true'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND ((LegalReliefType = 'Bankruptcy' AND  TrusteeAppointed = 0) OR LegalReliefType = 'Receivership') AND (OfficePhone IS NOT  NULL OR CellPhone IS NOT NULL  OR FaxNumber IS NOT NULL OR EMailId IS NOT NULL)

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'ReceiverOfficePhone/ReceiverDirectPhone/ReceiverEmailId is applicable for Legal Relief type Receivership'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Bankruptcy' AND (ReceiverEmailId IS NOT NULL OR ReceiverDirectPhone IS NOT NULL OR ReceiverOfficePhone IS NOT NULL )

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Bar Date is applicable for Legal Relief type Receivership'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND BarDate IS NOT NULL AND LegalReliefType = 'Bankruptcy'

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'State Court District is applicable for Legal Relief type Receivership'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND StateCourtDistrict IS NOT NULL AND LegalReliefType = 'Bankruptcy'

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Receiver Name is applicable for Legal Relief type Receivership'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND ReceiverName IS NOT NULL AND LegalReliefType = 'Bankruptcy'

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'WebPage is applicable for Legal Relief type Receivership'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Bankruptcy' AND  WebPage IS NOT NULL

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Only Active Status is applicable for Legal Relief type Receivership'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND (LegalReliefType = 'Receivership' AND LR.Status NOT IN  ('Active', '_')) OR (LegalReliefType = 'Bankruptcy' AND LR.Status = 'Active')

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Receiver EmailId is not in valid format'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Receivership' AND ReceiverEmailId IS NOT NULL AND  ReceiverEmailId  NOT LIKE '%_@__%.__%'

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'POCDeadlineDate/ReaffirmationDate/ConfirmationDate/ConverstionDate is applicable for Legal Relief type Bankruptcy'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Receivership' AND (POCDeadlineDate IS NOT NULL OR ReaffirmationDate IS NOT NULL OR ConfirmationDate IS NOT NULL OR ConversionDate IS NOT NULL)

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Notes/DebtorNotes/BankruptcyNoticeNumber is applicable for Legal Relief type Bankruptcy'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Receivership' AND (Notes IS NOT NULL OR DebtorNotes IS NOT NULL OR BankruptcyNoticeNumber IS NOT NULL )

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'DebtorinPossession/TrusteeAppointed is applicable for Legal Relief type Bankruptcy'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Receivership' AND (DebtorinPossession =1 OR TrusteeAppointed =1)

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'TrusteeNotes/TrusteeAppointedUniqueIdentifier is applicable if Trustee Appointed is true for Legal Relief type Bankruptcy'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Receivership'  AND (TrusteeNotes IS NOT NULL OR TrusteeAppointedUniqueIdentifier IS NOT NULL)

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Email Id is not in valid format'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND LegalReliefType = 'Bankruptcy' AND EMailId IS NOT NULL AND EMailId  NOT LIKE '%_@__%.__%'

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Please provide valid url in Web Page.'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND dbo.IsValidUrl(Webpage) = 0


IF(@MigrateActivity = 1)
BEGIN
UPDATE A Set R_PersonContactId = PC.Id
	FROM stgActivity A
	INNER JOIN Parties P ON UPPER(A.CustomerNumber) = UPPER(P.PartyNumber)
	INNER JOIN PartyContacts PC ON UPPER(PC.UniqueIdentifier) = UPPER(A.PersonContactedUniqueIdentifier) AND P.Id = PC.PartyId
	WHERE PC.IsActive = 1 AND A.IsMigrated = 0 AND A.IsFailed = 0 AND P.PortfolioId = A.R_PortfolioId AND A.PersonContactedUniqueIdentifier IS NOT NULL

UPDATE A Set R_CustomerId = P.Id
	FROM stgActivity A
    INNER JOIN Parties P ON UPPER(A.CustomerNumber) = UPPER(P.PartyNumber)
	WHERE A.IsMigrated = 0 AND A.IsFailed = 0 AND P.CurrentRole = 'Customer' AND  A.CustomerNumber IS NOT NULL

UPDATE AC Set AC.R_ContractId = C.Id
	FROM stgActivity A
	INNER JOIN stgActivityContractDetail AC ON AC.ActivityId = A.Id
    INNER JOIN Contracts C ON UPPER(C.SequenceNumber) = UPPER(AC.ContractSequenceNumber) AND C.ContractType IN ('Lease', 'Loan')
	LEFT JOIN LeaseFinances LF ON LF.ContractId = C.Id AND LF.CustomerId = R_CustomerId AND LF.IsCurrent = 1 AND LF.BookingStatus <> 'Terminated'
	AND LF.ApprovalStatus <> 'Inactive' AND (C.Status = 'Commenced' OR (LF.BookingStatus = 'FullyPaidOff' AND A.ActivityType  IN ('AgencyPlacement','LegalPlacement')))
	LEFT JOIN LoanFinances LOF ON LOF.ContractId = C.Id AND LOF.CustomerId = R_CustomerId AND LOF.IsCurrent = 1 AND LOF.Status <> 'Terminated'
	AND LOF.ApprovalStatus <> 'Rejected' AND (C.Status = 'Commenced' OR (LOF.Status = 'FullyPaidOff' AND A.ActivityType  IN ('AgencyPlacement','LegalPlacement')))
	WHERE (LF.Id IS NOT NULL OR LOF.Id IS NOT NULL) AND   AC.ContractSequenceNumber IS NOT NULL  AND C.IsAssignToRecovery = 1 

--Legal Relief
UPDATE LR Set R_TrusteeAppointedUniqueIdentifierId = PC.Id
 FROM stgActivity A
 INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
 INNER JOIN Parties P ON  UPPER(A.CustomerNumber) = UPPER(P.PartyNumber) AND P.PortfolioId = A.R_PortfolioId
 INNER JOIN PartyContacts PC ON UPPER(LR.TrusteeAppointedUniqueIdentifier) = UPPER(PC.UniqueIdentifier) AND PC.IsActive = 1
 INNER JOIN PartyContactTypes PCT ON PC.Id = PCT.PartyContactId 
 WHERE PC.IsActive = 1 AND A.IsMigrated = 0  AND PCT.ContactType = 'DebtorAttorney'

--Placement
UPDATE LP Set R_CollectionAgencyOrAttorneyNumberId =CASE WHEN (LP.PlacementType = 'Agency'AND V.Type = 'CollectionAgency') OR
                                                                    (LP.PlacementType = 'Legal'AND V.Type = 'Attorney')
												                    THEN P.Id
																	ELSE NULL
																	END
FROM stgAgencyLegalPlacement LP
INNER JOIN Parties P ON LP.CollectionAgencyNumberOrAttorneyNumber = P.PartyNumber
INNER JOIN Vendors V ON P.Id = V.Id AND V.Status = 'Active'

UPDATE LRPC Set R_ContractId = AC.R_ContractId
	FROM stgActivity A
	INNER JOIN stgActivityContractDetail AC ON A.Id = AC.ActivityId
	INNER JOIN stgLegalReliefPOCContract LRPC ON UPPER(AC.ContractSequenceNumber) = UPPER(LRPC.ContractSequenceNumber) 
	WHERE A.IsMigrated = 0 


--Activity
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Id,@ModuleIterationStatusId, (REPLACE('The Placement cannot be migrated as there are more than one active Placement records for the following Customer {@CustomerNumber}','@CustomerNumber', CustomerNumber))
FROM stgActivity WHERE IsMigrated = 0 AND ActivityType IN ('AgencyPlacement','LegalPlacement') AND CustomerNumber IN (SELECT DISTINCT CustomerNumber 
FROM stgActivity Activity
LEFT JOIN Activities  A on Activity.R_CustomerId = A.EntityId AND IsActive = 1 AND Activity.R_ActivityTypeId = A.ActivityTypeId
WHERE (Ismigrated = 0 OR (Ismigrated = 1 AND A.Id IS NOT NULL)) AND ActivityType IN ('AgencyPlacement','LegalPlacement')
GROUP BY CustomerNumber
Having Count(CustomerNumber) > 1)

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Id,@ModuleIterationStatusId,(REPLACE('The Legal Relief cannot be migrated as there are more than one active Legal Relief records for the following Customer {@CustomerNumber}','@CustomerNumber', CustomerNumber))
FROM stgActivity WHERE IsMigrated = 0 AND ActivityType IN ('Bankruptcy','Receivership') AND CustomerNumber IN (SELECT DISTINCT CustomerNumber
FROM stgActivity Activity
LEFT JOIN Activities A on Activity.R_CustomerId = A.EntityId AND IsActive = 1 AND Activity.R_ActivityTypeId = A.ActivityTypeId
WHERE (Ismigrated = 0 OR (Ismigrated = 1 AND A.Id IS NOT NULL)) AND ActivityType IN ('Bankruptcy','Receivership')
GROUP BY CustomerNumber
Having Count(CustomerNumber) > 1)

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Id,@ModuleIterationStatusId,'Invalid Customer Number'
FROM stgActivity Activity
where IsMigrated = 0 AND R_CustomerId IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Contract is invalid or Not Assigned to Recovery.Please provide valid Contract Sequence Number.'
FROM stgActivity Activity
INNER JOIN stgActivityContractDetail ActivityContractDetail ON Activity.Id = ActivityContractDetail.ActivityId
where IsMigrated = 0 AND R_ContractId IS NULL

INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Activity.Id,@ModuleIterationStatusId,'Invalid Person Contacted Unique Identifier'
FROM stgActivity Activity
LEFT JOIN PartyContacts PC ON UPPER(PC.UniqueIdentifier) = UPPER(Activity.PersonContactedUniqueIdentifier)
where IsMigrated = 0 AND Activity.IsCustomerContacted = 1 AND Activity.PersonContactedUniqueIdentifier IS NOT NULL AND PC.Id IS  NULL

--Legal Relief
INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Invalid Trustee Appointed Unique Identifier'
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
WHERE IsMigrated = 0 AND TrusteeAppointedUniqueIdentifier IS NOT NULL AND R_TrusteeAppointedUniqueIdentifierId IS NULL

INSERT  INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT LR.Id,@ModuleIterationStatusId,(REPLACE('The Contracts in Intentions grid should be in consistent with the Contracts in the Proof of Claim(s): {@ClaimNumber}', '@ClaimNumber', ClaimNumber))
FROM stgActivity A
INNER JOIN stgLegalRelief LR ON A.Id = LR.Id
INNER JOIN stgLegalReliefProofOfClaim POC ON LR.Id = POC.LegalReliefId
INNER JOIN stgLegalReliefPOCContract PC ON  POC.Id = PC.LegalReliefProofOfClaimId
LEFT JOIN stgActivityContractDetail  C ON LR.Id = C.ActivityId AND UPPER(PC.ContractSequenceNumber) = UPPER(C.ContractSequenceNumber)
WHERE IsMigrated = 0 AND PC.Id IS NOT NULL AND C.Id IS NULL

--Placement
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT A.Id,@ModuleIterationStatusId,'Incorrect Collection Agency/Attorney Number'
FROM stgActivity A
INNER JOIN stgAgencyLegalPlacement AP ON A.Id = AP.Id
WHERE IsMigrated = 0 AND CollectionAgencyNumberOrAttorneyNumber IS NOT NULL AND R_CollectionAgencyOrAttorneyNumberId IS NULL AND AP.Status IN ('FirstPlacement','SecondPlacement','ThirdPlacement')
END

UPDATE stgActivity
	Set [IsFailed] = 1
From stgActivity Activity
Join @ErrorLogs [Errors]
	On [Errors].StagingRootEntityId = Activity.[Id]

SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM @ErrorLogs
);
IF(@MigrateActivity = 0)
BEGIN
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgActivity
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM @ErrorLogs
)
) AS ProcessedActivity
ON(ProcessingLog.StagingRootEntityId = ProcessedActivity.Id
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ProcessedActivity.Id
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT 'Successful'
, 'Information'
, @UserId
, @CreatedTime
, Id
FROM #CreatedProcessingLogs;
END

MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT DISTINCT
StagingRootEntityId
FROM @ErrorLogs
) AS ErrorActivities
ON(ProcessingLog.StagingRootEntityId = ErrorActivities.StagingRootEntityId
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
, UpdatedById = @UserId
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ErrorActivities.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorActivities.StagingRootEntityId
INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT Message
, 'Error'
, @UserId
, @CreatedTime
, #FailedProcessingLogs.Id
FROM @ErrorLogs E
JOIN #FailedProcessingLogs ON StagingRootEntityId = #FailedProcessingLogs.ActivityId;
SELECT @FailedRecords;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO
