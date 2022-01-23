SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveServicingDetail]
(
 @val [dbo].[ServicingDetail] READONLY
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
MERGE [dbo].[ServicingDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EffectiveDate]=S.[EffectiveDate],[IsActive]=S.[IsActive],[IsCobrand]=S.[IsCobrand],[IsCollected]=S.[IsCollected],[IsNonNotification]=S.[IsNonNotification],[IsPerfectPay]=S.[IsPerfectPay],[IsPrivateLabel]=S.[IsPrivateLabel],[IsServiced]=S.[IsServiced],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EffectiveDate],[IsActive],[IsCobrand],[IsCollected],[IsNonNotification],[IsPerfectPay],[IsPrivateLabel],[IsServiced])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EffectiveDate],S.[IsActive],S.[IsCobrand],S.[IsCollected],S.[IsNonNotification],S.[IsPerfectPay],S.[IsPrivateLabel],S.[IsServiced])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
