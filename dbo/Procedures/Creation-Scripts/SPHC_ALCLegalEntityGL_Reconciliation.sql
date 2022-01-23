SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_ALCLegalEntityGL_Reconciliation]
(@AssetLifeCycleData      AssetLifeCycleDataType READONLY, 
 @AssetPurchaseAPData     AssetPurchaseAPDataType READONLY, 
 @BookValueAdjustmentData BookValueAdjustmentDataType READONLY, 
 @ContractData            ContractDataType READONLY, 
 @AssetSaleData           AssetSaleDataType READONLY, 
 @PaydownData             PaydownDataType READONLY, 
 @BookDepreciationData    BookDepreciationDataType READONLY, 
 @ResultOption            NVARCHAR(20),
 @LegalEntityIds ReconciliationId READONLY
)
AS

    BEGIN

	IF OBJECT_ID('tempdb..#EligibleLegalEntities') IS NOT NULL
			DROP TABLE #EligibleLegalEntities;
		
	IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
			DROP TABLE #ResultList;
		
	IF OBJECT_ID('tempdb..#LegalEntitySummary') IS NOT NULL
			DROP TABLE #LegalEntitySummary;

        DECLARE @True BIT= 1;
        DECLARE @False BIT= 0;
		DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)

		SELECT 
			le.Name AS LegalEntityName
			,le.LegalEntityNumber
		INTO #EligibleLegalEntities
		FROM LegalEntities le
		WHERE @True = (CASE
						WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = le.Id) THEN @True
						WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False
					END)

        SELECT *
             , CASE
                   WHEN t.AcquisitionCost_Difference != 0.00
                        OR t.AssetBookValueAdjustment_Difference != 0.00
						OR t.ETC_Difference != 0.00
						OR t.CapitalizedCost_Difference != 0.00
                        OR t.ReturnedToInventory_Paydown_Difference != 0.00
						OR t.LeasedAssetCost_Difference != 0.00
                        OR t.AssetAmortizedValue_Difference != 0.00
                        OR t.ClearedDepreciation_Difference != 0.00
                        OR t.ClearedImpairment_Difference != 0.00
                        OR t.CostOfGoodsSold_Difference != 0.00
						OR t.ChargeOff_Difference != 0.00
						OR t.InventoryBalance_Difference != 0.00
                        OR t.AccumulatedFixedTermDepreciation_Difference != 0.00
                        OR t.AccumulatedOTPDepreciation_Difference != 0.00
                        OR t.AccumulatedAssetDepreciation_Difference != 0.00
                        OR t.AccumulatedNBVImpairment_Difference != 0.00
                        OR t.AccumulatedAssetImpairment_Difference != 0.00
                   THEN 'Problem Record'
                   ELSE 'Not Problem Record'
               END [Result]
        INTO #ResultList
        FROM
        (
            SELECT le.LegalEntityName
                 , le.LegalEntityNumber
                 , ISNULL(alc.AcquisitionCost_Table, 0.00) AS AcquisitionCost_Table
                 , ISNULL(ap.AcquisitionCost_GL, 0.00) AS AcquisitionCost_GL
                 , ISNULL(alc.AcquisitionCost_Table, 0.00) - ISNULL(ap.AcquisitionCost_GL, 0.00) AS AcquisitionCost_Difference

                 , ISNULL(alc.AssetBookValueAdjustment_Table, 0.00) AS AssetBookValueAdjustment_Table
                 , ISNULL(bva.AssetBookValueAdjustment_GL, 0.00) AS AssetBookValueAdjustment_GL
                 , ISNULL(alc.AssetBookValueAdjustment_Table, 0.00) - ISNULL(bva.AssetBookValueAdjustment_GL, 0.00) AS AssetBookValueAdjustment_Difference

				 , ISNULL(alc.ETC_Table, 0.00) AS ETC_Table
				 , ISNULL(c.ETC_CT_GL, 0.00) AS ETC_GL
				 , ISNULL(alc.ETC_Table, 0.00) - ISNULL(c.ETC_CT_GL, 0.00) AS ETC_Difference

				 , ISNULL(alc.CapitalizedCost_Table,0.00) AS CapitalizedCost_Table
				 , ISNULL(c.CapitalizedCost_CT_GL,0.00) AS CapitalizedCost_GL
				 , ISNULL(alc.CapitalizedCost_Table,0.00) - ISNULL(c.CapitalizedCost_CT_GL,0.00) AS CapitalizedCost_Difference

                 , ISNULL(alc.ReturnedToInventory_Paydown_Table, 0.00) AS ReturnedToInventory_Paydown_Table
                 , ISNULL(pd.ReturnedToInventory_Paydown_GL, 0.00) AS ReturnedToInventory_Paydown_GL
                 , ISNULL(alc.ReturnedToInventory_Paydown_Table, 0.00) - ISNULL(pd.ReturnedToInventory_Paydown_GL, 0.00) AS ReturnedToInventory_Paydown_Difference
				 
				 , ISNULL(alc.LeasedAssetCost_Table,0.00) AS LeasedAssetCost_Table
				 , (ISNULL(c.Inventory_CT_GL,0.00) - ISNULL(c.ETC_LAC_CT_GL,0.00) + ISNULL(c.CapitalizedCost_LAC_CT_GL,0.00))
					- ISNULL(c.SyndicationLARTI_CT_GL,0.00)
					- (ISNULL(c.PaidOffAssets_LAC_Table,0.00) - ISNULL(c.PaidOffAssets_LAC_ETC_Table,0.00))
					- ISNULL(alc.RenewalAmortizedValue_Table,0.00)
					- ISNULL(alc.LeasedChargedOff_Table,0.00) AS LeasedAssetCost_GL
				 , (ISNULL(alc.LeasedAssetCost_Table,0.00))
				 - ((ISNULL(c.Inventory_CT_GL,0.00) - ISNULL(c.ETC_LAC_CT_GL,0.00) + ISNULL(c.CapitalizedCost_LAC_CT_GL,0.00))
					- ISNULL(c.SyndicationLARTI_CT_GL,0.00)
					- (ISNULL(c.PaidOffAssets_LAC_Table,0.00) - ISNULL(c.PaidOffAssets_LAC_ETC_Table,0.00))
					- ISNULL(alc.RenewalAmortizedValue_Table,0.00)
					- ISNULL(alc.LeasedChargedOff_Table,0.00)) AS LeasedAssetCost_Difference

				 , ISNULL(alc.AssetAmortizedValue_Table, 0.00) AS AssetAmortizedValue_Table
				 , (((ISNULL(c.PaidOffAssets_Inventory_Table,0.00) - ISNULL(c.PaidOffAssets_ETC_Table,0.00)))
				 - (ISNULL(c.PaidOffAssets_LARTI_GL,0.00))
				 - (ISNULL(c.OperatingAmortCleared_CT_GL,0.00))
				 - (ISNULL(c.CapitalAmortCleared_CT_GL,0.00))
				 - (ISNULL(c.FinanceChargeOffAmount_Table,0.00))) AS AssetAmortizedValue_GL
				 , (ISNULL(alc.AssetAmortizedValue_Table, 0.00))
				 - ((((ISNULL(c.PaidOffAssets_Inventory_Table,0.00) - ISNULL(c.PaidOffAssets_ETC_Table,0.00)))
				 - (ISNULL(c.PaidOffAssets_LARTI_GL,0.00))
				 - (ISNULL(c.OperatingAmortCleared_CT_GL,0.00))
				 - (ISNULL(c.CapitalAmortCleared_CT_GL,0.00))
				 - (ISNULL(c.FinanceChargeOffAmount_Table,0.00)))) AS AssetAmortizedValue_Difference

                 , ISNULL(alc.ClearedDepreciation_Table, 0.00) AS ClearedDepreciation_Table
                 , ISNULL(bva.AccumulatedAssetDepreciation_BVA_GL, 0.00) + ISNULL(c.ClearedDepreciation_CT_GL, 0.00) + ISNULL(ats.AccumulatedAssetDepreciation_AS_GL, 0.00) AS ClearedDepreciation_GL
                 , ISNULL(alc.ClearedDepreciation_Table, 0.00) - (ISNULL(bva.AccumulatedAssetDepreciation_BVA_GL, 0.00) + ISNULL(c.ClearedDepreciation_CT_GL, 0.00) + ISNULL(ats.AccumulatedAssetDepreciation_AS_GL, 0.00)) AS ClearedDepreciation_Difference

                 , ISNULL(alc.ClearedImpairment_Table, 0.00) AS ClearedImpairment_Table
                 , ISNULL(bva.AccumulatedAssetImpairment_BVA_GL, 0.00) + ISNULL(c.ClearedImpairment_CT_GL, 0.00) + ISNULL(ats.AccumulatedAssetImpairment_AS_GL, 0.00) AS ClearedImpairment_GL
                 , ISNULL(alc.ClearedImpairment_Table, 0.00) - (ISNULL(bva.AccumulatedAssetImpairment_BVA_GL, 0.00) + ISNULL(c.ClearedImpairment_CT_GL, 0.00) + ISNULL(ats.AccumulatedAssetImpairment_AS_GL, 0.00)) AS ClearedImpairment_Difference

                 , ISNULL(alc.CostOfGoodsSold_Table, 0.00) AS CostOfGoodsSold_Table
                 , ISNULL(c.CostOfGoodsSold_CT_GL, 0.00) + ISNULL(ats.CostOfGoodsSold_AS_GL, 0.00) AS CostOfGoodsSold_GL
                 , ISNULL(alc.CostOfGoodsSold_Table, 0.00) - (ISNULL(c.CostOfGoodsSold_CT_GL, 0.00) + ISNULL(ats.CostOfGoodsSold_AS_GL, 0.00)) AS CostOfGoodsSold_Difference

				 , ISNULL(alc.ChargeOff_Table, 0.00) AS ChargeOff_Table
				 , ISNULL(c.ChargeOff_CT_GL, 0.00) AS ChargeOff_GL
				 , ISNULL(alc.ChargeOff_Table, 0.00) - ISNULL(c.ChargeOff_CT_GL, 0.00) AS ChargeOff_Difference

				 , (ISNULL(alc.AcquisitionCost_Table, 0.00)
					+ ISNULL(alc.AssetBookValueAdjustment_Table, 0.00)
					- ISNULL(alc.ETC_Table, 0.00)
					+ ISNULL(alc.CapitalizedCost_Table,0.00)
					+ ISNULL(alc.ReturnedToInventory_Paydown_Table, 0.00)
					- ISNULL(alc.LeasedAssetCost_Table,0.00)
					- ISNULL(alc.AssetAmortizedValue_Table, 0.00)
					- ISNULL(alc.ClearedDepreciation_Table, 0.00)
					- ISNULL(alc.ClearedImpairment_Table, 0.00)
					- ISNULL(alc.CostOfGoodsSold_Table, 0.00)
					- ISNULL(alc.ChargeOff_Table, 0.00)) AS InventoryBalance_Table
				 , (ISNULL(ap.AcquisitionCost_GL, 0.00)
					+ ISNULL(bva.AssetBookValueAdjustment_GL, 0.00)
					- ISNULL(c.ETC_CT_GL, 0.00)
					+ ISNULL(c.CapitalizedCost_CT_GL,0.00)
					+ ISNULL(pd.ReturnedToInventory_Paydown_GL, 0.00)
					- ((ISNULL(c.Inventory_CT_GL,0.00) - ISNULL(c.ETC_LAC_CT_GL,0.00) + ISNULL(c.CapitalizedCost_LAC_CT_GL,0.00))
						- ISNULL(c.SyndicationLARTI_CT_GL,0.00)
						- (ISNULL(c.PaidOffAssets_LAC_Table,0.00) - ISNULL(c.PaidOffAssets_LAC_ETC_Table,0.00))
						- ISNULL(alc.RenewalAmortizedValue_Table,0.00)
						- ISNULL(alc.LeasedChargedOff_Table,0.00))
					- (((ISNULL(c.PaidOffAssets_Inventory_Table,0.00) - ISNULL(c.PaidOffAssets_ETC_Table,0.00))
							+ (ISNULL(c.LeasedAssets_Inventory_Table,0.00) - ISNULL(c.ActiveAssets_ETC_Table,0.00)))
						- (ISNULL(c.LeasedAssets_Inventory_Table,0.00) - ISNULL(c.ActiveAssets_ETC_Table,0.00))
						- (ISNULL(c.PaidOffAssets_LARTI_GL,0.00))
						- (ISNULL(c.OperatingAmortCleared_CT_GL,0.00))
						- (ISNULL(c.CapitalAmortCleared_CT_GL,0.00))
						- (ISNULL(c.FinanceChargeOffAmount_Table,0.00)))
					- (ISNULL(bva.AccumulatedAssetDepreciation_BVA_GL, 0.00) + ISNULL(c.ClearedDepreciation_CT_GL, 0.00) + ISNULL(ats.AccumulatedAssetDepreciation_AS_GL, 0.00))
					- (ISNULL(bva.AccumulatedAssetImpairment_BVA_GL, 0.00) + ISNULL(c.ClearedImpairment_CT_GL, 0.00) + ISNULL(ats.AccumulatedAssetImpairment_AS_GL, 0.00))
					- (ISNULL(c.CostOfGoodsSold_CT_GL, 0.00) + ISNULL(ats.CostOfGoodsSold_AS_GL, 0.00))
					- (ISNULL(c.ChargeOff_CT_GL,0.00))) AS InventoryBalance_GL
				 , (ISNULL(alc.AcquisitionCost_Table, 0.00)
					+ ISNULL(alc.AssetBookValueAdjustment_Table, 0.00)
					- ISNULL(alc.ETC_Table, 0.00)
					+ ISNULL(alc.CapitalizedCost_Table,0.00)
					+ ISNULL(alc.ReturnedToInventory_Paydown_Table, 0.00)
					- ISNULL(alc.LeasedAssetCost_Table,0.00)
					- ISNULL(alc.AssetAmortizedValue_Table, 0.00)
					- ISNULL(alc.ClearedDepreciation_Table, 0.00)
					- ISNULL(alc.ClearedImpairment_Table, 0.00)
					- ISNULL(alc.CostOfGoodsSold_Table, 0.00)
					- ISNULL(alc.ChargeOff_Table, 0.00))
				 - (ISNULL(ap.AcquisitionCost_GL, 0.00)
					+ ISNULL(bva.AssetBookValueAdjustment_GL, 0.00)
					- ISNULL(c.ETC_CT_GL, 0.00)
					+ ISNULL(c.CapitalizedCost_CT_GL,0.00)
					+ ISNULL(pd.ReturnedToInventory_Paydown_GL, 0.00)
					- ((ISNULL(c.Inventory_CT_GL,0.00) - ISNULL(c.ETC_LAC_CT_GL,0.00) + ISNULL(c.CapitalizedCost_LAC_CT_GL,0.00))
						- ISNULL(c.SyndicationLARTI_CT_GL,0.00)
						- (ISNULL(c.PaidOffAssets_LAC_Table,0.00) - ISNULL(c.PaidOffAssets_LAC_ETC_Table,0.00))
						- ISNULL(alc.RenewalAmortizedValue_Table,0.00)
						- ISNULL(alc.LeasedChargedOff_Table,0.00))
					- (((ISNULL(c.PaidOffAssets_Inventory_Table,0.00) - ISNULL(c.PaidOffAssets_ETC_Table,0.00))
							+ (ISNULL(c.LeasedAssets_Inventory_Table,0.00) - ISNULL(c.ActiveAssets_ETC_Table,0.00)))
						- (ISNULL(c.LeasedAssets_Inventory_Table,0.00) - ISNULL(c.ActiveAssets_ETC_Table,0.00))
						- (ISNULL(c.PaidOffAssets_LARTI_GL,0.00))
						- (ISNULL(c.OperatingAmortCleared_CT_GL,0.00))
						- (ISNULL(c.CapitalAmortCleared_CT_GL,0.00))
						- (ISNULL(c.FinanceChargeOffAmount_Table,0.00)))
					- (ISNULL(bva.AccumulatedAssetDepreciation_BVA_GL, 0.00) + ISNULL(c.ClearedDepreciation_CT_GL, 0.00) + ISNULL(ats.AccumulatedAssetDepreciation_AS_GL, 0.00))
					- (ISNULL(bva.AccumulatedAssetImpairment_BVA_GL, 0.00) + ISNULL(c.ClearedImpairment_CT_GL, 0.00) + ISNULL(ats.AccumulatedAssetImpairment_AS_GL, 0.00))
					- (ISNULL(c.CostOfGoodsSold_CT_GL, 0.00) + ISNULL(ats.CostOfGoodsSold_AS_GL, 0.00))
					- (ISNULL(c.ChargeOff_CT_GL,0.00))) AS InventoryBalance_Difference

                 , ISNULL(alc.AccumulatedFixedTermDepreciation_Table, 0.00) AS AccumulatedFixedTermDepreciation_Table
                 , ISNULL(c.AccumulatedFixedTermDepreciation_CT_GL, 0.00) AS AccumulatedFixedTermDepreciation_GL
                 , ISNULL(alc.AccumulatedFixedTermDepreciation_Table, 0.00) - ISNULL(c.AccumulatedFixedTermDepreciation_CT_GL, 0.00) AS AccumulatedFixedTermDepreciation_Difference

                 , ISNULL(alc.AccumulatedOTPDepreciation_Table, 0.00) AS AccumulatedOTPDepreciation_Table
                 , ISNULL(c.AccumulatedOTPDepreciation_CT_GL, 0.00) AS AccumulatedOTPDepreciation_GL
                 , ISNULL(alc.AccumulatedOTPDepreciation_Table, 0.00) - ISNULL(c.AccumulatedOTPDepreciation_CT_GL, 0.00) AS AccumulatedOTPDepreciation_Difference

                 , ISNULL(alc.AccumulatedAssetDepreciation_Table, 0.00) AS AccumulatedAssetDepreciation_Table
                 , ISNULL(c.AccumulatedAssetDepreciation_CT_GL, 0.00) + ISNULL(bd.AccumulatedAssetDepreciation_BD_GL, 0.00) - ISNULL(ats.AccumulatedAssetDepreciation_AS_GL,0.00) - ISNULL(bva.AccumulatedAssetDepreciation_BVA_GL,0.00) AS AccumulatedAssetDepreciation_GL
                 , ISNULL(alc.AccumulatedAssetDepreciation_Table, 0.00) - (ISNULL(c.AccumulatedAssetDepreciation_CT_GL, 0.00) + ISNULL(bd.AccumulatedAssetDepreciation_BD_GL, 0.00) - ISNULL(ats.AccumulatedAssetDepreciation_AS_GL,0.00) - ISNULL(bva.AccumulatedAssetDepreciation_BVA_GL,0.00)) AS AccumulatedAssetDepreciation_Difference

                 , ISNULL(alc.AccumulatedNBVImpairment_Table, 0.00) AS AccumulatedNBVImpairment_Table
                 , ISNULL(c.AccumulatedNBVImpairment_CT_GL, 0.00) AS AccumulatedNBVImpairment_GL
                 , ISNULL(alc.AccumulatedNBVImpairment_Table, 0.00) - ISNULL(c.AccumulatedNBVImpairment_CT_GL, 0.00) AS AccumulatedNBVImpairment_Difference

                 , ISNULL(alc.AccumulatedAssetImpairment_Table, 0.00) AS AccumulatedAssetImpairment_Table
                 , ISNULL(c.AccumulatedAssetImpairment_CT_GL, 0.00) + ISNULL(bva.AccumulatedImpairment_GL,0.00) - ISNULL(ats.AccumulatedAssetImpairment_AS_GL,0.00) - ISNULL(bva.AccumulatedAssetImpairment_BVA_GL,0.00) AS AccumulatedAssetImpairment_GL
                 , ISNULL(alc.AccumulatedAssetImpairment_Table, 0.00) - (ISNULL(c.AccumulatedAssetImpairment_CT_GL, 0.00) + ISNULL(bva.AccumulatedImpairment_GL,0.00) - ISNULL(ats.AccumulatedAssetImpairment_AS_GL,0.00) - ISNULL(bva.AccumulatedAssetImpairment_BVA_GL,0.00)) AS AccumulatedAssetImpairment_Difference
            FROM #EligibleLegalEntities le
                 LEFT JOIN @AssetLifeCycleData alc ON alc.LegalEntityName = le.LegalEntityName
                 LEFT JOIN @AssetPurchaseAPData ap ON ap.LegalEntityName = le.LegalEntityName
                 LEFT JOIN @BookValueAdjustmentData bva ON bva.LegalEntityName = le.LegalEntityName
                 LEFT JOIN @ContractData c ON c.LegalEntityName = le.LegalEntityName
                 LEFT JOIN @AssetSaleData ats ON ats.LegalEntityName = le.LegalEntityName
                 LEFT JOIN @PaydownData pd ON pd.LegalEntityName = le.LegalEntityName
                 LEFT JOIN @BookDepreciationData bd ON bd.LegalEntityName = le.LegalEntityName
        ) AS t
        ORDER BY LegalEntityName;

        SELECT name AS Name
             , 0 AS Count
             , CAST(0 AS BIT) AS IsProcessed
             , CAST('' AS NVARCHAR(MAX)) AS Label
			 , column_Id AS ColumnId
        INTO #LegalEntitySummary
        FROM tempdb.sys.columns
        WHERE object_id = OBJECT_ID('tempdb..#ResultList')
              AND Name LIKE '%Difference';

        DECLARE @query NVARCHAR(MAX);
        DECLARE @TableName NVARCHAR(MAX);
        WHILE EXISTS (SELECT 1 FROM #LegalEntitySummary WHERE IsProcessed = 0)
            BEGIN
                SELECT TOP 1 @TableName = Name
                FROM #LegalEntitySummary
                WHERE IsProcessed = 0;
                SET @query = 'UPDATE #LegalEntitySummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName + ' != 0.00), IsProcessed = 1
        				WHERE Name = ''' + @TableName + ''' ;';
                EXEC (@query);
            END;

        UPDATE #LegalEntitySummary SET 
                               Label = CASE
                                           WHEN Name = 'AcquisitionCost_Difference'
                                           THEN '1_Acquisition Cost_Difference'
                                           WHEN Name = 'AssetBookValueAdjustment_Difference'
                                           THEN '2_Asset Book Value Adjustment_Difference'
                                           WHEN Name = 'ETC_Difference'
                                           THEN '3_ETC_Difference'
                                           WHEN Name = 'CapitalizedCost_Difference'
                                           THEN '4_Capitalized Cost_Difference'
                                           WHEN Name = 'ReturnedToInventory_Paydown_Difference'
                                           THEN '5_Returned To Inventory_Paydown_Difference'
                                           WHEN Name = 'LeasedAssetCost_Difference'
                                           THEN '6_Leased Asset Cost_Difference'
                                           WHEN Name = 'AssetAmortizedValue_Difference'
                                           THEN '7_Asset Amortized Value_Difference'
                                           WHEN Name = 'ClearedDepreciation_Difference'
                                           THEN '8_Cleared Depreciation_Difference'
                                           WHEN Name = 'ClearedImpairment_Difference'
                                           THEN '9_Cleared Impairment_Difference'
                                           WHEN Name = 'CostOfGoodsSold_Difference'
                                           THEN '10_Cost Of Goods Sold_Difference'
                                           WHEN Name = 'ChargeOff_Difference'
                                           THEN '11_ChargeOff_Difference'
                                           WHEN Name = 'InventoryBalance_Difference'
                                           THEN '12_Inventory Balance_Difference'
                                           WHEN Name = 'AccumulatedFixedTermDepreciation_Difference'
                                           THEN '13_Accumulated Fixed Term Depreciation_Difference'
                                           WHEN Name = 'AccumulatedOTPDepreciation_Difference'
                                           THEN '14_Accumulated OTP Depreciation_Difference'
                                           WHEN Name = 'AccumulatedAssetDepreciation_Difference'
                                           THEN '15_Accumulated Asset Depreciation_Difference'
                                           WHEN Name = 'AccumulatedNBVImpairment_Difference'
                                           THEN '16_Accumulated NBV Impairment_Difference'
                                           WHEN Name = 'AccumulatedAssetImpairment_Difference'
                                           THEN '17_Accumulated Asset Impairment_Difference'
                                       END;
        SELECT Label AS Name
             , Count
        FROM #LegalEntitySummary
		ORDER BY ColumnId;
		
        IF(@ResultOption = 'All')
            BEGIN
                SELECT *
                FROM #ResultList
                ORDER BY LegalEntityName;
        END;

        IF(@ResultOption = 'Failed')
            BEGIN
                SELECT *
                FROM #ResultList
                WHERE Result = 'Problem Record'
                ORDER BY LegalEntityName;
        END;

        IF(@ResultOption = 'Passed')
            BEGIN
                SELECT *
                FROM #ResultList
                WHERE Result = 'Not Problem Record'
                ORDER BY LegalEntityName;
        END;

        DECLARE @TotalCount BIGINT;
        SELECT @TotalCount = ISNULL(COUNT(*), 0)
        FROM #ResultList;

        DECLARE @InCorrectCount BIGINT;
        SELECT @InCorrectCount = ISNULL(COUNT(*), 0)
        FROM #ResultList
        WHERE Result = 'Problem Record';

        DECLARE @Messages STOREDPROCMESSAGE;

        INSERT INTO @Messages (Name, ParameterValuesCsv)
        VALUES ('TotalLegalEntities',(SELECT 'LegalEntities=' + CONVERT(NVARCHAR(40), @TotalCount)));
        INSERT INTO @Messages (Name, ParameterValuesCsv)
        VALUES ('LegalEntitiesSuccessful',(SELECT 'LegalEntitiesSuccessful=' + CONVERT(NVARCHAR(40), (@TotalCount - @InCorrectCount))));
		INSERT INTO @Messages (Name, ParameterValuesCsv)
        VALUES ('LegalEntitiesIncorrect',(SELECT 'LegalEntitiesIncorrect=' + CONVERT(NVARCHAR(40), @InCorrectCount)));
		INSERT INTO @Messages (Name, ParameterValuesCsv)
		VALUES ('LegalEntitiesResultOption',(SELECT 'ResultOption=' + CONVERT(NVARCHAR(40), @ResultOption)));

        SELECT * FROM @Messages;
		
		DROP TABLE #EligibleLegalEntities;
		DROP TABLE #ResultList;
		DROP TABLE #LegalEntitySummary;

    END;

GO
