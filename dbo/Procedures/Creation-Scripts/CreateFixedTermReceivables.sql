SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[CreateFixedTermReceivables]  
(  
@ContractId BIGINT,  
@LeaseFinanceId BIGINT,  
@RentalPeriodBeginDate DATE,  
@MaturityDate DATE,  
@Currency NVARCHAR(3),  
@ReceivableEntityType NVARCHAR(40),  
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
@CreatedTime DATETIMEOFFSET,  
@CreatedById BIGINT,  
@PaymentTypeFixedTerm NVARCHAR(28),  
@PaymentTypeDownPayment NVARCHAR(28),  
@PaymentTypeMaturityPayment NVARCHAR(28),  
@SourceTable NVARCHAR(2),  
@BillToId BIGINT = NULL,  
@NumberOfPayments INT,
@IsRegularLease BIT,
@TaxSourceType_SalesTax NVARCHAR(10),
@TaxSourceDetails TaxSourceDetailInfo READONLY,
@AssetLevelInformations AssetLevelInformation READONLY,  
@AlternateBillingCurrencyDetails AlternateBillingCurrencyDetails READONLY,  
@AssetSKULevelDistributionFactor AssetSKULevelDistributionFactor READONLY,
@AssetTrueDownpaymentDistribution AssetTrueDownpaymentDistribution READONLY,
@IsArrearAndVATApplicable BIT,
@OldReceivableInfo LeaseReceivableInfo READONLY
)  
AS
BEGIN
SET NOCOUNT ON;
DECLARE @RoundingValue DECIMAL(16,2) = 0.01;

SELECT * INTO #AssetSKULevelDistributionFactor FROM @AssetSKULevelDistributionFactor

CREATE INDEX IX_AssetId ON #AssetSKULevelDistributionFactor(AssetId, AssetSKUId)

SELECT * INTO #AssetLevelInformations FROM @AssetLevelInformations

CREATE INDEX IX_AssetId ON #AssetLevelInformations(AssetId)

SELECT * INTO #AssetTrueDownpaymentDistribution FROM @AssetTrueDownpaymentDistribution

CREATE TABLE #ReceivableTemp  
(  
	ReceivableId BIGINT,  
	TotalAmount_Amount DECIMAL(16,2) not null,  
	PaymentScheduleId BIGINT not null,
	PaymentType NVARCHAR(28) not null,
	StartDate DATETIME not null,
	TotalAssetRentOrCustomerCost Decimal(16,2) not null,
	TotalAmountOfPaidOffAssets DECIMAL(16,2) not null,
) 

CREATE TABLE #ReceivableDetailsComponent
(
	LeaseComponentAmount     DECIMAL(16, 2), 
	NonLeaseComponentAmount  DECIMAL(16, 2), 
	ReceivableId       BIGINT not null,
	AssetId bigint not null
)

CREATE TABLE #RDetailOutput
(
	Id				BIGINT NOT NULL,
	ReceivableId    BIGINT NOT NULL,
	AssetId			BIGINT NOT NULL,
	Amount_Amount	DECIMAL(16,2)
)

CREATE TABLE #RSKUs 
(
	[Amount_Amount]		[decimal](16, 2) NOT NULL,	
	[AssetSKUId]		[bigint] NULL,  
	[ReceivableId]		[bigint] NOT NULL,  
	[AssetId]			[bigint] NULL,
	[PreCapitalizationRent]		[decimal](16, 2) NOT NULL
)
  
CREATE TABLE #GroupedPaidOffReceivables
(
	StartDate DATE,
	Amount DECIMAL(16,2) not null
);
  
DECLARE @IsReceivableDueOnCommencement BIT =
			(SELECT
				CASE WHEN @MaturityDate = (SELECT CommencementDate FROM LeaseFinanceDetails WHERE Id = @LeaseFinanceId)
				THEN 1 
				ELSE 0
			END)
