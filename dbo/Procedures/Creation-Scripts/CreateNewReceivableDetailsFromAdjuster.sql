SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CreateNewReceivableDetailsFromAdjuster]
(
@receivableDetailsSet CreateNewReceivableDetailsFromAdjusterParam READONLY,
@Currency NVARCHAR(3),
@IsNonAccrual BIT,
@isFromSelfTaxAssessedModule BIT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@IsSalesTaxRequiredForLoan BIT
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #InsertedReceivables
	(
		ReceivableId BIGINT,
		SourceId BIGINT NULL,
		FunderId BIGINT NULL,
		TotalAmount_Amount DECIMAL(16,2),
		TotalAmount_Currency NVARCHAR(3),
		DueDate DATETIME NULL,
		PaymentScheduleId BIGINT NULL,
	)
CREATE TABLE #ReceivableDetailsComponent
(
	LeaseComponentAmount     DECIMAL(16, 2), 
	NonLeaseComponentAmount  DECIMAL(16, 2), 
	ReceivableDetailId       BIGINT
);
  


SELECT * INTO #ReceivableDetailsForCreation
FROM @receivableDetailsSet
--DECLARE @IsSalesTaxRequiredForLoan BIT
--SET @IsSalesTaxRequiredForLoan = (SELECT TOP 1 CASE WHEN Value = 'True' THEN 1 ELSE 0 END FROM GlobalParameters WHERE Category = 'SalesTax' AND Name = 'IsSalesTaxRequiredForLoan')
SELECT
CASE WHEN (C.Id IS NOT NULL AND C.ContractType <> 'Loan' AND  @isFromSelfTaxAssessedModule = 0 )
OR ( RFC.IsDummy = 0 AND RT.Name = 'LoanInterest' AND @IsSalesTaxRequiredForLoan = 1)
THEN 0 ELSE 1 END IsTaxAssessed,
CASE WHEN RT.Name = 'LoanInterest' OR RT.Name = 'LoanPrincipal'
THEN 1 ELSE 0 END AS IsLoanInterestOrPrincipal,
RDFC.*
INTO #ReceivableDetailForCreation
FROM Receivables RFC
JOIN #ReceivableDetailsForCreation RDFC ON RFC.Id = RDFC.ReceivableId
JOIN ReceivableCodes RC ON RFC.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
LEFT JOIN Contracts C on RFC.EntityId = C.Id AND RFC.EntityType = 'CT'

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
	)
	SELECT 
		 RDFC.[Amount]
        ,@Currency
        ,RDFC.[Amount]
        ,@Currency
        ,RDFC.[Amount]
        ,@Currency
        ,1
        ,'NotInvoiced'
        ,RDFC.IsTaxAssessed
        ,@CreatedById
        ,@CreatedTime
        ,RDFC.[AssetId]
        ,RDFC.[BillToId]
        ,RDFC.AdjustmentReceivableDetailId
        ,R.Id
		,0
		,CASE WHEN RDFC.IsLoanInterestOrPrincipal = 1 AND  @IsNonAccrual =1  THEN RDFC.Amount ELSE 0.0 END
		,@Currency
		,CASE WHEN LA.IsLeaseAsset = 1 THEN 'Lease' 
			  WHEN LA.IsLeaseAsset = 0 THEN 'Finance'
			  ELSE '_' END
	    ,0.00
        ,@Currency
	    ,0.00
        ,@Currency
	    ,0.00
        ,@Currency
	    ,0.00
        ,@Currency
		,0.00
        ,@Currency
	FROM 
		 #ReceivableDetailForCreation RDFC 	
	INNER JOIN Receivables R ON RDFC.ReceivableId = R.Id
	LEFT JOIN LeaseAssets LA ON LA.AssetId = RDFC.[AssetId]

	SELECT rd.ReceivableId, 
		SUM(Amount_Amount) Amount,
		SUM(Balance_Amount) Balance,
		SUM(EffectiveBalance_Amount) EffectiveBalance INTO #ReceivableDetailsToUpdate
		FROM [ReceivableDetails]  rd
		INNER JOIN #InsertedReceivables R ON rd.ReceivableId = R.ReceivableId
		GROUP BY rd.ReceivableId

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
		 INNER JOIN #ReceivableDetailForCreation rdfc ON rdfc.ReceivableId = R.Id
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
         INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
         INNER JOIN LeaseAssets la ON la.AssetId =  rd.AssetId
		 INNER JOIN Assets a ON la.AssetId = a.Id
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
		 INNER JOIN #ReceivableDetailForCreation rdfc ON rdfc.ReceivableId = R.Id
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

UPDATE ReceivableDetails
  SET 
      LeaseComponentAmount_Amount = rd.Amount_Amount
    , LeaseComponentBalance_Amount = rd.Balance_Amount
FROM ReceivableDetails rd WITH(NOLOCK)
	 INNER JOIN #ReceivableDetailsToUpdate rdtu ON rd.ReceivableId  = rdtu.ReceivableId
	 LEFT JOIN #ReceivableDetailsComponent rdc ON rd.Id = rdc.ReceivableDetailId
	 WHERE rdc.ReceivableDetailId IS NULL


UPDATE #InsertedReceivables SET [TotalAmount_Amount] = R.[TotalAmount_Amount] , [TotalAmount_Currency] = R.[TotalAmount_Currency] 
FROM Receivables R
WHERE #InsertedReceivables.ReceivableId = R.Id

 
	SELECT ReceivableId,		
		SourceId,
		FunderId,
		TotalAmount_Amount,
		TotalAmount_Currency,
		DueDate,
		PaymentScheduleId
	FROM #InsertedReceivables

IF OBJECT_ID('tempdb..#ReceivableDetailsComponent') IS NOT NULL 
	DROP TABLE #ReceivableDetailsComponent

	END

GO
