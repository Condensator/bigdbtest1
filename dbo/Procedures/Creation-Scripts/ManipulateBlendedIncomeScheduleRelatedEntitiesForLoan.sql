SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ManipulateBlendedIncomeScheduleRelatedEntitiesForLoan]  
(  
@IncomeSchedules BlendedIncomeScheduleValuesForLoan READONLY,  
@Sundry LoanBlendedItemSundryTypeForLoan READONLY,  
@BlendedItemDetail BlendedItemDetailValuesForLoan READONLY,  
@ReceivableOnlySundryType NVARCHAR(20),  
@PayableOnlySundryType NVARCHAR(20),  
@ModificationType NVARCHAR(25),  
@UserId BIGINT,  
@Time DATETIMEOFFSET  
)  
AS  
BEGIN  
SET NOCOUNT ON;  
CREATE TABLE #SundryIdMapping  
(  
Id BIGINT,  
Identifier BIGINT,  
BlendedItemId BIGINT  
);  
CREATE TABLE #PayableSundryMapping  
(  
SundryId BIGINT,  
PayableId BIGINT  
);  
CREATE TABLE #ReceivableSundryMapping  
(  
SundryId BIGINT,  
ReceivableId BIGINT  
);  
CREATE TABLE #TreasuryPayableSundryMapping  
(  
SundryId BIGINT,  
PayableId BIGINT,  
TreasuryPayableId BIGINT  
);  
MERGE dbo.BlendedIncomeSchedules AS PersistedBlendedIncome  
USING @IncomeSchedules AS Income  
ON (PersistedBlendedIncome.Id = Income.Id)  
WHEN MATCHED THEN  
UPDATE SET AdjustmentEntry = Income.AdjustmentEntry  
,BlendedItemId = Income.BlendedItemId  
,EffectiveInterest_Amount = Income.EffectiveInterest  
,EffectiveInterest_Currency = Income.Currency  
,EffectiveYield = Income.EffectiveYield  
,Income_Amount = Income.Income  
,Income_Currency = Income.Currency  
,IncomeBalance_Amount = Income.IncomeBalance  
,IncomeBalance_Currency = Income.Currency  
,IncomeDate = Income.IncomeDate  
,IsAccounting = Income.IsAccounting  
,IsNonAccrual = Income.IsNonAccrual  
,IsSchedule = Income.IsSchedule  
,LeaseFinanceId = NULL  
,LoanFinanceId = Income.LoanFinanceId  
,ModificationId = Income.LoanFinanceId  
,ModificationType = @ModificationType  
,PostDate = Income.PostDate  
,ReversalPostDate = NULL  
,UpdatedById = @UserId  
,UpdatedTime = @Time  
,IsRecomputed = Income.IsRecomputed  
WHEN NOT MATCHED THEN  
INSERT (AdjustmentEntry  
,BlendedItemId  
,CreatedById  
,CreatedTime  
,EffectiveInterest_Amount  
,EffectiveInterest_Currency  
,EffectiveYield  
,Income_Amount  
,Income_Currency  
,IncomeBalance_Amount  
,IncomeBalance_Currency  
,IncomeDate  
,IsAccounting  
,IsNonAccrual  
,IsSchedule  
,LeaseFinanceId  
,LoanFinanceId  
,ModificationId  
,ModificationType  
,PostDate  
,ReversalPostDate  
,IsRecomputed)  
VALUES (Income.AdjustmentEntry  
,Income.BlendedItemId  
,@UserId  
,@Time  
,Income.EffectiveInterest  
,Income.Currency  
,Income.EffectiveYield  
,Income.Income  
,Income.Currency  
,Income.IncomeBalance  
,Income.Currency  
,Income.IncomeDate  
,Income.IsAccounting  
,Income.IsNonAccrual  
,Income.IsSchedule  
,NULL  
,Income.LoanFinanceId  
,Income.LoanFinanceId  
,@ModificationType  
,Income.PostDate  
,NULL  
,Income.IsRecomputed);  
MERGE Sundries  
USING @Sundry Sundry ON 1 = 0  
WHEN NOT MATCHED  
THEN  
INSERT ([SundryType]  
,[EntityType]  
,[ReceivableDueDate]  
,[InvoiceComment]  
,[PayableDueDate]  
,[Memo]  
,[IsAssetBased]  
,[Amount_Amount]  
,[Amount_Currency]  
,[IsActive]  
,[IsTaxExempt]  
,[IsServiced]  
,[IsCollected]  
,[IsPrivateLabel]  
,[CreatedById]  
,[CreatedTime]  
,[ReceivableCodeId]  
,[PayableCodeId]  
,[BillToId]  
,[LegalEntityId]  
,[ContractId]  
,[CustomerId]  
,[VendorId]  
,[ReceivableRemitToId]  
,[PayableRemitToId]  
,[LocationId]  
,[CurrencyId]  
,[LineofBusinessId]  
,[InstrumentTypeId]  
,[IsOwned]  
,[IsAssignAtAssetLevel]  
,[IsSystemGenerated]  
,[InvoiceAmendmentType]  
,[Type]  
,[TaxPortionOfPayable_Amount]  
,[TaxPortionOfPayable_Currency]  
,[PayableAmount_Amount]  
,[PayableAmount_Currency]  
,[Status]  
,[CostCenterId]
,PayableWithholdingTaxRate
,IsVATAssessed
,CountryId
,ProjectedVATAmount_Amount
,ProjectedVATAmount_Currency)  
VALUES (Sundry.SundryType  
,Sundry.EntityType  
,(CASE WHEN SundryType != @ReceivableOnlySundryType THEN NULL ELSE Sundry.DueDate END)  
,Sundry.InvoiceComment  
,(CASE WHEN SundryType != @PayableOnlySundryType THEN NULL ELSE Sundry.DueDate END)  
,Sundry.Memo  
,Sundry.IsAssetBased  
,Sundry.Amount  
,Sundry.Currency  
,1  
,Sundry.IsTaxExempt  
,Sundry.IsServiced  
,Sundry.IsCollected  
,Sundry.IsPrivateLabel  
,@UserId  
,@Time  
,Sundry.ReceivableCodeId  
,Sundry.PayableCodeId  
,Sundry.BillToId  
,Sundry.LegalEntityId  
,Sundry.ContractId  
,Sundry.CustomerId  
,Sundry.VendorId  
,Sundry.ReceivableRemitToId  
,Sundry.PayableRemitToId  
,Sundry.LocationId  
,Sundry.CurrencyId  
,Sundry.LineofBusinessId  
,Sundry.InstrumentTypeId  
,Sundry.IsOwned  
,Sundry.IsAssignAtAssetLevel  
,Sundry.IsSystemGenerated  
,Sundry.InvoiceAmendmentType  
,Sundry.Type  
,0.0  
,Sundry.Currency  
,0.0  
,Sundry.Currency  
,'Pending'  
,Sundry.CostCenterId
,Sundry.PayableWithholdingTaxRate
,0
,NULL
,0.0
,Sundry.Currency)  
OUTPUT INSERTED.Id, Sundry.Identifier, Sundry.BlendedItemId INTO #SundryIdMapping  
;  
SELECT Mapping.Id 'SundryId', S.*  
INTO #PersistedSundries  
FROM @Sundry S  
JOIN #SundryIdMapping Mapping ON S.Identifier = Mapping.Identifier  
;  
MERGE Payables P  
USING (SELECT * FROM #PersistedSundries WHERE SundryType != @ReceivableOnlySundryType) Sundry ON 0 = 1  
WHEN NOT MATCHED  
THEN  
INSERT ([EntityType]  
,[EntityId]  
,[Amount_Amount]  
,[Amount_Currency]  
,[Balance_Amount]  
,[Balance_Currency]  
,[DueDate]  
,[Status]  
,[SourceTable]  
,[SourceId]  
,[InternalComment]  
,[IsGLPosted]  
,[CreatedById]  
,[CreatedTime]  
,[CurrencyId]  
,[PayableCodeId]  
,[LegalEntityId]  
,[PayeeId]  
,[RemitToId]  
,[TaxPortion_Amount]  
,[TaxPortion_Currency]  
,WithholdingTaxRate)  
VALUES (Sundry.PayableEntityType  
,Sundry.ContractId  
,Sundry.Amount  
,Sundry.Currency  
,Sundry.Amount  
,Sundry.Currency  
,Sundry.DueDate  
,Sundry.PayableStatus  
,Sundry.PayableSourceTable  
,Sundry.SundryId  
,Sundry.Memo  
,0  
,@UserId  
,@Time  
,Sundry.CurrencyId  
,Sundry.PayableCodeId  
,Sundry.LegalEntityId  
,Sundry.VendorId  
,Sundry.PayableRemitToId  
,0  
,Sundry.Currency  
,Sundry.PayableWithholdingTaxRate)  
OUTPUT Sundry.SundryId, INSERTED.Id 'PayableId' INTO #PayableSundryMapping  
;  
UPDATE SS  
SET SS.PayableId = Mapping.PayableId  
FROM Sundries SS  
JOIN #PayableSundryMapping Mapping ON Mapping.SundryId = SS.Id  
;  
MERGE TreasuryPayables TP  
USING (SELECT * FROM #PersistedSundries WHERE SundryType != @ReceivableOnlySundryType) Sundry ON 0 = 1  
WHEN NOT MATCHED  
THEN  
INSERT([RequestedPaymentDate]  
,[Amount_Amount]  
,[Amount_Currency]  
,[Balance_Amount]  
,[Balance_Currency]  
,[Status]  
,[Memo]  
,[PayeeId]  
,[RemitToId]  
,[LegalEntityId]  
,[ReceiptType]  
,[CurrencyId]  
,[CreatedById]  
,[CreatedTime]  
,[ContractSequenceNumber]  
,[TransactionNumber])  
VALUES(Sundry.DueDate  
,Sundry.Amount  
,Sundry.Currency  
,Sundry.Amount  
,Sundry.Currency  
,Sundry.TreasuryPayableStatus  
,Sundry.Memo  
,Sundry.VendorId  
,Sundry.PayableRemitToId  
,Sundry.LegalEntityId  
,Sundry.ReceiptType  
,Sundry.CurrencyId  
,@UserId  
,@Time  
,Sundry.ContractSequenceNumber  
,Sundry.ContractSequenceNumber)  
OUTPUT Sundry.SundryId, 0'PayableId', INSERTED.Id 'TreasuryPayableId' INTO #TreasuryPayableSundryMapping  
;  
UPDATE SS SET SS.PayableId = Mapping.PayableId  
FROM #TreasuryPayableSundryMapping SS  
JOIN #PayableSundryMapping Mapping ON Mapping.SundryId = SS.SundryId  
;  
INSERT INTO TreasuryPayableDetails  
([PayableId]  
,[TreasuryPayableId]  
,[ReceivableOffsetAmount_Amount]  
,[ReceivableOffsetAmount_Currency]  
,[IsActive]  
,[CreatedById]  
,[CreatedTime])  
SELECT  
Mapping.PayableId  
,Mapping.TreasuryPayableId  
,0.00  
,Sundry.Currency  
,1  
,@UserId  
,@Time  
FROM @Sundry Sundry  
JOIN #PersistedSundries PersistedSundry ON Sundry.Identifier = PersistedSundry.Identifier  
JOIN #TreasuryPayableSundryMapping Mapping ON PersistedSundry.SundryId = Mapping.SundryId  
;  
MERGE Receivables R
USING (SELECT * FROM #PersistedSundries WHERE SundryType != @PayableOnlySundryType) Sundry ON 0 = 1
WHEN NOT MATCHED
THEN
INSERT ([EntityType]
,[EntityId]
,[DueDate]
,[IsDSL]
,[IsActive]
,[InvoiceComment]
,[InvoiceReceivableGroupingOption]
,[IsGLPosted]
,[IncomeType]
,[PaymentScheduleId]
,[IsCollected]
,[IsServiced]
,[CreatedById]
,[CreatedTime]
,[ReceivableCodeId]
,[CustomerId]
,[FunderId]
,[RemitToId]
,[TaxRemitToId]
,[LocationId]
,[LegalEntityId]
,[IsDummy]
,[IsPrivateLabel]
,[SourceId]
,[SourceTable]
,[TotalAmount_Amount]
,[TotalAmount_Currency]
,[TotalBalance_Amount]
,[TotalBalance_Currency]
,[TotalEffectiveBalance_Amount]
,[TotalEffectiveBalance_Currency]
,[TotalBookBalance_Amount]
,[TotalBookBalance_Currency]
,[ExchangeRate]
,[AlternateBillingCurrencyId])
VALUES (Sundry.EntityType
,Sundry.ContractId
,Sundry.DueDate
,0
,1
,Sundry.InvoiceComment
,Sundry.InvoiceReceivableGroupingOption
,0
,'_'
,NULL
,Sundry.IsCollected
,Sundry.IsServiced
,@UserId
,@Time
,Sundry.ReceivableCodeId
,Sundry.CustomerId
,NULL
,Sundry.ReceivableRemitToId
,Sundry.ReceivableRemitToId
,Sundry.LocationId
,Sundry.LegalEntityId
,0
,Sundry.IsPrivateLabel
,Sundry.SundryId
,Sundry.ReceivableSourceTable
,Sundry.Amount
,Sundry.Currency
,Sundry.Amount
,Sundry.Currency
,Sundry.Amount
,Sundry.Currency
,0.0
,Sundry.Currency
,Sundry.ExchangeRate
,Sundry.AlternateBillingCurrencyId)
OUTPUT Sundry.SundryId, INSERTED.Id 'ReceivableId' INTO #ReceivableSundryMapping
;
INSERT INTO ReceivableDetails
([Amount_Amount]
,[Amount_Currency]
,[Balance_Amount]
,[Balance_Currency]
,[EffectiveBalance_Amount]
,[EffectiveBalance_Currency]
,[IsActive]
,[BilledStatus]
,[IsTaxAssessed]
,[CreatedById]
,[CreatedTime]
,[AssetId]
,[BillToId]
,[AdjustmentBasisReceivableDetailId]
,[ReceivableId]
,[StopInvoicing]
,[EffectiveBookBalance_Amount]
,[EffectiveBookBalance_Currency]
,[AssetComponentType]
,[LeaseComponentAmount_Amount]
,[LeaseComponentAmount_Currency]
,[NonLeaseComponentAmount_Amount]
,[NonLeaseComponentAmount_Currency]
,[LeaseComponentBalance_Amount]
,[LeaseComponentBalance_Currency]
,[NonLeaseComponentBalance_Amount]
,[NonLeaseComponentBalance_Currency]
,[PreCapitalizationRent_Amount]
,[PreCapitalizationRent_Currency])
SELECT
Sundry.Amount
,Sundry.Currency
,Sundry.Amount
,Sundry.Currency
,Sundry.Amount
,Sundry.Currency
,1
,Sundry.ReceivableBilledStatus
,Sundry.IsReceivableTaxAssessed
,@UserId
,@Time
,NULL
,Sundry.BillToId
,NULL
,Mapping.ReceivableId
,0
,0.0
,Sundry.Currency
,'_'
,Sundry.Amount
,Sundry.Currency
,0.00
,Sundry.Currency
,Sundry.Amount
,Sundry.Currency
,0.00
,Sundry.Currency
,0.00
,Sundry.Currency
FROM @Sundry Sundry
JOIN #PersistedSundries PersistedSundry ON Sundry.Identifier = PersistedSundry.Identifier
JOIN #ReceivableSundryMapping Mapping ON PersistedSundry.SundryId = Mapping.SundryId
;
UPDATE SS
SET SS.ReceivableId = Mapping.ReceivableId
FROM Sundries SS
JOIN #ReceivableSundryMapping Mapping ON Mapping.SundryId = SS.Id
;
INSERT INTO BlendedItemDetails
([DueDate]
,[PostDate]
,[IsActive]
,[CreatedTime]
,[BlendedItemId]
,[CreatedById]
,[Amount_Amount]
,[Amount_Currency]
,[SundryId]
,[IsGLPosted])
SELECT SS.DueDate
,NULL
,1
,@Time
,SS.BlendedItemId
,@UserId
,SS.Amount
,SS.Currency
,Mapping.SundryId
,0
FROM @Sundry SS
JOIN #PersistedSundries Mapping ON SS.BlendedItemId = Mapping.BlendedItemId AND SS.Identifier = Mapping.Identifier
;
DROP TABLE #PayableSundryMapping;
DROP TABLE #PersistedSundries;
DROP TABLE #ReceivableSundryMapping;
DROP TABLE #SundryIdMapping;
DROP TABLE #TreasuryPayableSundryMapping;
MERGE BlendedItemDetails
USING @BlendedItemDetail BlendedItemDetail ON 1 = 0
WHEN NOT MATCHED
THEN
INSERT
([DueDate]
,[PostDate]
,[IsActive]
,[CreatedTime]
,[BlendedItemId]
,[CreatedById]
,[Amount_Amount]
,[Amount_Currency]
,[SundryId]
,[IsGLPosted])
VALUES
(BlendedItemDetail.DueDate
,NULL
,1
,@Time
,BlendedItemDetail.BlendedItemId
,@UserId
,BlendedItemDetail.Amount
,BlendedItemDetail.Currency
,NULL
,0);
SET NOCOUNT OFF;
END

GO