SELECT Amount_Amount,StartDate,EndDate,DueDate,Id,BillingCurrencyId,BillingExchangeRate,PaymentType, TaxSourceDetailId, DealCountryId, ISNULL(TaxSourceType, @TaxSourceType_SalesTax) TaxSourceType INTO #ReceivablesData
 FROM LeasePaymentSchedules 
 JOIN @AlternateBillingCurrencyDetails billingcurrency ON LeasePaymentSchedules.Id = billingcurrency.LeasePaymentScheduleId  
 LEFT JOIN @TaxSourceDetails TaxSourceDetail ON LeasePaymentSchedules.Id = TaxSourceDetail.LeasePaymentScheduleId
 WHERE LeaseFinanceDetailId = @LeaseFinanceId AND IsActive = 1   
 AND 
		((@IsArrearAndVATApplicable = 0 AND StartDate BETWEEN @RentalPeriodBeginDate AND @MaturityDate )
		OR 
		(@IsArrearAndVATApplicable = 1 AND @IsReceivableDueOnCommencement = 1 AND EndDate <= @MaturityDate)
		OR
		(@IsArrearAndVATApplicable = 1 AND @IsReceivableDueOnCommencement = 0 AND EndDate > @RentalPeriodBeginDate))
		AND (PaymentType = @PaymentTypeFixedTerm OR PaymentType = @PaymentTypeDownPayment OR PaymentType = @PaymentTypeMaturityPayment)
 
  
MERGE INTO [dbo].[Receivables]  
USING(
SELECT  Amount_Amount,StartDate,EndDate,DueDate,Id,BillingCurrencyId,BillingExchangeRate,PaymentType, TaxSourceDetailId, DealCountryId, TaxSourceType FROM #ReceivablesData
)  
AS LPS ON 1=0  
WHEN NOT MATCHED THEN  
INSERT   
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
,[AlternateBillingCurrencyId]
,[ReceivableTaxType]  
,[DealCountryId]  
,[TaxSourceDetailId])  
VALUES  
(  
LPS.DueDate  
,@ReceivableEntityType  
,1  
,'from '+ CONVERT(VARCHAR,LPS.StartDate,110) + ' to ' + CONVERT(VARCHAR,LPS.EndDate,110)  
,@InvoiceReceivableGroupingOption  
,0  
,@IncomeType  
,LPS.Id  
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
,LPS.Amount_Amount  
,@Currency  
,LPS.Amount_Amount  
,@Currency  
,LPS.Amount_Amount  
,@Currency  
,0.0  
,LPS.BillingExchangeRate  
,LPS.BillingCurrencyId
,LPS.TaxSourceType
,LPS.DealCountryId
,LPS.TaxSourceDetailId)
OUTPUT INSERTED.Id, LPS.Amount_Amount, LPS.Id, LPS.PaymentType, LPS.StartDate, 0.00 as TotalAssetRentOrCustomerCost, 0.00 as TotalAmountOfPaidOffAssets INTO #ReceivableTemp;  
  
SELECT 
 ALI.AssetRentOrCustomerCost
,ALI.AssetId
,R.ReceivableId
,ALI.TerminationDate
Into #AssetLevelRentForEachReceivable
FROM
#AssetLevelInformations ALI
JOIN #ReceivableTemp R ON ALI.AssetInLeaseDate <= R.StartDate AND (ALI.TerminationDate Is NULL OR ALI.TerminationDate > R.StartDate)

