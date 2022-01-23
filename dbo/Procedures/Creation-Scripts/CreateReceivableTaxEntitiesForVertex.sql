SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateReceivableTaxEntitiesForVertex]  
(	 
	 @ReceivableTaxParameter               ReceivableTaxParameter READONLY,  
     @ReceivableTaxDetailParameter         ReceivableTaxDetailParameter READONLY,  
     @ReceivableTaxImpositionParameter     ReceivableTaxImpositionParameter READONLY,  
	 @ReceivableTaxSKUImpositionParameter  ReceivableTaxSKUImpositionParameter READONLY,  
     @ReceivableTaxReversalDetailParameter ReceivableTaxReversalDetailParameter READONLY,
	 @ReceivableSKUTaxReversalDetailParameter ReceivableSKUTaxReversalDetailParameter READONLY,  
     @CreatedById                          BIGINT,  
     @CreatedTime                          DATETIMEOFFSET,
	 @JobStepInstanceId					   BIGINT,
	 @ReceivableIdsMessage				   NVARCHAR(100),
	 @IsManuallyAssessed				   BIT
)  
AS  
  
     BEGIN  
	 SET NOCOUNT ON 

         CREATE TABLE #InsertedReceivableTaxes  
         (
			ReceivableTaxId			BIGINT,
			ReceivableId			BIGINT  
         );  
  
         CREATE TABLE #InsertedReceivableTaxDetails  
         (
			ReceivableTaxDetailId			BIGINT, 
			ReceivableDetailId				BIGINT,  
			ReceivableDetailAssetId			BIGINT NULL,
			Action							VARCHAR(400)
         );

		 MERGE [ReceivableTaxes] AS TargetReceivableTax
		 USING @ReceivableTaxParameter AS SourceReceivableTax 
		 ON (TargetReceivableTax.ReceivableId = SourceReceivableTax.ReceivableId AND TargetReceivableTax.IsActive = 1)
		 WHEN NOT MATCHED THEN
		 INSERT 
			 (	[CreatedById],  
			  [CreatedTime],  
			  [ReceivableId],  
			  [IsActive],  
			  [IsGLPosted],  
			  [Amount_Amount],  
			  [Amount_Currency],  
			  [Balance_Amount],  
			  [Balance_Currency],  
			  [EffectiveBalance_Amount],  
			  [EffectiveBalance_Currency],  
			  [IsDummy],
			  [GlTemplateId],
			  [IsCashBased]
			 )  	 
		  VALUES(@CreatedById,  
                 @CreatedTime,  
                 [ReceivableId],  
                 1,  
                 0,  
                 [Amount_Amount],  
                 [Amount_Currency],  
                 [Balance_Amount],  
                 [Balance_Currency],  
                 [EffectiveBalance_Amount],  
                 [EffectiveBalance_Currency],  
                 0,
				 [GlTemplateId],
				 [IsCashBased])
		  
		  WHEN MATCHED THEN
			UPDATE SET TargetReceivableTax.UpdatedById = @CreatedById, TargetReceivableTax.UpdatedTime = @CreatedTime,
					   TargetReceivableTax.Amount_Amount = TargetReceivableTax.Amount_Amount + SourceReceivableTax.Amount_Amount,
					   TargetReceivableTax.Balance_Amount = TargetReceivableTax.Balance_Amount + SourceReceivableTax.Balance_Amount,
					   TargetReceivableTax.EffectiveBalance_Amount = TargetReceivableTax.EffectiveBalance_Amount + SourceReceivableTax.EffectiveBalance_Amount
			
		  OUTPUT INSERTED.Id AS ReceivableTaxId, INSERTED.ReceivableId AS ReceivableId INTO #InsertedReceivableTaxes;

		  
SELECT
				TaxBasisType,  
                Revenue_Amount,  
                Revenue_Currency,  
                FairMarketValue_Amount,  
                FairMarketValue_Currency,  
                Cost_Amount,  
                Cost_Currency,  
                TaxAreaId ,
				AssetLocationId,  
                LocationId,  
                AssetId,  
                ReceivableDetailId,  
                IRT.ReceivableTaxId, 
				Amount_Amount,  
                Amount_Currency,  
                Balance_Amount,  
                Balance_Currency,  
                EffectiveBalance_Amount,  
                EffectiveBalance_Currency,
				UpfrontPayableFactor,
				TaxCodeId
INTO #Temp_ReceivableTaxDetailsParameters
FROM @ReceivableTaxDetailParameter RTP  
INNER JOIN #InsertedReceivableTaxes IRT ON RTP.ReceivableId = IRT.ReceivableId;  

