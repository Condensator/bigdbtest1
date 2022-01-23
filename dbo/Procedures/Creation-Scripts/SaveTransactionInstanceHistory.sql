SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTransactionInstanceHistory]
(
 @val [dbo].[TransactionInstanceHistory] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[TransactionInstanceHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AsOfDate]=S.[AsOfDate],[FollowUpDate]=S.[FollowUpDate],[LatestWorkItemHistoryId]=S.[LatestWorkItemHistoryId],[Reason]=S.[Reason],[Status]=S.[Status],[SuspendReasonId]=S.[SuspendReasonId],[SuspendResumeComment]=S.[SuspendResumeComment],[TransactionInstanceId]=S.[TransactionInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([AsOfDate],[CreatedById],[CreatedTime],[FollowUpDate],[LatestWorkItemHistoryId],[Reason],[Status],[SuspendReasonId],[SuspendResumeComment],[TransactionInstanceId],[UserId])
    VALUES (S.[AsOfDate],S.[CreatedById],S.[CreatedTime],S.[FollowUpDate],S.[LatestWorkItemHistoryId],S.[Reason],S.[Status],S.[SuspendReasonId],S.[SuspendResumeComment],S.[TransactionInstanceId],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