UPDATE #ReceivableTemp
SET TotalAssetRentOrCustomerCost = groupedReceivables.TotalAssetRentOrCustomerCost
FROM #ReceivableTemp R 
JOIN (SELECT ReceivableId, SUM(AssetRentOrCustomerCost) as TotalAssetRentOrCustomerCost FROM #AssetLevelRentForEachReceivable WHERE TerminationDate Is NULL GROUP BY ReceivableId) as groupedReceivables ON R.ReceivableId = groupedReceivables.ReceivableId

UPDATE #ReceivableTemp
SET TotalAmountOfPaidOffAssets = groupedReceivables.TotalAmount
FROM #ReceivableTemp R 
JOIN (SELECT StartDate, Sum(Amount) as TotalAmount From @OldReceivableInfo ORI GROUP By StartDate) as groupedReceivables ON R.StartDate = groupedReceivables.StartDate


INSERT INTO #GroupedPaidOffReceivables 
SELECT StartDate, Sum(Amount) as Amount 
FROM @OldReceivableInfo 
GROUP BY StartDate;

SELECT
CASE WHEN R.PaymentType = @PaymentTypeMaturityPayment THEN ROUND(LA.MaturityPayment, 2) 
	 WHEN R.TotalAssetRentOrCustomerCost <> 0.00 THEN ( CASE WHEN ORI.Amount Is NULL THEN ROUND(R.TotalAmount_Amount * (CAST (ALR.AssetRentOrCustomerCost AS DECIMAL(38,30))/R.TotalAssetRentOrCustomerCost), 2) 
														     ELSE ROUND((R.TotalAmount_Amount - ORI.Amount) * (CAST (ALR.AssetRentOrCustomerCost AS DECIMAL(38,30))/R.TotalAssetRentOrCustomerCost), 2) END)
	 ELSE 0.00 END as [Amount_Amount]
,LA.AssetId
,CASE WHEN @BillToId IS NULL THEN LA.BillToId ELSE @BillToId END as BillToId
,R.ReceivableId
,LA.AssetComponentType
,[TotalAmount_Amount] AS NonLeaseComponentAmount
, [TotalAmount_Amount] AS LeaseComponentAmount
,LA.PreCapitalizationRent
into #RDetails
FROM
#AssetLevelInformations LA
JOIN #AssetLevelRentForEachReceivable ALR ON LA.AssetId = ALR.AssetId
JOIN #ReceivableTemp R ON ALR.ReceivableId = R.ReceivableId
LEFT JOIN #GroupedPaidOffReceivables ORI ON R.StartDate = ORI.StartDate


UPDATE 
	#RDetails
	SET Amount_Amount = DownPaymentDistribution.TrueDownPayment
FROM #RDetails
INNER JOIN #ReceivableTemp ON #RDetails.ReceivableId = #ReceivableTemp.ReceivableId
AND #ReceivableTemp.PaymentType = @PaymentTypeDownPayment
INNER JOIN #AssetTrueDownpaymentDistribution DownPaymentDistribution
ON #RDetails.AssetId = DownPaymentDistribution.AssetId

DECLARE @RoundingFactor BIGINT = CASE WHEN @Currency = 'JPY' THEN 0 ELSE 2 END; 

If(@Currency <> 'JPY')
BEGIN  
	UPDATE #RDetails
	SET Amount_Amount = Amount_Amount + RoundingValue
	FROM #RDetails RD
	JOIN #AssetLevelInformations LA ON RD.AssetId = LA.AssetId
	JOIN (SELECT #ReceivableTemp.ReceivableId,(#ReceivableTemp.TotalAmount_Amount - #ReceivableTemp.TotalAmountOfPaidOffAssets - SUM(Amount_Amount)) DifferenceAfterDistribution, CASE WHEN (#ReceivableTemp.TotalAmount_Amount - #ReceivableTemp.TotalAmountOfPaidOffAssets - SUM(Amount_Amount)) < 0 THEN -(@RoundingValue) ELSE @RoundingValue END AS RoundingValue
	FROM #ReceivableTemp
	JOIN #RDetails RD ON #ReceivableTemp.ReceivableId = RD.ReceivableId
	JOIN #AssetLevelInformations LA ON RD.AssetId = LA.AssetId
	WHERE LA.TerminationDate Is NULL
	GROUP BY #ReceivableTemp.ReceivableId,#ReceivableTemp.TotalAmount_Amount, #ReceivableTemp.TotalAmountOfPaidOffAssets
	HAVING (#ReceivableTemp.TotalAmount_Amount - #ReceivableTemp.TotalAmountOfPaidOffAssets) <> SUM(Amount_Amount))
	AS AppliedRD ON RD.ReceivableId = AppliedRD.ReceivableId
	AND LA.RowNumber <= CAST(AppliedRD.DifferenceAfterDistribution/RoundingValue AS BIGINT)
	WHERE LA.TerminationDate Is NULL

	UPDATE #RDetails
	SET Amount_Amount = ORI.Amount
	FROM #RDetails RD
	JOIN #AssetLevelInformations LA ON RD.AssetId = LA.AssetId
	JOIN #ReceivableTemp R ON RD.ReceivableId = R.ReceivableId
    JOIN @OldReceivableInfo ORI ON R.StartDate = ORI.StartDate AND RD.AssetId = ORI.AssetId
	WHERE LA.TerminationDate Is NOT NULL
END

INSERT INTO #RSKUs 
([Amount_Amount], [AssetSKUId],[ReceivableId], [AssetId], [PreCapitalizationRent])
SELECT CASE
			WHEN R.PaymentType = @PaymentTypeMaturityPayment
			THEN ROUND(LAS.MaturityPayment, 2)
			ELSE ROUND(RD.Amount_Amount * LAS.Factor, 2)
		END
		, LAS.AssetSKUId
		, RD.ReceivableId
		, RD.AssetId
		, LAS.PreCapitalizationRent
FROM #AssetSKULevelDistributionFactor LAS
		JOIN #RDetails RD ON LAS.AssetId = RD.AssetId
		JOIN #ReceivableTemp R ON RD.ReceivableId = R.ReceivableId

--TODO: Change JPY hardcoding to a parameter list of currencies
If(@Currency <> 'JPY')
BEGIN
	UPDATE #RSKUs
	SET Amount_Amount = Amount_Amount + RoundingValue
	FROM #RSKUs
	JOIN #AssetSKULevelDistributionFactor LAS ON #RSKUs.AssetSKUId = LAS.AssetSKUId 
	JOIN (
			SELECT (RD.Amount_Amount - SUM(S.Amount_Amount)) DifferenceAfterDistribution, 
			CASE WHEN (RD.Amount_Amount - SUM(S.Amount_Amount)) < 0 THEN -(@RoundingValue) ELSE @RoundingValue END AS RoundingValue
			,RD.ReceivableId
			,RD.AssetId
			FROM #RDetails RD
			JOIN #RSKUs S ON RD.ReceivableId = S.ReceivableId
			AND RD.AssetId=S.AssetId
			GROUP BY RD.ReceivableId,RD.Amount_Amount,RD.AssetId
			HAVING RD.Amount_Amount <> SUM(S.Amount_Amount)
		) AS AppliedRSKU
		ON #RSKUs.ReceivableId = AppliedRSKU.ReceivableId and #RSKUs.AssetId=AppliedRSKU.AssetId
	WHERE  LAS.RowNumber <= CAST(AppliedRSKU.DifferenceAfterDistribution/RoundingValue AS BIGINT)
END

INSERT INTO #ReceivableDetailsComponent
	SELECT CASE
				WHEN la.IsLeaseAsset = 1 THEN trd.Amount_Amount
				ELSE 0.00
			END AS LeaseComponentAmount
			, CASE
				WHEN la.IsLeaseAsset = 0 THEN trd.Amount_Amount
				ELSE 0.00
			END AS NonLeaseComponentAmount
			,trd.ReceivableId
			,trd.AssetId
	FROM 
			#RDetails trd 
			INNER JOIN #AssetLevelInformations la ON  trd.AssetId = la.AssetId
			WHERE la.HasSku = 0
	UNION All
	SELECT SUM(CASE WHEN las.IsLeaseComponent = 1 THEN rs.Amount_Amount
					ELSE 0.00
				END) AS LeaseComponentAmount
			, SUM(CASE
					WHEN las.IsLeaseComponent = 0 THEN rs.Amount_Amount
					ELSE 0.00
				END) AS  NonLeaseComponentAmount
			, trd.ReceivableId
			,trd.AssetId
		FROM #RDetails trd
			INNER JOIN #RSKUs rs on trd.ReceivableId = rs.ReceivableId and trd.AssetId=rs.AssetId
			INNER JOIN #AssetSKULevelDistributionFactor las ON trd.AssetId = las.AssetId 
				AND rs.AssetSKUId = las.AssetSKUId
	GROUP BY trd.ReceivableId
			, trd.AssetId

UPDATE #RDetails
	SET NonLeaseComponentAmount = rdc.NonLeaseComponentAmount
	, LeaseComponentAmount = rdc.LeaseComponentAmount
	, Amount_Amount= rdc.LeaseComponentAmount+rdc.NonLeaseComponentAmount
FROM #RDetails rd 
		INNER JOIN #ReceivableDetailsComponent rdc ON rd.ReceivableId = rdc.ReceivableId
		and rd.AssetId=rdc.AssetId

INSERT INTO dbo.ReceivableDetails
(
	 Amount_Amount
	, Amount_Currency
	, Balance_Amount
	, Balance_Currency
	, EffectiveBalance_Amount
	, EffectiveBalance_Currency
	, IsActive
	, BilledStatus
	, IsTaxAssessed
	, CreatedById
	, CreatedTime
	, AssetId
	, BillToId
	, ReceivableId
	, StopInvoicing
	, EffectiveBookBalance_Amount
	, EffectiveBookBalance_Currency
	, AssetComponentType
	, LeaseComponentAmount_Amount
	, LeaseComponentAmount_Currency
	, NonLeaseComponentAmount_Amount
	, NonLeaseComponentAmount_Currency
	, LeaseComponentBalance_Amount
	, LeaseComponentBalance_Currency
	, NonLeaseComponentBalance_Amount
	, NonLeaseComponentBalance_Currency
	, PreCapitalizationRent_Amount
	, PreCapitalizationRent_Currency
)
OUTPUT INSERTED.Id,INSERTED.ReceivableId, inserted.AssetId, inserted.Amount_Amount INTO #RDetailOutput
SELECT
		Amount_Amount
	, @Currency
	, Amount_Amount
	, @Currency
	, Amount_Amount
	, @Currency
	, 1
	, @BilledStatus
	, 0
	, @CreatedById
	, @CreatedTime
	, AssetId
	, BillToId
	, ReceivableId
	, 0
	, 0
	, @Currency
	, AssetComponentType
	, LeaseComponentAmount
	, @Currency
	, NonLeaseComponentAmount
	, @Currency
	, LeaseComponentAmount
	, @Currency
	, NonLeaseComponentAmount
	, @Currency
	, CASE WHEN (@IsRegularLease = 1) THEN ROUND(PreCapitalizationRent / @NumberOfPayments, 2) ELSE Amount_Amount END PreCapitalizationRent
	, @Currency
FROM #RDetails
ORDER BY Receivableid,AssetId

CREATE UNIQUE CLUSTERED INDEX IX ON #RDetailOutput (ReceivableId,AssetId);

INSERT INTO dbo.ReceivableSKUs
(
	  Amount_Amount
	, Amount_Currency
	, CreatedById
	, CreatedTime
	, AssetSKUId
	, ReceivableDetailId
	, PreCapitalizationRent_Amount
	, PreCapitalizationRent_Currency
)
SELECT S.Amount_Amount
		, @Currency
		, @CreatedById
		, @CreatedTime
		, S.AssetSKUId
		, D.Id
		, CASE WHEN (@IsRegularLease = 1) THEN ROUND(S.PreCapitalizationRent / @NumberOfPayments, 2) ELSE S.Amount_Amount END PreCapitalizationRent
		, @Currency
FROM #RSKUs S join #RDetailOutput D on 
S.ReceivableId=D.ReceivableId and S.AssetId=D.AssetId

END

GO
