SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CreateFixedTermReceivablesForFutureFunding]
(
@ContractId BIGINT,
@LeaseFinanceId BIGINT,
@RentalPeriodBeginDate DATE,
@MaturityDate DATE,
@AssetLevelRent DECIMAL(18,2),
@Currency NVARCHAR(3),
@ReceivableEntityType NVARCHAR(40),
@FinancialType NVARCHAR(40),
@LegalEntityId BIGINT,
@CustomerId BIGINT,
@RemitToId BIGINT,
@ReceivableCodeId BIGINT,
@InvoiceReceivableGroupingOption NVARCHAR(8),
@BilledStatus NVARCHAR(11),
@IncomeType NVARCHAR(16),
@IsDSL BIT,
@IsCollected BIT,
@IsServiced  BIT,
@IsPrivateLabel BIT,
@IsDummy BIT,
@Status NVARCHAR(15),
@CreatedTime DATETIMEOFFSET,
@CreatedById BIGINT,
@PaymentTypeFixedTerm NVARCHAR(28),
@PaymentTypeDownPayment NVARCHAR(28),
@PaymentTypeMaturityPayment NVARCHAR(28),
@SourceTable NVARCHAR(2),
@IsFutureFunding BIT,
@UnknownPaymentType NVARCHAR(14),
@AssetSummary LeaseAssetInput READONLY,
@IsAdvance BIT,
@BillToId BIGINT = NULL,
@AlternateBillingCurrencyDetailsForFutureFunding AlternateBillingCurrencyDetailsForFutureFunding READONLY
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @Amount DECIMAL(18,2)
DECLARE @RentalPeriodStartDate DATE
DECLARE @RentalPeriodEndDate DATE
DECLARE @DueDate DATE
DECLARE @PaymentScheduleId BIGINT
DECLARE @AssetLevelRentForCurrentPeriod DECIMAL(18,2)
DECLARE @PaymentType NVARCHAR(28)
DECLARE @NextPaymentType NVARCHAR(28)
DECLARE @NextPaymentEndDate DATE
DECLARE @TempDate DATE = NULL
DECLARE @BillingCurrencyId BIGINT
DECLARE @BillingExchangeRate DECIMAL(18,8)
DECLARE @AmountToAdd DECIMAL(18,2) = 0.00
DECLARE PaymentSchedule_Cursor CURSOR LOCAL FOR SELECT CASE WHEN @IsFutureFunding = 1 THEN LeasePaymentSchedules.ActualPayment_Amount ELSE LeasePaymentSchedules.Amount_Amount END,LeasePaymentSchedules.StartDate,LeasePaymentSchedules.EndDate,LeasePaymentSchedules.DueDate,LeasePaymentSchedules.Id,LeasePaymentSchedules.PaymentType,NexPaymentSchedule.PaymentType AS NextPaymentType,NexPaymentSchedule.EndDate AS NextPaymentEndDate,billingcurrency.BillingExchangeRate AS BillingExchangeRate,billingcurrency.BillingCurrencyId AS BillingCurrencyId
FROM LeasePaymentSchedules JOIN @AlternateBillingCurrencyDetailsForFutureFunding billingcurrency ON LeasePaymentSchedules.Id = billingcurrency.LeasePaymentScheduleId LEFT JOIN LeasePaymentSchedules AS NexPaymentSchedule ON NexPaymentSchedule.LeaseFinanceDetailId = @LeaseFinanceId AND NexPaymentSchedule.IsActive=1 AND CAST(DATEADD(dd,1,LeasePaymentSchedules.EndDate) as date) = NexPaymentSchedule.StartDate
AND NexPaymentSchedule.StartDate BETWEEN @RentalPeriodBeginDate AND @MaturityDate AND (NexPaymentSchedule.PaymentType = @PaymentTypeFixedTerm OR NexPaymentSchedule.PaymentType = @PaymentTypeDownPayment OR NexPaymentSchedule.PaymentType = @PaymentTypeMaturityPayment OR NexPaymentSchedule.PaymentType = @UnknownPaymentType)
WHERE LeasePaymentSchedules.LeaseFinanceDetailId = @LeaseFinanceId AND LeasePaymentSchedules.IsActive = 1 AND LeasePaymentSchedules.StartDate BETWEEN @RentalPeriodBeginDate AND @MaturityDate AND (LeasePaymentSchedules.PaymentType = @PaymentTypeFixedTerm OR LeasePaymentSchedules.PaymentType = @PaymentTypeDownPayment OR LeasePaymentSchedules.PaymentType = @PaymentTypeMaturityPayment OR LeasePaymentSchedules.PaymentType = @UnknownPaymentType) ORDER BY LeasePaymentSchedules.StartDate
OPEN PaymentSchedule_Cursor
FETCH NEXT FROM PaymentSchedule_Cursor INTO @Amount,@RentalPeriodStartDate,@RentalPeriodEndDate,@DueDate,@PaymentScheduleId,@PaymentType,@NextPaymentType,@NextPaymentEndDate,@BillingExchangeRate,@BillingCurrencyId
WHILE @@FETCH_STATUS = 0
BEGIN
IF OBJECT_ID('tempdb..#ReceivableDetailTemp') IS NULL
BEGIN
CREATE TABLE #ReceivableDetailTemp
(
Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
AssetId BIGINT,
CalculatedRentalAmount DECIMAL(18,2),
AssetComponentType NVARCHAR(7)
)
END
DECLARE @AmountAfterDistribution DECIMAL(18,2)
DECLARE @ReceivableId BIGINT
DECLARE @Difference INT
IF @IsFutureFunding = 1
BEGIN
IF @IsAdvance = 1 AND @NextPaymentType = @UnknownPaymentType
BEGIN
SET @TempDate = @RentalPeriodEndDate
SET @RentalPeriodEndDate = @NextPaymentEndDate
END
ELSE IF @IsAdvance = 0 AND @PaymentType = @UnknownPaymentType
BEGIN
SET @TempDate = @RentalPeriodStartDate
END
ELSE IF @IsAdvance = 0 AND @PaymentType != @UnknownPaymentType AND @TempDate IS NOT NULL
BEGIN
DECLARE @NewTempDate DATE = @RentalPeriodStartDate
SET @RentalPeriodStartDate = @TempDate
SET @TempDate = @NewTempDate
END
END
IF @PaymentType <>  @UnknownPaymentType
BEGIN
INSERT INTO [dbo].[Receivables]
([DueDate]
,[EntityType]
,[IsActive]
,[InvoiceComment]
,[InvoiceReceivableGroupingOption]
,[IsGLPosted]
,[IncomeType]
,[PaymentScheduleId]
,[IsCollected]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[ReceivableCodeId]
,[CustomerId]
,[RemitToId]
,[TaxRemitToId]
,[LocationId]
,[LegalEntityId]
,[EntityId]
,[IsDSL]
,[IsServiced]
,[IsDummy]
,[IsPrivateLabel]
,[FunderId]
,[SourceTable]
,[TotalAmount_Currency]
,[TotalAmount_Amount]
,[TotalEffectiveBalance_Currency]
,[TotalEffectiveBalance_Amount]
,[TotalBalance_Currency]
,[TotalBalance_Amount]
,[TotalBookBalance_Currency]
,[TotalBookBalance_Amount]
,[ExchangeRate]
,[AlternateBillingCurrencyId])
VALUES
(
@DueDate
,@ReceivableEntityType
,1
,'from '+ CONVERT(VARCHAR,@RentalPeriodStartDate,110) + ' to ' + CONVERT(VARCHAR,@RentalPeriodEndDate,110)
,@InvoiceReceivableGroupingOption
,0
,@IncomeType
,@PaymentScheduleId
,@IsCollected
,@CreatedById
,@CreatedTime
,NULL
,NULL
,@ReceivableCodeId
,@CustomerId
,@RemitToId
,@RemitToId
,NULL
,@LegalEntityId
,@ContractId
,@IsDSL
,@IsServiced
,@IsDummy
,@IsPrivateLabel
,NULL
,@SourceTable
,@Currency
,0.0
,@Currency
,0.0
,@Currency
,0.0
,@Currency
,0.0
,@BillingExchangeRate
,@BillingCurrencyId)
SELECT @ReceivableId = Scope_Identity()
END
IF @IsFutureFunding = 1
BEGIN
IF @IsAdvance = 1 AND @NextPaymentType = @UnknownPaymentType
BEGIN
SET @RentalPeriodEndDate = @TempDate
END
ELSE IF @IsAdvance = 0 AND @PaymentType != @UnknownPaymentType AND @TempDate IS NOT NULL
BEGIN
SET @RentalPeriodStartDate = @TempDate
SET @TempDate = NULL
END
END
IF OBJECT_ID('tempdb..#AssetCostTemp') IS NOT NULL
DROP TABLE #AssetCostTemp
SELECT AssetInfo.AssetId,
AssetCostInfo.SumOfAssetLevelRent,
AssetCostInfo.SumOfCustomerCost,
AssetCostInfo.IsDistributeFromCost,
AssetInfo.AssetComponentType
INTO #AssetCostTemp
FROM @AssetSummary AssetInfo
JOIN
(SELECT SUM(AssetDetail.Rent) AS SumOfAssetLevelRent,
SUM(LeaseAssets.CustomerCost_Amount) AS SumOfCustomerCost,
CASE WHEN SUM(AssetDetail.Rent) = 0 THEN 1 ELSE 0 END AS IsDistributeFromCost,
AssetDetail.StartDate,
AssetDetail.EndDate
FROM @AssetSummary AssetDetail
JOIN LeaseAssets ON AssetDetail.AssetId = LeaseAssets.AssetId
WHERE AssetDetail.StartDate <= @RentalPeriodStartDate AND  AssetDetail.EndDate >= @RentalPeriodEndDate
AND LeaseAssets.IsActive = 1
AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId
GROUP BY AssetDetail.StartDate,AssetDetail.EndDate) AS AssetCostInfo
ON AssetInfo.StartDate = AssetCostInfo.StartDate AND AssetInfo.EndDate = AssetCostInfo.EndDate
IF @Amount <> @AssetLevelRent AND @AssetLevelRent <> 0.0
BEGIN
INSERT INTO #ReceivableDetailTemp
(
AssetId,
CalculatedRentalAmount,
AssetComponentType
)
SELECT
AssetDetail.AssetId,
CASE WHEN #AssetCostTemp.IsDistributeFromCost != 1 THEN ROUND((LeaseAssets.Rent_Amount/#AssetCostTemp.SumOfAssetLevelRent) * @Amount,2)
ELSE ROUND((LeaseAssets.CustomerCost_Amount/#AssetCostTemp.SumOfCustomerCost) * @Amount,2) END AS CalculatedRentalAmount,
AssetDetail.AssetComponentType
FROM
LeaseAssets
INNER JOIN Assets
ON LeaseAssets.AssetId = Assets.Id
INNER JOIN @AssetSummary AssetDetail ON Assets.Id = AssetDetail.AssetId
INNER JOIN #AssetCostTemp ON #AssetCostTemp.AssetId = LeaseAssets.AssetId
WHERE
LeaseFinanceId = @LeaseFinanceId AND
LeaseAssets.IsActive = 1 AND
Assets.FinancialType = @FinancialType AND
AssetDetail.StartDate <= @RentalPeriodStartDate AND AssetDetail.EndDate >= @RentalPeriodEndDate AND
(#AssetCostTemp.SumOfAssetLevelRent <> 0 OR #AssetCostTemp.SumOfCustomerCost <> 0)
ORDER BY LeaseAssets.Rent_Amount DESC,LeaseAssets.AssetId
END
ELSE
BEGIN
INSERT INTO #ReceivableDetailTemp
(
AssetId,
CalculatedRentalAmount,
AssetComponentType
)
SELECT
AssetDetail.AssetId,
CASE WHEN #AssetCostTemp.IsDistributeFromCost != 1 THEN ROUND((LeaseAssets.Rent_Amount/#AssetCostTemp.SumOfAssetLevelRent) * @Amount,2)
ELSE ROUND((LeaseAssets.CustomerCost_Amount/#AssetCostTemp.SumOfCustomerCost) * @Amount,2) END AS CalculatedRentalAmount,
AssetDetail.AssetComponentType
FROM
LeaseAssets
INNER JOIN Assets
ON LeaseAssets.AssetId = Assets.Id
INNER JOIN @AssetSummary AssetDetail ON Assets.Id = AssetDetail.AssetId
INNER JOIN #AssetCostTemp ON #AssetCostTemp.AssetId = LeaseAssets.AssetId
WHERE
LeaseFinanceId = @LeaseFinanceId AND
LeaseAssets.IsActive = 1 AND
Assets.FinancialType = @FinancialType AND
AssetDetail.StartDate <= @RentalPeriodStartDate AND AssetDetail.EndDate >= @RentalPeriodEndDate AND
(#AssetCostTemp.SumOfAssetLevelRent <> 0 OR #AssetCostTemp.SumOfCustomerCost <> 0)
ORDER BY LeaseAssets.Rent_Amount DESC,LeaseAssets.AssetId
END
IF (@IsFutureFunding=0 OR ((@IsAdvance=0 AND @PaymentType <> @UnknownPaymentType) OR (@IsAdvance=1 AND (@NextPaymentType IS NULL OR @NextPaymentType!=@UnknownPaymentType))))
BEGIN
SET @Amount = @Amount + @AmountToAdd
SET @AmountToAdd = 0.00
SELECT @AmountAfterDistribution = (SELECT SUM(CalculatedRentalAmount) FROM #ReceivableDetailTemp)
IF((@Amount - @AmountAfterDistribution != 0) AND (@Amount - @AmountAfterDistribution > 0.00))
BEGIN
SET @Difference = (@Amount - @AmountAfterDistribution)/0.01
UPDATE TOP(@Difference) #ReceivableDetailTemp SET CalculatedRentalAmount = CalculatedRentalAmount + 0.01
END
ELSE IF((@Amount - @AmountAfterDistribution != 0) AND (@Amount - @AmountAfterDistribution < 0.00))
BEGIN
SET @Difference = ((@Amount - @AmountAfterDistribution)/0.01) * (-1)
;WITH CTE_Update AS
(
SELECT top(@Difference) * FROM #ReceivableDetailTemp ORDER BY Id
)
UPDATE CTE_Update SET CalculatedRentalAmount = CalculatedRentalAmount - 0.01
END
INSERT INTO [dbo].[ReceivableDetails]
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
,[UpdatedById]
,[UpdatedTime]
,[AssetId]
,[BillToId]
,[AdjustmentBasisReceivableDetailId]
,[ReceivableId]
,[StopInvoicing]
,[EffectiveBookBalance_Amount]
,[EffectiveBookBalance_Currency]
,[AssetComponentType]
,[PreCapitalizationRent_Amount]
,[PreCapitalizationRent_Currency]
)
SELECT
receivableDetailTemp.CalculatedRentalAmount
,@Currency
,receivableDetailTemp.CalculatedRentalAmount
,@Currency
,receivableDetailTemp.CalculatedRentalAmount
,@Currency
,1
,@BilledStatus
,0
,@CreatedById
,@CreatedTime
,NULL
,NULL
,receivableDetailTemp.AssetId
,CASE WHEN @BillToId IS NULL THEN LeaseAsset.BillToId ELSE @BillToId END
,NULL
,@ReceivableId
,0
,0.00
,@Currency
,receivableDetailTemp.AssetComponentType
,0.00
,@Currency
FROM
LeaseAssets LeaseAsset
INNER JOIN #ReceivableDetailTemp receivableDetailTemp ON LeaseAsset.AssetId = receivableDetailTemp.AssetId
WHERE   LeaseAsset.LeaseFinanceId = @LeaseFinanceId
IF EXISTS (SELECT * FROM ReceivableDetails WHERE ReceivableId = @ReceivableId AND IsActive=1)
BEGIN
UPDATE R SET [TotalAmount_Currency] = @Currency,
[TotalBalance_Currency] = @Currency,
[TotalEffectiveBalance_Currency] = @Currency,
[TotalAmount_Amount] = (SELECT SUM(Amount_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = @ReceivableId),
[TotalBalance_Amount] = (SELECT SUM(Balance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = @ReceivableId),
[TotalEffectiveBalance_Amount] = (SELECT SUM(EffectiveBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = @ReceivableId),
[UpdatedById] = @CreatedById,
[UpdatedTime] = @CreatedTime
FROM [Receivables] R WHERE R.Id = @ReceivableId
END
ELSE
BEGIN
UPDATE R SET [TotalAmount_Currency] = @Currency,
[TotalBalance_Currency] = @Currency,
[TotalEffectiveBalance_Currency] = @Currency,
[TotalAmount_Amount] = 0.0,
[TotalBalance_Amount] = 0.0,
[TotalEffectiveBalance_Amount] = 0.0 ,
[UpdatedById] = @CreatedById,
[UpdatedTime] = @CreatedTime
FROM [Receivables] R WHERE R.Id = @ReceivableId
END
DROP TABLE #ReceivableDetailTemp
END
ELSE
SET @AmountToAdd = @Amount
FETCH NEXT FROM PaymentSchedule_Cursor INTO @Amount,@RentalPeriodStartDate,@RentalPeriodEndDate,@DueDate,@PaymentScheduleId,@PaymentType,@NextPaymentType,@NextPaymentEndDate,@BillingExchangeRate,@BillingCurrencyId
END
CLOSE PaymentSchedule_Cursor
DEALLOCATE PaymentSchedule_Cursor
SET NOCOUNT OFF
END

GO
