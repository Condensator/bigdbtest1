SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_BookValueAdjustmentGL_Reconciliation]
(@ResultOption      NVARCHAR(20), 
 @IsFromLegalEntity BIT NULL, 
 @LegalEntityIds    ReconciliationId READONLY
)
AS
    BEGIN

        IF OBJECT_ID('tempdb..#EligibleBookValueAdjustments') IS NOT NULL
            DROP TABLE #EligibleBookValueAdjustments;
        IF OBJECT_ID('tempdb..#AssetSplitInfo') IS NOT NULL
            DROP TABLE #AssetSplitInfo;
        IF OBJECT_ID('tempdb..#BookValueAdjustmentDetails') IS NOT NULL
            DROP TABLE #BookValueAdjustmentDetails;
        IF OBJECT_ID('tempdb..#BookValueAdjustments_Table') IS NOT NULL
            DROP TABLE #BookValueAdjustments_Table;
		IF OBJECT_ID('tempdb..#BookValueAndAVHInfo') IS NOT NULL
            DROP TABLE #BookValueAndAVHInfo;
        IF OBJECT_ID('tempdb..#maxCleared') IS NOT NULL
            DROP TABLE #maxCleared;
        IF OBJECT_ID('tempdb..#minCleared') IS NOT NULL
            DROP TABLE #minCleared;
        IF OBJECT_ID('tempdb..#BookValueAdjustments_Accumulated') IS NOT NULL
            DROP TABLE #BookValueAdjustments_Accumulated;
        IF OBJECT_ID('tempdb..#BookValueAdjustment_GL') IS NOT NULL
            DROP TABLE #BookValueAdjustment_GL;
        IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
            DROP TABLE #ResultList;
		IF OBJECT_ID('tempdb..#BookValueAdjustmentSummary') IS NOT NULL
			DROP TABLE #BookValueAdjustmentSummary;

        DECLARE @True BIT= 1;
        DECLARE @False BIT= 0;
		
        DECLARE @LegalEntitiesCount BIGINT= ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0);
        DECLARE @FilterCondition NVARCHAR(MAX)= '';
        DECLARE @IsSku BIT= 0;
        DECLARE @Sql NVARCHAR(MAX)= '';

        IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
		BEGIN
                SET @FilterCondition = ' AND ea.IsSKU = 0';
                SET @IsSku = 1;
        END;

        SELECT DISTINCT 
               avsc.Id AS AssetsValueStatusChangeId
             , avsc.LegalEntityId
             , avscd.LineofBusinessId
             , avscd.InstrumentTypeId
             , avscd.CostCenterId
             , avscd.BranchId
             , avsc.Reason
             , avsc.IsZeroMode
             , avsc.SourceModule
             , avsc.PostDate
        INTO #EligibleBookValueAdjustments
        FROM AssetsValueStatusChanges avsc
             INNER JOIN AssetsValueStatusChangeDetails avscd ON avsc.Id = avscd.AssetsValueStatusChangeId
		WHERE avscd.GLJournalID IS NOT NULL
			AND avscd.ReversalGLJournalId IS NULL
			AND @True = (CASE WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = avsc.LegalEntityId) THEN @True
							WHEN @LegalEntitiesCount = 0 THEN @True
							ELSE @False
						END);

        SELECT t.Id
             , t.SplitType
        INTO #AssetSplitInfo
        FROM
        (
            SELECT ea.Id
                 , asl.SplitType
            FROM Assets ea
                 INNER JOIN AssetSplitDetails asd ON ea.Id = asd.OriginalAssetId
                 INNER JOIN AssetSplits asl ON asl.Id = asd.AssetSplitId
            WHERE asd.IsActive = 1
                  AND asl.ApprovalStatus = 'Approved'
            UNION
            SELECT ea.Id
                 , asl.SplitType
            FROM Assets ea
                 INNER JOIN AssetSplits asl ON asl.FeatureAssetId = ea.Id
            WHERE asl.ApprovalStatus = 'Approved'
        ) AS t
        GROUP BY t.Id
               , t.SplitType;

        SELECT ebva.AssetsValueStatusChangeId
             , avscd.AdjustmentAmount_Amount
             , avscd.AssetId
             , a.IsLeaseComponent
             , ebva.PostDate
        INTO #BookValueAdjustmentDetails
        FROM #EligibleBookValueAdjustments ebva
             INNER JOIN AssetsValueStatusChangeDetails avscd ON ebva.AssetsValueStatusChangeId = avscd.AssetsValueStatusChangeId
             INNER JOIN Assets a ON avscd.AssetId = a.Id
             LEFT JOIN #AssetSplitInfo asi ON asi.Id = a.Id
                                              AND asi.SplitType = ('AssetSplit')
        WHERE asi.Id IS NULL;

        SELECT ebva.AssetsValueStatusChangeId
             , SUM(CASE
                       WHEN ebva.Reason != 'Impairment'
                            AND bvad.IsLeaseComponent = 1
                       THEN -(bvad.AdjustmentAmount_Amount)
                       ELSE 0.00
                   END) AS BookValueChange_LC_Table
             , SUM(CASE
                       WHEN ebva.Reason != 'Impairment'
                            AND bvad.IsLeaseComponent = 0
                       THEN -(bvad.AdjustmentAmount_Amount)
                       ELSE 0.00
                   END) AS BookValueChange_FC_Table
             , SUM(CASE
                       WHEN ebva.Reason = 'Impairment'
                            AND bvad.IsLeaseComponent = 1
                       THEN bvad.AdjustmentAmount_Amount
                       ELSE 0.00
                   END) AS AccumulatedImpairment_LC_Table
             , SUM(CASE
                       WHEN ebva.Reason = 'Impairment'
                            AND bvad.IsLeaseComponent = 0
                       THEN bvad.AdjustmentAmount_Amount
                       ELSE 0.00
                   END) AS AccumulatedImpairment_FC_Table
        INTO #BookValueAdjustments_Table
        FROM #EligibleBookValueAdjustments ebva
             INNER JOIN #BookValueAdjustmentDetails bvad ON ebva.AssetsValueStatusChangeId = bvad.AssetsValueStatusChangeId
        GROUP BY ebva.AssetsValueStatusChangeId;

		SELECT avh.Id AS AVHId,bvad.AssetId,bvad.AssetsValueStatusChangeId
		INTO #BookValueAndAVHInfo
		FROM AssetValueHistories avh
			INNER JOIN #BookValueAdjustmentDetails bvad ON avh.SourceModuleId = bvad.AssetsValueStatusChangeId
		WHERE avh.SourceModule IN ('AssetValueAdjustment','AssetImpairment')

        -- (MAX) IsCleared =1
        SELECT avh.AssetId
			 , bvad.AssetsValueStatusChangeId
             , MAX(Id) AS MaxId
        INTO #maxCleared
        FROM AssetValueHistories avh
             INNER JOIN #BookValueAdjustmentDetails bvad ON bvad.AssetId = avh.AssetId
			 INNER JOIN #BookValueAndAVHInfo bv ON bv.AssetId = avh.AssetId AND bv.AssetsValueStatusChangeId = bvad.AssetsValueStatusChangeId
        WHERE avh.IsAccounted = 1
              AND avh.IsCleared = 1
              AND avh.GLJournalId IS NOT NULL
              AND avh.ReversalGLJournalId IS NULL
			  AND avh.SourceModule NOT IN ('ClearAccumulatedAccounts')
             AND avh.IncomeDate <= bvad.PostDate
			 AND avh.Id < bv.AVHId
        GROUP BY avh.AssetId,bvad.AssetsValueStatusChangeId;
		
        -- (MAX - 1) IsCleared =1
        SELECT avh.AssetId
             , MAX(avh.Id) AS MinId
        INTO #minCleared
        FROM #BookValueAdjustmentDetails bvad
             INNER JOIN AssetValueHistories avh ON bvad.AssetId = avh.AssetId
             INNER JOIN #MaxCleared AS t ON t.AssetId = avh.AssetId
                                            AND avh.Id < t.MaxId
        WHERE avh.IsAccounted = 1
              AND avh.IsCleared = 1
              AND avh.GLJournalId IS NOT NULL
              AND avh.ReversalGLJournalId IS NULL
              AND avh.IncomeDate <= bvad.PostDate
			  AND avh.SourceModule NOT IN ('ClearAccumulatedAccounts')
        GROUP BY avh.AssetId;
		
        SELECT ebva.AssetsValueStatusChangeId
             , SUM(CASE
                       WHEN avh.SourceModule IN('InventoryBookDepreciation','FixedTermDepreciation')
                            AND bvad.IsLeaseComponent = 1
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END) AS BookValueAdj_AccumulatedAssetDepreciation_LC_Table
             , SUM(CASE
                       WHEN avh.SourceModule IN('InventoryBookDepreciation','FixedTermDepreciation')
                            AND bvad.IsLeaseComponent = 0
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END) AS BookValueAdj_AccumulatedAssetDepreciation_FC_Table
             , SUM(CASE
                       WHEN avh.SourceModule IN('AssetImpairment')
                            AND ebva.AssetsValueStatusChangeId = avh.SourceModuleId
                            AND ebva.SourceModule = 'Payoff'
                            AND avh.IsCleared = 0
                            AND bvad.IsLeaseComponent = 1
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END)
				+ SUM(CASE
                       WHEN avh.SourceModule IN('NBVImpairment')
                            AND ebva.AssetsValueStatusChangeId = avh.SourceModuleId
                            AND avh.IsCleared = 0
                            AND bvad.IsLeaseComponent = 1
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END) AS BookValueAdj_AccumulatedAssetImpairment_LC_Table
             , SUM(CASE
                       WHEN avh.SourceModule IN('AssetImpairment')
                            AND ebva.AssetsValueStatusChangeId = avh.SourceModuleId
                            AND ebva.SourceModule = 'Payoff'
                            AND avh.IsCleared = 0
                            AND bvad.IsLeaseComponent = 0
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END)
				+ SUM(CASE
                       WHEN avh.SourceModule IN('NBVImpairment')
                            AND ebva.AssetsValueStatusChangeId = avh.SourceModuleId
                            AND avh.IsCleared = 0
                            AND bvad.IsLeaseComponent = 0
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END) AS BookValueAdj_AccumulatedAssetImpairment_FC_Table
        INTO #BookValueAdjustments_Accumulated
        FROM #EligibleBookValueAdjustments ebva
             INNER JOIN #BookValueAdjustmentDetails bvad ON ebva.AssetsValueStatusChangeId = bvad.AssetsValueStatusChangeId
             INNER JOIN AssetValueHistories avh ON bvad.AssetId = avh.AssetId
				AND avh.SourceModule IN('AssetImpairment','NBVImpairment','InventoryBookDepreciation','FixedTermDepreciation')
             INNER JOIN #minCleared minc ON avh.AssetId = minc.AssetId
                                            AND avh.Id > MinId
             INNER JOIN #maxCleared maxc ON avh.AssetId = maxc.AssetId
                                            AND avh.Id <= MaxId
		WHERE avh.IsAccounted = 1 
			  AND avh.IsLessorOwned = 1
        GROUP BY ebva.AssetsValueStatusChangeId;

        SELECT gld.EntityId
             , SUM(CASE
                       WHEN gle.Name = 'Inventory'
                            AND gld.IsDebit = 1
							AND t.GLJournalId IS NULL
                       THEN gld.Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gle.Name = 'Inventory'
                                       AND gld.IsDebit = 0
									   AND t.GLJournalId IS NULL
                                  THEN gld.Amount_Amount
                                  ELSE 0.00
                              END) AS BookValueChange_GL
             , SUM(CASE
                       WHEN gle.Name = 'AccumulatedImpairment'
                            AND gld.IsDebit = 0
                       THEN gld.Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gle.Name IN('AccumulatedImpairment')
                                       AND gld.IsDebit = 1
                                  THEN gld.Amount_Amount
                                  ELSE 0.00
                              END) AS AccumulatedImpairment_GL
             , SUM(CASE
                       WHEN gle.Name = 'AccumulatedImpairmentOffLeaseAssets'
                            AND gld.IsDebit = 0
                       THEN gld.Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gle.Name IN('AccumulatedImpairmentOffLeaseAssets')
                                       AND gld.IsDebit = 1
                                  THEN gld.Amount_Amount
                                  ELSE 0.00
                              END) AS AccumulatedOImpairment_GL
             , SUM(CASE
                       WHEN gle.Name IN('AccumulatedAssetDepreciation')
                            AND gld.IsDebit = 0
                       THEN gld.Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gle.Name IN('AccumulatedAssetDepreciation')
                                       AND gld.IsDebit = 1
                                  THEN gld.Amount_Amount
                                  ELSE 0.00
                              END) AS BookValueAdj_AccumulatedAssetDepreciation_GL
             , SUM(CASE
                       WHEN gle.Name IN('AccumulatedAssetImpairment')
                            AND gld.IsDebit = 0
                       THEN gld.Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gle.Name IN('AccumulatedAssetImpairment')
                                       AND gld.IsDebit = 1
                                  THEN gld.Amount_Amount
                                  ELSE 0.00
                              END) AS BookValueAdj_AccumulatedAssetImpairment_GL
        INTO #BookValueAdjustment_GL
        FROM GLJournalDetails gld
             INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
             INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
             INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
             LEFT JOIN
        (
            SELECT DISTINCT 
                   GLJournalId
            FROM AssetValueHistories
            WHERE SourceModule = 'ClearAccumulatedAccounts'
        ) AS t ON t.GLJournalId = gld.GLJournalId
        WHERE gld.EntityType = 'AssetValueAdjustment'
              AND gltt.Name = 'AssetBookValueAdjustment'
              AND gle.Name IN('Inventory', 'AccumulatedImpairment', 'AccumulatedImpairmentOffLeaseAssets', 'AccumulatedAssetDepreciation', 'AccumulatedAssetImpairment')
        GROUP BY gld.EntityId;

        SELECT t.*
             , CASE
                   WHEN t.AssetBookValueAdjustment_ValueChange_Difference != 0.00
                        OR t.AssetBookValueAdjustment_AccumulatedImpairment_Difference != 0.00
                        OR t.AssetBookValueAdjustment_AccumulatedAssetDepreciation_Difference != 0.00
                        OR t.AssetBookValueAdjustment_AccumulatedAssetImpairment_Difference != 0.00
                   THEN 'Problem Record'
                   ELSE 'Not Problem Record'
               END [Result]
        INTO #ResultList
        FROM
        (
            SELECT ebva.AssetsValueStatusChangeId
                 , le.Name AS LegalEntityName
                 , lob.Name AS LineOfBusinessName
                 , it.Code AS InstrumentType
                 , cc.CostCenter
                 , b.BranchName
                 , ebva.Reason
                 , ebva.IsZeroMode
				 , ebva.SourceModule
                 , ISNULL(bvat.BookValueChange_LC_Table, 0.00) AS AssetBookValueAdjustment_ValueChange_LC_Table
                 , ISNULL(bvat.BookValueChange_FC_Table, 0.00) AS AssetBookValueAdjustment_ValueChange_FC_Table
                 , ISNULL(bvagl.BookValueChange_GL, 0.00) AS AssetBookValueAdjustment_ValueChange_GL
                 , (ISNULL(bvat.BookValueChange_LC_Table, 0.00) + ISNULL(bvat.BookValueChange_FC_Table, 0.00)) - (ISNULL(bvagl.BookValueChange_GL, 0.00)) AssetBookValueAdjustment_ValueChange_Difference
                 , ISNULL(bvat.AccumulatedImpairment_LC_Table, 0.00) AS AssetBookValueAdjustment_AccumulatedImpairment_LC_Table
                 , ISNULL(bvat.AccumulatedImpairment_FC_Table, 0.00) AS AssetBookValueAdjustment_AccumulatedImpairment_FC_Table
                 , ISNULL(bvagl.AccumulatedImpairment_GL, 0.00) + ISNULL(bvagl.AccumulatedOImpairment_GL, 0.00) AS AssetBookValueAdjustment_AccumulatedImpairment_GL
                 , (ISNULL(bvat.AccumulatedImpairment_LC_Table, 0.00) + ISNULL(bvat.AccumulatedImpairment_FC_Table, 0.00)) - (ISNULL(bvagl.AccumulatedImpairment_GL, 0.00) + ISNULL(bvagl.AccumulatedOImpairment_GL, 0.00)) AssetBookValueAdjustment_AccumulatedImpairment_Difference
                 , ISNULL(bvaa.BookValueAdj_AccumulatedAssetDepreciation_LC_Table, 0.00) AS AssetBookValueAdjustment_AccumulatedAssetDepreciation_LC_Table
                 , ISNULL(bvaa.BookValueAdj_AccumulatedAssetDepreciation_FC_Table, 0.00) AS AssetBookValueAdjustment_AccumulatedAssetDepreciation_FC_Table
                 , ISNULL(bvagl.BookValueAdj_AccumulatedAssetDepreciation_GL, 0.00) AS AssetBookValueAdjustment_AccumulatedAssetDepreciation_GL
                 , (ISNULL(bvaa.BookValueAdj_AccumulatedAssetDepreciation_LC_Table, 0.00) + ISNULL(bvaa.BookValueAdj_AccumulatedAssetDepreciation_FC_Table, 0.00)) - (ISNULL(bvagl.BookValueAdj_AccumulatedAssetDepreciation_GL, 0.00)) AssetBookValueAdjustment_AccumulatedAssetDepreciation_Difference
                 , ISNULL(bvaa.BookValueAdj_AccumulatedAssetImpairment_LC_Table, 0.00) AS AssetBookValueAdjustment_AccumulatedAssetImpairment_LC_Table
                 , ISNULL(bvaa.BookValueAdj_AccumulatedAssetImpairment_FC_Table, 0.00) AS AssetBookValueAdjustment_AccumulatedAssetImpairment_FC_Table
                 , ISNULL(bvagl.BookValueAdj_AccumulatedAssetImpairment_GL, 0.00) AS AssetBookValueAdjustment_AccumulatedAssetImpairment_GL
                 , (ISNULL(bvaa.BookValueAdj_AccumulatedAssetImpairment_LC_Table, 0.00) + ISNULL(bvaa.BookValueAdj_AccumulatedAssetImpairment_FC_Table, 0.00)) - (ISNULL(bvagl.BookValueAdj_AccumulatedAssetImpairment_GL, 0.00)) AssetBookValueAdjustment_AccumulatedAssetImpairment_Difference
            FROM #EligibleBookValueAdjustments ebva
                 INNER JOIN #BookValueAdjustments_Table bvat ON ebva.AssetsValueStatusChangeId = bvat.AssetsValueStatusChangeId
                 INNER JOIN LegalEntities le ON ebva.LegalEntityId = le.Id
                 INNER JOIN CostCenterConfigs cc ON ebva.CostCenterId = cc.Id
                 INNER JOIN InstrumentTypes it ON ebva.InstrumentTypeId = it.Id
                 LEFT JOIN LineofBusinesses lob ON ebva.LineofBusinessId = lob.Id
                 LEFT JOIN Branches b ON ebva.BranchId = b.Id
                 LEFT JOIN #BookValueAdjustments_Accumulated bvaa ON ebva.AssetsValueStatusChangeId = bvaa.AssetsValueStatusChangeId
                 LEFT JOIN #BookValueAdjustment_GL bvagl ON ebva.AssetsValueStatusChangeId = bvagl.EntityId
        ) AS t
        ORDER BY t.AssetsValueStatusChangeId;

        SELECT name AS Name
             , 0 AS Count
             , CAST(0 AS BIT) AS IsProcessed
             , CAST('' AS NVARCHAR(MAX)) AS Label
			 , column_Id AS ColumnId
        INTO #BookValueAdjustmentSummary
        FROM tempdb.sys.columns
        WHERE object_id = OBJECT_ID('tempdb..#ResultList')
              AND Name LIKE '%Difference';

        DECLARE @query NVARCHAR(MAX);
        DECLARE @TableName NVARCHAR(MAX);
        WHILE EXISTS (SELECT 1 FROM #BookValueAdjustmentSummary WHERE IsProcessed = 0)
		BEGIN
			SELECT TOP 1 @TableName = Name
                FROM #BookValueAdjustmentSummary
                WHERE IsProcessed = 0;
                SET @query = 'UPDATE #BookValueAdjustmentSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName + ' != 0.00), IsProcessed = 1
				WHERE Name = ''' + @TableName + ''' ;';
                EXEC (@query);
        END;

        UPDATE #BookValueAdjustmentSummary SET 
                                               Label = CASE
                                                           WHEN Name = 'AssetBookValueAdjustment_ValueChange_Difference'
                                                           THEN '1_Asset Book Value Adjustment Value Change_Difference'
                                                           WHEN Name = 'AssetBookValueAdjustment_AccumulatedImpairment_Difference'
                                                           THEN '2_Asset Book Value Adjustment Accumulated Impairment_Difference'
                                                           WHEN Name = 'AssetBookValueAdjustment_AccumulatedAssetDepreciation_Difference'
                                                           THEN '3_Asset Book Value Adjustment Accumulated Asset Depreciation_Difference'
                                                           WHEN Name = 'AssetBookValueAdjustment_AccumulatedAssetImpairment_Difference'
                                                           THEN '4_Asset Book Value Adjustment Accumulated Asset Impairment_Difference'
                                                       END;

        IF @IsFromLegalEntity = 0
            BEGIN

                SELECT Label AS Name
                     , Count
                FROM #BookValueAdjustmentSummary
                ORDER BY ColumnId;

                IF(@ResultOption = 'All')
                    BEGIN
                        SELECT *
                        FROM #ResultList
                        ORDER BY AssetsValueStatusChangeId;
                END;

                IF(@ResultOption = 'Failed')
                    BEGIN
                        SELECT *
                        FROM #ResultList
                        WHERE Result = 'Problem Record'
                        ORDER BY AssetsValueStatusChangeId;
                END;

                IF(@ResultOption = 'Passed')
                    BEGIN
                        SELECT *
                        FROM #ResultList
                        WHERE Result = 'Not Problem Record'
                        ORDER BY AssetsValueStatusChangeId;
                END;

                DECLARE @TotalCount BIGINT;
                SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ResultList;

                DECLARE @InCorrectCount BIGINT;
                SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ResultList WHERE Result = 'Problem Record';

                DECLARE @Messages STOREDPROCMESSAGE;

                INSERT INTO @Messages (Name, ParameterValuesCsv)
                VALUES ('TotalBookValueAdjustments',(SELECT 'BookValueAdjustments=' + CONVERT(NVARCHAR(40), @TotalCount)));
                INSERT INTO @Messages (Name, ParameterValuesCsv)
                VALUES ('BookValueAdjustmentsSuccessful',(SELECT 'BookValueAdjustmentsSuccessful=' + CONVERT(NVARCHAR(40), (@TotalCount - @InCorrectCount))));
				INSERT INTO @Messages (Name, ParameterValuesCsv)
                VALUES ('BookValueAdjustmentsIncorrect',(SELECT 'BookValueAdjustmentsIncorrect=' + CONVERT(NVARCHAR(40), @InCorrectCount)));
                INSERT INTO @Messages (Name, ParameterValuesCsv)
                VALUES ('BookValueAdjustmentsResultOption',(SELECT 'ResultOption=' + CONVERT(NVARCHAR(40), @ResultOption)));

                SELECT * FROM @Messages;
        END;

        IF @IsFromLegalEntity = 1
            BEGIN
                SELECT LegalEntityName
                     , SUM(AssetBookValueAdjustment_ValueChange_GL) AS AssetBookValueAdjustment_GL
                     , SUM(CASE WHEN SourceModule != 'Payoff' THEN AssetBookValueAdjustment_AccumulatedImpairment_GL ELSE 0.00 END) AS AccumulatedImpairment_GL
                     , SUM(AssetBookValueAdjustment_AccumulatedAssetDepreciation_GL) AS AccumulatedAssetDepreciation_BVA_GL
                     , SUM(AssetBookValueAdjustment_AccumulatedAssetImpairment_GL) AS AccumulatedAssetImpairment_BVA_GL
                FROM #ResultList
                GROUP BY LegalEntityName;
        END;

        DROP TABLE #EligibleBookValueAdjustments;
        DROP TABLE #AssetSplitInfo;
        DROP TABLE #BookValueAdjustmentDetails;
        DROP TABLE #BookValueAdjustments_Table;
		DROP TABLE #BookValueAndAVHInfo;
        DROP TABLE #maxCleared;
        DROP TABLE #minCleared;
        DROP TABLE #BookValueAdjustments_Accumulated;
        DROP TABLE #BookValueAdjustment_GL;
        DROP TABLE #ResultList;
        DROP TABLE #BookValueAdjustmentSummary;
    END;

GO
