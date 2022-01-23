SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetSaleReceivable]
(
 @val [dbo].[AssetSaleReceivable] READONLY
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
MERGE [dbo].[AssetSaleReceivables] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[ContractId]=S.[ContractId],[DueDate]=S.[DueDate],[InstallmentNumber]=S.[InstallmentNumber],[IsActive]=S.[IsActive],[LegalEntityId]=S.[LegalEntityId],[ReceivableId]=S.[ReceivableId],[SundryReceivableId]=S.[SundryReceivableId],[SundryRecurringId]=S.[SundryRecurringId],[Tax_Amount]=S.[Tax_Amount],[Tax_Currency]=S.[Tax_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AssetSaleId],[ContractId],[CreatedById],[CreatedTime],[DueDate],[InstallmentNumber],[IsActive],[LegalEntityId],[ReceivableId],[SundryReceivableId],[SundryRecurringId],[Tax_Amount],[Tax_Currency])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AssetSaleId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[InstallmentNumber],S.[IsActive],S.[LegalEntityId],S.[ReceivableId],S.[SundryReceivableId],S.[SundryRecurringId],S.[Tax_Amount],S.[Tax_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
