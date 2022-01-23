SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBlendedItem]
(
 @val [dbo].[BlendedItem] READONLY
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
MERGE [dbo].[BlendedItems] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccumulateExpense]=S.[AccumulateExpense],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AmountBilled_Amount]=S.[AmountBilled_Amount],[AmountBilled_Currency]=S.[AmountBilled_Currency],[BillToId]=S.[BillToId],[BlendedItemCodeId]=S.[BlendedItemCodeId],[BookingGLTemplateId]=S.[BookingGLTemplateId],[BookRecognitionMode]=S.[BookRecognitionMode],[CurrentEndDate]=S.[CurrentEndDate],[DeferRecognition]=S.[DeferRecognition],[Description]=S.[Description],[DueDate]=S.[DueDate],[DueDay]=S.[DueDay],[EarnedAmount_Amount]=S.[EarnedAmount_Amount],[EarnedAmount_Currency]=S.[EarnedAmount_Currency],[EndDate]=S.[EndDate],[EntityType]=S.[EntityType],[ExpenseRecognitionMode]=S.[ExpenseRecognitionMode],[Frequency]=S.[Frequency],[FrequencyUnit]=S.[FrequencyUnit],[GeneratePayableOrReceivable]=S.[GeneratePayableOrReceivable],[IncludeInBlendedYield]=S.[IncludeInBlendedYield],[IncludeInClassificationTest]=S.[IncludeInClassificationTest],[InvoiceReceivableGroupingOption]=S.[InvoiceReceivableGroupingOption],[IsActive]=S.[IsActive],[IsAssetBased]=S.[IsAssetBased],[IsETC]=S.[IsETC],[IsFAS91]=S.[IsFAS91],[IsFromST]=S.[IsFromST],[IsNewlyAdded]=S.[IsNewlyAdded],[IsSystemGenerated]=S.[IsSystemGenerated],[IsVendorCommission]=S.[IsVendorCommission],[IsVendorSubsidy]=S.[IsVendorSubsidy],[LeaseAssetId]=S.[LeaseAssetId],[LocationId]=S.[LocationId],[Name]=S.[Name],[NumberOfPayments]=S.[NumberOfPayments],[NumberOfReceivablesGenerated]=S.[NumberOfReceivablesGenerated],[Occurrence]=S.[Occurrence],[ParentBlendedItemId]=S.[ParentBlendedItemId],[PartyId]=S.[PartyId],[PayableCodeId]=S.[PayableCodeId],[PayableRemitToId]=S.[PayableRemitToId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[PostDate]=S.[PostDate],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableRemitToId]=S.[ReceivableRemitToId],[RecognitionGLTemplateId]=S.[RecognitionGLTemplateId],[RecognitionMethod]=S.[RecognitionMethod],[RelatedBlendedItemId]=S.[RelatedBlendedItemId],[RowNumber]=S.[RowNumber],[StartDate]=S.[StartDate],[SystemConfigType]=S.[SystemConfigType],[TaxCreditTaxBasisPercentage]=S.[TaxCreditTaxBasisPercentage],[TaxDepTemplateId]=S.[TaxDepTemplateId],[TaxRecognitionMode]=S.[TaxRecognitionMode],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AccumulateExpense],[Amount_Amount],[Amount_Currency],[AmountBilled_Amount],[AmountBilled_Currency],[BillToId],[BlendedItemCodeId],[BookingGLTemplateId],[BookRecognitionMode],[CreatedById],[CreatedTime],[CurrentEndDate],[DeferRecognition],[Description],[DueDate],[DueDay],[EarnedAmount_Amount],[EarnedAmount_Currency],[EndDate],[EntityType],[ExpenseRecognitionMode],[Frequency],[FrequencyUnit],[GeneratePayableOrReceivable],[IncludeInBlendedYield],[IncludeInClassificationTest],[InvoiceReceivableGroupingOption],[IsActive],[IsAssetBased],[IsETC],[IsFAS91],[IsFromST],[IsNewlyAdded],[IsSystemGenerated],[IsVendorCommission],[IsVendorSubsidy],[LeaseAssetId],[LocationId],[Name],[NumberOfPayments],[NumberOfReceivablesGenerated],[Occurrence],[ParentBlendedItemId],[PartyId],[PayableCodeId],[PayableRemitToId],[PayableWithholdingTaxRate],[PostDate],[ReceivableCodeId],[ReceivableRemitToId],[RecognitionGLTemplateId],[RecognitionMethod],[RelatedBlendedItemId],[RowNumber],[StartDate],[SystemConfigType],[TaxCreditTaxBasisPercentage],[TaxDepTemplateId],[TaxRecognitionMode],[Type],[VATAmount_Amount],[VATAmount_Currency])
    VALUES (S.[AccumulateExpense],S.[Amount_Amount],S.[Amount_Currency],S.[AmountBilled_Amount],S.[AmountBilled_Currency],S.[BillToId],S.[BlendedItemCodeId],S.[BookingGLTemplateId],S.[BookRecognitionMode],S.[CreatedById],S.[CreatedTime],S.[CurrentEndDate],S.[DeferRecognition],S.[Description],S.[DueDate],S.[DueDay],S.[EarnedAmount_Amount],S.[EarnedAmount_Currency],S.[EndDate],S.[EntityType],S.[ExpenseRecognitionMode],S.[Frequency],S.[FrequencyUnit],S.[GeneratePayableOrReceivable],S.[IncludeInBlendedYield],S.[IncludeInClassificationTest],S.[InvoiceReceivableGroupingOption],S.[IsActive],S.[IsAssetBased],S.[IsETC],S.[IsFAS91],S.[IsFromST],S.[IsNewlyAdded],S.[IsSystemGenerated],S.[IsVendorCommission],S.[IsVendorSubsidy],S.[LeaseAssetId],S.[LocationId],S.[Name],S.[NumberOfPayments],S.[NumberOfReceivablesGenerated],S.[Occurrence],S.[ParentBlendedItemId],S.[PartyId],S.[PayableCodeId],S.[PayableRemitToId],S.[PayableWithholdingTaxRate],S.[PostDate],S.[ReceivableCodeId],S.[ReceivableRemitToId],S.[RecognitionGLTemplateId],S.[RecognitionMethod],S.[RelatedBlendedItemId],S.[RowNumber],S.[StartDate],S.[SystemConfigType],S.[TaxCreditTaxBasisPercentage],S.[TaxDepTemplateId],S.[TaxRecognitionMode],S.[Type],S.[VATAmount_Amount],S.[VATAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
