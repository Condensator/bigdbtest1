SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSundryRecurring]
(
 @val [dbo].[SundryRecurring] READONLY
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
MERGE [dbo].[SundryRecurrings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BillPastEndDate]=S.[BillPastEndDate],[BillToId]=S.[BillToId],[BranchId]=S.[BranchId],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[CountryId]=S.[CountryId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[DueDay]=S.[DueDay],[EntityType]=S.[EntityType],[FirstDueDate]=S.[FirstDueDate],[Frequency]=S.[Frequency],[InstrumentTypeId]=S.[InstrumentTypeId],[InvoiceAmendmentType]=S.[InvoiceAmendmentType],[InvoiceComment]=S.[InvoiceComment],[IsActive]=S.[IsActive],[IsApplyAtAssetLevel]=S.[IsApplyAtAssetLevel],[IsAssetBased]=S.[IsAssetBased],[IsCollected]=S.[IsCollected],[IsExternalTermination]=S.[IsExternalTermination],[IsFinancialParametersChanged]=S.[IsFinancialParametersChanged],[IsOwned]=S.[IsOwned],[IsPayableAdjusted]=S.[IsPayableAdjusted],[IsPrivateLabel]=S.[IsPrivateLabel],[IsRegular]=S.[IsRegular],[IsRentalBased]=S.[IsRentalBased],[IsServiced]=S.[IsServiced],[IsSystemGenerated]=S.[IsSystemGenerated],[IsTaxExempt]=S.[IsTaxExempt],[IsVATAssessed]=S.[IsVATAssessed],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[LocationId]=S.[LocationId],[Memo]=S.[Memo],[NextPaymentDate]=S.[NextPaymentDate],[NumberOfDays]=S.[NumberOfDays],[NumberOfPayments]=S.[NumberOfPayments],[PayableAmount_Amount]=S.[PayableAmount_Amount],[PayableAmount_Currency]=S.[PayableAmount_Currency],[PayableCodeId]=S.[PayableCodeId],[PayableRemitToId]=S.[PayableRemitToId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[PaymentDateOffset]=S.[PaymentDateOffset],[ProcessThroughDate]=S.[ProcessThroughDate],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableRemitToId]=S.[ReceivableRemitToId],[RegularAmount_Amount]=S.[RegularAmount_Amount],[RegularAmount_Currency]=S.[RegularAmount_Currency],[Status]=S.[Status],[SundryType]=S.[SundryType],[TerminationDate]=S.[TerminationDate],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([BillPastEndDate],[BillToId],[BranchId],[ContractId],[CostCenterId],[CountryId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[DueDay],[EntityType],[FirstDueDate],[Frequency],[InstrumentTypeId],[InvoiceAmendmentType],[InvoiceComment],[IsActive],[IsApplyAtAssetLevel],[IsAssetBased],[IsCollected],[IsExternalTermination],[IsFinancialParametersChanged],[IsOwned],[IsPayableAdjusted],[IsPrivateLabel],[IsRegular],[IsRentalBased],[IsServiced],[IsSystemGenerated],[IsTaxExempt],[IsVATAssessed],[LegalEntityId],[LineofBusinessId],[LocationId],[Memo],[NextPaymentDate],[NumberOfDays],[NumberOfPayments],[PayableAmount_Amount],[PayableAmount_Currency],[PayableCodeId],[PayableRemitToId],[PayableWithholdingTaxRate],[PaymentDateOffset],[ProcessThroughDate],[ReceivableCodeId],[ReceivableRemitToId],[RegularAmount_Amount],[RegularAmount_Currency],[Status],[SundryType],[TerminationDate],[Type],[VendorId])
    VALUES (S.[BillPastEndDate],S.[BillToId],S.[BranchId],S.[ContractId],S.[CostCenterId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[DueDay],S.[EntityType],S.[FirstDueDate],S.[Frequency],S.[InstrumentTypeId],S.[InvoiceAmendmentType],S.[InvoiceComment],S.[IsActive],S.[IsApplyAtAssetLevel],S.[IsAssetBased],S.[IsCollected],S.[IsExternalTermination],S.[IsFinancialParametersChanged],S.[IsOwned],S.[IsPayableAdjusted],S.[IsPrivateLabel],S.[IsRegular],S.[IsRentalBased],S.[IsServiced],S.[IsSystemGenerated],S.[IsTaxExempt],S.[IsVATAssessed],S.[LegalEntityId],S.[LineofBusinessId],S.[LocationId],S.[Memo],S.[NextPaymentDate],S.[NumberOfDays],S.[NumberOfPayments],S.[PayableAmount_Amount],S.[PayableAmount_Currency],S.[PayableCodeId],S.[PayableRemitToId],S.[PayableWithholdingTaxRate],S.[PaymentDateOffset],S.[ProcessThroughDate],S.[ReceivableCodeId],S.[ReceivableRemitToId],S.[RegularAmount_Amount],S.[RegularAmount_Currency],S.[Status],S.[SundryType],S.[TerminationDate],S.[Type],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
