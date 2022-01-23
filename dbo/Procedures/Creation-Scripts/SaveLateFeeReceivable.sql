SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLateFeeReceivable]
(
 @val [dbo].[LateFeeReceivable] READONLY
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
MERGE [dbo].[LateFeeReceivables] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingTreatment]=S.[AccountingTreatment],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BillToId]=S.[BillToId],[CostCenterId]=S.[CostCenterId],[CurrencyId]=S.[CurrencyId],[DaysLate]=S.[DaysLate],[DueDate]=S.[DueDate],[EndDate]=S.[EndDate],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[InstrumentTypeId]=S.[InstrumentTypeId],[InvoiceComment]=S.[InvoiceComment],[InvoiceReceivableGroupingOption]=S.[InvoiceReceivableGroupingOption],[IsActive]=S.[IsActive],[IsCollected]=S.[IsCollected],[IsManuallyAssessed]=S.[IsManuallyAssessed],[IsOwned]=S.[IsOwned],[IsPrivateLabel]=S.[IsPrivateLabel],[IsServiced]=S.[IsServiced],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[ReceiptId]=S.[ReceiptId],[ReceivableAmendmentType]=S.[ReceivableAmendmentType],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableInvoiceId]=S.[ReceivableInvoiceId],[RemitToId]=S.[RemitToId],[ReversedDate]=S.[ReversedDate],[StartDate]=S.[StartDate],[TaxBasisAmount_Amount]=S.[TaxBasisAmount_Amount],[TaxBasisAmount_Currency]=S.[TaxBasisAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingTreatment],[Amount_Amount],[Amount_Currency],[BillToId],[CostCenterId],[CreatedById],[CreatedTime],[CurrencyId],[DaysLate],[DueDate],[EndDate],[EntityId],[EntityType],[InstrumentTypeId],[InvoiceComment],[InvoiceReceivableGroupingOption],[IsActive],[IsCollected],[IsManuallyAssessed],[IsOwned],[IsPrivateLabel],[IsServiced],[LegalEntityId],[LineofBusinessId],[ReceiptId],[ReceivableAmendmentType],[ReceivableCodeId],[ReceivableInvoiceId],[RemitToId],[ReversedDate],[StartDate],[TaxBasisAmount_Amount],[TaxBasisAmount_Currency])
    VALUES (S.[AccountingTreatment],S.[Amount_Amount],S.[Amount_Currency],S.[BillToId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[DaysLate],S.[DueDate],S.[EndDate],S.[EntityId],S.[EntityType],S.[InstrumentTypeId],S.[InvoiceComment],S.[InvoiceReceivableGroupingOption],S.[IsActive],S.[IsCollected],S.[IsManuallyAssessed],S.[IsOwned],S.[IsPrivateLabel],S.[IsServiced],S.[LegalEntityId],S.[LineofBusinessId],S.[ReceiptId],S.[ReceivableAmendmentType],S.[ReceivableCodeId],S.[ReceivableInvoiceId],S.[RemitToId],S.[ReversedDate],S.[StartDate],S.[TaxBasisAmount_Amount],S.[TaxBasisAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
