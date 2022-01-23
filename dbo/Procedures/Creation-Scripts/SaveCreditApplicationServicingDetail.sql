SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditApplicationServicingDetail]
(
 @val [dbo].[CreditApplicationServicingDetail] READONLY
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
MERGE [dbo].[CreditApplicationServicingDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsLessorCollected]=S.[IsLessorCollected],[IsLessorServiced]=S.[IsLessorServiced],[IsNonNotification]=S.[IsNonNotification],[IsPerfectPay]=S.[IsPerfectPay],[IsPrivateLabel]=S.[IsPrivateLabel],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[Id],[IsLessorCollected],[IsLessorServiced],[IsNonNotification],[IsPerfectPay],[IsPrivateLabel])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[Id],S.[IsLessorCollected],S.[IsLessorServiced],S.[IsNonNotification],S.[IsPerfectPay],S.[IsPrivateLabel])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
