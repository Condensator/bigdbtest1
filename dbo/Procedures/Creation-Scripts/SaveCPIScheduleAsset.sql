SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPIScheduleAsset]
(
 @val [dbo].[CPIScheduleAsset] READONLY
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
MERGE [dbo].[CPIScheduleAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BaseAllowance]=S.[BaseAllowance],[BaseAmount_Amount]=S.[BaseAmount_Amount],[BaseAmount_Currency]=S.[BaseAmount_Currency],[BaseProcessThroughDate]=S.[BaseProcessThroughDate],[BaseRate]=S.[BaseRate],[BeginDate]=S.[BeginDate],[IsActive]=S.[IsActive],[IsPrimaryAsset]=S.[IsPrimaryAsset],[LastBaseRateUsed]=S.[LastBaseRateUsed],[OverageProcessThroughDate]=S.[OverageProcessThroughDate],[TerminationDate]=S.[TerminationDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[BaseAllowance],[BaseAmount_Amount],[BaseAmount_Currency],[BaseProcessThroughDate],[BaseRate],[BeginDate],[CPIScheduleId],[CreatedById],[CreatedTime],[IsActive],[IsPrimaryAsset],[LastBaseRateUsed],[OverageProcessThroughDate],[TerminationDate])
    VALUES (S.[AssetId],S.[BaseAllowance],S.[BaseAmount_Amount],S.[BaseAmount_Currency],S.[BaseProcessThroughDate],S.[BaseRate],S.[BeginDate],S.[CPIScheduleId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsPrimaryAsset],S.[LastBaseRateUsed],S.[OverageProcessThroughDate],S.[TerminationDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
