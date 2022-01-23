SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GenerateStatementInvoices] 
(
	@ProcessThroughDate DATETIME
	,@ContractID BIGINT 
	,@DiscountingID BIGINT 
	,@RunTimeComment NVARCHAR(MAX) 
	,@IsAllDiscounting BIT 
	,@IsAllLease BIT
	,@IsAllLoan BIT
	,@IsAllLeveragedLease BIT
	,@InvoiceType NVARCHAR(100)
	,@JobStepInstanceId BIGINT
	,@CreatedBy BIGINT
	,@CreatedTime DATETIMEOFFSET
	,@IsInvoiceSensitive BIT 
	,@InvoicePreference NVARCHAR(MAX)
	,@CustomerDetailsForStatement CustomerDetails READONLY
	,@ComputedProcessThroughDate ComputedProcessThroughDate READONLY
	,@StatementInvoiceCount INT OUTPUT
)
AS
SET NOCOUNT ON;

--DECLARE
--	@ProcessThroughDate DATETIME = '09/01/2019'--SYSDATETIMEOFFSET()
--	,@ContractID BIGINT = 3266
--	,@DiscountingID BIGINT = NULL
--	,@RunTimeComment NVARCHAR(MAX) = NULL
--	,@IsAllDiscounting BIT = 0
--	,@IsAllLease BIT = 0
--	,@IsAllLoan BIT = 0
--	,@IsAllLeveragedLease BIT = 0
--	,@InvoiceType NVARCHAR(100) = '_'
--	,@JobStepInstanceId BIGINT = 21170
--	,@CreatedBy BIGINT = 40043
--	,@CreatedTime DATETIMEOFFSET = SysDateTimeOffset()
--	,@IsInvoiceSensitive BIT = 0
--	,@InvoicePreference NVARCHAR(MAX) = 'GenerateAndDeliver'
--	,@CustomerDetailsForStatement CustomerDetails
--,@ComputedProcessThroughDate ComputedProcessThroughDate
/*Current Receivable Invoice genereated */

SELECT CustomerDetailsForStatement.* INTO #CustomerDetailsForStatement FROM @CustomerDetailsForStatement CustomerDetailsForStatement

CREATE TABLE #ReceivableDetailsForStatement(
		ReceivableInvoiceId BIGINT
		,ReceivableDetailId BIGINT
		,EntityId BIGINT
		,EntityType NVARCHAR(4)
		,DueDate DATETIME
		,ReceivableInvoiceDueDate DATETIME
		,BillToId BIGINT
		,CustomerId BIGINT
		,StatementInvoicePreference NVARCHAR(50)
		,RemitToId BIGINT
		,LegalEntityId BIGINT
		,CurrencyId BIGINT
		,IsPrivateLabel BIT
		,IsDSL BIT
		,AlternateBillingCurrencyId BIGINT
		,JobStepInstanceId BIGINT
		,LastStatementGeneratedDueDate DATETIME
		,SplitByContract BIT
		,ReceivableCodeId BIGINT
		,AssetId BIGINT
		,AdjustmentBasisReceivableDetailId BIGINT
		,ExchangeRate DECIMAL(18, 2)
		,InvoiceTransitDays INT
		,InvoiceLeadDays INT
		,WithHoldingTaxAmount DECIMAL(18, 2)
		,WithHoldingTaxBalance DECIMAL(18, 2)
		)

CREATE NONCLUSTERED INDEX [IX_ReceivableInvoiceId] ON [dbo].[#ReceivableDetailsForStatement] ([ReceivableInvoiceId]) 
 
CREATE NONCLUSTERED INDEX [IX_ReceivableDetailId] ON [dbo].[#ReceivableDetailsForStatement] ([ReceivableDetailId]) 

CREATE TABLE #ParameterDetailsToFetchInvoice(
		ReceivableInvoiceId BIGINT
		,CalculatedDueDate DATETIME
		,BillToId BIGINT
		,CustomerId BIGINT
		,StatementInvoicePreference NVARCHAR(50)
		,RemitToId BIGINT
		,LegalEntityId BIGINT
		,CurrencyId BIGINT
		,IsPrivateLabel BIT
		,IsDSL BIT
		,AlternateBillingCurrencyId BIGINT
		,IsOffPeriod BIT
		)

CREATE TABLE #ReceivableInvoiceDetailsInfo(
		Number NVARCHAR(100)
		,ReceivableInvoiceId BIGINT
		,ReceivableInvoiceDueDate DATETIME
		,SplitByContract BIT
		,SplitByLocation BIT
		,SplitByAsset BIT
		,SplitCreditsByOriginalInvoice BIT
		,SplitByReceivableAdj BIT
		,GenerateSummaryInvoice BIT
		,ReceivableDetailId BIGINT
		,CustomerId BIGINT
		,BillToId BIGINT
		,RemitToId BIGINT
		,LegalEntityId BIGINT
		,ReceivableCategoryId BIGINT
		,CurrencyId BIGINT
		,InvoiceDetailAmount DECIMAL(18, 2)
		,InvoiceDetailBalance DECIMAL(18, 2)
		,InvoiceDetailEffectiveBalance DECIMAL(18, 2)
		,InvoiceDetailTaxAmount DECIMAL(18, 2)
		,InvoiceDetailTaxBalance DECIMAL(18, 2)
		,InvoiceDetailEffectiveTaxBalance DECIMAL(18, 2)
		,CurrencyISO NVARCHAR(80)
		,StatementInvoicePreference NVARCHAR(80)
		,IsPrivateLabel BIT
		,OriginationSource NVARCHAR(50)
		,OriginationSourceId BIGINT
		,IsACH BIT
		,AlternateBillingCurrencyId BIGINT
		,LastStatementGeneratedDueDate DATE
		,JobStepInstanceId BIGINT
		,InvoiceTransitDays INT
		,InvoiceLeadDays INT
		)

