SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CommentHistorySummaryReport]
@FromDate DATE = NULL,
@ToDate DATE = NULL,
@SequenceNumber NVARCHAR(100) = NULL,
@PartyNumber NVARCHAR(100) = NULL,
@AppraisalNumber NVARCHAR(100) = NULL,
@AssetAlias NVARCHAR(100) = NULL,
@EntityType NVARCHAR(100) = NULL,
@AssumptionSequence NVARCHAR(100) = NULL,
@AmendmentId NVARCHAR(100) = NULL,
@LegalEntityNumber NVARCHAR(100) = NULL,
@CreditProfileNumber NVARCHAR(100) = NULL,
@ProposalNumber NVARCHAR(100) = NULL,
@CreditApplicationNumber NVARCHAR(100) = NULL,
@CollectionWorkListNumber NVARCHAR(100) = NULL,
@CollateralTrackingNumber NVARCHAR(100) = NULL,
@LeaseType NVARCHAR(100) = NULL,
@LoanType NVARCHAR(100) = NULL,
@CustomerType NVARCHAR(100) = NULL,
@FunderType NVARCHAR(100) = NULL,
@VendorType NVARCHAR(100) = NULL,
@AssetType NVARCHAR(100) = NULL,
@AppraisalRequestType NVARCHAR(100) = NULL,
@LeaseAmendmentType NVARCHAR(100) = NULL,
@LoanAmendmentType NVARCHAR(100) = NULL,
@LegalEntityType NVARCHAR(100) = NULL,
@CreditProfileType NVARCHAR(100) = NULL,
@ProposalType NVARCHAR(100) = NULL,
@AssumptionType NVARCHAR(100) = NULL,
@CreditApplicationType NVARCHAR(100) = NULL,
@CollectionWorkListType NVARCHAR(100) = NULL,
@CollateralTrackingType NVARCHAR(100) = NULL,
@LeaseLabel NVARCHAR(100) = NULL,
@LoanLabel NVARCHAR(100) = NULL,
@CustomerLabel NVARCHAR(100) = NULL,
@FunderLabel NVARCHAR(100) = NULL,
@VendorLabel NVARCHAR(100) = NULL,
@AssetLabel NVARCHAR(100) = NULL,
@AppraisalRequestLabel NVARCHAR(100) = NULL,
@LeaseAmendmentLabel NVARCHAR(100) = NULL,
@LoanAmendmentLabel NVARCHAR(100) = NULL,
@LegalEntityLabel NVARCHAR(100) = NULL,
@CreditProfileLabel NVARCHAR(100) = NULL,
@ProposalLabel NVARCHAR(100) = NULL,
@AssumptionLabel NVARCHAR(100) = NULL,
@CreditApplicationLabel NVARCHAR(100) = NULL,
@CollectionWorkListLabel NVARCHAR(100) = NULL,
@CollateralTrackingLabel NVARCHAR(100) = NULL,
@ConversationModeClosed  NVARCHAR(100) = NULL
AS
BEGIN
SET NOCOUNT ON
SET NOCOUNT ON CREATE TABLE #Base (Id BIGINT, UniqueId NVARCHAR(100));
IF @EntityType IS NOT NULL
BEGIN
IF @EntityType = @CustomerLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, P.PartyNumber FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Parties P on P.Id = EH.EntityId
JOIN Customers C on C.Id = P.Id AND EC.Name = @CustomerType WHERE P.PartyNumber=@PartyNumber;
END
IF @EntityType = @FunderLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id as Id, P.PartyNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Parties P on P.Id = EH.EntityId
JOIN Funders F on F.Id = P.Id AND EC.Name = @FunderType WHERE PartyNumber=@PartyNumber;
END
IF @EntityType = @VendorLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, P.PartyNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Parties P on P.Id = EH.EntityId
JOIN Vendors V on V.Id = P.id AND EC.Name = @VendorType WHERE PartyNumber= @PartyNumber;
END
IF @EntityType = @AssetLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, A.Alias as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Assets A on A.Id= EH.EntityId AND EC.Name = @AssetType WHERE Alias= @AssetAlias ;
END
IF @EntityType = @AppraisalRequestLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, AR.AppraisalNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN AppraisalRequests AR on AR.Id= EH.EntityId AND EC.Name = @AppraisalRequestType WHERE AppraisalNumber= @AppraisalNumber;
END
IF @EntityType = @LeaseLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, C.SequenceNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LeaseFinances LF ON LF.Id= EH.EntityId
JOIN Contracts C on C.Id = LF.ContractId
AND EC.Name = @LeaseType WHERE SequenceNumber=@SequenceNumber;
END
IF @EntityType = @LoanLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, C.SequenceNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LoanFinances LF ON LF.Id= EH.EntityId
JOIN Contracts C on C.Id = LF.ContractId
AND EC.Name = @LoanType WHERE SequenceNumber= @SequenceNumber;
END
IF @EntityType = @LeaseAmendmentLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id,CAST(LA.Id as NVARCHAR) as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LeaseAmendments LA ON LA.Id= EH.EntityId
AND EC.Name = @LeaseAmendmentType WHERE LA.Id= @AmendmentId ;
END
IF @EntityType = @LoanAmendmentLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, CAST(LA.Id as NVARCHAR) as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LoanAmendments LA ON LA.Id= EH.EntityId
AND EC.Name = @LoanAmendmentType WHERE LA.Id=@AmendmentId ;
END
IF @EntityType = @LegalEntityLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, LE.LegalEntityNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LegalEntities LE ON LE.Id= EH.EntityId AND EC.Name = @LegalEntityType WHERE LegalEntityNumber=@LegalEntityNumber;
END
IF @EntityType = @CreditProfileLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, CP.Number as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN CreditProfiles CP ON CP.Id= EH.EntityId AND EC.Name = @CreditProfileType WHERE CP.Number=@CreditProfileNumber ;
END
IF @EntityType = @ProposalLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, OP.Number as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Proposals P ON P.Id= EH.EntityId
JOIN Opportunities OP ON P.Id = OP.Id
AND EC.Name = @ProposalType WHERE OP.Number=@ProposalNumber ;
END
IF @EntityType = @AssumptionLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, C.SequenceNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Assumptions A ON A.Id= EH.EntityId
JOIN Contracts C ON C.Id = A.ContractId
AND EC.Name = @AssumptionType WHERE C.SequenceNumber=@AssumptionSequence ;
END
IF @EntityType = @CreditApplicationLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, OP.Number as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN CreditApplications CA ON CA.Id= EH.EntityId
JOIN Opportunities OP ON OP.Id = CA.Id
AND EC.Name = @CreditApplicationType WHERE OP.Number=@CreditApplicationNumber;
END
IF @EntityType = @CollectionWorkListLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, CW.Id as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN CollectionWorkLists CW ON CW.Id= EH.EntityId
AND EC.Name = @CollectionWorkListType WHERE CW.Id=@CollectionWorkListNumber;
END
IF @EntityType = @CollateralTrackingLabel
BEGIN
INSERT INTO #Base SELECT Cmt.Id, CT.Id as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN CollateralTrackings CT ON CT.Id= EH.EntityId
AND EC.Name = @CollateralTrackingType WHERE CT.Id=@CollateralTrackingNumber ;
END
SELECT
CONVERT(SMALLDATETIME,Comments.CreatedTime) [CommentDate],
Author.FullName [CreatedBy],
EntityConfigs.Name [EntityType],
B.UniqueId [EntityId],
Comments.Id [CommentId],
CommentTypes.Name [CommentType],
Comments.ConversationMode ,
CASE WHEN ConversationMode = @ConversationModeClosed THEN CONVERT(SMALLDATETIME,Comments.UpdatedTime) ELSE NULL END [CompletionDate],
Comments.Body [Comment],
CONVERT(SMALLDATETIME, CommentResponses.CreatedTime) [RespondedDate],
[RespondedBy].FullName [RespondedBy],
CommentResponses.Body [Response]
FROM Comments
INNER JOIN Users [Author] ON Comments.AuthorId = [Author].Id
INNER JOIN CommentTypes ON Comments.CommentTypeId = CommentTypes.Id
INNER JOIN CommentLists on CommentLists.CommentId=Comments.Id
INNER JOIN CommentHeaders on CommentHeaders.Id=CommentLists.CommentHeaderId
INNER JOIN EntityHeaders on EntityHeaders.Id=CommentHeaders.Id
INNER JOIN EntityConfigs ON EntityHeaders.EntityTypeId = EntityConfigs.Id
INNER JOIN #Base B ON Comments.Id = B.Id
LEFT JOIN CommentResponses ON Comments.Id = CommentResponses.CommentId
LEFT JOIN Users [RespondedBy] ON CommentResponses.CreatedById = [RespondedBy].Id
WHERE Comments.IsActive = 1
AND (@FromDate is null or CAST(Comments.CreatedTime AS DATE) >= CAST(@FromDate AS DATE))
AND (@ToDate is null or CAST(Comments.CreatedTime AS DATE) <= CAST(@ToDate AS DATE))
END
ELSE
BEGIN
;With CTE_Base AS
(
SELECT Cmt.Id, P.PartyNumber  as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Parties P on P.Id = EH.EntityId
JOIN Customers C on C.Id = P.Id AND EC.Name = @CustomerType
UNION
SELECT Cmt.Id, P.PartyNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Parties P on P.Id = EH.EntityId
JOIN Funders F on F.Id = P.Id AND EC.Name = @FunderType
UNION
SELECT Cmt.Id, P.PartyNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Parties P on P.Id = EH.EntityId
JOIN Vendors V on V.Id = P.id AND EC.Name = @VendorType
UNION
SELECT Cmt.Id, A.Alias as UniqueId  FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Assets A on A.Id= EH.EntityId AND EC.Name = @AssetType
UNION
SELECT Cmt.Id, AR.AppraisalNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN AppraisalRequests AR on AR.Id= EH.EntityId AND EC.Name = @AppraisalRequestType
UNION
SELECT Cmt.Id, C.SequenceNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LeaseFinances LF on LF.Id= EH.EntityId
JOIN Contracts C on C.Id = LF.ContractId AND EC.Name = @LeaseType
UNION
SELECT Cmt.Id, C.SequenceNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LoanFinances LF on LF.Id= EH.EntityId
JOIN Contracts C on C.Id = LF.ContractId AND EC.Name = @LoanType
UNION
SELECT Cmt.Id, CAST(LA.Id as NVARCHAR) as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LeaseAmendments LA ON LA.Id= EH.EntityId
AND EC.Name = @LeaseAmendmentType
UNION
SELECT Cmt.Id, CAST(LA.Id as NVARCHAR) as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LoanAmendments LA ON LA.Id= EH.EntityId
AND EC.Name = @LoanAmendmentType
UNION
SELECT Cmt.Id, LE.LegalEntityNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN LegalEntities LE ON LE.Id= EH.EntityId AND EC.Name = @LegalEntityType
UNION
SELECT Cmt.Id, CP.Number as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN CreditProfiles CP ON CP.Id= EH.EntityId AND EC.Name = @CreditProfileType
UNION
SELECT Cmt.Id, OP.Number as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Proposals P ON P.Id= EH.EntityId
JOIN Opportunities OP ON P.Id = OP.Id AND EC.Name = @ProposalType
UNION
SELECT Cmt.Id, C.SequenceNumber as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN Assumptions A ON A.Id= EH.EntityId
JOIN Contracts C ON C.Id = A.ContractId And EC.Name = @AssumptionType
UNION
SELECT Cmt.Id, OP.Number as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN CreditApplications CA ON CA.Id= EH.EntityId
JOIN Opportunities OP ON OP.Id = CA.Id AND EC.Name = @CreditApplicationType
UNION
SELECT Cmt.Id, CAST(CW.Id AS NVARCHAR) as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN CollectionWorkLists CW ON CW.Id= EH.EntityId AND EC.Name = @CollectionWorkListType
UNION
SELECT Cmt.Id, CAST(CT.Id AS NVARCHAR) as UniqueId FROM CommentHeaders CH
JOIN EntityHeaders EH ON CH.Id = EH.Id
JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
JOIN CommentLists CL ON CH.Id = CL.CommentHeaderId
JOIN Comments Cmt ON CL.CommentId = Cmt.Id
JOIN CollateralTrackings CT ON CT.Id= EH.EntityId AND EC.Name = @CollateralTrackingType
)
SELECT
CONVERT(SMALLDATETIME,Comments.CreatedTime) [CommentDate],
Author.FullName [CreatedBy],
EntityConfigs.Name [EntityType],
B.UniqueId [EntityId],
Comments.Id [CommentId],
CommentTypes.Name [CommentType],
Comments.ConversationMode ,
CASE WHEN ConversationMode = @ConversationModeClosed THEN CONVERT(SMALLDATETIME,Comments.UpdatedTime) ELSE NULL END [CompletionDate],
Comments.Body [Comment],
CONVERT(SMALLDATETIME, CommentResponses.CreatedTime) [RespondedDate],
[RespondedBy].FullName [RespondedBy],
CommentResponses.Body [Response]
FROM Comments
INNER JOIN CommentLists on CommentLists.CommentId=comments.Id
INNER JOIN CommentHeaders on CommentHeaders.Id = CommentLists.CommentHeaderId
INNER JOIN EntityHeaders on EntityHeaders.Id=CommentHeaders.Id
INNER JOIN Users [Author] ON Comments.AuthorId = [Author].Id
INNER JOIN CommentTypes ON Comments.CommentTypeId = CommentTypes.Id
INNER JOIN EntityConfigs ON EntityHeaders.EntityTypeId = EntityConfigs.Id
INNER JOIN CTE_Base B ON Comments.Id = B.Id
LEFT JOIN CommentResponses ON Comments.Id = CommentResponses.CommentId
LEFT JOIN Users [RespondedBy] ON CommentResponses.CreatedById = [RespondedBy].Id
WHERE Comments.IsActive = 1
AND (@FromDate is null or CAST(Comments.CreatedTime AS DATE) >= CAST(@FromDate AS DATE))
AND (@ToDate is null or CAST(Comments.CreatedTime AS DATE) <= CAST(@ToDate AS DATE))
END
Drop Table #Base
END

GO