MERGE [ReceivableTaxDetails] AS TargetReceivableTaxDetail
USING (SELECT * FROM #Temp_ReceivableTaxDetailsParameters WHERE AssetId IS NOT NULL) AS SourceReceivableTaxDetail
ON (TargetReceivableTaxDetail.ReceivableDetailId = SourceReceivableTaxDetail.ReceivableDetailId AND 
TargetReceivableTaxDetail.AssetId = SourceReceivableTaxDetail.AssetId AND TargetReceivableTaxDetail.IsActive = 1 ) 
WHEN NOT MATCHED THEN
INSERT   
         ([TaxBasisType],  
          [Revenue_Amount],  
          [Revenue_Currency],  
          [FairMarketValue_Amount],  
          [FairMarketValue_Currency],  
          [Cost_Amount],  
          [Cost_Currency],  
          [TaxAreaId],  
          [IsActive],  
          [ManuallyAssessed],  
          [CreatedById],  
          [CreatedTime],  
          [AssetLocationId],  
          [LocationId],  
          [AssetId],  
          [ReceivableDetailId],  
          [ReceivableTaxId],  
          [IsGLPosted],  
          [Amount_Amount],  
          [Amount_Currency],  
          [Balance_Amount],  
          [Balance_Currency],  
          [EffectiveBalance_Amount],  
          [EffectiveBalance_Currency],
		  [UpfrontTaxMode],
		  [UpfrontPayableFactor],
		  [TaxCodeId]
         ) 
  
        Values( TaxBasisType,  
                Revenue_Amount,  
                Revenue_Currency,  
                FairMarketValue_Amount,  
                FairMarketValue_Currency,  
                Cost_Amount,  
                Cost_Currency,  
                TaxAreaId,  
                1,  
                @IsManuallyAssessed,  
                @CreatedById,  
                @CreatedTime,  
                AssetLocationId,  
                LocationId,  
                AssetId,  
                ReceivableDetailId,  
                ReceivableTaxId,  
                0,  
                Amount_Amount,  
                Amount_Currency,  
                Balance_Amount,  
                Balance_Currency,  
                EffectiveBalance_Amount,  
                EffectiveBalance_Currency,
				'_',
				[UpfrontPayableFactor],
				[TaxCodeId]
 )WHEN MATCHED THEN
UPDATE SET TargetReceivableTaxDetail.UpdatedById = @CreatedById, TargetReceivableTaxDetail.UpdatedTime = SYSDATETIMEOFFSET(),
TargetReceivableTaxDetail.Amount_Amount = TargetReceivableTaxDetail.Amount_Amount + SourceReceivableTaxDetail.Amount_Amount,
TargetReceivableTaxDetail.Balance_Amount = TargetReceivableTaxDetail.Balance_Amount + SourceReceivableTaxDetail.Amount_Amount,
TargetReceivableTaxDetail.EffectiveBalance_Amount = TargetReceivableTaxDetail.EffectiveBalance_Amount + SourceReceivableTaxDetail.Amount_Amount
OUTPUT INSERTED.Id AS ReceivableTaxDetailId,  
                INSERTED.ReceivableDetailId AS ReceivableDetailId,  
				INSERTED.AssetId AS ReceivableDetailAssetId,
				$Action AS Action
                INTO #InsertedReceivableTaxDetails;  

 MERGE [ReceivableTaxDetails] AS TargetReceivableTaxDetail
USING (SELECT * FROM #Temp_ReceivableTaxDetailsParameters WHERE AssetId IS NULL) AS SourceReceivableTaxDetail
ON (TargetReceivableTaxDetail.ReceivableDetailId = SourceReceivableTaxDetail.ReceivableDetailId AND 
TargetReceivableTaxDetail.AssetId IS NULL AND TargetReceivableTaxDetail.IsActive = 1 ) 
WHEN NOT MATCHED THEN
INSERT   
         ([TaxBasisType],  
          [Revenue_Amount],  
          [Revenue_Currency],  
          [FairMarketValue_Amount],  
          [FairMarketValue_Currency],  
          [Cost_Amount],  
          [Cost_Currency],  
          [TaxAreaId],  
          [IsActive],  
          [ManuallyAssessed],  
          [CreatedById],  
          [CreatedTime],  
          [AssetLocationId],  
          [LocationId],  
          [AssetId],  
          [ReceivableDetailId],  
          [ReceivableTaxId],  
          [IsGLPosted],  
          [Amount_Amount],  
          [Amount_Currency],  
          [Balance_Amount],  
          [Balance_Currency],  
          [EffectiveBalance_Amount],  
          [EffectiveBalance_Currency],
		  [UpfrontTaxMode],
		  [UpfrontPayableFactor],
		  [TaxCodeId]
         ) 
  
        Values( TaxBasisType,  
                Revenue_Amount,  
                Revenue_Currency,  
                FairMarketValue_Amount,  
                FairMarketValue_Currency,  
                Cost_Amount,  
                Cost_Currency,  
                TaxAreaId,  
                1,  
                @IsManuallyAssessed,  
                @CreatedById,  
                @CreatedTime,  
                AssetLocationId,  
                LocationId,  
                AssetId,  
                ReceivableDetailId,  
                ReceivableTaxId,  
                0,  
                Amount_Amount,  
                Amount_Currency,  
                Balance_Amount,  
                Balance_Currency,  
                EffectiveBalance_Amount,  
                EffectiveBalance_Currency,
				'_',
				[UpfrontPayableFactor],
				[TaxCodeId]
 )WHEN MATCHED THEN
UPDATE SET TargetReceivableTaxDetail.UpdatedById = @CreatedById, TargetReceivableTaxDetail.UpdatedTime = SYSDATETIMEOFFSET(),
TargetReceivableTaxDetail.Amount_Amount = TargetReceivableTaxDetail.Amount_Amount + SourceReceivableTaxDetail.Amount_Amount,
TargetReceivableTaxDetail.Balance_Amount = TargetReceivableTaxDetail.Balance_Amount + SourceReceivableTaxDetail.Amount_Amount,
TargetReceivableTaxDetail.EffectiveBalance_Amount = TargetReceivableTaxDetail.EffectiveBalance_Amount + SourceReceivableTaxDetail.Amount_Amount
OUTPUT INSERTED.Id AS ReceivableTaxDetailId,  
                INSERTED.ReceivableDetailId AS ReceivableDetailId,  
				INSERTED.AssetId AS ReceivableDetailAssetId,
				$Action AS Action
                INTO #InsertedReceivableTaxDetails;  

  
         INSERT INTO [dbo].[ReceivableTaxImpositions]  
         (		[ExemptionType],  
          [ExemptionRate],  
          [ExemptionAmount_Amount],  
          [ExemptionAmount_Currency],  
          [TaxableBasisAmount_Amount],  
          [TaxableBasisAmount_Currency],  
          [AppliedTaxRate],  
          [Amount_Amount],  
          [Amount_Currency],  
          [Balance_Amount],  
          [Balance_Currency],  
          [EffectiveBalance_Amount],  
          [EffectiveBalance_Currency],  
          [ExternalTaxImpositionType],  
          [CreatedById],  
          [CreatedTime],  
          [TaxTypeId],  
          [ExternalJurisdictionLevelId],  
          [ReceivableTaxDetailId],  
          [IsActive],
		  [TaxBasisType]
		          )  
        SELECT [ExemptionType],  
                [ExemptionRate],  
                [ExemptionAmount_Amount],  
                [ExemptionAmount_Currency],  
                [TaxableBasisAmount_Amount],  
                [TaxableBasisAmount_Currency],  
                [AppliedTaxRate],  
                [Amount_Amount],  
                [Amount_Currency],  
                [Balance_Amount],  
                [Balance_Currency],  
                [EffectiveBalance_Amount],  
                [EffectiveBalance_Currency],  
                [ExternalTaxImpositionType],  
                @CreatedById,  
                @CreatedTime,  
                [TaxTypeId],  
                [ExternalJurisdictionLevelId],  
                [ReceivableTaxDetailId],  
                1,
				TaxBasisType
        FROM @ReceivableTaxImpositionParameter RTIP  
                INNER JOIN #InsertedReceivableTaxDetails IRTD ON RTIP.ReceivableDetailId = IRTD.ReceivableDetailId AND IRTD.Action = 'INSERT'
			    WHERE IRTD.ReceivableDetailAssetId = RTIP.AssetId OR RTIP.AssetId IS NULL;  
			;  

		INSERT INTO [dbo].[ReceivableTaxSKUImpositions]  
         (		[ExemptionType],  
          [ExemptionRate],  
          [ExemptionAmount_Amount],  
          [ExemptionAmount_Currency],  
          [TaxableBasisAmount_Amount],  
          [TaxableBasisAmount_Currency],  
          [AppliedTaxRate],  
          [Amount_Amount],  
          [Amount_Currency],  
          [ExternalTaxImpositionType],  
          [CreatedById],  
          [CreatedTime],  
          [TaxTypeId],  
          [ExternalJurisdictionLevelId],  
          [ReceivableTaxDetailId],  
          [IsActive],
		  [AssetSKUId],
		  [TaxBasisType]
         )  
        SELECT [ExemptionType],  
                [ExemptionRate],  
                [ExemptionAmount_Amount],  
                [ExemptionAmount_Currency],  
                [TaxableBasisAmount_Amount],  
                [TaxableBasisAmount_Currency],  
                [AppliedTaxRate],  
                [Amount_Amount],  
                [Amount_Currency],  
                [ExternalTaxImpositionType],  
                @CreatedById,  
                @CreatedTime,  
                [TaxTypeId],  
                [ExternalJurisdictionLevelId],  
                ReceivableTaxDetailId,  
                1,
				[AssetSKUId],
				TaxBasisType
        FROM @ReceivableTaxSKUImpositionParameter RTSKUIP  
                 INNER JOIN #InsertedReceivableTaxDetails IRTD ON RTSKUIP.ReceivableDetailId = IRTD.ReceivableDetailId AND IRTD.Action = 'INSERT'
			     WHERE IRTD.ReceivableDetailAssetId = RTSKUIP.AssetId OR RTSKUIP.AssetId IS NULL;

  
         INSERT INTO [dbo].[ReceivableTaxReversalDetails]  
         (		[Id],  
          [IsExemptAtAsset],  
          [IsExemptAtLease],  
          [IsExemptAtSundry],  
          [Company],  
          [Product],  
          [ContractType],  
          [AssetType],  
          [LeaseType],  
          [LeaseTerm],  
          [TitleTransferCode],  
          [TransactionCode],  
          [AmountBilledToDate],  
          [CreatedById],  
          [CreatedTime],  
          [AssetId],  
          [AssetLocationId],  
          [ToStateName],  
          [FromStateName] ,
		  [SalesTaxRemittanceResponsibility],
          [IsCapitalizeUpfrontSalesTax],
		  [UpfrontTaxAssessedInLegacySystem],
		  [BusCode]
         )  
        SELECT  IRTD.ReceivableTaxDetailId,  
                [IsExemptAtAsset],  
                [IsExemptAtLease],  
                [IsExemptAtSundry],  
                [Company],  
                [Product],  
                [ContractType],  
                [AssetType],  
                [LeaseType],  
                [LeaseTerm],  
                [TitleTransferCode],  
                [TransactionCode],  
                [AmountBilledToDate],  
                @CreatedById,  
                @CreatedTime,  
                [AssetId],  
                [AssetLocationId],  
                [ToStateName],  
                [FromStateName] ,
				[SalesTaxRemittanceResponsibility],
                [IsCapitalizeUpfrontSalesTax],
				[UpfrontTaxAssessedInLegacySystem],
				[BusCode]
        FROM @ReceivableTaxReversalDetailParameter RTRDP  
        INNER JOIN #InsertedReceivableTaxDetails IRTD ON RTRDP.ReceivableDetailId = IRTD.ReceivableDetailId AND IRTD.Action = 'INSERT'
        WHERE (IRTD.ReceivableDetailAssetId = RTRDP.AssetId OR RTRDP.AssetId IS NULL);  


INSERT INTO [dbo].[ReceivableSKUTaxReversalDetails]  
         ( 
          [Revenue_Amount],  
          [Revenue_Currency],  
          [FairMarketValue_Amount],  
          [FairMarketValue_Currency],  
          [Cost_Amount],  
          [Cost_Currency],  
          [IsActive],   
          [CreatedById],  
          [CreatedTime],  
          [AssetSKUId],  
          [ReceivableSKUId],  
          [ReceivableTaxDetailId],  
          [Amount_Amount],  
          [Amount_Currency],
		  [IsExemptAtAssetSKU],   
          [AmountBilledToDate_Amount],
		  [AmountBilledToDate_Currency] 
         )  
        SELECT  
                [Revenue_Amount],  
                [Revenue_Currency],  
                [FairMarketValue_Amount],  
                [FairMarketValue_Currency],  
                [Cost_Amount],  
                [Cost_Currency],  
                1,   
                @CreatedById,  
                @CreatedTime,  
                [AssetSKUId],  
                [ReceivableSKUId],  
                IRTD.ReceivableTaxDetailId,  
                [Amount_Amount],  
                [Amount_Currency],
				[IsExemptAtAssetSKU],
				[AmountBilledToDate_Amount],
				[Amount_Currency]
        FROM @ReceivableSKUTaxReversalDetailParameter RSTP  
                 INNER JOIN #InsertedReceivableTaxDetails IRTD ON RSTP.ReceivableDetailId = IRTD.ReceivableDetailId  AND IRTD.Action = 'INSERT';
				 
  UPDATE ReceivableDetails   
  SET IsTaxAssessed = 1 , UpdatedById = @CreatedById, UpdatedTime = @CreatedTime  
  FROM ReceivableDetails  
  JOIN #InsertedReceivableTaxDetails InsertedReceivableTaxDetail 
  ON ReceivableDetails.Id = InsertedReceivableTaxDetail.ReceivableDetailId  AND InsertedReceivableTaxDetail.Action = 'INSERT'    
  
  DROP TABLE #InsertedReceivableTaxDetails;  
  DROP TABLE #InsertedReceivableTaxes;   
   
  END;

GO