CREATE NONCLUSTERED INDEX [IX_ReceivableInvoiceId] ON [dbo].[#ReceivableInvoiceDetailsInfo] ([ReceivableInvoiceId]) 

CREATE NONCLUSTERED INDEX [ReceivableDetailId] ON [dbo].[#ReceivableInvoiceDetailsInfo] ([ReceivableDetailId]) 

CREATE TABLE #ReceivableInvoiceForStatement(
		Number NVARCHAR(100)
		,ReceivableInvoiceId BIGINT
		,ReceivableInvoiceDueDate DATETIME
		,SplitByContract BIT
		,SplitByLocation BIT
		,SplitByAsset BIT
		,SplitCreditsByOriginalInvoice BIT
		,SplitByReceivableAdj BIT
		,DefaultInvoiceReceivableGroupingOption NVARCHAR(100)
		,IsReceivableAdjustment BIT
		,GenerateSummaryInvoice BIT
		,ReceivableDetailId BIGINT
		,CustomerId BIGINT
		,ContractId BIGINT
		,DiscountingId BIGINT
		,BillToId BIGINT
		,RemitToId BIGINT
		,LegalEntityId BIGINT
		,ReceivableCategoryId BIGINT
		,ReportFormatId BIGINT
		,CurrencyId BIGINT
		,InvoiceDetailAmount DECIMAL(18, 2)
		,InvoiceDetailBalance DECIMAL(18, 2)
		,InvoiceDetailEffectiveBalance DECIMAL(18, 2)
		,InvoiceDetailTaxAmount DECIMAL(18, 2)
		,InvoiceDetailTaxBalance DECIMAL(18, 2)
		,InvoiceDetailEffectiveTaxBalance DECIMAL(18, 2)
		,CurrencyISO NVARCHAR(80)
		,StatementInvoicePreference NVARCHAR(80)
		,AssetID BIGINT
		,LocationID BIGINT
		,IsPrivateLabel BIT
		,OriginationSource NVARCHAR(50)
		,OriginationSourceId BIGINT
		,IsDSL BIT
		,IsACH BIT
		,IsRental BIT
		,EntityType NVARCHAR(MAX)
		,ExchangeRate DECIMAL(20,10)
		,AdjustmentBasisReceivableDetailId BIGINT
		,AlternateBillingCurrencyId BIGINT
		,IsPrimaryInvoice BIT
		,LastStatementGeneratedDueDate DATE
		,DueDay INT
		,StatementFrequency NVARCHAR(100)
		,GenerateStatementInvoice BIT
		,IsOffPeriod BIT
		,IsNeitherOnNorOffPeriod BIT
		,WithHoldingTaxAmount DECIMAL(18, 2)
		,WithHoldingTaxBalance DECIMAL(18, 2)
		)

CREATE TABLE #StatementInvoice (
		Number NVARCHAR(100)
		,ReceivableInvoiceId BIGINT
		,ReceivableInvoiceDueDate DATETIME
		,DueDate DATETIME
		,SplitByContract BIT
		,SplitByLocation BIT
		,SplitByAsset BIT
		,SplitCreditsByOriginalInvoice BIT
		,SplitByReceivableAdj BIT
		,GenerateSummaryInvoice BIT
		,CustomerId BIGINT
		,BillTo BIGINT
		,RemitToId BIGINT
		,LegalEntityId BIGINT
		,ReceivableCategoryId BIGINT
		,ReportFormatId BIGINT
		,CurrencyId BIGINT
		,ReceivableDetailId BIGINT
		,OriginalTaxBalance DECIMAL(18, 2)
		,OriginalEffectiveTaxBalance DECIMAL(18, 2)
		,OriginalTaxAmount DECIMAL(18, 2)
		,ReceivableDetailAmount DECIMAL(18, 2)
		,ReceivableDetailBalance DECIMAL(18, 2)
		,ReceivableDetailEffectiveBalance DECIMAL(18, 2)
		,CurrencyISO NVARCHAR(80)
		,StatementInvoicePreference NVARCHAR(80)
		,EntityType NVARCHAR(MAX)
		,EntityId BIGINT
		,IsPrivateLabel BIT
		,OriginationSource NVARCHAR(50)
		,OriginationSourceId BIGINT
		,IsDSL BIT
		,IsACH BIT
		,IsRental BIT
		,ExchangeRate DECIMAL(20,10)
		,AlternateBillingCurrencyId BIGINT
		,IsPrimaryInvoice BIT
		,LastStatementGeneratedDueDate DATE
		,IsOffPeriod BIT
		,WithHoldingTaxAmount DECIMAL(18, 2)
		,WithHoldingTaxBalance DECIMAL(18, 2)
		)

CREATE TABLE #StatementInvoiceNumberGenerator(
		SequenceGeneratedInvoiceNumber NVARCHAR(100)
		,InvoiceRankValue NVARCHAR(100)
		)

CREATE TABLE #InsertedStatementInvoice(
	 	Id BIGINT NOT NULL
		,InvoiceNumber NVARCHAR(100)
		)

CREATE TABLE #ComputedProcessThroughDateDetails(
		EntityId BIGINT
		,EntityType NVARCHAR(2)
		,CustomerId BIGINT
		,ReceivableInvoiceId BIGINT
		,ReceivableInvoiceDueDate DATE
		,LastStatementGeneratedDueDate DATE
		,StatementDueDay INT
		,ComputedProcessThroughDate DATE
		,StatementFrequency INT
		)

CREATE TABLE #NextPossibleStatementGenerationDueDates(
		NextPossibleStatementGenerationDueDate DATE,
		StatementDueDay INT,
		ReceivableInvoiceId BIGINT
		)

INSERT INTO #ReceivableInvoiceDetailsInfo
(
	Number
	,ReceivableInvoiceId 
	,ReceivableInvoiceDueDate 
	,SplitByContract 
	,SplitByLocation 
	,SplitByAsset 
	,SplitCreditsByOriginalInvoice 
	,SplitByReceivableAdj 
	,GenerateSummaryInvoice 
	,ReceivableDetailId 
	,CustomerId 
	,BillToId 
	,RemitToId 
	,LegalEntityId 
	,ReceivableCategoryId 
	,CurrencyId 
	,InvoiceDetailAmount
	,InvoiceDetailBalance
	,InvoiceDetailEffectiveBalance
	,InvoiceDetailTaxAmount
	,InvoiceDetailTaxBalance
	,InvoiceDetailEffectiveTaxBalance
	,CurrencyISO
	,StatementInvoicePreference
	,IsPrivateLabel 
	,OriginationSource 
	,OriginationSourceId 
	,IsACH 
	,AlternateBillingCurrencyId 
	,LastStatementGeneratedDueDate 
	,JobStepInstanceId
	,InvoiceTransitDays 
	,InvoiceLeadDays 
)
SELECT
	RI.Number 
	,RI.Id
	,RI.DueDate 
	,RI.SplitByContract 
	,RI.SplitByLocation 
	,RI.SplitByAsset 
	,RI.SplitCreditsByOriginalInvoice 
	,RI.SplitByReceivableAdj 
	,RI.GenerateSummaryInvoice 
	,RID.ReceivableDetailId
	,RI.CustomerId 
	,RI.BillToId 
	,RI.RemitToId 
	,RI.LegalEntityId 
	,RI.ReceivableCategoryId 
	,RI.CurrencyId
	,RID.InvoiceAmount_Amount
	,RID.Balance_Amount
	,RID.EffectiveBalance_Amount 
	,RID.InvoiceTaxAmount_Amount 
	,RID.TaxBalance_Amount 
	,RID.EffectiveTaxBalance_Amount
	,RID.InvoiceAmount_Currency 
	,RI.StatementInvoicePreference
	,RI.IsPrivateLabel 
	,RI.OriginationSource 
	,RI.OriginationSourceId 
	,RI.IsACH 
	,RI.AlternateBillingCurrencyId
	,RI.LastStatementGeneratedDueDate
	,RI.JobStepInstanceId
	,CustomerDetailsForStatement.InvoiceTransitDays
	,CustomerDetailsForStatement.InvoiceLeadDays
FROM #CustomerDetailsForStatement CustomerDetailsForStatement
	JOIN ReceivableInvoices RI ON CustomerDetailsForStatement.CustomerID = RI.CustomerId
	JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
	where (RID.EffectiveBalance_Amount != 0 OR RID.EffectiveTaxBalance_Amount != 0)
	AND RI.IsActive = 1 
	AND RID.IsActive = 1

