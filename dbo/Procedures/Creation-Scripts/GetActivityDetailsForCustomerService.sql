SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetActivityDetailsForCustomerService]
(
@CustomerNumber nvarchar(50),
@ActivitySource nvarchar(20)
)
AS
SET NOCOUNT ON
BEGIN
DECLARE @Test bit;
/*
CREATE TABLE #ActivityDetails ( Date DATE
,ActivitySource NVARCHAR(500)
,ActivityType NVARCHAR(500)
,Comment NVARCHAR(MAX)
,Status NVARCHAR(500)
,UserName NVARCHAR(500)
,Reference NVARCHAR(100)
,EntityId BIGINT
,ActivityEntityId BIGINT
,EntityName NVARCHAR(500)
,TransactionName NVARCHAR(500)
,ActivityEntityName NVARCHAR(500)
,ActivityTransactionName NVARCHAR(500)
,SortOrder INT
,IsActive BIT
,CreatedTime datetimeoffset
)
INSERT INTO #ActivityDetails(	  Date,
ActivitySource,
ActivityType,
Comment,
Status,
Reference,
UserName,
EntityId,
ActivityEntityId,
EntityName,
TransactionName,
ActivityEntityName,
ActivityTransactionName,
SortOrder,
IsActive,
CreatedTime
)
SELECT
CONVERT(date, C.CreatedTime)
,@ActivitySource [ActivitySource]
,CA.ActivityType
,CA.ActivityNote [Comment]
,C.Status
,'' [Reference]
,Users.FullName [UserName]
,C.Id [EntityId]
,C.Id
,'CollectionWorkList' [EntityName]
,'Edit' TransactionName
,'CollectionWorkList'
,'Edit'
,CASE WHEN C.Status = 'Cancelled' OR CA.IsActive = 0 THEN 4 ELSE 2 END
,CASE WHEN C.Status = 'Cancelled' OR CA.IsActive = 0 THEN 0 ELSE 1 END
,C.CreatedTime
FROM CollectionWorkLists C
INNER JOIN Users ON Users.Id = C.CreatedById
INNER JOIN CollectionWorkListActivities CA ON C.Id = CA.CollectionWorkListId
INNER JOIN Parties ON C.CustomerId = Parties.Id
WHERE Parties.PartyNumber = @CustomerNumber
ORDER BY ISNULL(C.UpdatedTime,C.CreatedTime) Desc
INSERT INTO #ActivityDetails(	  Date,
ActivitySource,
ActivityType,
Comment,
Status,
Reference,
UserName,
EntityId,
ActivityEntityId,
EntityName,
TransactionName,
ActivityEntityName,
ActivityTransactionName,
SortOrder,
IsActive,
CreatedTime
)
SELECT
A.ActivityDate
,A.ActivitySource
,A.ActivityType
,A.Comment
,A.Status
,CASE WHEN A.EntityId <> 0 AND A.EntityId IS NOT NULL THEN 'Link' ELSE '' END [Reference]
,Users.FullName [UserName]
,A.Id [EntityId]
,CASE WHEN A.EntityId IS NOT NULL THEN A.EntityId ELSE A.Id END [ActivityEntityId]
,'Activity' [EntityName]
,'Edit' TransactionName
,CASE WHEN A.ActivityType = 'Litigation' THEN 'Party' WHEN A.ActivityType = 'AssetAppraisal' OR A.ActivityType = 'AssetInspection' THEN 'AppraisalRequest' WHEN A.ActivityType = 'AgencyPlacement' OR A.ActivityType = 'LegalPlacement' THEN 'AgencyLegalPlacement' WHEN A.ActivityType = 'UpdateBankruptcyChapter' OR A.ActivityType = 'Receivership' OR  A.ActivityType = 'Bankruptcy' THEN 'LegalRelief' ELSE 'Activity' END [ActivityEntityName]
,CASE WHEN A.ActivityType = 'Litigation' THEN 'EditCustomer' ELSE 'Edit' END [ActivityTransactionName]
,CASE WHEN A.Status = 'Cancelled' OR A.IsActive = 0 THEN 2 ELSE 1 END
,CASE WHEN A.Status = 'Cancelled' OR A.IsActive = 0 THEN 0 ELSE 1 END
,A.CreatedTime
FROM Activities A
INNER JOIN Users ON Users.Id = A.CreatedById
INNER JOIN Parties ON A.CustomerId = Parties.Id
WHERE Parties.PartyNumber = @CustomerNumber
ORDER BY ISNULL(A.UpdatedTime,A.CreatedTime) Desc
SELECT * FROM #ActivityDetails
ORDER BY SortOrder,CreatedTime  Desc
*/
END

GO
