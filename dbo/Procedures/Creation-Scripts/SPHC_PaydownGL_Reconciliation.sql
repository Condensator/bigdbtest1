SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_PaydownGL_Reconciliation]
(@ResultOption      NVARCHAR(20), 
 @IsFromLegalEntity BIT NULL, 
 @LegalEntityIds    ReconciliationId READONLY
)
AS
    BEGIN

        IF OBJECT_ID('tempdb..#EligibleContracts') IS NOT NULL
            DROP TABLE #EligibleContracts;

        IF OBJECT_ID('tempdb..#ContractDetails') IS NOT NULL
            DROP TABLE #ContractDetails;

        IF OBJECT_ID('tempdb..#InventoryAmount') IS NOT NULL
            DROP TABLE #InventoryAmount;

        IF OBJECT_ID('tempdb..#GLJournalDetails') IS NOT NULL
            DROP TABLE #GLJournalDetails;

        IF OBJECT_ID('tempdb..#AVHGLjournalIds') IS NOT NULL
            DROP TABLE #AVHGLjournalIds;

        IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
            DROP TABLE #ResultList;

        IF OBJECT_ID('tempdb..#PaydownSummary') IS NOT NULL
            DROP TABLE #PaydownSummary;

        DECLARE @True BIT= 1;
        DECLARE @False BIT= 0;
        DECLARE @IsSku BIT= 0;
		
        DECLARE @FilterCondition NVARCHAR(MAX)= NULL;
        DECLARE @Sql NVARCHAR(MAX)= '';
        DECLARE @LegalEntitiesCount BIGINT= ISNULL((SELECT COUNT(*)FROM @LegalEntityIds), 0);

        IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
        BEGIN
			SET @FilterCondition = ' AND a.IsSKU = 0';
			SET @IsSku = 1;
        END;

        CREATE TABLE #InventoryAmount
        (LoanPaydownId       BIGINT, 
         InventoryAmount_LC  DECIMAL(16, 2), 
         InventoryAmount_NLC DECIMAL(16, 2)
        );

        SELECT DISTINCT 
               c.Id AS ContractId
             , c.SequenceNumber AS SequenceNumber
             , lf.CustomerId
             , lp.[QuoteName] AS [QuoteName]
             , lf.LineofBusinessId
             , lf.InstrumentTypeId
             , lf.CostCenterId
             , lf.BranchId
             , lf.LegalEntityId
             , lp.Id AS LoanPaydownId
             , lf.Id AS LoanFinanceId
             , lp.PaydownGLTemplateId
        INTO #EligibleContracts
        FROM Contracts c
             INNER JOIN LoanFinances lf ON c.Id = lf.ContractId
             INNER JOIN LoanPaydowns lp ON lp.LoanFinanceId = lf.Id
        WHERE lp.Status = 'Active'
              AND lp.PaydownReason = 'Repossession'
              AND @True = (CASE WHEN @LegalEntitiesCount > 0
                                     AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = lf.LegalEntityId)
                                THEN @True
                                WHEN @LegalEntitiesCount = 0
                                THEN @True
                                ELSE @False
                           END);

        CREATE NONCLUSTERED INDEX IX_Id ON #EligibleContracts(ContractId);

        CREATE NONCLUSTERED INDEX IX_LoanPaydownId ON #EligibleContracts(LoanPaydownId);

        SELECT c.ContractId
             , p.PartyName
             , le.Name AS LegalEntityName
             , lob.Name AS LineOfBusiness
             , it.Code AS InstrumentType
             , ccc.CostCenter
             , b.BranchName
             , gl.Name AS GLTemplateName
        INTO #ContractDetails
        FROM #EligibleContracts c
             INNER JOIN Parties p ON c.CustomerId = p.Id
             INNER JOIN LegalEntities le ON c.LegalEntityId = le.Id
             INNER JOIN LineofBusinesses lob ON lob.Id = c.LineofBusinessId
             LEFT JOIN InstrumentTypes it ON it.Id = c.InstrumentTypeId
             LEFT JOIN CostCenterConfigs ccc ON ccc.Id = c.CostCenterId
             LEFT JOIN Branches b ON b.Id = c.BranchId
             LEFT JOIN GLTemplates gl ON gl.Id = c.PaydownGLTemplateId;

        CREATE NONCLUSTERED INDEX IX_Id ON #ContractDetails(ContractId);

        INSERT INTO #InventoryAmount
        SELECT ec.LoanPaydownId
             , SUM(CASE
                       WHEN a.IsLeaseComponent = 1
                       THEN avh.NetValue_Amount
                       ELSE 0.00
                   END) AS InventoryAmount_LC
             , SUM(CASE
                       WHEN a.IsLeaseComponent = 0
                       THEN avh.NetValue_Amount
                       ELSE 0.00
                   END) AS InventoryAmount_NLC
        FROM #EligibleContracts ec
             INNER JOIN LoanPaydownAssetDetails lpad ON ec.LoanPaydownId = lpad.LoanPaydownId
             INNER JOIN AssetValueHistories avh ON avh.SourceModuleid = ec.LoanPaydownId
                                                   AND lpad.AssetId = avh.AssetId
             INNER JOIN Assets a ON a.id = lpad.assetid
        WHERE lpad.isactive = 1
              AND lpad.AssetPaydownStatus = 'Inventory'
              AND avh.SourceModule = 'Paydown'
              AND avh.IsAccounted = 1
        GROUP BY ec.LoanPaydownId;

        SELECT DISTINCT 
               ec.LoanPaydownId
             , avh.GLJournalId
        INTO #AVHGLjournalIds
        FROM #EligibleContracts ec
             INNER JOIN LoanPaydownAssetDetails lpad ON ec.LoanPaydownId = lpad.LoanPaydownId
             INNER JOIN AssetValueHistories avh ON avh.SourceModuleid = ec.LoanPaydownId
                                                   AND lpad.AssetId = avh.AssetId
             INNER JOIN Assets a ON a.id = lpad.assetid
        WHERE lpad.isactive = 1
              AND lpad.AssetPaydownStatus = 'Inventory'
              AND avh.IsAccounted = 1
              AND avh.SourceModule = 'Paydown';

        CREATE NONCLUSTERED INDEX IX_Id ON #InventoryAmount(LoanPaydownId);

        SELECT ec.LoanPaydownId
             , SUM(CASE
                       WHEN gld.IsDebit = 1
                       THEN Amount_Amount
                       ELSE 0.00
                   END) - SUM(CASE
                                  WHEN gld.IsDebit = 0
                                  THEN Amount_Amount
                                  ELSE 0.00
                              END) AS Inventory_GL
        INTO #GLJournalDetails
        FROM #EligibleContracts ec
             INNER JOIN GLJournalDetails gld ON ec.ContractId = gld.EntityId
             INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
             INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
             INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
             INNER JOIN #AVHGLjournalIds avh ON avh.LoanPaydownId = ec.LoanPaydownId
                                                AND avh.GLjournalId = gld.GLjournalId
        WHERE gltt.Name IN('Paydown')
             AND gle.Name IN('Inventory')
        GROUP BY ec.LoanPaydownId;

        CREATE NONCLUSTERED INDEX IX_Id ON #GLJournalDetails(LoanPaydownId);

        SELECT ec.LoanPaydownId
             , ec.[QuoteName] AS [QuoteName]
             , cd.ContractId
             , ec.SequenceNumber
             , cd.PartyName AS [CustomerName]
             , cd.LegalEntityName
             , cd.LineOfBusiness AS LineOfBusinessName
             , cd.InstrumentType
             , cd.CostCenter
             , cd.BranchName
             , cd.GLTemplateName
             , ISNULL(ia.InventoryAmount_LC, 0.00) AS Paydown_Inventory_LC_Table
             , ISNULL(ia.InventoryAmount_NLC, 0.00) AS Paydown_Inventory_NLC_Table
             , ISNULL(gld.Inventory_GL, 0.00) AS Paydown_Inventory_GL
             , ISNULL(ia.InventoryAmount_LC, 0.00) + ISNULL(ia.InventoryAmount_NLC, 0.00) - ISNULL(gld.Inventory_GL, 0.00) Paydown_Inventory_Difference
             , CASE
                   WHEN ISNULL(ia.InventoryAmount_LC, 0.00) + ISNULL(ia.InventoryAmount_NLC, 0.00) - ISNULL(gld.Inventory_GL, 0.00) != 0.00
                   THEN 'Problem Record'
                   ELSE 'Not Problem Record'
               END AS Result
        INTO #ResultList
        FROM #EligibleContracts ec
             LEFT JOIN #ContractDetails cd ON ec.ContractId = cd.ContractId
             LEFT JOIN #InventoryAmount ia ON ec.LoanPaydownId = ia.LoanPaydownId
             LEFT JOIN #GLJournalDetails gld ON ec.LoanPaydownId = gld.LoanPaydownId;

        SELECT name AS Name
             , 0 AS Count
             , CAST(0 AS BIT) AS IsProcessed
             , CAST('' AS NVARCHAR(MAX)) AS Label
			 , column_Id AS ColumnId
        INTO #PaydownSummary
        FROM tempdb.sys.columns
        WHERE object_id = OBJECT_ID('tempdb..#ResultList')
              AND Name LIKE '%Difference';

        DECLARE @query NVARCHAR(MAX);
        DECLARE @TableName NVARCHAR(MAX);

        WHILE EXISTS(SELECT 1 FROM #PaydownSummary WHERE IsProcessed = 0)
		BEGIN
			SELECT TOP 1 @TableName = Name
			FROM #PaydownSummary
			WHERE IsProcessed = 0;
			SET @query = 'UPDATE #PaydownSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName + ' != 0.00), IsProcessed = 1
			WHERE Name = ''' + @TableName + ''' ;';
			EXEC (@query);
		END;

        UPDATE #PaydownSummary SET 
                                   Label = CASE
                                               WHEN Name = 'Paydown_Inventory_Difference'
                                               THEN '1_Paydown Inventory_Difference'
                                           END;

        IF @IsFromLegalEntity = 0
		BEGIN
			SELECT Label AS Name
				 , Count
			FROM #PaydownSummary
			ORDER BY ColumnId;

			IF(@ResultOption = 'All')
			BEGIN
				SELECT *
				FROM #ResultList
				ORDER BY LoanPaydownId;
			END;

			IF(@ResultOption = 'Failed')
			BEGIN
				SELECT *
				FROM #ResultList
				WHERE Result = 'Problem Record'
				ORDER BY LoanPaydownId;
			END;

			IF(@ResultOption = 'Passed')
			BEGIN
				SELECT *
				FROM #ResultList
				WHERE Result = 'Not Problem Record'
				ORDER BY LoanPaydownId;
			END;

			DECLARE @TotalCount BIGINT;
			SELECT @TotalCount = ISNULL(COUNT(*), 0)
			FROM #ResultList;

			DECLARE @InCorrectCount BIGINT;
			SELECT @InCorrectCount = ISNULL(COUNT(*), 0)
			FROM #ResultList
			WHERE Result = 'Problem Record';

			DECLARE @Messages StoredProcMessage;

			INSERT INTO @Messages(Name, ParameterValuesCsv)
			VALUES('TotalPaydowns',(SELECT 'Paydowns=' + CONVERT(NVARCHAR(40), @TotalCount)));

			INSERT INTO @Messages(Name, ParameterValuesCsv)
			VALUES('PaydownsSuccessful',(SELECT 'PaydownsSuccessful=' + CONVERT(NVARCHAR(40), (@TotalCount - @InCorrectCount))));

			INSERT INTO @Messages(Name, ParameterValuesCsv)
			VALUES('PaydownsIncorrect',(SELECT 'PaydownsIncorrect=' + CONVERT(NVARCHAR(40), @InCorrectCount)));

			INSERT INTO @Messages(Name, ParameterValuesCsv)
			VALUES('PaydownsResultOption',(SELECT 'ResultOption=' + CONVERT(NVARCHAR(40), @ResultOption)));

			SELECT * FROM @Messages;
        END;

        IF @IsFromLegalEntity = 1
            BEGIN
                SELECT LegalEntityName
                     , SUM(Paydown_Inventory_GL) AS ReturnedToInventory_Paydown_GL
                FROM #ResultList
                GROUP BY LegalEntityName;
        END;

        DROP TABLE #EligibleContracts;
        DROP TABLE #ContractDetails;
        DROP TABLE #InventoryAmount;
        DROP TABLE #GLJournalDetails;
        DROP TABLE #ResultList;
        DROP TABLE #PaydownSummary;
    END;

GO