INSERT INTO #ReceivableDetailsForStatement
(
	ReceivableInvoiceId
	,ReceivableDetailId
	,EntityId
	,EntityType
	,DueDate
	,ReceivableInvoiceDueDate
	,BillToID 
	,CustomerId 
	,StatementInvoicePreference
	,RemitToId 
	,LegalEntityId 
	,CurrencyId 
	,IsPrivateLabel 
	,IsDSL
	,AlternateBillingCurrencyId 
	,AdjustmentBasisReceivableDetailId
	,LastStatementGeneratedDueDate
	,JobStepInstanceId
	,SplitByContract
	,ReceivableCodeId
	,AssetId
	,ExchangeRate
	,InvoiceTransitDays
	,InvoiceLeadDays
	,WithHoldingTaxAmount
	,WithHoldingTaxBalance
)
SELECT 
	 RI.ReceivableInvoiceId
	,RD.Id
	,R.EntityId
	,R.EntityType
	,R.DueDate
	,RI.ReceivableInvoiceDueDate
	,RI.BillToId
	,RI.CustomerId
	,RI.StatementInvoicePreference
	,RI.RemitToId
	,RI.LegalEntityId
	,RI.CurrencyId
	,RI.IsPrivateLabel
	,R.IsDSL
	,RI.AlternateBillingCurrencyId
	,RD.AdjustmentBasisReceivableDetailId
	,RI.LastStatementGeneratedDueDate
	,RI.JobStepInstanceId
	,RI.SplitByContract
	,R.ReceivableCodeId
	,RD.AssetId
	,R.ExchangeRate
	,RI.InvoiceTransitDays
	,RI.InvoiceLeadDays
	,ISNULL(RDWTD.Tax_Amount, 0)
	,ISNULL(RDWTD.Balance_Amount, 0)
FROM #ReceivableInvoiceDetailsInfo RI
	INNER JOIN ReceivableDetails RD ON RI.ReceivableDetailId = RD.Id
	INNER JOIN Receivables R ON RD.ReceivableId = R.Id	
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWTD ON RDWTD.ReceivableDetailId = RD.Id AND RDWTD.IsActive = 1
	
/*Fetching Invoices generated from current instance */
INSERT INTO #ParameterDetailsToFetchInvoice(
	ReceivableInvoiceId
	,CalculatedDueDate
	,BillToID 
	,CustomerId 
	,StatementInvoicePreference
	,RemitToId 
	,LegalEntityId 
	,CurrencyId 
	,IsPrivateLabel 
	,IsDSL
	,AlternateBillingCurrencyId 
	,IsOffPeriod)
SELECT 
	 RDS.ReceivableInvoiceId
	,RDS.DueDate
	,RDS.BillToId
	,RDS.CustomerId
	,RDS.StatementInvoicePreference
	,RDS.RemitToId
	,RDS.LegalEntityId
	,RDS.CurrencyId
	,RDS.IsPrivateLabel
	,RDS.IsDSL
	,RDS.AlternateBillingCurrencyId
	,0
FROM #ReceivableDetailsForStatement RDS
WHERE RDS.JobStepInstanceId = @JobStepInstanceId
GROUP BY 
	 RDS.ReceivableInvoiceId
	,RDS.DueDate
	,RDS.BillToId
	,RDS.CustomerId
	,RDS.StatementInvoicePreference
	,RDS.RemitToId
	,RDS.LegalEntityId
	,RDS.CurrencyId
	,RDS.IsPrivateLabel
	,RDS.IsDSL
	,RDS.AlternateBillingCurrencyId


/*Off period statement invoice*/
INSERT INTO #ComputedProcessThroughDateDetails
(EntityId
,EntityType
,CustomerId
,ReceivableInvoiceId
,ReceivableInvoiceDueDate
,LastStatementGeneratedDueDate
,ComputedProcessThroughDate
,StatementDueDay
,StatementFrequency)
SELECT 
		ComputedProcessThroughDate.EntityId
		,ComputedProcessThroughDate.EntityType
		,ComputedProcessThroughDate.CustomerId
		,RDS.ReceivableInvoiceId
		,CASE WHEN RDS.DueDate != RDS.ReceivableInvoiceDueDate
			  THEN DATEADD(DAY,0-RDS.InvoiceTransitDays,RDS.ReceivableInvoiceDueDate)
			  ELSE RDS.ReceivableInvoiceDueDate
			  END AS ReceivableInvoiceDueDate
		,RDS.LastStatementGeneratedDueDate
		,CASE WHEN RDS.SplitByContract = 1 OR @IsInvoiceSensitive = 0
			THEN ComputedProcessThroughDate
			ELSE DATEADD(Day,RDS.InvoiceLeadDays - ComputedProcessThroughDate.LeadDays,ComputedProcessThroughDate)
		END AS ComputedProcessThroughDate
		,CASE WHEN RDS.SplitByContract = 1 AND ComputedProcessThroughDate.EntityType = 'CT' 
					AND ComputedProcessThroughDate.DueDay != 0
			  THEN ComputedProcessThroughDate.DueDay
			  ELSE BT.StatementDueDay
		END AS StatementDueDay
		,CASE 
			WHEN BT.StatementFrequency = 'Monthly' THEN 1
			WHEN BT.StatementFrequency = 'Quarterly' THEN 3
			WHEN BT.StatementFrequency = 'HalfYearly' THEN 6
			WHEN BT.StatementFrequency = 'Yearly' THEN 12
			ELSE 1
		END StatementFrequency
FROM #ReceivableDetailsForStatement RDS
JOIN BillToes BT ON BT.Id = RDS.BillToId
JOIN @ComputedProcessThroughDate ComputedProcessThroughDate 
	ON ComputedProcessThroughDate.EntityId = RDS.EntityId 
	AND ComputedProcessThroughDate.EntityType = RDS.EntityType	
WHERE BT.GenerateStatementInvoice = 1

