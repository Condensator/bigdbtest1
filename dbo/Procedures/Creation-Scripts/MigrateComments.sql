SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateComments]
(
@UserId BIGINT ,
@ModuleIterationStatusId BIGINT ,
@CreatedTime DATETIMEOFFSET = NULL,
@ProcessedRecords BIGINT OUT,
@FailedRecords BIGINT OUT
)
AS
BEGIN
SET NOCOUNT ON
SET XACT_ABORT ON
--DECLARE @CreatedTime DATETIMEOFFSET = NULL;
--DECLARE @ProcessedRecords BIGINT = 0;
--DECLARE @FailedRecords BIGINT =0;
--DECLARE @UserId BIGINT= 1;
--DECLARE @ModuleIterationStatusId BIGINT;
--SELECT @ModuleIterationStatusId=MAX(ModuleIterationStatusId) from stgProcessingLog;
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
SET @FailedRecords = 0
SET @ProcessedRecords = 0
DECLARE @TakeCount INT = 50000
DECLARE @SkipCount INT = 0
DECLARE @MaxCommentId INT = 0
DECLARE @BatchCount INT = 0
DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgComment WHERE IsMigrated = 0)
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , NULL
CREATE TABLE #ErrorLogs
(
Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
StagingRootEntityId BIGINT,
Result NVARCHAR(10),  Message NVARCHAR(MAX)
)
CREATE TABLE #FailedProcessingLogs
(
MergeAction NVARCHAR(20),
InsertedId BIGINT,
ErrorId BIGINT
)
UPDATE stgComment SET R_AuthorId = Users.Id
FROM stgComment Comment
INNER JOIN Users ON Comment.AuthorLoginName = USERS.LoginName
WHERE R_AuthorId IS NULL AND IsMigrated=0
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid Author Login Name {'+ISNULL(AuthorLoginName,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment C
WHERE C.IsMigrated = 0 AND R_AuthorId Is NULL AND AuthorLoginName IS NOT NULL
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Please Enter Comment Type Name {'+ISNULL(CommentTypeName,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment C
WHERE C.IsMigrated = 0 AND CommentTypeName IS NULL
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Please Enter Title {'+ISNULL(Title,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment C
WHERE C.IsMigrated = 0 AND Title IS NULL
UPDATE stgComment SET R_CommentTypeId = type.Id
FROM stgComment Comment
INNER JOIN CommentTypes type ON Comment.CommentTypeName = type.Name
WHERE type.IsActive = 1 AND R_CommentTypeId IS NULL AND IsMigrated=0
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid Comment Type Name {'+ISNULL(CommentTypeName,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment C
WHERE C.IsMigrated = 0 AND R_CommentTypeId Is NULL AND CommentTypeName IS NOT NULL
UPDATE stgCommentUser SET R_UserLoginId = U.Id
FROM stgCommentUser CU
INNER JOIN stgComment C ON C.Id = CU.CommentId
INNER JOIN Users U ON U.LoginName = CU.UserLoginName
WHERE R_UserLoginId IS NULL AND IsMigrated=0 AND CU.UserLoginName IS NOT NULL
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid User Login Name {'+ISNULL(UserLoginName,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment C
INNER JOIN stgCommentUser CU ON C.Id = CU.CommentId
WHERE C.IsMigrated = 0 AND R_UserLoginId IS NULL AND UserLoginName IS NOT NULL
UPDATE stgComment SET R_FollowUpById = Users.Id
FROM stgComment Comment
INNER JOIN Users ON Comment.FollowUpByLoginName = Users.LoginName
WHERE R_FollowUpById IS NULL AND IsMigrated=0 AND Comment.FollowUpByLoginName IS NOT NULL AND ConversationMode='Open'
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid Follow Up By Login Name {'+ISNULL(FollowUpByLoginName,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment C
WHERE C.IsMigrated = 0 AND R_FollowUpById Is NULL AND FollowUpByLoginName IS NOT NULL AND ConversationMode='Open'
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Follow Up By Login Name should not be present when ConversationMode is None {'+ISNULL(FollowUpByLoginName,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment C
WHERE C.IsMigrated = 0 AND R_FollowUpById Is NULL AND FollowUpByLoginName IS NOT NULL AND ConversationMode='None'
UPDATE stgCommentResponse SET R_UserId = Users.Id
FROM stgCommentResponse CommentResponse
INNER JOIN Users ON CommentResponse.UserLoginName = Users.LoginName
INNER JOIN stgComment Comment ON Comment.Id = CommentResponse.CommentId
WHERE CommentResponse.R_UserId IS NULL AND IsMigrated=0
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid User Login Name {'+ISNULL(CommentResponse.UserLoginName,'NULL')+'} with Comment Response Id {'+CONVERT(NVARCHAR(MAX),CommentResponse.Id)+'}')
FROM stgCommentResponse CommentResponse
INNER JOIN stgComment C ON C.Id = CommentResponse.CommentId
WHERE C.IsMigrated = 0 AND CommentResponse.R_UserId IS NULL
UPDATE stgComment SET R_CommentEntityTagId = detail.CommentEntityConfigId
FROM stgComment C
INNER JOIN (
SELECT UserFriendlyName AS Name,CommentEntityConfigs.Id AS CommentEntityConfigId,EntityResources.Value as Value FROM CommentEntityConfigs
INNER JOIN EntityConfigs ON CommentEntityConfigs.Id = EntityConfigs.Id
LEFT JOIN EntityResources ON EntityConfigs.Id = EntityResources.EntityId AND EntityResources.EntityType='EntityConfig' AND EntityResources.Name='UserFriendlyName'
) AS detail ON ((detail.Name = C.EntityTypeName AND detail.Value IS NULL) OR detail.Value = C.EntityTypeName)
WHERE C.IsMigrated = 0 AND C.EntityTypeName IS NOT NULL AND R_CommentEntityTagId IS NULL
UPDATE stgCommentTag SET R_CommentEntityTagId = CommentTagValuesConfigs.Id ,R_IsEntityTag = 0
FROM stgCommentTag
INNER JOIN stgComment Comment ON Comment.Id =  stgCommentTag.CommentId
INNER JOIN CommentTagConfigs ON stgCommentTag.CommentTagConfigName = CommentTagConfigs.Name AND CommentTagConfigs.IsActive = 1
INNER JOIN CommentTagValuesConfigs ON CommentTagConfigs.Id = CommentTagValuesConfigs.CommentTagConfigId AND CommentTagValuesConfigs.Value = stgCommentTag.Value
WHERE Comment.IsMigrated = 0 AND stgCommentTag.CommentTagConfigName IS NOT NULL AND stgCommentTag.R_CommentEntityTagId IS NULL
UPDATE stgCommentTag SET R_CommentEntityTagId = detail.CommentEntityConfigId,R_IsEntityTag = 1
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id
INNER JOIN (
SELECT UserFriendlyName AS Name,CommentEntityConfigs.Id AS CommentEntityConfigId,EntityResources.Value as Value FROM CommentEntityConfigs
INNER JOIN EntityConfigs ON CommentEntityConfigs.Id = EntityConfigs.Id
LEFT JOIN EntityResources ON EntityConfigs.Id = EntityResources.EntityId AND EntityResources.EntityType='EntityConfig' AND EntityResources.Name='UserFriendlyName'
) AS detail ON ((detail.Name = CT.CommentTagConfigName AND detail.Value IS NULL) OR detail.Value = CT.CommentTagConfigName)
WHERE C.IsMigrated = 0 AND CT.CommentTagConfigName IS NOT NULL AND CT.R_CommentEntityTagId IS NULL
UPDATE stgCommentTag SET R_IsEntityTag = 0 WHERE R_IsEntityTag IS NULL;
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Tag Value does not match {'+ISNULL(tag.CommentTagConfigName,'NULL')+'} for Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment C
INNER JOIN stgCommentTag tag on C.Id = tag.CommentId
INNER JOIN CommentTagValuesConfigs config on tag.R_CommentEntityTagId = config.Id
WHERE C.IsMigrated = 0 AND tag.R_IsEntityTag = 0 AND config.Value ! = tag.Value
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid Tag Name {'+ISNULL(C.EntityTypeName,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment  C
WHERE C.IsMigrated = 0 AND C.R_CommentEntityTagId IS NULL AND C.EntityTypeName IS NOT NULL
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid Tag Name {'+ISNULL(CommentTag.CommentTagConfigName,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment  C
INNER JOIN stgCommentTag CommentTag ON C.Id = CommentTag.CommentId
WHERE C.IsMigrated = 0 AND CommentTag.R_CommentEntityTagId IS NULL AND CommentTagConfigName IS NOT NULL
UPDATE stgComment SET R_EntityId = Customers.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = Parties.PortfolioId
FROM stgComment C
INNER JOIN Parties ON C.EntityTypeValue = Parties.PartyNumber
INNER JOIN Customers ON Customers.Id = Parties.Id
WHERE C.IsMigrated = 0 AND C.EntityTypeName='Customer'
UPDATE stgComment SET R_EntityId = Funders.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = Parties.PortfolioId
FROM stgComment C
INNER JOIN Parties ON C.EntityTypeValue = Parties.PartyNumber
INNER JOIN Funders ON Funders.Id = Parties.Id
WHERE C.IsMigrated = 0 AND C.EntityTypeName='Funder'
UPDATE stgComment SET R_EntityId = Vendors.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = Parties.PortfolioId
FROM stgComment C
INNER JOIN Parties ON C.EntityTypeValue = Parties.PartyNumber
INNER JOIN Vendors ON Vendors.Id = Parties.Id
WHERE C.IsMigrated = 0 AND C.EntityTypeName='Vendor'
UPDATE stgComment SET R_EntityId = LoanFinances.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = LoanFinances.LegalEntityId
FROM stgComment C
INNER JOIN Contracts ON C.EntityTypeValue = Contracts.SequenceNumber
INNER JOIN LoanFinances ON LoanFinances.ContractId = Contracts.Id AND LoanFinances.IsCurrent = 1
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Loan Finance')
UPDATE stgComment SET R_EntityId = LeaseFinances.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = LeaseFinances.LegalEntityId
FROM stgComment C
INNER JOIN Contracts ON C.EntityTypeValue = Contracts.SequenceNumber
INNER JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Lease Finance')
UPDATE stgComment SET R_EntityId = CreditApplications.Id, R_AccessScopeName = 'BusinessUnit', R_AccessScopeId = Opportunities.BusinessUnitId
FROM stgComment C
INNER JOIN Opportunities ON C.EntityTypeValue = Opportunities.Number
INNER JOIN CreditApplications ON CreditApplications.Id = Opportunities.Id
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Credit Application')
UPDATE stgComment SET R_EntityId = CreditProfiles.Id, R_AccessScopeName = 'BusinessUnit', R_AccessScopeId = CreditProfiles.BusinessUnitId
FROM stgComment C
INNER JOIN CreditProfiles ON C.EntityTypeValue = CreditProfiles.Number
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Credit Profile')
UPDATE stgComment SET R_EntityId = AppraisalRequests.Id, R_AccessScopeName = 'BusinessUnit', R_AccessScopeId = AppraisalRequests.BusinessUnitId
FROM stgComment C
INNER JOIN AppraisalRequests ON C.EntityTypeValue = AppraisalRequests.AppraisalNumber
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Appraisal Request')
UPDATE stgComment SET R_EntityId = LoanAmendments.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = LoanFinances.LegalEntityId
FROM stgComment C
INNER JOIN Contracts ON C.EntityTypeValue = Contracts.SequenceNumber
INNER JOIN LoanFinances ON LoanFinances.ContractId = Contracts.Id AND LoanFinances.IsCurrent = 1
INNER JOIN LoanAmendments ON LoanAmendments.LoanFinanceId = LoanFinances.Id
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Loan Amendment')
UPDATE stgComment SET R_EntityId = LeaseAmendments.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = LeaseFinances.LegalEntityId
FROM stgComment C
INNER JOIN Contracts ON C.EntityTypeValue = Contracts.SequenceNumber
INNER JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
INNER JOIN LeaseAmendments ON LeaseAmendments.CurrentLeaseFinanceId = LeaseFinances.Id
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Lease Amendment')
UPDATE stgComment SET R_EntityId = CollectionWorkLists.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = CollectionWorkLists.PortfolioId
FROM stgComment C
INNER JOIN CollectionWorkLists ON C.EntityTypeValue = CollectionWorkLists.Id
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Collection Worklist')

UPDATE stgComment SET R_EntityId = CollectionWorkListContractDetails.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = CollectionWorkLists.PortfolioId
FROM stgComment C
INNER JOIN Contracts ON C.EntityTypeValue = Contracts.SequenceNumber
INNER JOIN CollectionWorkListContractDetails ON CollectionWorkListContractDetails.ContractId = Contracts.Id
INNER JOIN CollectionWorkLists ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Collection Worklist Contract')

UPDATE stgComment SET R_EntityId = Assets.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = Assets.LegalEntityId
FROM stgComment C
INNER JOIN Assets ON C.EntityTypeValue = Assets.Alias
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Asset')
UPDATE stgComment SET R_EntityId = CollateralTrackings.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = Assets.LegalEntityId
FROM stgComment C
INNER JOIN CollateralTrackings ON C.EntityTypeValue = CollateralTrackings.Id
INNER JOIN Assets ON CollateralTrackings.AssetId = Assets.Id
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='CollateralTracking')
UPDATE stgComment SET R_EntityId = ActivityForCollectionWorkLists.Id
FROM stgComment C
INNER JOIN ActivityForCollectionWorkLists ON C.EntityTypeValue = ActivityForCollectionWorkLists.Id
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Activity For CollectionWorkList')
UPDATE stgComment SET R_EntityId = Contracts.Id, R_AccessScopeName = 'LegalEntity',R_AccessScopeId = CASE WHEN ContractType ='Lease' THEN LeaseFinances.LegalEntityId
WHEN ContractType ='LeveragedLease' THEN LeveragedLeases.LegalEntityId
WHEN ContractType ='Loan' OR ContractType ='ProgressLoan' THEN LoanFinances.LegalEntityId END
FROM stgComment C
INNER JOIN Contracts ON C.EntityTypeValue = Contracts.SequenceNumber
LEFT JOIN LeaseFinances ON  Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
LEFT JOIN LeveragedLeases ON  Contracts.Id = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent = 1
LEFT JOIN LoanFinances ON  Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Contract')
UPDATE stgComment SET R_EntityId = Activities.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = Activities.PortfolioId
FROM stgComment C
INNER JOIN Activities ON C.EntityTypeValue = Activities.EntityNaturalId
WHERE C.IsMigrated = 0 AND (C.EntityTypeName='Activity')
UPDATE stgCommentTag SET R_EntityId = Customers.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = Parties.PortfolioId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Parties ON CT.Value = Parties.PartyNumber
INNER JOIN Customers ON Customers.Id = Parties.Id
WHERE C.IsMigrated = 0 AND CT.CommentTagConfigName='Customer'
UPDATE stgCommentTag SET R_EntityId = Funders.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = Parties.PortfolioId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Parties ON CT.Value= Parties.PartyNumber
INNER JOIN Funders ON Funders.Id = Parties.Id
WHERE C.IsMigrated = 0 AND CT.CommentTagConfigName='Funder'
UPDATE stgCommentTag SET R_EntityId = Vendors.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = Parties.PortfolioId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Parties ON CT.Value = Parties.PartyNumber
INNER JOIN Vendors ON Vendors.Id = Parties.Id
WHERE C.IsMigrated = 0 AND CT.CommentTagConfigName='Vendor'
UPDATE stgCommentTag SET R_EntityId = LoanFinances.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = LoanFinances.LegalEntityId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Contracts ON CT.Value= Contracts.SequenceNumber
INNER JOIN LoanFinances ON LoanFinances.ContractId = Contracts.Id
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Loan Finance')
UPDATE stgCommentTag SET R_EntityId = LeaseFinances.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = LeaseFinances.LegalEntityId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Contracts ON CT.Value= Contracts.SequenceNumber
INNER JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Lease Finance')
UPDATE stgCommentTag SET R_EntityId = CreditApplications.Id, R_AccessScopeName = 'BusinessUnit', R_AccessScopeId = Opportunities.BusinessUnitId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Opportunities ON Ct.Value= Opportunities.Number
INNER JOIN CreditApplications ON CreditApplications.Id = Opportunities.Id
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Credit Application')
UPDATE stgCommentTag SET R_EntityId = CreditProfiles.Id, R_AccessScopeName = 'BusinessUnit', R_AccessScopeId = CreditProfiles.BusinessUnitId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN CreditProfiles ON CT.Value= CreditProfiles.Number
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Credit Profile')
UPDATE stgCommentTag SET R_EntityId = AppraisalRequests.Id, R_AccessScopeName = 'BusinessUnit', R_AccessScopeId = AppraisalRequests.BusinessUnitId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN AppraisalRequests ON CT.Value= AppraisalRequests.AppraisalNumber
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Appraisal Request')
UPDATE stgCommentTag SET R_EntityId = LoanAmendments.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = LoanFinances.LegalEntityId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Contracts ON CT.Value= Contracts.SequenceNumber
INNER JOIN LoanFinances ON LoanFinances.ContractId = Contracts.Id
INNER JOIN LoanAmendments ON LoanAmendments.LoanFinanceId = LoanFinances.Id
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Loan Amendment')
UPDATE stgCommentTag SET R_EntityId = LeaseAmendments.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = LeaseFinances.LegalEntityId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Contracts ON CT.Value= Contracts.SequenceNumber
INNER JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id
INNER JOIN LeaseAmendments ON LeaseAmendments.CurrentLeaseFinanceId = LeaseFinances.Id
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Lease Amendment')
UPDATE stgCommentTag SET R_EntityId = CollectionWorkLists.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = CollectionWorkLists.PortfolioId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN CollectionWorkLists ON CT.Value= CollectionWorkLists.Id
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Collection Worklist')

UPDATE stgCommentTag SET R_EntityId = CollectionWorkListContractDetails.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = CollectionWorkLists.PortfolioId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Contracts ON CT.Value = Contracts.SequenceNumber
INNER JOIN CollectionWorkListContractDetails ON CollectionWorkListContractDetails.ContractId = Contracts.Id
INNER JOIN CollectionWorkLists ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Collection Worklist Contract')

UPDATE stgCommentTag SET R_EntityId = Assets.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = Assets.LegalEntityId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Assets ON CT.Value= Assets.Alias
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Asset')
UPDATE stgCommentTag SET R_EntityId = CollateralTrackings.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = Assets.LegalEntityId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN CollateralTrackings ON CT.Value= CollateralTrackings.Id
INNER JOIN Assets ON CollateralTrackings.AssetId = Assets.Id
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='CollateralTracking')
UPDATE stgCommentTag SET R_EntityId = ActivityForCollectionWorkLists.Id
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN ActivityForCollectionWorkLists ON CT.Value= ActivityForCollectionWorkLists.Id
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Activity For CollectionWorkList')
UPDATE stgCommentTag SET R_EntityId = Contracts.Id, R_AccessScopeName = 'LegalEntity', R_AccessScopeId = CASE WHEN ContractType ='Lease' THEN LeaseFinances.LegalEntityId
WHEN ContractType ='LeveragedLease' THEN LeveragedLeases.LegalEntityId
WHEN ContractType ='Loan' OR ContractType ='ProgressLoan' THEN LoanFinances.LegalEntityId END
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Contracts ON CT.Value= Contracts.SequenceNumber
LEFT JOIN LeaseFinances ON  Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
LEFT JOIN LeveragedLeases ON  Contracts.Id = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent = 1
LEFT JOIN LoanFinances ON  Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Contract')
UPDATE stgCommentTag SET R_EntityId = Activities.Id, R_AccessScopeName = 'Portfolio', R_AccessScopeId = Activities.PortfolioId
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id AND CT.R_IsEntityTag = 1
INNER JOIN Activities ON CT.Value= Activities.EntityNaturalId
WHERE C.IsMigrated = 0 AND (CT.CommentTagConfigName='Activity')
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid Entity Type Value {'+ISNULL(C.EntityTypeValue,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment  C
WHERE C.IsMigrated = 0 AND C.R_EntityId IS NULL AND C.R_CommentEntityTagId IS NOT NULL
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid Entity Type Value {'+ISNULL(C.EntityTypeValue,'NULL')+'} For Comment Tag Id { ' + CONVERT(NVARCHAR(MAX),CT.Id) +' } with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment  C
INNER JOIN stgCommentTag CT ON C.Id = CT.CommentId
WHERE C.IsMigrated = 0 AND CT.R_EntityId IS NULL AND CT.R_CommentEntityTagId IS NOT NULL AND R_IsEntityTag = 1
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('At least one Comment Sub-Type must be added for Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment  C
INNER JOIN CommentTypes CT ON C.R_CommentTypeId= CT.Id
LEFT JOIN stgCommentTypeSubType SubType ON SubType.CommentId = C.Id
WHERE C.IsMigrated = 0 AND CT.IsSubTypeRequired = 1 AND SubType.Id IS NULL
UPDATE stgCommentTypeSubType SET R_SubTypeId = CommentSubTypes.Id
FROM stgCommentTypeSubType SubType
INNER JOIN stgComment C ON C.Id = SubType.CommentId
INNER JOIN CommentTypes type ON C.R_CommentTypeId = type.Id
INNER JOIN CommentTypeSubTypes CommentSubTypes ON CommentSubTypes.Name = SubType.Name AND type.Id = CommentTypeId
WHERE R_SubTypeId IS NULL AND IsMigrated=0 AND CommentSubTypes.IsActive = 1
INSERT INTO #ErrorLogs
SELECT
C.Id
,'Error'
,('Invalid Sub Type Name {'+ISNULL(SubType.Name,'NULL')+'} with Comment Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgComment C
INNER JOIN CommentTypes type ON C.R_CommentTypeId = type.Id
INNER JOIN stgCommentTypeSubType SubType ON C.Id = SubType.CommentId
WHERE C.IsMigrated = 0 AND SubType.R_SubTypeId IS NULL
SELECT * INTO #ErrorLogDetails FROM #ErrorLogs ORDER BY StagingRootEntityId ;
WHILE @SkipCount < @TotalRecordsCount
BEGIN
BEGIN TRY
BEGIN TRANSACTION
CREATE TABLE #CreatedProcessingLogs
(MergeAction NVARCHAR(20)
,InsertedId BIGINT);
CREATE TABLE #CreatedComments
([Action] NVARCHAR(10) NOT NULL
,[Id] BIGINT NOT NULL
,[CommentId] BIGINT NOT NULL);
CREATE TABLE #CreatedHeaders
([Action] NVARCHAR(10) NOT NULL
,[Id] BIGINT NOT NULL
,[EntityId] BIGINT NULL
,[CommentEntityTagId] BIGINT NULL);
CREATE TABLE #CommentedLists
([R_EntityId] BIGINT NULL
,[CreatedHeaderId] BIGINT NOT NULL
,[CommentId] BIGINT NOT NULL);
SELECT
TOP(@TakeCount) * INTO #CommentSubset
FROM
stgComment Comment
WHERE
Comment.Id > @MaxCommentId AND Comment.IsMigrated = 0
AND
NOT Exists (SELECT * FROM #ErrorLogDetails WHERE StagingRootEntityId = Comment.Id)
ORDER BY
Comment.Id
SELECT @MaxCommentId = MAX(Id) FROM #CommentSubset
SELECT @BatchCount = ISNULL(COUNT(Id),0) FROM #CommentSubset
MERGE Comments AS Comment
USING (SELECT * FROM #CommentSubset) AS CommentsToMigrate
ON (0=1)
WHEN NOT MATCHED THEN
INSERT
([Title]
,[Body]
,[Importance]
,[IsActive]
,[ConversationMode]
,[OriginalCreatedTime]
,[FollowUpDate]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[CommentTypeId]
,[AuthorId]
,[FollowUpById]
,[DefaultPermission]
,[EntityId]
,[EntityTypeId]
,[IsInternal])
VALUES
(CommentsToMigrate.Title
,'<p>' + CommentsToMigrate.Body + '</p>'
,CommentsToMigrate.Importance
,1
,CommentsToMigrate.ConversationMode
,CommentsToMigrate.OriginalCreatedTime
,CommentsToMigrate.FollowUpDate
,@UserId
,@CreatedTime
,NULL
,NULL
,CommentsToMigrate.R_CommentTypeId
,CommentsToMigrate.R_AuthorId
,CommentsToMigrate.R_FollowUpById
,CommentsToMigrate.DefaultPermission
,NULL
,NULL
,CommentsToMigrate.IsInternal)
OUTPUT $action, Inserted.Id, CommentsToMigrate.Id INTO #CreatedComments;
INSERT INTO CommentSubTypes
([IsActive]
,[CommentId]
,[CommentTypeSubTypeId]
,[CreatedById]
,[CreatedTime])
SELECT
1 AS IsActive
,#CreatedComments.Id
,R_SubTypeId
,@UserId
,@CreatedTime
FROM #CreatedComments
INNER JOIN #CommentSubset ON  #CommentSubset.Id= #CreatedComments.CommentId
INNER JOIN stgCommentTypeSubType SubType ON SubType.CommentId = #CommentSubset.Id
WHERE SubType.R_SubTypeId IS NOT NULL
--Add User (Create)
INSERT INTO CommentPermissions
([Permission]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[UserId]
,[CommentId]
,[IsAddedManually]
,[CommentTypePermissionId])
SELECT
'F'
,1
,@UserId
,@CreatedTime
,NULL
,NULL
,CU.R_UserLoginId
,#CreatedComments.Id
,1
,NULL
FROM #CreatedComments
INNER JOIN #CommentSubset ON  #CommentSubset.Id= #CreatedComments.CommentId
INNER JOIN stgCommentUser CU ON CU.CommentId = #CommentSubset.Id
LEFT JOIN CommentPermissions permission ON permission.CommentId = #CommentSubset.Id AND Permission.UserId = CU.R_UserLoginId
WHERE permission.Id IS NULL AND R_UserLoginId IS NOT NULL
--Add User (Update)

INSERT INTO [dbo].[CommentUserPreferences]
([IsFollowing]
,[IsRead]
,[Hidden]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[UserId]
,[CommentId]
,[LastReadCommentResponseId])
SELECT
1
,0
,0
,@UserId
,@CreatedTime
,NULL
,NULL
,CommentUser.R_UserLoginId
,#CreatedComments.Id
,NULL
FROM #CreatedComments
INNER JOIN stgCommentUser CommentUser ON CommentUser.CommentId = #CreatedComments.CommentId
LEFT JOIN CommentUserPreferences Preferences ON Preferences.UserId = CommentUser.R_UserLoginId AND Preferences.CommentId = CommentUser.CommentId
WHERE Preferences.Id IS NULL AND R_UserLoginId IS NOT NULL

--Comment Permission For Follow Up User
INSERT INTO CommentPermissions
([Permission]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[UserId]
,[CommentId]
,[IsAddedManually]
,[CommentTypePermissionId])
SELECT
'F'
,1
,@UserId
,@CreatedTime
,NULL
,NULL
,#CommentSubset.R_FollowUpById
,#CreatedComments.Id
,0
,NULL
FROM #CreatedComments
INNER JOIN #CommentSubset ON  #CommentSubset.Id= #CreatedComments.CommentId
WHERE #CommentSubset.R_FollowUpById IS NOT NULL
INSERT INTO [dbo].[CommentUserPreferences]
([IsFollowing]
,[IsRead]
,[Hidden]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[UserId]
,[CommentId]
,[LastReadCommentResponseId])
SELECT
1
,0
,0
,@UserId
,@CreatedTime
,NULL
,NULL
,R_FollowUpById
,#CreatedComments.Id
,NULL
FROM #CommentSubset
INNER JOIN #CreatedComments ON #CreatedComments.CommentId = #CommentSubset.Id
LEFT JOIN CommentUserPreferences Preferences ON Preferences.UserId = #CommentSubset.R_FollowUpById AND Preferences.CommentId = #CreatedComments.Id
WHERE Preferences.Id IS NULL AND R_FollowUpById IS NOT NULL

--Comment User Preference For Author (Create)
INSERT INTO [dbo].[CommentUserPreferences]
([IsFollowing]
,[IsRead]
,[Hidden]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[UserId]
,[CommentId]
,[LastReadCommentResponseId])
SELECT
1
,1
,0
,@UserId
,@CreatedTime
,NULL
,NULL
,#CommentSubset.R_AuthorId
,#CreatedComments.Id
,0
FROM #CommentSubset
INNER JOIN #CreatedComments ON #CreatedComments.CommentId = #CommentSubset.Id
LEFT JOIN CommentUserPreferences Preferences ON Preferences.UserId = #CommentSubset.R_AuthorId AND Preferences.CommentId = #CreatedComments.Id
WHERE Preferences.Id IS NULL
--Comment User Preference For Author (Update)

--Comment Permission For Comment Type Users
INSERT INTO CommentPermissions
([Permission]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[UserId]
,[CommentId]
,[IsAddedManually]
,[CommentTypePermissionId])
SELECT
TypePermission.Permission
,1
,@UserId
,@CreatedTime
,NULL
,NULL
,UserSelectionParams.UserId
,#CreatedComments.Id
,0
,TypePermission.Id
FROM #CreatedComments
INNER JOIN #CommentSubset ON  #CommentSubset.Id= #CreatedComments.CommentId
INNER JOIN CommentTypePermissions TypePermission ON #CommentSubset.R_CommentTypeId = TypePermission.CommentTypeId AND TypePermission.IsActive = 1
INNER JOIN UserSelectionParams ON TypePermission.UserSelectionId = UserSelectionParams.Id
WHERE UserSelectionParams.UserId IS NOT NULL
MERGE CommentPermissions AS CommentPermissions
USING (SELECT DISTINCT Users.Id AS UserId,#CreatedComments.Id AS CommentId,TypePermission.Id AS CommentTypePermissionId,TypePermission.Permission AS Permission  FROM #CreatedComments
INNER JOIN #CommentSubset ON #CommentSubset.Id= #CreatedComments.CommentId
INNER JOIN CommentTypePermissions TypePermission ON #CommentSubset.R_CommentTypeId = TypePermission.CommentTypeId AND TypePermission.IsActive = 1
INNER JOIN UserSelectionParams ON TypePermission.UserSelectionId = UserSelectionParams.Id
INNER JOIN UserGroups ON UserSelectionParams.UserGroupId = UserGroups.Id
INNER JOIN UsersInUserGroups ON UserGroups.Id =  UsersInUserGroups.UserGroupId
INNER JOIN Users ON UsersInUserGroups.UserId = Users.Id
WHERE UsersInUserGroups.IsActive = 1 AND Users.ApprovalStatus= 'Approved'
UNION
SELECT DISTINCT Users.Id AS UserId,#CreatedComments.Id AS CommentId,TypePermission.Id AS CommentTypePermissionId,TypePermission.Permission AS Permission  FROM #CreatedComments
INNER JOIN #CommentSubset ON  #CommentSubset.Id= #CreatedComments.CommentId
INNER JOIN CommentTypePermissions TypePermission ON #CommentSubset.R_CommentTypeId = TypePermission.CommentTypeId AND TypePermission.IsActive = 1
INNER JOIN UserSelectionParams ON TypePermission.UserSelectionId = UserSelectionParams.Id
INNER JOIN RolesInUserGroups ON UserSelectionParams.UserGroupId = RolesInUserGroups.UserGroupId
INNER JOIN Roles ON RolesInUserGroups.RoleId = Roles.Id AND Roles.IsActive = 1 AND RolesInUserGroups.IsActive = 1
INNER JOIN RolesForUsers ON Roles.Id = RolesForUsers.RoleId AND RolesForUsers.IsActive = 1
INNER JOIN Users ON RolesForUsers.UserId = Users.Id
WHERE
Users.ApprovalStatus ='Approved') AS CommentsToMigrate
ON (1=0)
WHEN NOT MATCHED THEN
INSERT
([Permission]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[UserId]
,[CommentId]
,[IsAddedManually]
,[CommentTypePermissionId])
VALUES
(Permission
,1
,@UserId
,@CreatedTime
,NULL
,NULL
,UserId
,CommentId
,0
,CommentTypePermissionId);
INSERT INTO [dbo].[CommentResponses]
([Body]
,[IsActive]
,[OriginalCreatedTime]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[UserId]
,[CommentId])
SELECT
CommentResponse.Body
,1
,CommentResponse.OriginalCreatedTime
,@UserId
,@CreatedTime
,NULL
,NULL
,R_UserId
,#CreatedComments.Id
FROM stgCommentResponse CommentResponse
INNER JOIN #CreatedComments ON #CreatedComments.CommentId = CommentResponse.CommentId
INSERT INTO [dbo].[CommentTags]
([IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[CommentId]
,[TagId])
SELECT
1
,@UserId
,@CreatedTime
,NULL
,NULL
,#CreatedComments.Id
,CommentTag.R_CommentEntityTagId
FROM stgCommentTag CommentTag
INNER JOIN #CreatedComments ON CommentTag.CommentId = #CreatedComments.CommentId
WHERE CommentTag.R_IsEntityTag = 0
UPDATE CommentUserPreferences SET IsFollowing = 1, Hidden = 0, IsRead=1, LastReadCommentResponseId = ResponseId
FROM CommentUserPreferences preferences
INNER JOIN (SELECT TOP 1 responses.Id AS ResponseId,CommentUserPreferences.Id AS Id FROM #CreatedComments
INNER JOIN CommentResponses responses ON responses.CommentId = #CreatedComments.Id
INNER JOIN CommentUserPreferences ON CommentUserPreferences.CommentId = #CreatedComments.Id AND CommentUserPreferences.UserId = responses.UserId) AS detail ON detail.Id = preferences.Id
MERGE EntityHeaders AS Header
USING (SELECT DISTINCT C.R_EntityId,C.EntityTypeValue,R_CommentEntityTagId, header.Id AS headerId, C.R_AccessScopeName, C.R_AccessScopeId
FROM stgComment C
INNER JOIN #CreatedComments ON #CreatedComments.CommentId = C.Id
LEFT JOIN EntityHeaders header ON header.EntityId  = R_EntityId AND header.EntityTypeId = C.R_CommentEntityTagId
WHERE C.R_EntityId IS NOT NULL AND C.R_CommentEntityTagId IS NOT NULL AND header.Id IS NULL) AS CommentsToMigrate
ON (CommentsToMigrate.headerId IS NOT NULL)
WHEN NOT MATCHED THEN
INSERT
([EntityId]
,[EntityNaturalId]
,[EntitySummary]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[EntityTypeId]
,[AccessScope]
,[AccessScopeId])
VALUES
(CommentsToMigrate.R_EntityId
,CommentsToMigrate.EntityTypeValue
,NULL
,@UserId
,@CreatedTime
,NULL
,NULL
,CommentsToMigrate.R_CommentEntityTagId
,CommentsToMigrate.R_AccessScopeName
,CommentsToMigrate.R_AccessScopeId)
OUTPUT $action, Inserted.Id, CommentsToMigrate.R_EntityId,CommentsToMigrate.R_CommentEntityTagId INTO #CreatedHeaders;
INSERT INTO #CreatedHeaders
SELECT DISTINCT 'Present',header.Id,C.R_EntityId,C.R_CommentEntityTagId
FROM stgComment C
INNER JOIN #CreatedComments ON #CreatedComments.CommentId = C.Id
LEFT JOIN EntityHeaders header ON  header.EntityId  = R_EntityId AND header.EntityTypeId = C.R_CommentEntityTagId
LEFT JOIN #CreatedHeaders ON #CreatedHeaders.Id = header.Id
WHERE header.Id IS NOT NULL AND #CreatedHeaders.Id IS NULL
INSERT INTO [dbo].[CommentHeaders]
([Id]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime])
SELECT
#CreatedHeaders.Id
,@UserId
,@CreatedTime
,NULL
,NULL
FROM #CreatedHeaders
LEFT JOIN CommentHeaders ON #CreatedHeaders.Id = CommentHeaders.Id
WHERE CommentHeaders.Id IS NULL
INSERT INTO #CommentedLists (R_EntityId,CreatedHeaderId,CommentId)
SELECT DISTINCT R_EntityId,#CreatedHeaders.Id,#CreatedComments.Id
FROM #CreatedHeaders
INNER JOIN stgComment Comment ON #CreatedHeaders.EntityId = Comment.R_EntityId AND #CreatedHeaders.CommentEntityTagId = Comment.R_CommentEntityTagId
INNER JOIN #CreatedComments ON Comment.Id = #CreatedComments.CommentId
INSERT INTO [dbo].[CommentLists]
([RelatedAutomatically]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[CommentId]
,[CommentHeaderId]
,[IsRootEntity])
SELECT
0
,1
,@UserId
,@CreatedTime
,NULL
,NULL
,CommentId
,CreatedHeaderId
,0
FROM
#CommentedLists
UPDATE Comments SET EntityId = R_EntityId,EntityTypeId = R_CommentEntityTagId
FROM Comments
INNER JOIN #CreatedComments ON Comments.Id = #CreatedComments.Id
INNER JOIN  stgComment Comment ON Comment.Id = #CreatedComments.CommentId
INNER JOIN #CreatedHeaders ON  #CreatedHeaders.EntityId = Comment.R_EntityId AND #CreatedHeaders.CommentEntityTagId = Comment.R_CommentEntityTagId
DELETE FROM #CreatedHeaders
MERGE EntityHeaders AS Header
USING (SELECT DISTINCT CT.R_EntityId,CT.Value,CT.R_CommentEntityTagId, header.Id AS headerId, CT.R_AccessScopeName, CT.R_AccessScopeId
FROM stgComment C
INNER JOIN #CreatedComments ON #CreatedComments.CommentId = C.Id
INNER JOIN stgCommentTag CT ON CT.CommentId = C.Id
LEFT JOIN EntityHeaders header ON  header.EntityId  = CT.R_EntityId AND header.EntityTypeId = CT.R_CommentEntityTagId
WHERE CT.R_EntityId IS NOT NULL AND CT.R_CommentEntityTagId IS NOT NULL AND CT.R_IsEntityTag = 1) AS CommentsToMigrate
ON (CommentsToMigrate.headerId IS NOT NULL)
WHEN NOT MATCHED THEN
INSERT
([EntityId]
,[EntityNaturalId]
,[EntitySummary]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[EntityTypeId]
,[AccessScope]
,[AccessScopeId])
VALUES
(CommentsToMigrate.R_EntityId
,CommentsToMigrate.Value
,NULL
,@UserId
,@CreatedTime
,NULL
,NULL
,CommentsToMigrate.R_CommentEntityTagId
,CommentsToMigrate.R_AccessScopeName
,CommentsToMigrate.R_AccessScopeId)
OUTPUT $action, Inserted.Id, CommentsToMigrate.R_EntityId,CommentsToMigrate.R_CommentEntityTagId INTO #CreatedHeaders;
INSERT INTO #CreatedHeaders
SELECT DISTINCT 'Present',header.Id,CT.R_EntityId,CT.R_CommentEntityTagId
FROM stgComment C
INNER JOIN #CreatedComments ON #CreatedComments.CommentId = C.Id
INNER JOIN stgCommentTag CT ON C.Id = CT.CommentId
INNER JOIN EntityHeaders header ON  header.EntityId  = CT.R_EntityId AND header.EntityTypeId = CT.R_CommentEntityTagId
LEFT JOIN #CreatedHeaders ON #CreatedHeaders.Id = header.Id
WHERE CT.R_IsEntityTag = 1 AND #CreatedHeaders.Id IS NULL
INSERT INTO [dbo].[CommentHeaders]
([Id]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime])
SELECT
#CreatedHeaders.Id
,@UserId
,@CreatedTime
,NULL
,NULL
FROM #CreatedHeaders
LEFT JOIN CommentHeaders ON #CreatedHeaders.Id = CommentHeaders.Id
WHERE CommentHeaders.Id IS NULL
DELETE FROM #CommentedLists
INSERT INTO #CommentedLists (R_EntityId,CreatedHeaderId,CommentId)
SELECT DISTINCT CommentTag.R_EntityId,#CreatedHeaders.Id,#CreatedComments.Id
FROM #CreatedHeaders
INNER JOIN stgCommentTag CommentTag ON #CreatedHeaders.EntityId = CommentTag.R_EntityId AND #CreatedHeaders.CommentEntityTagId = CommentTag.R_CommentEntityTagId
INNER JOIN stgComment Comment ON Comment.Id = CommentTag.CommentId
INNER JOIN #CreatedComments ON Comment.Id = #CreatedComments.CommentId
INSERT INTO [dbo].[CommentLists]
([RelatedAutomatically]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[CommentId]
,[CommentHeaderId]
,[IsRootEntity])
SELECT
0
,1
,@UserId
,@CreatedTime
,NULL
,NULL
,CommentId
,CreatedHeaderId
,0
FROM
#CommentedLists
INSERT INTO [dbo].[CommentUserPreferences]
([IsFollowing]
,[IsRead]
,[Hidden]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[UserId]
,[CommentId]
,[LastReadCommentResponseId])
SELECT
1
,1
,0
,@UserId
,@CreatedTime
,NULL
,NULL
,responses.UserId
,#CreatedComments.Id
,responses.Id
FROM  #CreatedComments
INNER JOIN CommentResponses responses ON responses.CommentId = #CreatedComments.Id
LEFT JOIN CommentUserPreferences Preferences ON Preferences.CommentId = #CreatedComments.Id AND Preferences.UserId = responses.UserId
WHERE Preferences.Id IS NULL
UPDATE stgComment SET IsMigrated = 1 WHERE Id IN (SELECT CommentId FROM #CreatedComments)
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT CommentId  FROM #CreatedComments) AS Processed
ON (ProcessingLog.StagingRootEntityId = Processed.CommentId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
(StagingRootEntityId
,CreatedById
,CreatedTime
,ModuleIterationStatusId)
VALUES
(Processed.CommentId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId)
OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
,Type
,CreatedById
,CreatedTime
,ProcessingLogId)
SELECT
'Successful'
,'Information'
,@UserId
,@CreatedTime
,InsertedId
FROM #CreatedProcessingLogs
DROP TABLE #CreatedProcessingLogs
DROP TABLE #CreatedComments
DROP TABLE #CreatedHeaders
DROP TABLE #CommentSubset
DROP TABLE #CommentedLists
SET @SkipCount = @SkipCount + @TakeCount;
COMMIT TRANSACTION
END TRY
BEGIN CATCH
SET @SkipCount = @SkipCount  + @TakeCount;
DECLARE @ErrorMessage Nvarchar(max);
DECLARE @ErrorLine Nvarchar(max);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @ErrorLogs ErrorMessageList;
DECLARE @ModuleName Nvarchar(max) = 'MigrateComments'
Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
IF (XACT_STATE()) = -1
BEGIN
ROLLBACK TRANSACTION;
EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
SET @FailedRecords = @FailedRecords+@BatchCount;
END;
IF (XACT_STATE()) = 1
BEGIN
COMMIT TRANSACTION;
RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);
END;
END CATCH
END
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT  DISTINCT StagingRootEntityId FROM #ErrorLogs) AS ErrorComments
ON (ProcessingLog.StagingRootEntityId = ErrorComments.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
(StagingRootEntityId
,CreatedById
,CreatedTime
,ModuleIterationStatusId)
VALUES
(ErrorComments.StagingRootEntityId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId)
OUTPUT $action, Inserted.Id,ErrorComments.StagingRootEntityId INTO #FailedProcessingLogs;
DECLARE @TotalRecordsFailed INT = (SELECT  COUNT( DISTINCT InsertedId) FROM #FailedProcessingLogs)
INSERT INTO stgProcessingLogDetail
(Message
,Type
,CreatedById
,CreatedTime
,ProcessingLogId)
SELECT
#ErrorLogs.Message
,#ErrorLogs.Result
,@UserId
,@CreatedTime
,#FailedProcessingLogs.InsertedId
FROM
#ErrorLogs
INNER JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.ErrorId
set @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogDetails)
SET @ProcessedRecords =  @ProcessedRecords + @TotalRecordsCount
DROP TABLE #ErrorLogs
DROP TABLE #ErrorLogDetails
DROP TABLE #FailedProcessingLogs
SET NOCOUNT OFF
SET XACT_ABORT OFF;
END

GO
