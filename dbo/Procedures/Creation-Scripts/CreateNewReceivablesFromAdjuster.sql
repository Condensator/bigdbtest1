SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateNewReceivablesFromAdjuster]
(
@receivableSet CreateNewReceivablesFromAdjusterParam READONLY,
@NonRentalEntityType NVARCHAR(40) NULL,
@NonRentalEntityTypeId BIGINT NULL,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #InsertedReceivables
(
ReceivableId BIGINT,
SourceId BIGINT,
ReceivableTempId BIGINT
)
SELECT * INTO #ReceivablesForCreation
FROM @receivableSet
MERGE Receivables R
USING @receivableSet RFC ON 1 = 0
WHEN NOT MATCHED THEN
INSERT
(           [EntityType]
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
,[IsDummy]
,[IsPrivateLabel]
,[SourceTable]
,[SourceId]
,[TotalAmount_Amount]
,[TotalAmount_Currency]
,[TotalBalance_Amount]
,[TotalBalance_Currency]
,[TotalEffectiveBalance_Amount]
,[TotalEffectiveBalance_Currency]
,[TotalBookBalance_Amount]
,[TotalBookBalance_Currency]
,[CreatedById]
,[CreatedTime]
,[ReceivableCodeId]
,[CustomerId]
,[FunderId]
,[RemitToId]
,[TaxRemitToId]
,[LocationId]
,[LegalEntityId]
,[ExchangeRate]
,[AlternateBillingCurrencyId]
,[CalculatedDueDate])
VALUES ( RFC.[EntityType]
,RFC.[EntityId]
,RFC.[DueDate]
,RFC.[IsDSL]
,1
,RFC.[InvoiceComment]
,RFC.[InvoiceReceivableGroupingOption]
,0
,RFC.[IncomeType]
,RFC.[PaymentScheduleId]
,RFC.[IsCollected]
,RFC.[IsServiced]
,RFC.[IsDummy]
,RFC.[IsPrivateLabel]
,RFC.[SourceTable]
,RFC.[SourceId]
,'0.0'
,'USD'
,'0.0'
,'USD'
,'0.0'
,'USD'
,'0.0'
,'USD'
,@CreatedById
,@CreatedTime
,RFC.[ReceivableCodeId]
,RFC.[CustomerId]
,RFC.[FunderId]
,RFC.[RemitToId]
,RFC.[TaxRemitToId]
,RFC.[LocationId]
,RFC.[LegalEntityId]
,RFC.[ExchangeRate]
,RFC.[AlternateBillingCurrencyId]
,NULL
)
OUTPUT Inserted.Id,Inserted.SourceId,RFC.ReceivableTempId INTO #InsertedReceivables;
IF( @NonRentalEntityTypeId IS NOT NULL)
BEGIN
DECLARE @NewReceivableId BIGINT
SELECT @NewReceivableId = ReceivableId FROM #InsertedReceivables
IF (@NonRentalEntityType = 'Sundry' )
BEGIN
UPDATE  Sundries  SET ReceivableId = @NewReceivableId WHERE Id = @NonRentalEntityTypeId
END
ELSE IF (@NonRentalEntityType = 'SundryRecurring')
BEGIN
UPDATE  SRP	SET ReceivableId = IR.ReceivableId
FROM SundryRecurringPaymentSchedules SRP
JOIN #InsertedReceivables IR ON SRP.SourceId = IR.SourceId
WHERE SundryRecurringId = @NonRentalEntityTypeId
END
ELSE IF (@NonRentalEntityType = 'PropertyTax' )
BEGIN
UPDATE  PropertyTaxes SET PropTaxReceivableId = @NewReceivableId WHERE Id = @NonRentalEntityTypeId
END
ELSE IF (@NonRentalEntityType = 'SecurityDeposit' )
BEGIN
UPDATE  SecurityDeposits SET ReceivableId = @NewReceivableId WHERE Id = @NonRentalEntityTypeId
END
END;
SELECT ReceivableId ,
ReceivableTempId
FROM #InsertedReceivables
END

GO
