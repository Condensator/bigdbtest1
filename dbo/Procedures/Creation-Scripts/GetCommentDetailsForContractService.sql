SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCommentDetailsForContractService]
(
@ContractSequenceNumber nvarchar(80)
,@CommentFetchCount INT
)
AS
SET NOCOUNT ON
BEGIN
DECLARE @Count  INT = @CommentFetchCount
IF @CommentFetchCount = 0
SET @Count = 20
DECLARE @IsLease bit = (select
case when c.ContractType = 'Lease' then 1 else 0
end
from Contracts c where c.SequenceNumber = @ContractSequenceNumber )
DECLARE @EntityId bigint = (select IsNULL(LeaseF.Id,LoanF.Id)
from Contracts c
LEFT JOIN LeaseFinances LeaseF on c.Id = LeaseF.ContractId AND LeaseF.IsCurrent = 1
LEFT JOIN LoanFinances LoanF on c.Id = LoanF.ContractId AND LoanF.IsCurrent = 1
where c.SequenceNumber = @ContractSequenceNumber )
CREATE TABLE #CommentDetails( Comment NVARCHAR(MAX),
EnteredDate Datetimeoffset,
Originator NVARCHAR(250),
CommentType NVARCHAR(MAX),
CommentTitle NVARCHAR(MAX),
LastUpdatedDate Datetimeoffset,
LastRespondedDate Datetimeoffset,
CommentId BIGINT
)
insert into #CommentDetails(Comment ,
EnteredDate ,
Originator ,
CommentType,
CommentTitle ,
LastUpdatedDate,
LastRespondedDate,
CommentId
)
SELECT REPLACE(C.Body,char(13) + char(10),' ') as Comment,
C.OriginalCreatedTime as EnteredDate,
U.FullName as Originator ,
CT.Name  [CommentType] ,
C.Title [CommentTitle] ,
C.UpdatedTime  [LastUpdatedDate] ,
CASE WHEN EXISTS(SELECT Id FROM CommentResponses WHERE CommentResponses.CommentId = C.Id) THEN (SELECT MAX(CreatedTime) FROM CommentResponses WHERE CommentResponses.CommentId = C.Id) ELSE null END ,
C.Id
from CommentHeaders CH
INNER JOIN EntityHeaders EH on CH.Id = EH.Id
INNER JOIN EntityConfigs EC on EH.EntityTypeId = EC.Id
INNER JOIN CommentLists CL  on CH.Id = CL.CommentHeaderId
INNER JOIN Comments C on CL.CommentId = C.Id
INNER JOIN CommentTypes CT on C.CommentTypeId = CT.Id
INNER JOIN Users U on c.AuthorId = U.Id
WHERE
EC.Name = CASE WHEN @IsLease = 1 THEN 'LeaseFinance' ELSE 'LoanFinance' END
AND C.IsActive = 1
AND EH.EntityId = @EntityId
SELECT
TOP (@Count)
EnteredDate ,
Comment ,
Originator ,
CommentType,
CommentTitle ,
CASE WHEN LastRespondedDate IS NOT NULL AND LastUpdatedDate IS NOT NULL AND  LastRespondedDate > LastUpdatedDate  THEN LastRespondedDate ELSE
CASE WHEN LastUpdatedDate IS NULL THEN LastRespondedDate ELSE LastUpdatedDate END  END [LastUpdatedDate],
CommentId
From #CommentDetails WHERE CommentType <> 'Legal'
ORDER BY EnteredDate DESC
SELECT
TOP (@Count)
EnteredDate ,
Comment ,
Originator ,
CommentType,
CommentTitle ,
CASE WHEN LastRespondedDate IS NOT NULL AND LastUpdatedDate IS NOT NULL AND  LastRespondedDate > LastUpdatedDate  THEN LastRespondedDate ELSE
CASE WHEN LastUpdatedDate IS NULL THEN LastRespondedDate ELSE LastUpdatedDate END  END [LastUpdatedDate],
CommentId
From #CommentDetails WHERE CommentType = 'Legal'
ORDER BY EnteredDate DESC
END

GO
