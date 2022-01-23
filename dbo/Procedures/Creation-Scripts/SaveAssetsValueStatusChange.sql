SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetsValueStatusChange]
(
 @val [dbo].[AssetsValueStatusChange] READONLY
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
MERGE [dbo].[AssetsValueStatusChanges] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comment]=S.[Comment],[CurrencyId]=S.[CurrencyId],[IsActive]=S.[IsActive],[IsZeroMode]=S.[IsZeroMode],[LegalEntityId]=S.[LegalEntityId],[MigrationId]=S.[MigrationId],[PostDate]=S.[PostDate],[Reason]=S.[Reason],[ReversalPostDate]=S.[ReversalPostDate],[SourceModule]=S.[SourceModule],[SourceModuleId]=S.[SourceModuleId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Comment],[CreatedById],[CreatedTime],[CurrencyId],[IsActive],[IsZeroMode],[LegalEntityId],[MigrationId],[PostDate],[Reason],[ReversalPostDate],[SourceModule],[SourceModuleId])
    VALUES (S.[Comment],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[IsActive],S.[IsZeroMode],S.[LegalEntityId],S.[MigrationId],S.[PostDate],S.[Reason],S.[ReversalPostDate],S.[SourceModule],S.[SourceModuleId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
