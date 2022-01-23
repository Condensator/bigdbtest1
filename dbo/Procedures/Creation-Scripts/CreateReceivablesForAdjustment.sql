SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateReceivablesForAdjustment]
(
@ReceivableDetailsForCreation CreateReceivablesForAdjustmentParam ReadOnly,
@ReceivableDetailsForInactivation CreateReceivablesForAdjustmentParam ReadOnly,
@MigratedReceivableIdsForInactivation CreateReceivablesForAdjustmentParam ReadOnly,
@MigratedReceivableIdsForCreditCreation CreateReceivablesForAdjustmentParam ReadOnly,
@IsSelfTaxAssessed BIT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
SELECT ReceivableId INTO #ReceivablesToInactivate
FROM  @ReceivableDetailsForInactivation
SELECT ReceivableId INTO #MigratedReceivablesToInactivate
FROM  @MigratedReceivableIdsForInactivation
CREATE TABLE #InsertedReceivables
(
NewReceivableId BIGINT,
OldReceivableId BIGINT
)
CREATE TABLE #InsertedReceivableDetails
(
NewReceivableDetailId BIGINT,
OldReceivableDetailId BIGINT,
NewReceivableId BIGINT
)
CREATE TABLE #InsertedReceivableWHT
(
NewReceivableWHTId BIGINT,
NewReceivableId BIGINT
)
CREATE TABLE #ReceivableDetailsComponent
(	LeaseComponentAmount     DECIMAL(16, 2), 
	NonLeaseComponentAmount  DECIMAL(16, 2), 
	ReceivableDetailId       BIGINT
);
MERGE Receivables R
USING (SELECT *	FROM Receivables
JOIN @ReceivableDetailsForCreation RDs ON  Receivables.Id = RDs.ReceivableId) oldreceivables ON 1=0
WHEN  NOT MATCHED THEN
INSERT
([EntityType]
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
,[TotalAmount_Currency]
,[TotalAmount_Amount]
,[TotalBalance_Currency]
,[TotalBalance_Amount]
,[TotalEffectiveBalance_Currency]
,[TotalEffectiveBalance_Amount]
,[TotalBookBalance_Currency]
,[TotalBookBalance_Amount]
,[ExchangeRate]
,[AlternateBillingCurrencyId])
VALUES
([EntityType]
,[EntityId]
,[DueDate]
,[IsDSL]
,[IsActive]
,[InvoiceComment]
,[InvoiceReceivableGroupingOption]
,0
,[IncomeType]
,[PaymentScheduleId]
,[IsCollected]
,[IsServiced]
,@CreatedById
,@CreatedTime
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
,'USD'
,0.0
,'USD'
,0.0
,'USD'
,0.0
,'USD'
,0.0
,[ExchangeRate]
,[AlternateBillingCurrencyId])
OUTPUT Inserted.Id, oldreceivables.Id INTO #InsertedReceivables;

INSERT INTO ReceivableDetails
(
[Amount_Amount]
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
,[PreCapitalizationRent_Currency]
) OUTPUT Inserted.Id,Inserted.[AdjustmentBasisReceivableDetailId],Inserted.[ReceivableId] INTO #InsertedReceivableDetails
SELECT
0 - RD.[Amount_Amount]
,RD.[Amount_Currency]
,0 - RD.[Amount_Amount]
,RD.[Balance_Currency]
,0 - RD.[Amount_Amount]
,RD.[EffectiveBalance_Currency]
,RD.[IsActive]
,'NotInvoiced'
,@IsSelfTaxAssessed
,@CreatedById
,@CreatedTime
,RD.[AssetId]
,RD.[BillToId]
,RD.Id
,#InsertedReceivables.[NewReceivableId]
,0
,0
,RD.EffectiveBookBalance_Currency
,RD.AssetComponentType
,0 - RD.[LeaseComponentAmount_Amount]
,RD.[Amount_Currency]
,0 - RD.[NonLeaseComponentAmount_Amount]
,RD.[Amount_Currency]
,0- RD.[LeaseComponentAmount_Amount]
,RD.[Amount_Currency]
,0- RD.[NonLeaseComponentAmount_Amount]
,RD.[Amount_Currency]
,0- RD.PreCapitalizationRent_Amount
,RD.[Amount_Currency]
FROM
ReceivableDetails RD
INNER JOIN Receivables
ON RD.ReceivableId = Receivables.Id
INNER JOIN #InsertedReceivables
ON Receivables.Id = #InsertedReceivables.OldReceivableId

INSERT INTO ReceivableWithholdingTaxDetails
(
[TaxRate]
,[BasisAmount_Amount]
,[BasisAmount_Currency]
,[Tax_Amount]
,[Tax_Currency]
,[Balance_Amount]
,[Balance_Currency]
,[EffectiveBalance_Amount]
,[EffectiveBalance_Currency]
,[ReceivableId]
,[WithholdingTaxCodeDetailId]
,[IsActive]
,[CreatedById]
,[CreatedTime]
) OUTPUT Inserted.Id,Inserted.ReceivableId INTO #InsertedReceivableWHT
SELECT
RWHT.[TaxRate]
,0 - RWHT.[BasisAmount_Amount]
,RWHT.[BasisAmount_Currency]
,0 - RWHT.[Tax_Amount]
,RWHT.[Tax_Currency]
,0 - RWHT.[Balance_Amount]
,RWHT.[Balance_Currency]
,0 - RWHT.[EffectiveBalance_Amount]
,RWHT.[EffectiveBalance_Currency]
,#InsertedReceivables.NewReceivableId
,RWHT.WithholdingTaxCodeDetailId
,RWHT.[IsActive]
,@CreatedById
,@CreatedTime
FROM
ReceivableWithholdingTaxDetails RWHT
INNER JOIN Receivables
ON RWHT.ReceivableId = Receivables.Id
INNER JOIN #InsertedReceivables
ON Receivables.Id = #InsertedReceivables.OldReceivableId
WHERE RWHT.IsActive =1

INSERT INTO ReceivableDetailsWithholdingTaxDetails
(
[BasisAmount_Amount]
,[BasisAmount_Currency]
,[Tax_Amount]
,[Tax_Currency]
,[Balance_Amount]
,[Balance_Currency]
,[EffectiveBalance_Amount]
,[EffectiveBalance_Currency]
,[ReceivableDetailId]
,[ReceivableWithholdingTaxDetailId]
,[IsActive]
,[CreatedById]
,[CreatedTime]
)
SELECT
0 - RDWHT.[BasisAmount_Amount]
,RDWHT.[BasisAmount_Currency]
,0 - RDWHT.[Tax_Amount]
,RDWHT.[Tax_Currency]
,0 - RDWHT.[Balance_Amount]
,RDWHT.[Balance_Currency]
,0 - RDWHT.[EffectiveBalance_Amount]
,RDWHT.[EffectiveBalance_Currency]
,#InsertedReceivableDetails.NewReceivableDetailId
,#InsertedReceivableWHT.NewReceivableWHTId
,RDWHT.[IsActive]
,@CreatedById
,@CreatedTime
FROM
ReceivableDetailsWithholdingTaxDetails RDWHT
INNER JOIN ReceivableDetails
ON RDWHT.ReceivableDetailId = ReceivableDetails.Id
INNER JOIN #InsertedReceivableDetails
ON ReceivableDetails.Id = #InsertedReceivableDetails.OldReceivableDetailId
INNER JOIN #InsertedReceivableWHT
ON #InsertedReceivableWHT.NewReceivableId = #InsertedReceivableDetails.NewReceivableId
WHERE RDWHT.IsActive =1
DECLARE @Currency NVARCHAR(3) = NULL
SELECT TOP 1 @Currency = Amount_Currency
FROM [ReceivableDetails]
INNER JOIN #InsertedReceivables R ON ReceivableId = R.NewReceivableId
SELECT ReceivableId,
SUM(Amount_Amount) Amount,
SUM(Balance_Amount) Balance,
SUM(EffectiveBalance_Amount) EffectiveBalance INTO #ReceivableDetailsToUpdate
FROM [ReceivableDetails]
INNER JOIN #InsertedReceivables R ON ReceivableId = R.NewReceivableId
GROUP BY ReceivableId
UPDATE R SET [TotalAmount_Currency] = CASE WHEN (@Currency) IS NOT NULL THEN @Currency ELSE 'USD' END,
[TotalBalance_Currency] = CASE WHEN (@Currency) IS NOT NULL THEN @Currency ELSE 'USD' END,
[TotalEffectiveBalance_Currency] = CASE WHEN (@Currency) IS NOT NULL THEN @Currency ELSE 'USD' END,
[TotalAmount_Amount] =  Amount,
[TotalBalance_Amount] =Balance,
[TotalEffectiveBalance_Amount] = EffectiveBalance,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM [Receivables] R
JOIN #ReceivableDetailsToUpdate RD
ON R.Id  = RD.ReceivableId


UPDATE ReceivableDetails SET IsActive = 0 WHERE ReceivableId IN (Select ReceivableId FROM #ReceivablesToInactivate)
UPDATE Receivables SET IsActive = 0	WHERE Id IN (Select ReceivableId FROM #ReceivablesToInactivate)

UPDATE ReceivableDetails SET IsActive = 0, IsTaxAssessed = 0 WHERE ReceivableId IN (Select ReceivableId FROM #MigratedReceivablesToInactivate)
UPDATE Receivables SET IsActive = 0	WHERE Id IN (Select ReceivableId FROM #MigratedReceivablesToInactivate)

	INSERT INTO #ReceivableDetailsComponent
SELECT *
FROM
(
    SELECT CASE
               WHEN la.IsLeaseAsset = 1 THEN rd.Amount_Amount
               ELSE 0.00
           END AS LeaseComponentAmount
         , CASE
               WHEN la.IsLeaseAsset = 0 THEN rd.Amount_Amount
               ELSE 0.00
           END AS NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK)
		 INNER JOIN #InsertedReceivables IR ON r.Id = IR.NewReceivableId
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
         INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
         INNER JOIN LeaseAssets la ON la.AssetId =  rd.AssetId
		 INNER JOIN Assets a ON a.Id = la.AssetId
    WHERE rt.Name IN('CapitalLeaseRental', 'OperatingLeaseRental') 
		  AND a.IsSKU = 0
    UNION
    SELECT SUM(CASE WHEN las.IsLeaseComponent = 1 THEN rs.Amount_Amount
                    ELSE 0.00
               END) AS LeaseComponentAmount
         , SUM(CASE
                   WHEN las.IsLeaseComponent = 0 THEN rs.Amount_Amount
                   ELSE 0.00
               END) AS  NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK)
		 INNER JOIN #InsertedReceivables IR ON r.Id = IR.NewReceivableId
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN LeaseAssets la ON rd.AssetId = la.AssetId
         INNER JOIN LeaseAssetSKUs las ON la.Id = las.LeaseAssetId
         INNER JOIN ReceivableSKUs rs WITH(NOLOCK) ON las.AssetSKUId = rs.AssetSKUId AND rd.Id = rs.ReceivableDetailId
         INNER JOIN ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
         INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
    WHERE rt.Name IN('CapitalLeaseRental', 'OperatingLeaseRental')
    GROUP BY rd.Id
           , rd.AssetId
) AS Temp;


UPDATE ReceivableDetails
  SET 
      LeaseComponentAmount_Amount = rdc.LeaseComponentAmount
    , NonLeaseComponentAmount_Amount = rdc.NonLeaseComponentAmount
    , LeaseComponentBalance_Amount = rdc.LeaseComponentAmount
    , NonLeaseComponentBalance_Amount = rdc.NonLeaseComponentAmount
FROM ReceivableDetails rd WITH(NOLOCK)
     INNER JOIN #ReceivableDetailsComponent rdc ON rd.Id = rdc.ReceivableDetailId;

Select * INTO #MigratedReceivableIdsForCreditCreation from @MigratedReceivableIdsForCreditCreation

SELECT RD.ID AS OLD,
IRD.NewReceivableDetailId AS NEW
INTO #MigratedReceivableID
FROM
#InsertedReceivableDetails IRD
INNER JOIN ReceivableDetails RD on IRD.OldReceivableDetailId = RD.ID
INNER JOIN #MigratedReceivableIdsForCreditCreation MR ON MR.ReceivableId = RD.ReceivableId

UPDATE RD 
SET RD.IsTaxAssessed = 1
FROM ReceivableDetails RD
INNER JOIN #MigratedReceivableID MD ON MD.NEW = RD.Id


INSERT INTO dbo.VertexBilledRentalReceivables
(
RevenueBilledToDate_Amount,
RevenueBilledToDate_Currency,
CumulativeAmount_Amount,
CumulativeAmount_Currency,
IsActive,
CreatedById,
CreatedTime,
ContractId,
ReceivableDetailId,
AssetId,
StateId,
AssetSKUId
)
SELECT
vt.RevenueBilledToDate_Amount * -1,
vt.RevenueBilledToDate_Currency,
CASE 
WHEN vt.CumulativeAmount_Amount != 0
THEN vt.CumulativeAmount_Amount - vt.RevenueBilledToDate_Amount
ELSE 0
END,
vt.CumulativeAmount_Currency,
vt.IsActive,
@CreatedById,
@CreatedTime,
vt.ContractId,
rd.NEW,
vt.AssetId,
vt.StateId,
vt.AssetSKUId
FROM VertexBilledRentalReceivables vt
JOIN #MigratedReceivableID rd ON vt.ReceivableDetailId = rd.OLD
WHERE vt.IsActive = 1

SELECT
NewReceivableId ReceivableId
,OldReceivableId
FROM #InsertedReceivables
END

GO
