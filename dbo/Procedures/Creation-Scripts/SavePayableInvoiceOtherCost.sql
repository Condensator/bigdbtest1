SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayableInvoiceOtherCost]
(
 @val [dbo].[PayableInvoiceOtherCost] READONLY
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
MERGE [dbo].[PayableInvoiceOtherCosts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllocationMethod]=S.[AllocationMethod],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AssetFeatureId]=S.[AssetFeatureId],[AssetId]=S.[AssetId],[AssignOtherCostAtSKULevel]=S.[AssignOtherCostAtSKULevel],[AssociateAssets]=S.[AssociateAssets],[BillToId]=S.[BillToId],[BlendedItemCodeId]=S.[BlendedItemCodeId],[CapitalizedProgressPayment_Amount]=S.[CapitalizedProgressPayment_Amount],[CapitalizedProgressPayment_Currency]=S.[CapitalizedProgressPayment_Currency],[CapitalizeFrom]=S.[CapitalizeFrom],[Comment]=S.[Comment],[ContractId]=S.[ContractId],[CostTypeId]=S.[CostTypeId],[CreditBalance_Amount]=S.[CreditBalance_Amount],[CreditBalance_Currency]=S.[CreditBalance_Currency],[Description]=S.[Description],[DueDate]=S.[DueDate],[GLJournalId]=S.[GLJournalId],[InterestAccrualBalance_Amount]=S.[InterestAccrualBalance_Amount],[InterestAccrualBalance_Currency]=S.[InterestAccrualBalance_Currency],[InterestUpdateLastDate]=S.[InterestUpdateLastDate],[InterimInterestStartDate]=S.[InterimInterestStartDate],[IsActive]=S.[IsActive],[IsLeaseCostAdjusted]=S.[IsLeaseCostAdjusted],[IsNewlyAdded]=S.[IsNewlyAdded],[IsPaydownCompleted]=S.[IsPaydownCompleted],[IsPrepaidUpfrontTax]=S.[IsPrepaidUpfrontTax],[IsUpfit]=S.[IsUpfit],[LocationId]=S.[LocationId],[OtherCostCodeId]=S.[OtherCostCodeId],[OtherCostPayableCodeId]=S.[OtherCostPayableCodeId],[OtherCostWithholdingTaxRate]=S.[OtherCostWithholdingTaxRate],[PayableRemitToId]=S.[PayableRemitToId],[ProgressFundingId]=S.[ProgressFundingId],[ReceivableCodeId]=S.[ReceivableCodeId],[RemitToId]=S.[RemitToId],[ReversalGLJournalId]=S.[ReversalGLJournalId],[RowNumber]=S.[RowNumber],[SundryReceivableId]=S.[SundryReceivableId],[SystemCalculated]=S.[SystemCalculated],[TaxCodeId]=S.[TaxCodeId],[TaxCodeRateId]=S.[TaxCodeRateId],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATType]=S.[VATType],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([AllocationMethod],[Amount_Amount],[Amount_Currency],[AssetFeatureId],[AssetId],[AssignOtherCostAtSKULevel],[AssociateAssets],[BillToId],[BlendedItemCodeId],[CapitalizedProgressPayment_Amount],[CapitalizedProgressPayment_Currency],[CapitalizeFrom],[Comment],[ContractId],[CostTypeId],[CreatedById],[CreatedTime],[CreditBalance_Amount],[CreditBalance_Currency],[Description],[DueDate],[GLJournalId],[InterestAccrualBalance_Amount],[InterestAccrualBalance_Currency],[InterestUpdateLastDate],[InterimInterestStartDate],[IsActive],[IsLeaseCostAdjusted],[IsNewlyAdded],[IsPaydownCompleted],[IsPrepaidUpfrontTax],[IsUpfit],[LocationId],[OtherCostCodeId],[OtherCostPayableCodeId],[OtherCostWithholdingTaxRate],[PayableInvoiceId],[PayableRemitToId],[ProgressFundingId],[ReceivableCodeId],[RemitToId],[ReversalGLJournalId],[RowNumber],[SundryReceivableId],[SystemCalculated],[TaxCodeId],[TaxCodeRateId],[TaxTypeId],[VATType],[VendorId])
    VALUES (S.[AllocationMethod],S.[Amount_Amount],S.[Amount_Currency],S.[AssetFeatureId],S.[AssetId],S.[AssignOtherCostAtSKULevel],S.[AssociateAssets],S.[BillToId],S.[BlendedItemCodeId],S.[CapitalizedProgressPayment_Amount],S.[CapitalizedProgressPayment_Currency],S.[CapitalizeFrom],S.[Comment],S.[ContractId],S.[CostTypeId],S.[CreatedById],S.[CreatedTime],S.[CreditBalance_Amount],S.[CreditBalance_Currency],S.[Description],S.[DueDate],S.[GLJournalId],S.[InterestAccrualBalance_Amount],S.[InterestAccrualBalance_Currency],S.[InterestUpdateLastDate],S.[InterimInterestStartDate],S.[IsActive],S.[IsLeaseCostAdjusted],S.[IsNewlyAdded],S.[IsPaydownCompleted],S.[IsPrepaidUpfrontTax],S.[IsUpfit],S.[LocationId],S.[OtherCostCodeId],S.[OtherCostPayableCodeId],S.[OtherCostWithholdingTaxRate],S.[PayableInvoiceId],S.[PayableRemitToId],S.[ProgressFundingId],S.[ReceivableCodeId],S.[RemitToId],S.[ReversalGLJournalId],S.[RowNumber],S.[SundryReceivableId],S.[SystemCalculated],S.[TaxCodeId],S.[TaxCodeRateId],S.[TaxTypeId],S.[VATType],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