;WITH CTE_DueDateForStatement(
EntityId,EntityType,ReceivableInvoiceId,ReceivableInvoiceDueDate,LastStatementGeneratedDueDate,StatementDueDay
,InvoiceDueDateMonthDifference,LastGeneratedStatementDueDateMonthDifference
,CalculatedMonthsToAdd,ComputedProcessThroughDate,MonthsToAdd) 
AS(
SELECT
DISTINCT
 EntityId
,EntityType
,ReceivableInvoiceId
,ReceivableInvoiceDueDate
,LastStatementGeneratedDueDate
,StatementDueDay
,DATEDIFF(Month,ReceivableInvoiceDueDate,ComputedProcessThroughDate)
,DATEDIFF(Month,LastStatementGeneratedDueDate,ComputedProcessThroughDate)
,StatementFrequency * (DATEDIFF(Month,LastStatementGeneratedDueDate,ComputedProcessThroughDate)/ StatementFrequency)
,ComputedProcessThroughDate
,StatementFrequency
FROM #ComputedProcessThroughDateDetails	
)		
,CTE_NextPossibleDueDateBasedOnFrequency AS
(
SELECT 
DueDateForStatement.ReceivableInvoiceId,
CASE WHEN DueDateForStatement.LastStatementGeneratedDueDate	IS NOT NULL	AND DueDateForStatement.LastStatementGeneratedDueDate < ComputedProcessThroughDate
	 THEN CASE WHEN LastGeneratedStatementDueDateMonthDifference > MonthsToAdd
			   THEN CASE WHEN (DATEADD(MONTH,CalculatedMonthsToAdd,LastStatementGeneratedDueDate)) < ComputedProcessThroughDate						  
						 THEN DATEADD(MONTH,CalculatedMonthsToAdd,LastStatementGeneratedDueDate)
						  ELSE CASE WHEN StatementDueDay > Day(ComputedProcessThroughDate) 
										AND DATEADD(MONTH, CalculatedMonthsToAdd-MonthsToAdd,LastStatementGeneratedDueDate) != LastStatementGeneratedDueDate
									THEN DATEADD(MONTH, CalculatedMonthsToAdd - MonthsToAdd,LastStatementGeneratedDueDate)
									ELSE DATEADD(MONTH, CalculatedMonthsToAdd,LastStatementGeneratedDueDate)
									END
						  END
				ELSE DATEADD(MONTH, MonthsToAdd ,LastStatementGeneratedDueDate)			
				END                                            
       ELSE CASE WHEN InvoiceDueDateMonthDifference > MonthsToAdd
                      THEN CASE WHEN StatementDueDay > Day(ComputedProcessThroughDate)
                                           THEN DATEADD(MONTH,
                                           (MonthsToAdd * (InvoiceDueDateMonthDifference/ MonthsToAdd)) - MonthsToAdd, ReceivableInvoiceDueDate)
                                           ELSE DATEADD(MONTH,
                                           MonthsToAdd * (InvoiceDueDateMonthDifference/ MonthsToAdd), ReceivableInvoiceDueDate)
                                           END
                      ELSE  CASE WHEN (DATEADD(MONTH,MonthsToAdd,ReceivableInvoiceDueDate) < ComputedProcessThroughDate OR 
                                      (InvoiceDueDateMonthDifference = MonthsToAdd AND StatementDueDay <= Day(ComputedProcessThroughDate)) OR
									  (InvoiceDueDateMonthDifference < MonthsToAdd AND StatementDueDay <= Day(ReceivableInvoiceDueDate)))
                                           THEN DATEADD(MONTH,MonthsToAdd,ReceivableInvoiceDueDate)
                                           ELSE ReceivableInvoiceDueDate
                                           END
				END
END NextPossibleGenerationStatementDueDate
FROM
CTE_DueDateForStatement DueDateForStatement
)      	     
,CTE_BasedOnDueDay AS
(
SELECT 
DueDateForStatement.ReceivableInvoiceId,
CASE WHEN DAY(EOMONTH(NextPossibleGenerationStatementDueDate)) < StatementDueDay
	THEN DATEADD(DAY, DAY(EOMONTH(NextPossibleGenerationStatementDueDate)) 
	- DAY(NextPossibleGenerationStatementDueDate) ,NextPossibleGenerationStatementDueDate)
	ELSE DATEADD(DAY, StatementDueDay - DAY(NextPossibleGenerationStatementDueDate),NextPossibleGenerationStatementDueDate)
	END NextPossibleStatementGenerationDueDate
FROM
CTE_DueDateForStatement DueDateForStatement
JOIN CTE_NextPossibleDueDateBasedOnFrequency NextPossibleDueDateBasedOnFrequency
	ON NextPossibleDueDateBasedOnFrequency.ReceivableInvoiceId = DueDateForStatement.ReceivableInvoiceId
)
INSERT INTO #NextPossibleStatementGenerationDueDates(ReceivableInvoiceId,StatementDueDay,NextPossibleStatementGenerationDueDate)
SELECT
	DISTINCT
	CTE_BasedOnDueDay.ReceivableInvoiceId,
	StatementDueDay,
	NextPossibleGenerationStatementDueDate = CTE_BasedOnDueDay.NextPossibleStatementGenerationDueDate
						
FROM CTE_BasedOnDueDay
JOIN CTE_DueDateForStatement DueDateForStatement 
	ON CTE_BasedOnDueDay.ReceivableInvoiceId = DueDateForStatement.ReceivableInvoiceId


INSERT INTO #ParameterDetailsToFetchInvoice(
	ReceivableInvoiceId
	,CalculatedDueDate
	,BillToID 
	,CustomerId 
	,StatementInvoicePreference
	,RemitToId 
	,LegalEntityId 
	,CurrencyId 
	,IsPrivateLabel 
	,IsDSL
	,AlternateBillingCurrencyId 
	,IsOffPeriod
	)
SELECT 
	 RDS.ReceivableInvoiceId
	,DATEADD(DAY,cus.InvoiceTransitDays,NextPossibleStatementGenerationDueDate)	
	,RDS.BillToId
	,RDS.CustomerId
	,RDS.StatementInvoicePreference
	,RDS.RemitToId
	,RDS.LegalEntityId
	,RDS.CurrencyId
	,RDS.IsPrivateLabel
	,RDS.IsDSL
	,RDS.AlternateBillingCurrencyId
	,1
FROM #ReceivableDetailsForStatement RDS
	JOIN #NextPossibleStatementGenerationDueDates NextPossibleStatementGenerationDueDates 
		ON RDS.ReceivableInvoiceId = NextPossibleStatementGenerationDueDates.ReceivableInvoiceId
    JOIN #ComputedProcessThroughDateDetails ComputedProcessThroughDateDetails ON RDS.EntityId = ComputedProcessThroughDateDetails.EntityId
			AND RDS.EntityType = ComputedProcessThroughDateDetails.EntityType
			AND RDS.CustomerId = ComputedProcessThroughDateDetails.CustomerId
	JOIN BillToes BT ON RDS.BillToId = BT.Id	
	JOIN #CustomerDetailsForStatement cus ON cus.CustomerId = RDS.CustomerId AND cus.LegalEntityId = RDS.LegalEntityId 
	LEFT JOIN Contracts C ON RDS.EntityId = C.Id
			AND RDS.EntityType = 'CT'
	WHERE BT.GenerateStatementInvoice = 1
	AND (@IsAllLease = 0 OR C.ContractType = 'Lease' )
	AND (@IsAllLoan = 0 OR C.ContractType = 'Loan' )
	AND NextPossibleStatementGenerationDueDates.NextPossibleStatementGenerationDueDate 
							 <= ComputedProcessThroughDateDetails.ComputedProcessThroughDate			

/*Removing duplicate records in filter criteria*/

