SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSundry]
(
 @val [dbo].[Sundry] READONLY
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
MERGE [dbo].[Sundries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BillToId]=S.[BillToId],[BranchId]=S.[BranchId],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[CountryId]=S.[CountryId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[EntityType]=S.[EntityType],[InstrumentTypeId]=S.[InstrumentTypeId],[InvoiceAmendmentType]=S.[InvoiceAmendmentType],[InvoiceComment]=S.[InvoiceComment],[IsActive]=S.[IsActive],[IsAssetBased]=S.[IsAssetBased],[IsAssignAtAssetLevel]=S.[IsAssignAtAssetLevel],[IsCollected]=S.[IsCollected],[IsOwned]=S.[IsOwned],[IsPrivateLabel]=S.[IsPrivateLabel],[IsServiced]=S.[IsServiced],[IsSystemGenerated]=S.[IsSystemGenerated],[IsTaxExempt]=S.[IsTaxExempt],[IsVATAssessed]=S.[IsVATAssessed],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[LocationId]=S.[LocationId],[Memo]=S.[Memo],[PayableAmount_Amount]=S.[PayableAmount_Amount],[PayableAmount_Currency]=S.[PayableAmount_Currency],[PayableCodeId]=S.[PayableCodeId],[PayableDueDate]=S.[PayableDueDate],[PayableId]=S.[PayableId],[PayableRemitToId]=S.[PayableRemitToId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[ProjectedVATAmount_Amount]=S.[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency]=S.[ProjectedVATAmount_Currency],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableDueDate]=S.[ReceivableDueDate],[ReceivableId]=S.[ReceivableId],[ReceivableRemitToId]=S.[ReceivableRemitToId],[Status]=S.[Status],[SundryType]=S.[SundryType],[TaxPortionOfPayable_Amount]=S.[TaxPortionOfPayable_Amount],[TaxPortionOfPayable_Currency]=S.[TaxPortionOfPayable_Currency],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[BillToId],[BranchId],[ContractId],[CostCenterId],[CountryId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[EntityType],[InstrumentTypeId],[InvoiceAmendmentType],[InvoiceComment],[IsActive],[IsAssetBased],[IsAssignAtAssetLevel],[IsCollected],[IsOwned],[IsPrivateLabel],[IsServiced],[IsSystemGenerated],[IsTaxExempt],[IsVATAssessed],[LegalEntityId],[LineofBusinessId],[LocationId],[Memo],[PayableAmount_Amount],[PayableAmount_Currency],[PayableCodeId],[PayableDueDate],[PayableId],[PayableRemitToId],[PayableWithholdingTaxRate],[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency],[ReceivableCodeId],[ReceivableDueDate],[ReceivableId],[ReceivableRemitToId],[Status],[SundryType],[TaxPortionOfPayable_Amount],[TaxPortionOfPayable_Currency],[Type],[VendorId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[BillToId],S.[BranchId],S.[ContractId],S.[CostCenterId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[EntityType],S.[InstrumentTypeId],S.[InvoiceAmendmentType],S.[InvoiceComment],S.[IsActive],S.[IsAssetBased],S.[IsAssignAtAssetLevel],S.[IsCollected],S.[IsOwned],S.[IsPrivateLabel],S.[IsServiced],S.[IsSystemGenerated],S.[IsTaxExempt],S.[IsVATAssessed],S.[LegalEntityId],S.[LineofBusinessId],S.[LocationId],S.[Memo],S.[PayableAmount_Amount],S.[PayableAmount_Currency],S.[PayableCodeId],S.[PayableDueDate],S.[PayableId],S.[PayableRemitToId],S.[PayableWithholdingTaxRate],S.[ProjectedVATAmount_Amount],S.[ProjectedVATAmount_Currency],S.[ReceivableCodeId],S.[ReceivableDueDate],S.[ReceivableId],S.[ReceivableRemitToId],S.[Status],S.[SundryType],S.[TaxPortionOfPayable_Amount],S.[TaxPortionOfPayable_Currency],S.[Type],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
