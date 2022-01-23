SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivable]
(
 @val [dbo].[Receivable] READONLY
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
MERGE [dbo].[Receivables] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AlternateBillingCurrencyId]=S.[AlternateBillingCurrencyId],[CalculatedDueDate]=S.[CalculatedDueDate],[CreationSourceId]=S.[CreationSourceId],[CreationSourceTable]=S.[CreationSourceTable],[CustomerId]=S.[CustomerId],[DealCountryId]=S.[DealCountryId],[DueDate]=S.[DueDate],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[ExchangeRate]=S.[ExchangeRate],[FunderId]=S.[FunderId],[IncomeType]=S.[IncomeType],[InvoiceComment]=S.[InvoiceComment],[InvoiceReceivableGroupingOption]=S.[InvoiceReceivableGroupingOption],[IsActive]=S.[IsActive],[IsCollected]=S.[IsCollected],[IsDSL]=S.[IsDSL],[IsDummy]=S.[IsDummy],[IsGLPosted]=S.[IsGLPosted],[IsPrivateLabel]=S.[IsPrivateLabel],[IsServiced]=S.[IsServiced],[LegalEntityId]=S.[LegalEntityId],[LocationId]=S.[LocationId],[PaymentScheduleId]=S.[PaymentScheduleId],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableTaxType]=S.[ReceivableTaxType],[RemitToId]=S.[RemitToId],[SourceId]=S.[SourceId],[SourceTable]=S.[SourceTable],[TaxRemitToId]=S.[TaxRemitToId],[TaxSourceDetailId]=S.[TaxSourceDetailId],[TotalAmount_Amount]=S.[TotalAmount_Amount],[TotalAmount_Currency]=S.[TotalAmount_Currency],[TotalBalance_Amount]=S.[TotalBalance_Amount],[TotalBalance_Currency]=S.[TotalBalance_Currency],[TotalBookBalance_Amount]=S.[TotalBookBalance_Amount],[TotalBookBalance_Currency]=S.[TotalBookBalance_Currency],[TotalEffectiveBalance_Amount]=S.[TotalEffectiveBalance_Amount],[TotalEffectiveBalance_Currency]=S.[TotalEffectiveBalance_Currency],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AlternateBillingCurrencyId],[CalculatedDueDate],[CreatedById],[CreatedTime],[CreationSourceId],[CreationSourceTable],[CustomerId],[DealCountryId],[DueDate],[EntityId],[EntityType],[ExchangeRate],[FunderId],[IncomeType],[InvoiceComment],[InvoiceReceivableGroupingOption],[IsActive],[IsCollected],[IsDSL],[IsDummy],[IsGLPosted],[IsPrivateLabel],[IsServiced],[LegalEntityId],[LocationId],[PaymentScheduleId],[ReceivableCodeId],[ReceivableTaxType],[RemitToId],[SourceId],[SourceTable],[TaxRemitToId],[TaxSourceDetailId],[TotalAmount_Amount],[TotalAmount_Currency],[TotalBalance_Amount],[TotalBalance_Currency],[TotalBookBalance_Amount],[TotalBookBalance_Currency],[TotalEffectiveBalance_Amount],[TotalEffectiveBalance_Currency],[UniqueIdentifier])
    VALUES (S.[AlternateBillingCurrencyId],S.[CalculatedDueDate],S.[CreatedById],S.[CreatedTime],S.[CreationSourceId],S.[CreationSourceTable],S.[CustomerId],S.[DealCountryId],S.[DueDate],S.[EntityId],S.[EntityType],S.[ExchangeRate],S.[FunderId],S.[IncomeType],S.[InvoiceComment],S.[InvoiceReceivableGroupingOption],S.[IsActive],S.[IsCollected],S.[IsDSL],S.[IsDummy],S.[IsGLPosted],S.[IsPrivateLabel],S.[IsServiced],S.[LegalEntityId],S.[LocationId],S.[PaymentScheduleId],S.[ReceivableCodeId],S.[ReceivableTaxType],S.[RemitToId],S.[SourceId],S.[SourceTable],S.[TaxRemitToId],S.[TaxSourceDetailId],S.[TotalAmount_Amount],S.[TotalAmount_Currency],S.[TotalBalance_Amount],S.[TotalBalance_Currency],S.[TotalBookBalance_Amount],S.[TotalBookBalance_Currency],S.[TotalEffectiveBalance_Amount],S.[TotalEffectiveBalance_Currency],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