;WITH cte_DistinctParameterDetailsToFetchInvoice
     AS (SELECT IsOffPeriod,ROW_NUMBER() OVER (PARTITION BY ReceivableInvoiceId
			,BillToId
			,CustomerId
			,StatementInvoicePreference
			,RemitToId
			,LegalEntityId
			,CurrencyId
			,IsPrivateLabel
			,IsDSL
			,AlternateBillingCurrencyId 
            ORDER BY IsOffPeriod desc) RN
         FROM   #ParameterDetailsToFetchInvoice)
DELETE FROM cte_DistinctParameterDetailsToFetchInvoice
WHERE  RN > 1 

/*Fetching Relevant Invoices based on particular parameters*/
INSERT INTO #ReceivableInvoiceForStatement
(
		Number 
		,ReceivableInvoiceId
		,ReceivableInvoiceDueDate 
		,SplitByContract 
		,SplitByLocation 
		,SplitByAsset 
		,SplitCreditsByOriginalInvoice 
		,SplitByReceivableAdj 
		,DefaultInvoiceReceivableGroupingOption
		,IsReceivableAdjustment
		,GenerateSummaryInvoice 
		,ReceivableDetailId
		,CustomerId 
		,ContractId
		,DiscountingId
		,BillToId 
		,RemitToId 
		,LegalEntityId 
		,ReceivableCategoryId 
		,ReportFormatId 
		,CurrencyId 
		,InvoiceDetailAmount
		,InvoiceDetailBalance
		,InvoiceDetailEffectiveBalance
		,InvoiceDetailTaxAmount
		,InvoiceDetailTaxBalance
		,InvoiceDetailEffectiveTaxBalance
		,CurrencyISO
		,StatementInvoicePreference
		,AssetID
		,LocationID
		,IsPrivateLabel 
		,OriginationSource 
		,OriginationSourceId 
		,IsDSL
		,IsACH 
		,EntityType
		,ExchangeRate
		,AdjustmentBasisReceivableDetailId
		,AlternateBillingCurrencyId
		,IsPrimaryInvoice
		,LastStatementGeneratedDueDate
		,DueDay
		,StatementFrequency
		,GenerateStatementInvoice
		,IsOffPeriod
		,IsNeitherOnNorOffPeriod
		,WithHoldingTaxAmount
		,WithHoldingTaxBalance
)
--ReceivableInvoices eligible through On period or Off  period
SELECT 
	DISTINCT	
		 RI.Number 
		,RI.ReceivableInvoiceId
		,RI.ReceivableInvoiceDueDate 
		,RI.SplitByContract 
		,RI.SplitByLocation 
		,RI.SplitByAsset 
		,RI.SplitCreditsByOriginalInvoice 
		,RI.SplitByReceivableAdj 
		,RC.DefaultInvoiceReceivableGroupingOption
		,CASE WHEN RDS.AdjustmentBasisReceivableDetailId IS NOT NULL THEN 1 ELSE 0 END
		,RI.GenerateSummaryInvoice 
		,RDS.ReceivableDetailId
		,RI.CustomerId 
		,CASE 
				WHEN RDS.EntityType = 'CT'
					THEN RDS.EntityId
				ELSE NULL
		END 'ContractId'
		,CASE 
				WHEN RDS.EntityType = 'DT'
					THEN RDS.EntityId
				ELSE NULL
		END 'DiscountingId'
		,RI.BillToId 
		,RI.RemitToId 
		,RI.LegalEntityId 
		,RI.ReceivableCategoryId 
		,BT.StatementInvoiceFormatId
		,RI.CurrencyId
		,RI.InvoiceDetailAmount
		,RI.InvoiceDetailBalance
		,RI.InvoiceDetailEffectiveBalance 
		,RI.InvoiceDetailTaxAmount 
		,RI.InvoiceDetailTaxBalance
		,RI.InvoiceDetailEffectiveTaxBalance
		,RI.CurrencyISO
		,RI.StatementInvoicePreference
		,RDS.AssetId
		,AL.LocationId
		,RI.IsPrivateLabel 
		,RI.OriginationSource 
		,RI.OriginationSourceId 
		,RDS.IsDSL 
		,RI.IsACH 
		,RDS.EntityType
		,RDS.ExchangeRate
		,RDS.AdjustmentBasisReceivableDetailId
		,RI.AlternateBillingCurrencyId
		,CASE WHEN RI.JobStepInstanceId = @JobStepInstanceId THEN 1 ELSE 0 END
		,RI.LastStatementGeneratedDueDate
		,BT.StatementDueDay
		,BT.StatementFrequency
		,BT.GenerateStatementInvoice
		,CASE WHEN RI.JobStepInstanceId = @JobStepInstanceId
			  THEN ParameterDetailsToFetchInvoice.IsOffPeriod ELSE 1 END
		,0
		,RDS.WithHoldingTaxAmount
		,RDS.WithHoldingTaxBalance
FROM #ParameterDetailsToFetchInvoice ParameterDetailsToFetchInvoice 
	JOIN BillToes BT ON ParameterDetailsToFetchInvoice.BillToID = BT.Id
	JOIN #ReceivableInvoiceDetailsInfo RI ON ParameterDetailsToFetchInvoice.ReceivableInvoiceId = RI.ReceivableInvoiceId
	JOIN #ReceivableDetailsForStatement RDS ON RI.ReceivableDetailId = RDS.ReceivableDetailId
	JOIN ReceivableCodes RC ON RDS.ReceivableCodeId = RC.Id	
	LEFT JOIN AssetLocations AL ON AL.AssetId = RDS.AssetId
			AND AL.IsActive = 1
			AND AL.IsCurrent = 1
		
	UNION ALL
	--ReceivableInvoices eligible through the filter criteria
SELECT 
	DISTINCT	
		 RI.Number 
		,RI.ReceivableInvoiceId
		,RI.ReceivableInvoiceDueDate 
		,RI.SplitByContract 
		,RI.SplitByLocation 
		,RI.SplitByAsset 
		,RI.SplitCreditsByOriginalInvoice 
		,RI.SplitByReceivableAdj 
		,RC.DefaultInvoiceReceivableGroupingOption
		,CASE WHEN RDS.AdjustmentBasisReceivableDetailId IS NOT NULL THEN 1 ELSE 0 END
		,RI.GenerateSummaryInvoice 
		,RDS.ReceivableDetailId AS ReceivableDetailId
		,RI.CustomerId 
		,CASE 
				WHEN RDS.EntityType = 'CT'
					THEN RDS.EntityId
				ELSE NULL
		END 'ContractId'
		,CASE 
				WHEN RDS.EntityType = 'DT'
					THEN RDS.EntityId
				ELSE NULL
		END 'DiscountingId'
		,RI.BillToId 
		,RI.RemitToId 
		,RI.LegalEntityId 
		,RI.ReceivableCategoryId 
		,BT.StatementInvoiceFormatId
		,RI.CurrencyId
		,RI.InvoiceDetailAmount
		,RI.InvoiceDetailBalance
		,RI.InvoiceDetailEffectiveBalance 
		,RI.InvoiceDetailTaxAmount 
		,RI.InvoiceDetailTaxBalance
		,RI.InvoiceDetailEffectiveTaxBalance
		,RI.CurrencyISO
		,RI.StatementInvoicePreference
		,RDS.AssetId
		,AL.LocationId
		,RI.IsPrivateLabel 
		,RI.OriginationSource 
		,RI.OriginationSourceId 
		,RDS.IsDSL 
		,RI.IsACH 
		,RDS.EntityType
		,RDS.ExchangeRate
		,RDS.AdjustmentBasisReceivableDetailId
		,RI.AlternateBillingCurrencyId
		,CASE WHEN RI.JobStepInstanceId = @JobStepInstanceId THEN 1 ELSE 0 END
		,RI.LastStatementGeneratedDueDate
		,BT.StatementDueDay
		,BT.StatementFrequency
		,BT.GenerateStatementInvoice
		,0
		,1
		,RDS.WithHoldingTaxAmount
		,RDS.WithHoldingTaxBalance
FROM #ParameterDetailsToFetchInvoice ParameterDetailsToFetchInvoice 
	JOIN #ReceivableInvoiceDetailsInfo RI 
		ON ParameterDetailsToFetchInvoice.AlternateBillingCurrencyId = RI.AlternateBillingCurrencyId
		AND ParameterDetailsToFetchInvoice.CurrencyId = RI.CurrencyId
		AND ParameterDetailsToFetchInvoice.CustomerId = RI.CustomerId
		AND ParameterDetailsToFetchInvoice.StatementInvoicePreference = RI.StatementInvoicePreference
		AND ParameterDetailsToFetchInvoice.IsPrivateLabel = RI.IsPrivateLabel
		AND ParameterDetailsToFetchInvoice.LegalEntityId = RI.LegalEntityId
		AND ParameterDetailsToFetchInvoice.RemitToId = RI.RemitToId
		AND ParameterDetailsToFetchInvoice.BillToId = RI.BillToId
		AND RI.ReceivableInvoiceDueDate <= ParameterDetailsToFetchInvoice.CalculatedDueDate
	JOIN BillToes BT ON RI.BillToID = BT.Id
	JOIN #ReceivableDetailsForStatement RDS ON RI.ReceivableDetailId = RDS.ReceivableDetailId
	JOIN ReceivableCodes RC ON RDS.ReceivableCodeId = RC.Id	
	JOIN #NextPossibleStatementGenerationDueDates NextPossibleStatementGenerationDueDates 
		ON RI.ReceivableInvoiceId = NextPossibleStatementGenerationDueDates.ReceivableInvoiceId
    JOIN #ComputedProcessThroughDateDetails ComputedProcessThroughDateDetails ON RDS.EntityId = ComputedProcessThroughDateDetails.EntityId
			AND RDS.EntityType = ComputedProcessThroughDateDetails.EntityType
			AND RDS.CustomerId = ComputedProcessThroughDateDetails.CustomerId
	LEFT JOIN AssetLocations AL ON AL.AssetId = RDS.AssetId
			AND AL.IsActive = 1
			AND AL.IsCurrent = 1
	LEFT JOIN Contracts C ON RDS.EntityId = C.Id
			AND RDS.EntityType = 'CT'
	WHERE BT.GenerateStatementInvoice = 1
	AND ParameterDetailsToFetchInvoice.IsDSL = RDS.IsDSL
	AND (@IsAllLease = 0 OR C.ContractType = 'Lease' )
	AND (@IsAllLoan = 0 OR C.ContractType = 'Loan' )
	AND RI.ReceivableInvoiceId NOT IN (SELECT ReceivableInvoiceId FROM #ParameterDetailsToFetchInvoice)		

/*Statement Invoice Grouping*/
;WITH CTE_InvoiceGroupingWRTRemitToBillTo
	AS (
		SELECT Rank() OVER (
				ORDER BY RRI.LegalEntityId ASC	
					,RRI.CustomerID
					,RRI.RemitToId
					,RRI.BillToID
					,RRI.CurrencyId	
					,RRI.AlternateBillingCurrencyId
					,RRI.IsDSL
					,RRI.IsPrivateLabel
					,RRI.StatementInvoicePreference
				) AS InvoiceGroupNumber
			,RRI.*
		FROM #ReceivableInvoiceForStatement AS RRI
		)
		,CTE_GroupByCategory
		AS (
			SELECT DISTINCT Rank() OVER (
							ORDER BY GroupedWRTRemitToBillTo.InvoiceGroupNumber
							,GroupedWRTRemitToBillTo.SplitByContract
							,GroupedWRTRemitToBillTo.SplitByAsset
							,GroupedWRTRemitToBillTo.SplitByReceivableAdj
							,GroupedWRTRemitToBillTo.SplitByLocation
							,GroupedWRTRemitToBillTo.SplitCreditsByOriginalInvoice
							) newGrouping

			,GroupedWRTRemitToBillTo.*
		FROM CTE_InvoiceGroupingWRTRemitToBillTo AS GroupedWRTRemitToBillTo	
		),CTE_SplitByContract
		As (
		SELECT CASE WHEN GroupByCategoryDetails.SplitByContract = 1
					THEN Rank() OVER (
							ORDER BY GroupByCategoryDetails.newGrouping,
							GroupByCategoryDetails.ContractId
							)
					ELSE GroupByCategoryDetails.newGrouping
					END GroupByContract
					,GroupByCategoryDetails.*
			FROM CTE_GroupByCategory AS GroupByCategoryDetails
		),CTE_SplitByLocation
		AS (
		SELECT CASE WHEN SplitByContract.SplitByLocation = 1
					THEN Rank() OVER(
								ORDER BY SplitByContract.GroupByContract,
								SplitByContract.LocationID
								)
					ELSE SplitByContract.GroupByContract
					END GroupByLocation
					,SplitByContract.*
		FROM CTE_SplitByContract AS SplitByContract
		),CTE_SplitByAsset
		AS (
		SELECT CASE WHEN SplitByLocation.SplitByAsset = 1
					THEN Rank() OVER (
							ORDER BY SplitByLocation.GroupByLocation,
							SplitByLocation.AssetID
							)
					ELSE SplitByLocation.GroupByLocation
					END GroupByAsset
					,SplitByLocation.*
		FROM CTE_SplitByLocation AS SplitByLocation
		),CTE_SplitByReceivableAdjustment
		AS (
		SELECT CASE WHEN SplitByAsset.SplitByReceivableAdj = 1
					THEN Rank() OVER(
								ORDER BY SplitByAsset.GroupByAsset,
								SplitByAsset.IsReceivableAdjustment
								)
					ELSE SplitByAsset.GroupByAsset
					END GroupByReceivableAdjustment
					,SplitByAsset.*
		FROM CTE_SplitByAsset AS SplitByAsset
		),CTE_SplitCreditsByOriginalInvoice
		AS (
		SELECT CASE WHEN SplitByReceivableAdjustment.SplitCreditsByOriginalInvoice = 1
					THEN Rank() OVER(
								ORDER BY SplitByReceivableAdjustment.GroupByReceivableAdjustment,
								RI.Id
								)
					ELSE SplitByReceivableAdjustment.GroupByReceivableAdjustment
					END SplitCreditsByOriginalInvoiceGrouping
					,SplitByReceivableAdjustment.*
		FROM CTE_SplitByReceivableAdjustment AS SplitByReceivableAdjustment
		LEFT JOIN ReceivableDetails RD ON RD.Id = SplitByReceivableAdjustment.AdjustmentBasisReceivableDetailId AND RD.IsActive =1
		LEFT JOIN ReceivableInvoiceDetails RID ON RID.ReceivableDetailId = RD.Id AND RID.IsActive = 1
		LEFT JOIN ReceivableInvoices RI ON RI.Id = RID.ReceivableInvoiceId AND RI.IsActive = 1
		)  
		INSERT INTO #StatementInvoice (
		Number
		,ReceivableInvoiceId
		,ReceivableInvoiceDueDate
		,DueDate
		,SplitByContract
		,SplitByLocation
		,SplitByAsset
		,SplitCreditsByOriginalInvoice
		,SplitByReceivableAdj
		,GenerateSummaryInvoice
		,CustomerId
		,BillTo
		,RemitToId
		,LegalEntityId
		,ReceivableCategoryId
		,ReportFormatId
		,CurrencyId
		,ReceivableDetailId
		,OriginalTaxBalance
		,OriginalEffectiveTaxBalance
		,OriginalTaxAmount
		,ReceivableDetailAmount
		,ReceivableDetailBalance
		,ReceivableDetailEffectiveBalance
		,CurrencyISO
		,StatementInvoicePreference
		,EntityType
		,EntityId
		,IsPrivateLabel
		,OriginationSource
		,OriginationSourceId
		,IsDSL
		,IsACH
		,IsRental
		,ExchangeRate
		,AlternateBillingCurrencyId
		,IsPrimaryInvoice
		,LastStatementGeneratedDueDate
		,IsOffPeriod
		,WithHoldingTaxAmount
		,WithHoldingTaxBalance
		)
	SELECT (DENSE_RANK() OVER (
				ORDER BY T.SplitCreditsByOriginalInvoiceGrouping
					,T.StatementInvoicePreference ASC
					,T.IsPrivateLabel
					,T.IsDSL
				)) ReceivableInvoiceNumber
		,T.ReceivableInvoiceId
		,T.ReceivableInvoiceDueDate
		,CASE WHEN T.IsNeitherOnNorOffPeriod = 0
		 THEN CASE WHEN T.IsOffPeriod = 1 
					THEN DATEADD(DAY,c.InvoiceTransitDays,NextPossibleStatementGenerationDueDate)
					ELSE T.ReceivableInvoiceDueDate 
					END
		 ELSE CASE WHEN T.LastStatementGeneratedDueDate IS NOT NULL AND T.LastStatementGeneratedDueDate <= @ProcessThroughDate
					THEN DATEADD(DAY,c.InvoiceTransitDays,T.LastStatementGeneratedDueDate)
					ELSE CASE WHEN NextPossibleStatementGenerationDueDate <= @ProcessThroughDate
							THEN DATEADD(DAY,c.InvoiceTransitDays,NextPossibleStatementGenerationDueDate)
							ELSE T.ReceivableInvoiceDueDate 
							END
					END
		 END AS DueDate
		,T.SplitByContract
		,T.SplitByLocation
		,T.SplitByAsset
		,T.SplitCreditsByOriginalInvoice
		,T.SplitByReceivableAdj
		,T.GenerateSummaryInvoice
		,T.CustomerId
		,T.BillToID
		,T.RemitToId
		,T.LegalEntityId
		,T.ReceivableCategoryId
		,T.ReportFormatId
		,T.CurrencyId
		,T.ReceivableDetailId
		,T.InvoiceDetailTaxBalance
		,T.InvoiceDetailEffectiveTaxBalance
		,T.InvoiceDetailTaxAmount
		,T.InvoiceDetailAmount ReceivableDetailAmount
		,T.InvoiceDetailBalance ReceivableBalance
		,T.InvoiceDetailEffectiveBalance ReceivableEffectiveBalance
		,T.CurrencyISO
		,CAST(T.StatementInvoicePreference AS NVARCHAR(80))
		,T.EntityType
		,CASE 
			WHEN T.EntityType = 'CT'
				THEN T.ContractId
			WHEN T.EntityType = 'DT'
				THEN T.DiscountingId
			ELSE T.CustomerId
			END
		,T.IsPrivateLabel
		,T.OriginationSource
		,T.OriginationSourceId
		,T.IsDSL
		,T.IsACH
		,T.IsRental
		,T.ExchangeRate
		,T.AlternateBillingCurrencyId 
		,T.IsPrimaryInvoice
		,CASE WHEN T.IsOffPeriod = 1
			  THEN NextPossibleStatementGenerationDueDates.NextPossibleStatementGenerationDueDate 
			  ELSE NULL
			  END
		,T.IsOffPeriod
		,WithHoldingTaxBalance
		,WithHoldingTaxBalance
	FROM CTE_SplitCreditsByOriginalInvoice AS T
	INNER JOIN #CustomerDetailsForStatement c ON c.CustomerId = T.CustomerId AND c.LegalEntityId = T.LegalEntityId
	INNER JOIN #NextPossibleStatementGenerationDueDates NextPossibleStatementGenerationDueDates 
			ON T.ReceivableInvoiceId = NextPossibleStatementGenerationDueDates.ReceivableInvoiceId

	INSERT INTO #StatementInvoiceNumberGenerator 
	SELECT DISTINCT NULL,Number FROM #StatementInvoice

UPDATE #StatementInvoiceNumberGenerator SET SequenceGeneratedInvoiceNumber = CAST(NEXT VALUE FOR InvoiceNumberGenerator AS NVARCHAR(100))

UPDATE #StatementInvoice SET Number = SequenceGeneratedInvoiceNumber
	FROM #StatementInvoice
	JOIN #StatementInvoiceNumberGenerator ON #StatementInvoice.Number = #StatementInvoiceNumberGenerator.InvoiceRankValue

;WITH cte_StatementInvoice
     AS (SELECT Number,Max(DueDate) AS StatementInvoiceDueDate
         FROM #StatementInvoice
		 GROUP BY Number
		,SplitByContract
		,SplitByLocation
		,SplitByAsset
		,SplitCreditsByOriginalInvoice
		,SplitByReceivableAdj
		,GenerateSummaryInvoice
		,CustomerId
		,BillTo
		,RemitToId
		,LegalEntityId
		,ReportFormatId
		,CurrencyId
		,AlternateBillingCurrencyId
		,CurrencyISO
		,StatementInvoicePreference
		,IsPrivateLabel
		,IsDSL
		,IsACH
		 )
DELETE SI FROM #StatementInvoice SI
JOIN cte_StatementInvoice ON SI.Number = cte_StatementInvoice.Number
WHERE SI.ReceivableInvoiceDueDate > cte_StatementInvoice.StatementInvoiceDueDate


/*Insertion of Receivable Invoices*/
	INSERT INTO ReceivableInvoices (
		Number
		,DueDate
		,IsDummy
		,IsNumberSystemCreated
		,InvoiceRunDate
		,IsActive
		,IsInvoiceCleared
		,SplitByContract
		,SplitByLocation
		,SplitByAsset
		,SplitCreditsByOriginalInvoice
		,SplitByReceivableAdj
		,GenerateSummaryInvoice
		,IsEmailSent
		,CustomerId
		,BillToId
		,RemitToId
		,LegalEntityId
		,ReceivableCategoryId
		,ReportFormatId
		,JobStepInstanceId
		,CurrencyId
		,InvoiceAmount_Amount
		,Balance_Amount
		,EffectiveBalance_Amount
		,InvoiceTaxAmount_Amount
		,TaxBalance_Amount
		,EffectiveTaxBalance_Amount
		,InvoiceAmount_Currency
		,Balance_Currency
		,EffectiveBalance_Currency
		,InvoiceTaxAmount_Currency
		,TaxBalance_Currency
		,EffectiveTaxBalance_Currency
		,CreatedById
		,CreatedTime
		,InvoicePreference
		,StatementInvoicePreference
		,RunTimeComment
		,IsPrivateLabel
		,OriginationSource
		,OriginationSourceId
		,IsACH
		,InvoiceFileName
		,AlternateBillingCurrencyId
		,IsPdfGenerated
		,DaysLateCount
		,InvoiceFile_Source
		,InvoiceFile_Type
		,IsStatementInvoice
		,LastStatementGeneratedDueDate
		,WithHoldingTaxAmount_Amount
		,WithHoldingTaxBalance_Amount
		,WithHoldingTaxAmount_Currency
		,WithHoldingTaxBalance_Currency
		)
	OUTPUT Inserted.Id
		,Inserted.Number
	INTO #InsertedStatementInvoice
	SELECT RecInv.Number
		,Max(RecInv.DueDate)
		,0
		,1
		,GetDate()
		,1
		,0
		,RecInv.SplitByContract
		,RecInv.SplitByLocation
		,RecInv.SplitByAsset
		,RecInv.SplitCreditsByOriginalInvoice
		,RecInv.SplitByReceivableAdj
		,RecInv.GenerateSummaryInvoice
		,0
		,RecInv.CustomerId
		,RecInv.BillTo
		,RecInv.RemitToId
		,RecInv.LegalEntityId
		,MIN(RecInv.ReceivableCategoryId) ReceivableCategoryId
		,ReportFormatId
		,@JobStepInstanceId
		,RecInv.CurrencyId
		,SUM(RecInv.ReceivableDetailBalance) OriginalBalance
		,SUM(RecInv.ReceivableDetailBalance)
		,SUM(RecInv.ReceivableDetailEffectiveBalance)
		,SUM(RecInv.OriginalTaxBalance) OriginalTaxBalance
		,SUM(RecInv.OriginalTaxBalance)
		,SUM(RecInv.OriginalEffectiveTaxBalance)
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,@CreatedBy
		,@CreatedTime
		,RecInv.StatementInvoicePreference
		,RecInv.StatementInvoicePreference
		,@RunTimeComment
		,RecInv.IsPrivateLabel
		,'_'
		,NULL
		,MAX(CONVERT(INT,RecInv.IsACH)) --Even if one of the associated RI has IsACH as true then the SI will aslo have it as true 
		,RecInv.Number
		,RecInv.AlternateBillingCurrencyId
		,0
		,0
		,''
		,'' 
		,1
		,NULL
		,SUM(WithHoldingTaxAmount)
		,SUM(WithHoldingTaxBalance)
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
	FROM #StatementInvoice AS RecInv
	GROUP BY RecInv.Number
		,RecInv.SplitByContract
		,RecInv.SplitByLocation
		,RecInv.SplitByAsset
		,RecInv.SplitCreditsByOriginalInvoice
		,RecInv.SplitByReceivableAdj
		,RecInv.GenerateSummaryInvoice
		,RecInv.CustomerId
		,RecInv.BillTo
		,RecInv.RemitToId
		,RecInv.LegalEntityId
		,RecInv.ReportFormatId
		,RecInv.CurrencyId
		,RecInv.AlternateBillingCurrencyId
		,RecInv.CurrencyISO
		,RecInv.StatementInvoicePreference
		,RecInv.IsPrivateLabel
		,RecInv.IsDSL

SET @StatementInvoiceCount = (SELECT Count(*) FROM #InsertedStatementInvoice)

INSERT INTO ReceivableInvoiceStatementAssociations (
		StatementInvoiceID,
		ReceivableInvoiceID,
		IsCurrentInvoice,
		CreatedById,
		CreatedTime
		)
		SELECT 
		DISTINCT
		II.Id,
		SI.ReceivableInvoiceId,
		SI.IsPrimaryInvoice,
		@CreatedBy,
		@CreatedTime
		FROM #InsertedStatementInvoice II 
		JOIN #StatementInvoice SI ON II.InvoiceNumber = SI.Number
 
UPDATE ReceivableInvoices 
	SET InvoicePreference = 'SuppressGeneration'
	,ReceivableInvoices.UpdatedById = @CreatedBy
	,ReceivableInvoices.UpdatedTime = @CreatedTime
	FROM ReceivableInvoices
	JOIN #StatementInvoice SI ON ReceivableInvoices.Id = SI.ReceivableInvoiceId

UPDATE ReceivableInvoices 
	SET ReceivableInvoices.LastStatementGeneratedDueDate = SI.LastStatementGeneratedDueDate
	,ReceivableInvoices.UpdatedById = @CreatedBy
	,ReceivableInvoices.UpdatedTime = @CreatedTime
	FROM ReceivableInvoices
	JOIN #StatementInvoice SI ON ReceivableInvoices.Id = SI.ReceivableInvoiceId
	AND SI.LastStatementGeneratedDueDate IS NOT NULL 
 
;WITH CTE_LastStatementGeneratedDueDate AS
(
SELECT 
StatementInvoices.Id,
MAX(RI.LastStatementGeneratedDueDate) AS LastStatementGeneratedDueDate
FROM ReceivableInvoices StatementInvoices
JOIN ReceivableInvoiceStatementAssociations
	ON StatementInvoices.Id = ReceivableInvoiceStatementAssociations.StatementInvoiceId
JOIN #StatementInvoice StatementInvoice	
	ON StatementInvoice.Number = StatementInvoices.Number
JOIN ReceivableInvoices RI
	ON RI.Id = ReceivableInvoiceStatementAssociations.ReceivableInvoiceId
WHERE RI.LastStatementGeneratedDueDate IS NOT NULL
GROUP BY StatementInvoices.Id 
) UPDATE ReceivableInvoices
	SET ReceivableInvoices.LastStatementGeneratedDueDate = CTE_LastStatementGeneratedDueDate.LastStatementGeneratedDueDate
	,ReceivableInvoices.UpdatedById = @CreatedBy
	,ReceivableInvoices.UpdatedTime = @CreatedTime
	FROM CTE_LastStatementGeneratedDueDate 
	JOIN ReceivableInvoiceStatementAssociations 
	ON CTE_LastStatementGeneratedDueDate.Id = ReceivableInvoiceStatementAssociations.StatementInvoiceId
	JOIN ReceivableInvoices
	ON ReceivableInvoices.Id = ReceivableInvoiceStatementAssociations.ReceivableInvoiceId
	WHERE ((ReceivableInvoices.LastStatementGeneratedDueDate IS NULL
	AND CTE_LastStatementGeneratedDueDate.LastStatementGeneratedDueDate > ReceivableInvoices.DueDate)
	OR ReceivableInvoices.LastStatementGeneratedDueDate IS NOT NULL)

UPDATE RI 
	SET RI.LastStatementGeneratedDueDate = 
	CASE WHEN Day(ReceivableInvoiceDueDate) = NextPossibleStatementGenerationDueDates.StatementDueDay
		THEN CASE WHEN  NextPossibleStatementGenerationDueDate <= ComputedProcessThroughDate
				  THEN NextPossibleStatementGenerationDueDate
				  ELSE ReceivableInvoiceDueDate
				  END
		ELSE NULL
		END 
	,RI.UpdatedById = @CreatedBy
	,RI.UpdatedTime = @CreatedTime
	FROM ReceivableInvoices RI
	JOIN #ComputedProcessThroughDateDetails ComputedProcessThroughDateDetails ON ComputedProcessThroughDateDetails.ReceivableInvoiceId = RI.Id
	JOIN #NextPossibleStatementGenerationDueDates NextPossibleStatementGenerationDueDates ON RI.Id = NextPossibleStatementGenerationDueDates.ReceivableInvoiceId
	WHERE RI.LastStatementGeneratedDueDate IS NULL 

DROP TABLE #ComputedProcessThroughDateDetails
DROP TABLE #CustomerDetailsForStatement
DROP TABLE #ParameterDetailsToFetchInvoice
DROP TABLE #NextPossibleStatementGenerationDueDates
DROP TABLE #InsertedStatementInvoice
DROP TABLE #StatementInvoiceNumberGenerator
DROP TABLE #StatementInvoice
DROP TABLE #ReceivableInvoiceForStatement
DROP TABLE #ReceivableInvoiceDetailsInfo
DROP TABLE #ReceivableDetailsForStatement


GO
