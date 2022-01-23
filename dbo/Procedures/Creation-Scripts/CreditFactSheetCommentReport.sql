SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreditFactSheetCommentReport]
(
@CreditProfileId BIGINT,
@PartyId BigInt
)
AS
--Declare @PartyId BigInt;
--Declare @CreditProfileId BigInt;
--Set @PartyId = 1;
--set @CreditProfileId = 10110;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON
SELECT FullName, CreatedTime, Body, CommentId
FROM
(
SELECT U.FullName, C.CreatedTime, C.Body AS Body, C.Id AS CommentId
FROM CommentHeaders CH
INNER JOIN EntityHeaders EH on CH.Id = EH.Id
INNER JOIN EntityConfigs EC on EH.EntityTypeId = EC.Id
INNER JOIN CommentLists CL  on CH.Id = CL.CommentHeaderId
INNER JOIN Comments C on CL.CommentId = C.Id
INNER JOIN Users U on c.AuthorId = U.Id
WHERE EC.Name = 'CreditProfile'
AND C.IsActive = 1
AND EH.EntityId = @CreditProfileId
UNION
SELECT U.FullName, ISNULL(R.UpdatedTime, R.CreatedTime) AS CreatedTime, R.Body AS Body, C.Id AS CommentId
FROM CommentHeaders CH
INNER JOIN EntityHeaders EH on CH.Id = EH.Id
INNER JOIN EntityConfigs EC on EH.EntityTypeId = EC.Id
INNER JOIN CommentLists CL  on CH.Id = CL.CommentHeaderId
INNER JOIN Comments C on CL.CommentId = C.Id
INNER JOIN CommentResponses R on C.Id = R.CommentId
INNER JOIN Users U on c.AuthorId = U.Id
WHERE EC.Name = 'CreditProfile'
AND C.IsActive = 1
AND EH.EntityId = @CreditProfileId
) Temp1
ORDER BY Temp1.CreatedTime

GO
