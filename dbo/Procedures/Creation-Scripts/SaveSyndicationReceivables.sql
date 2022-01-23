SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SaveSyndicationReceivables]
(
@Receivables SyndicationReceivablesToSave READONLY,
@CurrencyCode NVARCHAR(3),
@CreatedByUserId BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
CREATE TABLE #InsertedReceivables
(
Id BIGINT,
DueDate DATETIME NULL,
ReceivableCodeId BIGINT NULL,
FunderId BIGINT NULL,
PaymentScheduleId BIGINT NULL
);
INSERT INTO [dbo].[Receivables] ([DueDate]
, [EntityType]
, [IsActive]
, [InvoiceComment]
, [InvoiceReceivableGroupingOption]
, [IsGLPosted]
, [IncomeType]
, [PaymentScheduleId]
, [IsCollected]
, [CreatedById]
, [CreatedTime]
, [ReceivableCodeId]
, [CustomerId]
, [RemitToId]
, [TaxRemitToId]
, [LocationId]
, [LegalEntityId]
, [EntityId]
, [IsDSL]
, [IsServiced]
, [IsDummy]
, [IsPrivateLabel]
, [FunderId]
, [SourceTable]
, [TotalAmount_Currency]
, [TotalAmount_Amount]
, [TotalEffectiveBalance_Currency]
, [TotalEffectiveBalance_Amount]
, [TotalBalance_Currency]
, [TotalBalance_Amount]
, [TotalBookBalance_Currency]
, [TotalBookBalance_Amount]
, [AlternateBillingCurrencyId]
, [ExchangeRate])
OUTPUT INSERTED.Id, INSERTED.DueDate, INSERTED.ReceivableCodeId, INSERTED.FunderId, INSERTED.PaymentScheduleId INTO #InsertedReceivables
SELECT
[DueDate],
[EntityType],
[IsActive],
[InvoiceComment],
[InvoiceReceivableGroupingOption],
[IsGLPosted],
[IncomeType],
[PaymentScheduleId],
[IsCollected],
@CreatedByUserId,
@CreatedTime,
[ReceivableCodeId],
[CustomerId],
[RemitToId],
[TaxRemitToId],
[LocationId],
[LegalEntityId],
[EntityId],
[IsDSL],
[IsServiced],
[IsDummy],
[IsPrivateLabel],
[FunderId],
[SourceTable],
@CurrencyCode,
[TotalAmount_Amount],
@CurrencyCode,
[TotalEffectiveBalance_Amount],
@CurrencyCode,
[TotalBalance_Amount],
@CurrencyCode,
[TotalBookBalance_Amount],
[AlternateBillingCurrencyId],
[ExchangeRate]
FROM @Receivables;
SELECT
Id,
FunderId,
PaymentScheduleId
FROM #InsertedReceivables
END

GO
