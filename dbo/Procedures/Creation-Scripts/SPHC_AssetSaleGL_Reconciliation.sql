SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_AssetSaleGL_Reconciliation]
(@ResultOption      NVARCHAR(20), 
 @IsFromLegalEntity BIT NULL, 
 @LegalEntityIds    ReconciliationId READONLY
)
AS
    BEGIN
        IF OBJECT_ID('tempdb..#InvestorAssets') IS NOT NULL
            DROP TABLE #InvestorAssets;
        IF OBJECT_ID('tempdb..#EligibleAssetSaleDetails') IS NOT NULL
            DROP TABLE #EligibleAssetSaleDetails;
        IF OBJECT_ID('tempdb..#AVHAssetsInfo') IS NOT NULL
            DROP TABLE #AVHAssetsInfo;
        IF OBJECT_ID('tempdb..#maxCleared') IS NOT NULL
            DROP TABLE #maxCleared;
        IF OBJECT_ID('tempdb..#minCleared') IS NOT NULL
            DROP TABLE #minCleared;
        IF OBJECT_ID('tempdb..#InventorySumInfo') IS NOT NULL
            DROP TABLE #InventorySumInfo;
		IF OBJECT_ID('tempdb..#InventoryTableInfo') IS NOT NULL
            DROP TABLE #InventoryTableInfo;
		IF OBJECT_ID('tempdb..#INValueInfo') IS NOT NULL
            DROP TABLE #INValueInfo;
		IF OBJECT_ID('tempdb..#INVenValueInfo') IS NOT NULL
            DROP TABLE #INVenValueInfo;
        IF OBJECT_ID('tempdb..#AssetSale_AccumulatedAmounts') IS NOT NULL
            DROP TABLE #AssetSale_AccumulatedAmounts;
        IF OBJECT_ID('tempdb..#AssetSale_AccumulatedAsset_GL') IS NOT NULL
            DROP TABLE #AssetSale_AccumulatedAsset_GL;
        IF OBJECT_ID('tempdb..#AssetSale_GL') IS NOT NULL
            DROP TABLE #AssetSale_GL;
        IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
            DROP TABLE #ResultList;
        IF OBJECT_ID('tempdb..#AssetSaleSummary') IS NOT NULL
            DROP TABLE #AssetSaleSummary;

		CREATE TABLE #AVHAssetsInfo
		(AssetId              BIGINT NOT NULL,
		IsLeaseAsset          BIT NOT NULL,
		IsFailedSaleLeaseback BIT NOT NULL
		);
		
		CREATE TABLE #maxCleared
		(AssetId          BIGINT NOT NULL, 
		 IsLeaseComponent BIT NOT NULL, 
		 MaxId            BIGINT NOT NULL
		);

		CREATE TABLE #minCleared
		(AssetSaleId      BIGINT NOT NULL,
         AssetId          BIGINT NOT NULL,
         IsLeaseComponent BIT NOT NULL,
         MinId            BIGINT NOT NULL
		 );
		
		CREATE TABLE #AssetSale_AccumulatedAmounts
		(AssetSaleId                       BIGINT NOT NULL,
		AccumulatedAssetDepreciation_Table DECIMAL (16, 2) NOT NULL,
		AccumulatedAssetImpairment_Table   DECIMAL (16, 2) NOT NULL
		);
		
		CREATE TABLE #InventoryTableInfo
		(AssetSaleId    BIGINT NOT NULL,
		Inventory_Table DECIMAL (16, 2) NOT NULL
		);

		CREATE TABLE #INValueInfo
		(AssetSaleId BIGINT NOT NULL,
		INValue      DECIMAL (16, 2) NOT NULL
		);

		CREATE TABLE #INVenValueInfo
		(AssetSaleId BIGINT NOT NULL,
		INValue      DECIMAL (16, 2) NOT NULL
		);

        DECLARE @True BIT= 1;
        DECLARE @False BIT= 0;
        DECLARE @LegalEntitiesCount BIGINT= ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0);
        DECLARE @FilterCondition NVARCHAR(MAX)= '';
        DECLARE @IsSku BIT= 0;
        DECLARE @Sql NVARCHAR(MAX)= '';
		DECLARE @IsLeaseComponent BIT = 0;

        IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
        BEGIN
			SET @FilterCondition = ' AND ea.IsSKU = 0';
			SET @IsSku = 1;
        END;

        IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AssetValueHistories' AND COLUMN_NAME = 'IsLeaseComponent')
        BEGIN
			SET @IsLeaseComponent = 1;
        END;

        SELECT asd.AssetId
        INTO #InvestorAssets
        FROM AssetSaleDetails asd
             INNER JOIN
        (
            SELECT DISTINCT 
                   AssetId
            FROM AssetHistories
            WHERE SourceModule = 'Payoff'
                  AND Status = 'Investor'
            INTERSECT
            SELECT DISTINCT 
                   AssetId
            FROM AssetHistories
            WHERE SourceModule = 'AssetSale'
                  AND Status = 'Sold'
        ) AS t ON t.AssetId = asd.AssetId;

        SELECT asd.AssetSaleId
             , sa.TransactionNumber
             , sa.TransactionDate
             , sa.LegalEntityId
             , sa.LineofBusinessId
             , sa.BuyerId
             , sa.CostCenterId
             , sa.BranchId
             , a.IsLeaseComponent
			 , a.PreviousSequenceNumber
			 , a.Status
             , asd.AssetId
             , CAST (0 AS bit) [IsSKU]
        INTO #EligibleAssetSaleDetails
        FROM AssetSaleDetails asd
             INNER JOIN AssetSales sa ON asd.AssetSaleId = sa.Id
             INNER JOIN Assets a ON a.Id = asd.AssetId
             LEFT JOIN AssetSalesTradeIns ast ON ast.AssetSaleId = sa.Id
        WHERE sa.Status = 'Completed'
            AND asd.AssetId NOT IN(SELECT AssetId FROM #InvestorAssets)
			AND @True = (CASE
                             WHEN @LegalEntitiesCount > 0 AND EXISTS(SELECT Id FROM @LegalEntityIds WHERE Id = sa.LegalEntityId)
                             THEN @True
                             WHEN @LegalEntitiesCount = 0
                             THEN @True
                             ELSE @False
                         END);

		CREATE NONCLUSTERED INDEX IX_Id ON #EligibleAssetSaleDetails(AssetSaleId);
		
		IF @IsSku = 1
		BEGIN
		SET @Sql =
		'UPDATE asd
		SET asd.IsSKU = 1
		FROM #EligibleAssetSaleDetails asd
		INNER JOIN Assets a ON asd.AssetId = a.Id AND a.IsSKU = 1'
		INSERT INTO #EligibleAssetSaleDetails
		EXEC (@Sql)
		END;
		
		INSERT INTO #AVHAssetsInfo
		SELECT 
			DISTINCT
			asd.AssetId
			,la.IsLeaseAsset
			,la.IsFailedSaleLeaseback
		FROM #EligibleAssetSaleDetails asd
		INNER JOIN LeaseAssets la ON asd.AssetId = la.AssetId
		INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		WHERE asd.PreviousSequenceNumber IS NULL
			AND asd.Status IN ('Leased','InvestorLeased')

		INSERT INTO #AVHAssetsInfo
		SELECT
			DISTINCT
			asd.AssetId
			,la.IsLeaseAsset
			,la.IsFailedSaleLeaseback
		FROM #EligibleAssetSaleDetails asd
		INNER JOIN LeaseAssets la ON asd.AssetId = la.AssetId
		INNER JOIN
		(SELECT 
			DISTINCT
			asd.AssetId
			,Max(la.LeaseFinanceId) LeaseFinanceId
		FROM #EligibleAssetSaleDetails asd
		INNER JOIN LeaseAssets la ON asd.AssetId = la.AssetId
		INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		WHERE asd.PreviousSequenceNumber IS NOT NULL
			AND asd.Status IN ('Leased','InvestorLeased')
		GROUP BY asd.AssetId) AS t ON t.AssetId = asd.AssetId AND t.LeaseFinanceId = la.LeaseFinanceId

		INSERT INTO #AVHAssetsInfo
		SELECT
			DISTINCT
			asd.AssetId
			,asd.IsLeaseComponent
			,CAST (0 AS BIT) IsFailedSaleLeaseback
		FROM #EligibleAssetSaleDetails asd
		WHERE asd.Status NOT IN ('Leased','InvestorLeased')

		CREATE NONCLUSTERED INDEX IX_Id ON #AVHAssetsInfo(AssetId);

		IF @IsLeaseComponent = 0
		BEGIN
		INSERT INTO #maxCleared
		SELECT
			t.AssetId
			,t.IsLeaseComponent
			,t.Id AS MaxId
		FROM (
        SELECT avh.AssetId
             , ai.IsLeaseAsset AS IsLeaseComponent
             , avh.Id
			 , ROW_NUMBER() OVER (PARTITION BY avh.AssetId
			   ORDER BY avh.Id DESC) AS rn
        FROM #EligibleAssetSaleDetails asd
             INNER JOIN AssetValueHistories avh ON asd.AssetId = avh.AssetId
			 INNER JOIN #AVHAssetsInfo ai ON ai.AssetId = avh.AssetId
        WHERE avh.IsAccounted = 1
              AND avh.IsCleared = 1
             AND avh.ReversalGLJournalId IS NULL
             AND avh.IncomeDate <= asd.TransactionDate
             AND avh.IsLessorOwned = 1
		) AS t
		WHERE t.rn = 1;
		END
		
		IF @IsLeaseComponent = 1
		BEGIN
		SET @Sql = '
		SELECT
			t.AssetId
			,t.IsLeaseComponent
			,t.Id AS MaxId
		FROM (
        SELECT avh.AssetId
             , avh.IsLeaseComponent
             , avh.Id
			 , ROW_NUMBER() OVER (PARTITION BY avh.AssetId
			   ORDER BY avh.Id DESC) AS rn
        FROM #EligibleAssetSaleDetails asd
             INNER JOIN AssetValueHistories avh ON asd.AssetId = avh.AssetId
        WHERE avh.IsAccounted = 1
              AND avh.IsCleared = 1
             AND avh.ReversalGLJournalId IS NULL
             AND avh.IncomeDate <= asd.TransactionDate
             AND avh.IsLessorOwned = 1
			 AND asd.IsSKU = 0
		) AS t
		WHERE t.rn = 1;'
		INSERT INTO #maxCleared
		EXEC (@Sql)
        
		SET @Sql = '
        SELECT avh.AssetId
             , avh.IsLeaseComponent
             , MAX(avh.Id) AS MaxId
        FROM #EligibleAssetSaleDetails asd
             INNER JOIN AssetValueHistories avh ON asd.AssetId = avh.AssetId
        WHERE avh.IsAccounted = 1
              AND avh.IsCleared = 1
             AND avh.ReversalGLJournalId IS NULL
             AND avh.IncomeDate <= asd.TransactionDate
             AND avh.IsLessorOwned = 1
			 AND asd.IsSKU = 1
        GROUP BY avh.AssetId
               , avh.IsLeaseComponent;'
		INSERT INTO #maxCleared
		EXEC (@Sql)
		END

        CREATE NONCLUSTERED INDEX IX_Id ON #maxCleared(MaxId);

		IF @IsLeaseComponent = 0
		BEGIN
		INSERT INTO #minCleared
        SELECT asd.AssetSaleId
             , avh.AssetId
             , t.IsLeaseComponent
             , MAX(avh.Id) AS MinId
        FROM AssetValueHistories avh
             INNER JOIN #MaxCleared AS t ON t.AssetId = avh.AssetId
                                            AND avh.Id < t.MaxId
             INNER JOIN #EligibleAssetSaleDetails asd ON asd.AssetId = avh.AssetId
        WHERE avh.IsAccounted = 1
              AND avh.IsCleared = 1
              AND avh.IncomeDate <= asd.TransactionDate
              AND avh.IsLessorOwned = 1
        GROUP BY asd.AssetSaleId
               , avh.AssetId
               , t.IsLeaseComponent;
		END

		IF @IsLeaseComponent = 1
		BEGIN
		SET @Sql = '
        SELECT asd.AssetSaleId
             , avh.AssetId
             , avh.IsLeaseComponent
             , MAX(avh.Id) AS MinId
        FROM AssetValueHistories avh
             INNER JOIN #MaxCleared AS t ON t.AssetId = avh.AssetId
                                            AND avh.Id < t.MaxId
											AND avh.IsLeaseComponent = t.IsLeaseComponent
             INNER JOIN #EligibleAssetSaleDetails asd ON asd.AssetId = avh.AssetId
        WHERE avh.IsAccounted = 1
              AND avh.IsCleared = 1
              AND avh.IncomeDate <= asd.TransactionDate
              AND avh.IsLessorOwned = 1
        GROUP BY asd.AssetSaleId
               , avh.AssetId
               , avh.IsLeaseComponent;'
		INSERT INTO #minCleared
		EXEC (@Sql)
		END

        CREATE NONCLUSTERED INDEX IX_Id ON #minCleared(AssetSaleId);

        SELECT DISTINCT asd.AssetSaleId
             , CAST(0.00 AS DECIMAL(16, 2)) [Inventory_Table]
             , CAST(0.00 AS DECIMAL(16, 2)) [MinAmountGL_Check]
        INTO #InventorySumInfo
        FROM #EligibleAssetSaleDetails asd;

        CREATE NONCLUSTERED INDEX IX_Id ON #InventorySumInfo(AssetSaleId);
		
		BEGIN
		SET @Sql = '
		SELECT asd.AssetSaleId
                , SUM(CASE
                        WHEN minc.AssetSaleId IS NOT NULL and avh.SourceModule NOT IN (''ResidualReclass'')
                        THEN avh.EndBookValue_Amount
                        ELSE 0.00
                    END) AS Inventory_Table
        FROM #EligibleAssetSaleDetails asd
                INNER JOIN AssetValueHistories avh ON asd.AssetId = avh.AssetId
                INNER JOIN #minCleared minc ON asd.AssetSaleId = minc.AssetSaleId
        WHERE avh.Id = MinId
                AND avh.IncomeDate <= asd.TransactionDate
                AND avh.IsAccounted = 1
                AND avh.IsCleared = 1
                AND avh.IsLessorOwned = 1
				AND avh.SourceModule NOT IN (''ResidualReclass'',''ResidualRecapture'')
				MaxMinIsLeaseComponent
        GROUP BY asd.AssetSaleId'
		IF @IsLeaseComponent = 1
		BEGIN
			SET @Sql = REPLACE(@Sql,'MaxMinIsLeaseComponent', 'AND avh.IsLeaseComponent = minc.IsLeaseComponent');
		END;
		ELSE
		BEGIN
			SET @Sql = REPLACE(@Sql,'MaxMinIsLeaseComponent','');
		END;
		INSERT INTO #InventoryTableInfo                
		EXEC (@Sql)
		END;
		
        CREATE NONCLUSTERED INDEX IX_Id ON #InventoryTableInfo(AssetSaleId);

        UPDATE isi SET 
                       isi.Inventory_Table = t.Inventory_Table
        FROM #InventorySumInfo isi
             INNER JOIN #InventoryTableInfo t ON isi.AssetSaleId = t.AssetSaleId;

		SELECT gld.SourceId
             , SUM(CASE
                       WHEN gle.Name = 'Inventory'
                            AND gld.IsDebit = 0
                       THEN Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gle.Name = 'Inventory'
                                       AND gld.IsDebit = 1
                                  THEN Amount_Amount
                                  ELSE 0.00
                              END) Inventory_GL
             , SUM(CASE
                       WHEN gle.Name = 'AccumulatedAssetDepreciation'
                            AND gld.IsDebit = 1
                       THEN Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gle.Name = 'AccumulatedAssetDepreciation'
                                       AND gld.IsDebit = 0
                                  THEN Amount_Amount
                                  ELSE 0.00
                              END) AccumulatedAssetDepreciation_GL
             , SUM(CASE
                       WHEN gle.Name = 'AccumulatedAssetImpairment'
                            AND gld.IsDebit = 1
                       THEN Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gle.Name = 'AccumulatedAssetImpairment'
                                       AND gld.IsDebit = 0
                                  THEN Amount_Amount
                                  ELSE 0.00
                              END) AccumulatedAssetImpairment_GL
             , SUM(CASE
                       WHEN gle.Name = 'CostOfGoodsSold'
                            AND gld.IsDebit = 1
                       THEN Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gle.Name = 'CostOfGoodsSold'
                                       AND gld.IsDebit = 0
                                  THEN Amount_Amount
                                  ELSE 0.00
                              END) CostofGoodsSold_GL
        INTO #AssetSale_GL
        FROM GLJournalDetails gld
             INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
             INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
             INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
             LEFT JOIN GLTemplateDetails mgltd ON mgltd.Id = gld.MatchingGLTemplateDetailId
             LEFT JOIN GLEntryItems mgle ON mgle.Id = mgltd.EntryItemId
             LEFT JOIN GLTransactionTypes mgltt ON mgle.GLTransactionTypeId = mgltt.Id
        WHERE gle.Name IN('AccumulatedAssetDepreciation', 'AccumulatedAssetImpairment', 'Inventory', 'CostOfGoodsSold')
             AND gltt.Name IN('AssetSale')
        GROUP BY gld.SourceId;

		CREATE NONCLUSTERED INDEX IX_Id ON #AssetSale_GL(SourceId);

		BEGIN
		SET @Sql = '
			SELECT asd.AssetSaleId
                 , SUM(avh.EndBookValue_Amount) AS INValue
            FROM #EligibleAssetSaleDetails asd
                 INNER JOIN AssetValueHistories avh ON asd.AssetId = avh.AssetId
                 INNER JOIN #maxCleared maxc ON asd.AssetId = maxc.AssetId
                                                AND avh.Id = maxc.MaxId                                                
                 LEFT JOIN #minCleared minc ON minc.AssetId = asd.AssetId
            WHERE minc.AssetId IS NULL
                  AND avh.IncomeDate <= asd.TransactionDate
                 AND avh.ReversalGLJournalId IS NULL
                 AND avh.IsAccounted = 1
                 AND avh.IsCleared = 1
                 AND avh.IsLessorOwned = 1
				 MaxMinIsLeaseComponent
            GROUP BY asd.AssetSaleId'
		IF @IsLeaseComponent = 1
		BEGIN
			SET @Sql = REPLACE(@Sql,'MaxMinIsLeaseComponent', 'AND avh.IsLeaseComponent = maxc.IsLeaseComponent');
		END;
		ELSE
		BEGIN
			SET @Sql = REPLACE(@Sql,'MaxMinIsLeaseComponent','');
		END;
		INSERT INTO #INValueInfo                
		EXEC (@Sql)
		END;
		
        CREATE NONCLUSTERED INDEX IX_Id ON #INValueInfo(AssetSaleId);

        UPDATE isi SET 
                       isi.Inventory_Table+=t.INValue
        FROM #InventorySumInfo isi
             INNER JOIN #INValueInfo t ON isi.AssetSaleId = t.AssetSaleId;

        UPDATE #InventorySumInfo SET 
                                     MinAmountGL_Check = 1
        FROM #InventorySumInfo isi
             INNER JOIN #AssetSale_GL asgl ON asgl.SourceId = isi.AssetSaleId
        WHERE asgl.Inventory_GL = isi.Inventory_Table;
		
		BEGIN
		SET @Sql = '
			SELECT asd.AssetSaleId
                , SUM(avh.EndBookValue_Amount) AS INValue
			FROM #EligibleAssetSaleDetails asd
					INNER JOIN AssetValueHistories avh ON asd.AssetId = avh.AssetId
					INNER JOIN #maxCleared maxc ON asd.AssetId = maxc.AssetId
												AND avh.Id = maxc.MaxId
												AND avh.IncomeDate <= asd.TransactionDate
			WHERE avh.ReversalGLJournalId IS NULL
				  AND avh.IsAccounted = 1
				  AND avh.IsCleared = 1
				  AND avh.IsLessorOwned = 1
				  AND avh.IncomeDate <= asd.TransactionDate
				  MaxMinIsLeaseComponent
            GROUP BY asd.AssetSaleId'
		IF @IsLeaseComponent = 1
		BEGIN
			SET @Sql = REPLACE(@Sql,'MaxMinIsLeaseComponent', 'AND avh.IsLeaseComponent = maxc.IsLeaseComponent');
		END;
		ELSE
		BEGIN
			SET @Sql = REPLACE(@Sql,'MaxMinIsLeaseComponent','');
		END;
		INSERT INTO #INVenValueInfo                
		EXEC (@Sql)
		END;
		
        CREATE NONCLUSTERED INDEX IX_Id ON #INVenValueInfo(AssetSaleId);

        UPDATE isi SET 
                       isi.Inventory_Table = t.INValue
        FROM #InventorySumInfo isi
             INNER JOIN #INVenValueInfo t ON isi.AssetSaleId = t.AssetSaleId
                  AND isi.MinAmountGL_Check = 0;

		BEGIN
		SET @Sql ='
		SELECT asd.AssetSaleId
             , -(SUM(CASE
                       WHEN avh.SourceModule IN(''FixedTermDepreciation'', ''InventoryBookDepreciation'')
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END)) AS AccumulatedAssetDepreciation_Table
             , -(SUM(CASE
                       WHEN avh.SourceModule IN(''NBVImpairments'', ''AssetImpairment'')
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END)) AS AccumulatedAssetImpairment_Table
        FROM AssetValueHistories avh
             INNER JOIN #EligibleAssetSaleDetails asd ON asd.AssetId = avh.AssetId
             INNER JOIN #minCleared minc ON avh.AssetId = minc.AssetId
                                            AND avh.Id > MinId
             INNER JOIN #maxCleared maxc ON avh.AssetId = maxc.AssetId
                                            AND avh.Id <= MaxId
                                            AND avh.GLJournalId IS NOT NULL
                                            AND avh.ReversalGLJournalId IS NULL
                                            AND avh.IsAccounted = 1
                                            AND avh.SourceModule IN(''FixedTermDepreciation'', ''NBVImpairments'', ''AssetImpairment'', ''InventoryBookDepreciation'')
											MaxMinIsLeaseComponent
			INNER JOIN #InventorySumInfo isi ON isi.AssetSaleId = asd.AssetSaleId
											AND isi.MinAmountGL_Check = 1
        GROUP BY asd.AssetSaleId;'
		IF @IsLeaseComponent = 1
		BEGIN
			SET @Sql = REPLACE(@Sql,'MaxMinIsLeaseComponent', 'AND avh.IsLeaseComponent = minc.IsLeaseComponent AND avh.IsLeaseComponent = maxc.IsLeaseComponent');
		END;
		ELSE
		BEGIN
			SET @Sql = REPLACE(@Sql,'MaxMinIsLeaseComponent','');
		END;
		INSERT INTO #AssetSale_AccumulatedAmounts
		EXEC (@Sql)
		END;

		CREATE NONCLUSTERED INDEX IX_Id ON #AssetSale_AccumulatedAmounts(AssetSaleId);

        SELECT t.*
             , CASE
                   WHEN t.AccumulatedAssetDepreciation_Difference != 0.00
                        OR t.AccumulatedAssetImpairment_Difference != 0.00
                        OR t.Inventory_Difference != 0.00
                        OR t.CostofGoodsSold_Difference != 0.00
                   THEN 'Problem Record'
                   ELSE 'Not Problem Record'
               END [Result]
        INTO #ResultList
        FROM
        (
            SELECT DISTINCT 
                   eas.AssetSaleId
                 , eas.TransactionNumber
                 , le.Name AS LegalEntityName
                 , lob.Name AS LineOfBusinessName
                 , P.PartyName [Buyer]
                 , cc.CostCenter
                 , b.BranchName
                 , ISNULL(isi.Inventory_Table, 0.00) AS Inventory_Table
                 , ISNULL(asgl.Inventory_GL, 0.00) AS Inventory_GL
                 , ISNULL(isi.Inventory_Table, 0.00) - ISNULL(asgl.Inventory_GL, 0.00) Inventory_Difference
                 , ISNULL(asaa.AccumulatedAssetDepreciation_Table, 0.00) AS AccumulatedAssetDepreciation_Table
                 , ISNULL(asgl.AccumulatedAssetDepreciation_GL, 0.00) AS AccumulatedAssetDepreciation_GL
                 , ISNULL(asaa.AccumulatedAssetDepreciation_Table, 0.00) - ISNULL(asgl.AccumulatedAssetDepreciation_GL, 0.00) AccumulatedAssetDepreciation_Difference
                 , ISNULL(asaa.AccumulatedAssetImpairment_Table, 0.00) AS AccumulatedAssetImpairment_Table
                 , ISNULL(asgl.AccumulatedAssetImpairment_GL, 0.00) AS AccumulatedAssetImpairment_GL
                 , ISNULL(asaa.AccumulatedAssetImpairment_Table, 0.00) - ISNULL(asgl.AccumulatedAssetImpairment_GL, 0.00) AccumulatedAssetImpairment_Difference
                 , ISNULL(isi.Inventory_Table, 0.00) - (ISNULL(asaa.AccumulatedAssetDepreciation_Table, 0.00) + ISNULL(asaa.AccumulatedAssetImpairment_Table, 0.00)) CostofGoodsSold_Table
                 , ISNULL(asgl.CostofGoodsSold_GL, 0.00) AS CostofGoodsSold_GL
                 , (ISNULL(isi.Inventory_Table, 0.00) - (ISNULL(asaa.AccumulatedAssetDepreciation_Table, 0.00) + ISNULL(asaa.AccumulatedAssetImpairment_Table, 0.00))) - ISNULL(asgl.CostofGoodsSold_GL, 0.00) AS CostofGoodsSold_Difference
            FROM #EligibleAssetSaleDetails eas
                 LEFT JOIN #AssetSale_AccumulatedAmounts asaa ON asaa.AssetSaleId = eas.AssetSaleId
                 LEFT JOIN #InventorySumInfo isi ON isi.AssetSaleId = eas.AssetSaleId
                 LEFT JOIN LegalEntities le ON eas.LegalEntityId = le.Id
                 LEFT JOIN CostCenterConfigs cc ON eas.CostCenterId = cc.Id
                 LEFT JOIN LineofBusinesses lob ON eas.LineofBusinessId = lob.Id
                 LEFT JOIN Branches b ON eas.BranchId = b.Id
                 LEFT JOIN #AssetSale_GL asgl ON eas.AssetSaleId = asgl.SourceId
                 LEFT JOIN Customers c ON eas.BuyerId = c.Id
                 LEFT JOIN Parties p ON P.id = C.id
        ) AS t
        ORDER BY t.AssetSaleId;

        SELECT name AS Name, 0 AS Count, CAST(0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(MAX)) AS Label, column_Id AS ColumnId
		INTO #AssetSaleSummary
		FROM tempdb.sys.columns
		WHERE object_id = OBJECT_ID('tempdb..#ResultList')
				AND Name LIKE '%Difference';

		DECLARE @query NVARCHAR(MAX);
		DECLARE @TableName NVARCHAR(MAX);
		WHILE EXISTS(SELECT 1 FROM #AssetSaleSummary WHERE IsProcessed = 0)
		BEGIN
			SELECT TOP 1 @TableName = Name
			FROM #AssetSaleSummary
			WHERE IsProcessed = 0;

			SET @query = 'UPDATE #AssetSaleSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName + ' != 0.00), IsProcessed = 1
			WHERE Name = ''' + @TableName + ''' ;';
			EXEC (@query);
		END;

        UPDATE #AssetSaleSummary SET 
                                     Label = CASE
                                                 WHEN Name = 'Inventory_Difference'
                                                 THEN '1_Inventory_Difference'
                                                 WHEN Name = 'AccumulatedAssetDepreciation_Difference'
                                                 THEN '2_Accumulated Asset Depreciation_Difference'
                                                 WHEN Name = 'AccumulatedAssetImpairment_Difference'
                                                 THEN '3_Accumulated Asset Impairment_Difference'
                                                 WHEN Name = 'CostofGoodsSold_Difference'
                                                 THEN '4_Cost Of Goods Sold_Difference'
                                             END;

        IF @IsFromLegalEntity = 0
            BEGIN
                SELECT Label AS Name
                     , Count
                FROM #AssetSaleSummary
                ORDER BY ColumnId;

                IF(@ResultOption = 'All')
                BEGIN
                        SELECT *
                        FROM #ResultList
                        ORDER BY AssetSaleId;
                END;

                IF(@ResultOption = 'Failed')
				BEGIN
                        SELECT *
                        FROM #ResultList
                        WHERE Result = 'Problem Record'
                        ORDER BY AssetSaleId;
                END;

                IF(@ResultOption = 'Passed')
				BEGIN
                        SELECT *
                        FROM #ResultList
                        WHERE Result = 'Not Problem Record'
                        ORDER BY AssetSaleId;
                END;

                DECLARE @TotalCount BIGINT;
                SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ResultList;
                DECLARE @InCorrectCount BIGINT;
                SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ResultList
                WHERE Result = 'Problem Record';
                DECLARE @Messages StoredProcMessage;

				INSERT INTO @Messages (Name, ParameterValuesCsv)
				VALUES ('TotalAssetSale', (SELECT 'AssetSales=' + CONVERT(NVARCHAR(40), @TotalCount)));
				INSERT INTO @Messages (Name, ParameterValuesCsv)
				VALUES ('AssetSalesSuccessful', (SELECT 'AssetSaleSuccessful=' + CONVERT(NVARCHAR(40), (@TotalCount - @InCorrectCount))));
				INSERT INTO @Messages (Name, ParameterValuesCsv)
				VALUES ('AssetSalesIncorrect', (SELECT 'AssetSaleIncorrect=' + CONVERT(NVARCHAR(40), @InCorrectCount)));
				INSERT INTO @Messages (Name, ParameterValuesCsv)
				VALUES ('AssetSalesResultOption', (SELECT 'ResultOption=' + CONVERT(NVARCHAR(40), @ResultOption)));

                SELECT * FROM @Messages;
        END;

        IF @IsFromLegalEntity = 1
            BEGIN
				SELECT LegalEntityName
                     , SUM(Inventory_GL) AS Inventory_AS_GL
                     , SUM(CostofGoodsSold_GL) AS CostOfGoodsSold_AS_GL
                     , SUM(AccumulatedAssetDepreciation_GL) AS AccumulatedAssetDepreciation_AS_GL
                     , SUM(AccumulatedAssetImpairment_GL) AS AccumulatedAssetImpairment_AS_GL
                FROM #ResultList
                GROUP BY LegalEntityName;
        END;

        DROP TABLE #EligibleAssetSaleDetails;
		DROP TABLE #AVHAssetsInfo;
        DROP TABLE #maxCleared;
        DROP TABLE #minCleared;
        DROP TABLE #InventorySumInfo;
		DROP TABLE #InventoryTableInfo;
		DROP TABLE #INValueInfo;
		DROP TABLE #INVenValueInfo;
        DROP TABLE #AssetSale_AccumulatedAmounts;
        DROP TABLE #AssetSale_GL;
        DROP TABLE #ResultList;
        DROP TABLE #AssetSaleSummary;
    END;

GO
