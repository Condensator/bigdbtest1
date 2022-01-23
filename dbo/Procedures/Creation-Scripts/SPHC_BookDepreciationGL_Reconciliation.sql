SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_BookDepreciationGL_Reconciliation]
(@ResultOption      NVARCHAR(20), 
 @IsFromLegalEntity BIT NULL, 
 @LegalEntityIds    ReconciliationId READONLY
)
AS
    BEGIN

        IF OBJECT_ID('tempdb..#EligbleBookDepreciations') IS NOT NULL
            DROP TABLE #EligbleBookDepreciations;

        IF OBJECT_ID('tempdb..#BookDepreciation_InventoryDepreciation_Table') IS NOT NULL
            DROP TABLE #BookDepreciation_InventoryDepreciation_Table;

        IF OBJECT_ID('tempdb..#BookDepreciation_InventoryDepreciation_GL') IS NOT NULL
            DROP TABLE #BookDepreciation_InventoryDepreciation_GL;

        IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
            DROP TABLE #ResultList;

        IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
            DROP TABLE #BookDepreciationSummary;

        DECLARE @True BIT = 1;
		DECLARE @False BIT = 0;
		DECLARE @LegalEntitiesCount BIGINT= ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0);
		DECLARE @FilterCondition NVARCHAR(MAX)= '';
		DECLARE @IsSku BIT= 0;
		DECLARE @Sql NVARCHAR(MAX)= '';

		IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
		BEGIN
			SET @FilterCondition = ' AND ea.IsSKU = 0';
			SET @IsSku = 1;
		END;

        SELECT bd.Id AS BookDepreciationId
             , bd.RemainingLifeInMonths
             , bd.CostBasis_Amount
             , bd.Salvage_Amount
             , bd.BeginDate
             , bd.EndDate
             , bd.TerminatedDate
             , bd.LineofBusinessId
             , a.Alias
             , a.LegalEntityId
             , bd.AssetId
             , a.IsLeaseComponent
        INTO #EligbleBookDepreciations
        FROM BookDepreciations bd
             INNER JOIN Assets a ON a.Id = bd.AssetId AND bd.IsActive = 1
		WHERE  @True = (CASE WHEN @LegalEntitiesCount > 0 AND EXISTS(SELECT Id FROM @LegalEntityIds WHERE Id = a.LegalEntityId) THEN @True
							WHEN @LegalEntitiesCount = 0 THEN @True
                            ELSE @False
                        END);

        SELECT ebd.BookDepreciationId
             , -(SUM(CASE
                       WHEN ebd.IsLeaseComponent = 1
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END)) AS InventoryDepreciation_LC_Table
             , -(SUM(CASE
                       WHEN ebd.IsLeaseComponent = 0
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END)) AS InventoryDepreciation_FC_Table
        INTO #BookDepreciation_InventoryDepreciation_Table
        FROM #EligbleBookDepreciations ebd
             INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = ebd.BookDepreciationId
        WHERE avh.IsAccounted = 1
			AND avh.GLJournalId IS NOT NULL
			AND avh.ReversalGLJournalId IS NULL
			AND avh.AdjustmentEntry = 0
			AND avh.SourceModule = 'InventoryBookDepreciation'
        GROUP BY ebd.BookDepreciationId;

        SELECT gld.EntityId
             , SUM(CASE
                       WHEN gld.IsDebit = 0
                       THEN Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gld.IsDebit = 1
                                  THEN Amount_Amount
                                  ELSE 0.00
                              END) AS BookDepreciation_InventoryDepreciation_GL
        INTO #BookDepreciation_InventoryDepreciation_GL
        FROM GLJournalDetails gld
             INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
             INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
             INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
        WHERE gle.Name IN('AccumulatedDepreciationOffLeaseAssets', 'AccumulatedDepreciation')
             AND gltt.Name = 'BookDepreciation'
             AND gld.EntityType = 'BookDepreciation'
        GROUP BY gld.EntityId;

        SELECT t.*
             , CASE
                   WHEN t.BookDepreciation_InventoryDepreciation_Difference != 0.00
                   THEN 'Problem Record'
                   ELSE 'Not Problem Record'
               END [Result]
        INTO #ResultList
        FROM
        (
            SELECT ebd.BookDepreciationId
                 , le.Name AS LegalEntityName
                 , ebd.Alias AS AssetAlias
                 , ebd.AssetId
                 , lob.Name [LineofBusinessName]
                 , ebd.RemainingLifeInMonths
                 , ebd.CostBasis_Amount
                 , ebd.Salvage_Amount
                 , ebd.BeginDate
                 , ebd.EndDate
                 , ebd.TerminatedDate
                 , ISNULL(bdt.InventoryDepreciation_LC_Table, 0.00) AS BookDepreciation_InventoryDepreciation_LC_Table
                 , ISNULL(bdt.InventoryDepreciation_FC_Table, 0.00) AS BookDepreciation_InventoryDepreciation_FC_Table
                 , ISNULL(bdg.BookDepreciation_InventoryDepreciation_GL, 0.00) AS BookDepreciation_InventoryDepreciation_GL
                 , (ISNULL(bdt.InventoryDepreciation_LC_Table, 0.00) + ISNULL(bdt.InventoryDepreciation_FC_Table, 0.00)) - (ISNULL(bdg.BookDepreciation_InventoryDepreciation_GL, 0.00)) BookDepreciation_InventoryDepreciation_Difference
            FROM #EligbleBookDepreciations ebd
                 INNER JOIN LegalEntities le ON ebd.LegalEntityId = le.Id
                 INNER JOIN #BookDepreciation_InventoryDepreciation_Table bdt ON bdt.BookDepreciationId = ebd.BookDepreciationId
                 LEFT JOIN #BookDepreciation_InventoryDepreciation_GL bdg ON bdg.EntityId = ebd.BookDepreciationId
                 LEFT JOIN LineofBusinesses lob ON ebd.LineofBusinessId = lob.Id
        ) AS t
        ORDER BY t.BookDepreciationId;

        SELECT name AS Name
             , 0 AS Count
             , CAST(0 AS BIT) AS IsProcessed
             , CAST('' AS NVARCHAR(MAX)) AS Label
			 , column_Id AS ColumnId
        INTO #BookDepreciationSummary
        FROM tempdb.sys.columns
        WHERE object_id = OBJECT_ID('tempdb..#ResultList')
              AND Name LIKE '%Difference';

        DECLARE @query NVARCHAR(MAX);
        DECLARE @TableName NVARCHAR(MAX);
        WHILE EXISTS
        (
            SELECT 1
            FROM #BookDepreciationSummary
            WHERE IsProcessed = 0
        )
            BEGIN
                SELECT TOP 1 @TableName = Name
                FROM #BookDepreciationSummary
                WHERE IsProcessed = 0;
                SET @query = 'UPDATE #BookDepreciationSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName + ' != 0.00), IsProcessed = 1
				WHERE Name = ''' + @TableName + ''' ;';
                EXEC (@query);
            END;

        UPDATE #BookDepreciationSummary SET 
                                            Label = CASE
                                                        WHEN Name = 'BookDepreciation_InventoryDepreciation_Difference'
                                                        THEN '1_Book Depreciation Inventory Depreciation_Difference'
                                                    END;

        IF @IsFromLegalEntity = 0
            BEGIN
                SELECT Label AS Name
                     , Count
                FROM #BookDepreciationSummary
                ORDER BY ColumnId;
                IF(@ResultOption = 'All')
                    BEGIN
                        SELECT *
                        FROM #ResultList
                        ORDER BY BookDepreciationId;
                END;
                IF(@ResultOption = 'Failed')
                    BEGIN
                        SELECT *
                        FROM #ResultList
                        WHERE Result = 'Problem Record'
                        ORDER BY BookDepreciationId;
                END;
                IF(@ResultOption = 'Passed')
                    BEGIN
                        SELECT *
                        FROM #ResultList
                        WHERE Result = 'Not Problem Record'
                        ORDER BY BookDepreciationId;
                END;

                DECLARE @TotalCount BIGINT;
                SELECT @TotalCount = ISNULL(COUNT(*), 0)
                FROM #ResultList;

                DECLARE @InCorrectCount BIGINT;
                SELECT @InCorrectCount = ISNULL(COUNT(*), 0)
                FROM #ResultList
                WHERE Result = 'Problem Record';

                DECLARE @Messages StoredProcMessage;

				INSERT INTO @Messages (Name, ParameterValuesCsv)
				VALUES ('TotalBookDepreciations', (SELECT 'BookDepreciations=' + CONVERT(NVARCHAR(40), @TotalCount)));
				INSERT INTO @Messages (Name, ParameterValuesCsv)
				VALUES ('BookDepreciationsSuccessful', (SELECT 'BookDepreciationsSuccessful=' + CONVERT(NVARCHAR(40), (@TotalCount - @InCorrectCount))));
				INSERT INTO @Messages (Name, ParameterValuesCsv)
				VALUES ('BookDepreciationsIncorrect', (SELECT 'BookDepreciationsIncorrect=' + CONVERT(NVARCHAR(40), @InCorrectCount)));
				INSERT INTO @Messages (Name, ParameterValuesCsv)
				VALUES ('BookDepreciationsResultOption', (SELECT 'ResultOption=' + CONVERT(NVARCHAR(40), @ResultOption)));
            
				SELECT * FROM @Messages;
        END;

        IF @IsFromLegalEntity = 1
            BEGIN
                SELECT LegalEntityName
                     , SUM(BookDepreciation_InventoryDepreciation_GL) AS AccumulatedAssetDepreciation_BD_GL
                FROM #ResultList
                GROUP BY LegalEntityName;
        END;

        DROP TABLE #EligbleBookDepreciations;
        DROP TABLE #BookDepreciation_InventoryDepreciation_Table;
        DROP TABLE #BookDepreciation_InventoryDepreciation_GL;
        DROP TABLE #ResultList;
        DROP TABLE #BookDepreciationSummary;
    END;

GO
