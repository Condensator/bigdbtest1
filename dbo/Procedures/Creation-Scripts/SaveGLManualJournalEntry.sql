SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveGLManualJournalEntry]
(
 @val [dbo].[GLManualJournalEntry] READONLY
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
MERGE [dbo].[GLManualJournalEntries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[AssetSaleId]=S.[AssetSaleId],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[CurrencyId]=S.[CurrencyId],[Description]=S.[Description],[EntityType]=S.[EntityType],[GLJournalId]=S.[GLJournalId],[InstrumentTypeId]=S.[InstrumentTypeId],[IsActive]=S.[IsActive],[IsGLExportRequired]=S.[IsGLExportRequired],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[ManualGLTransactionType]=S.[ManualGLTransactionType],[PostDate]=S.[PostDate],[ReceivableForTransferId]=S.[ReceivableForTransferId],[ReferenceGLManualId]=S.[ReferenceGLManualId],[ReversalGLJournalId]=S.[ReversalGLJournalId],[ReversalPostDate]=S.[ReversalPostDate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[AssetSaleId],[ContractId],[CostCenterId],[CreatedById],[CreatedTime],[CurrencyId],[Description],[EntityType],[GLJournalId],[InstrumentTypeId],[IsActive],[IsGLExportRequired],[LegalEntityId],[LineofBusinessId],[ManualGLTransactionType],[PostDate],[ReceivableForTransferId],[ReferenceGLManualId],[ReversalGLJournalId],[ReversalPostDate],[Status])
    VALUES (S.[AssetId],S.[AssetSaleId],S.[ContractId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[Description],S.[EntityType],S.[GLJournalId],S.[InstrumentTypeId],S.[IsActive],S.[IsGLExportRequired],S.[LegalEntityId],S.[LineofBusinessId],S.[ManualGLTransactionType],S.[PostDate],S.[ReceivableForTransferId],S.[ReferenceGLManualId],S.[ReversalGLJournalId],S.[ReversalPostDate],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
