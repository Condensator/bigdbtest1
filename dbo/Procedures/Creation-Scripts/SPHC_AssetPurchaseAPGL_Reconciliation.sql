SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_AssetPurchaseAPGL_Reconciliation]
(@ResultOption      NVARCHAR(20), 
 @IsFromLegalEntity BIT NULL, 
 @LegalEntityIds    ReconciliationId READONLY
)
AS
BEGIN

	IF OBJECT_ID('tempdb..#EligiblePayableInvoices') IS NOT NULL
    DROP TABLE #EligiblePayableInvoices;

    IF OBJECT_ID('tempdb..#PayableInvoiceInfo') IS NOT NULL
        DROP TABLE #PayableInvoiceInfo;

    IF OBJECT_ID('tempdb..#CostTable_HC') IS NOT NULL
        DROP TABLE #CostTable_HC;

    IF OBJECT_ID('tempdb..#CostTable_Posted') IS NOT NULL
        DROP TABLE #CostTable_Posted;

    IF OBJECT_ID('tempdb..#PayableInvoiceSpecificOtherCostInfo') IS NOT NULL
        DROP TABLE #PayableInvoiceSpecificOtherCostInfo;

    IF OBJECT_ID('tempdb..#SpecificCostTable_Posted') IS NOT NULL
        DROP TABLE #SpecificCostTable_Posted;

	IF OBJECT_ID('tempdb..#OtherCostsAmount') IS NOT NULL
		DROP TABLE #OtherCostsAmount;
	
	IF OBJECT_ID('tempdb..#AssociateAssetPPC') IS NOT NULL
		DROP TABLE #AssociateAssetPPC;

	IF OBJECT_ID('tempdb..#ResultList_Table') IS NOT NULL
		DROP TABLE #ResultList_Table;
	
	IF OBJECT_ID('tempdb..#DRGLAmount') IS NOT NULL
		DROP TABLE #DRGLAmount;
		
	IF OBJECT_ID('tempdb..#PPCandDNPAmounts') IS NOT NULL
		DROP TABLE #PPCandDNPAmounts;

	IF OBJECT_ID('tempdb..#TotalPrepaidAmount') IS NOT NULL
		DROP TABLE #TotalPrepaidAmount;
		
	IF OBJECT_ID('tempdb..#TotalCost_HC') IS NOT NULL
		DROP TABLE #TotalCost_HC;
		
	IF OBJECT_ID('tempdb..#TotalAssetCost') IS NOT NULL
		DROP TABLE #TotalAssetCost;
		
	IF OBJECT_ID('tempdb..#PayableInvoiceTable') IS NOT NULL
		DROP TABLE #PayableInvoiceTable;
		
	IF OBJECT_ID('tempdb..#DRTableAmount') IS NOT NULL
		DROP TABLE #DRTableAmount;
		
	IF OBJECT_ID('tempdb..#DRIdTable') IS NOT NULL
		DROP TABLE #DRIdTable;
		
	IF OBJECT_ID('tempdb..#DRINFO') IS NOT NULL
		DROP TABLE #DRINFO;

	IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
		DROP TABLE #ResultList;
		
	IF OBJECT_ID('tempdb..#AssetPurchaseAPSummary') IS NOT NULL
		DROP TABLE #AssetPurchaseAPSummary;

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

    CREATE TABLE #CostTable_HC
    (PayableInvoiceId           BIGINT NOT NULL, 
     AcquisitionCost_LC_Table   DECIMAL(16, 2) NOT NULL, 
     AcquisitionCost_FC_Table   DECIMAL(16, 2) NOT NULL, 
     OtherCost_LC_Table         DECIMAL(16, 2) NOT NULL, 
     OtherCost_FC_Table         DECIMAL(16, 2) NOT NULL, 
     TotalAcquisitionCost_Table DECIMAL(16, 2) NOT NULL
    );

    CREATE TABLE #CostTable_Posted
    (PayableInvoiceId         BIGINT NOT NULL, 
     AcquisitionCost_LC_Table DECIMAL(16, 2) NOT NULL, 
     AcquisitionCost_FC_Table DECIMAL(16, 2) NOT NULL, 
     OtherCost_LC_Table       DECIMAL(16, 2) NOT NULL, 
     OtherCost_FC_Table       DECIMAL(16, 2) NOT NULL
    );

    CREATE TABLE #SpecificCostTable_Posted
    (PayableInvoiceId                BIGINT NOT NULL, 
     SpecificCostAdjustment_LC_Table DECIMAL(16, 2) NOT NULL, 
     SpecificCostAdjustment_FC_Table DECIMAL(16, 2) NOT NULL
    );

	SELECT pin.InvoiceNumber
            , p.PartyName [VendorName]
            , pin.Id
            , pin.IsForeignCurrency
            , pin.InitialExchangeRate
            , pin.OriginalExchangeRate
            , le.Name [LegalEntityName]
            , lob.Name [LineOfBusinessName]
            , it.Code [InstrumentType]
            , cc.CostCenter [CostCenter]
            , b.BranchName [BranchName]
            , pt.PartyName [CustomerName]
            , pin.ContractType
            , c.SequenceNumber
            , pin.InvoiceDate
            , pin.InvoiceTotal_Currency [PayableInvoiceCurrency]
            , pin.TotalAssetCost_Currency [AssetBookingCurrency]
            , pin.InvoiceTotal_Amount [InvoiceTotalPayableValue]
            , pin.AssetCostPayableCodeId
    INTO #EligiblePayableInvoices
    FROM PayableInvoices pin
            INNER JOIN Parties p ON pin.VendorId = p.Id
            INNER JOIN LegalEntities le ON pin.LegalEntityId = le.Id
            LEFT JOIN LineofBusinesses lob ON pin.LineofBusinessId = lob.Id
            LEFT JOIN InstrumentTypes it ON pin.InstrumentTypeId = it.Id
            LEFT JOIN CostCenterConfigs cc ON pin.CostCenterId = cc.Id
            LEFT JOIN Branches b ON pin.BranchId = b.Id
            LEFT JOIN Parties pt ON pt.PartyNumber = pin.CustomerNumber
            LEFT JOIN Contracts c ON c.id = pin.ContractId
    WHERE pin.Status = 'Completed'
            AND pin.ContractType NOT IN('ProgressLoan', 'Loan')
            AND @True = (CASE WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = pin.LegalEntityId) THEN @True
                            WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False
                        END);

    CREATE NONCLUSTERED INDEX IX_Id ON #EligiblePayableInvoices(Id);

	SELECT pin.InvoiceNumber
            , pia.AssetId
            , pia.Id [PayableInvoiceAssetId]
            , pia.AcquisitionCost_Amount
            , pia.OtherCost_Amount
            , pin.Id
            , pin.IsForeignCurrency
            , pin.InitialExchangeRate
            , pin.OriginalExchangeRate
			, CAST (0 AS bit) [IsSKU]
			, ea.STATUS [AssetStatus]
            , ea.IsLeaseComponent
            , pin.ContractType
            , pin.InvoiceDate
            , pin.PayableInvoiceCurrency 
            , pin.AssetBookingCurrency
            , pin.InvoiceTotalPayableValue
            , pin.AssetCostPayableCodeId
			, ea.IsSystemCreated
    INTO #PayableInvoiceInfo
    FROM #EligiblePayableInvoices pin
            INNER JOIN PayableInvoiceAssets pia ON pia.PayableInvoiceId = pin.Id
            INNER JOIN Assets ea ON pia.AssetId = ea.Id
    WHERE pia.IsActive = 1;

	CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceInfo(Id);

	IF @IsSku = 1
	BEGIN
	SET @Sql =
	'UPDATE pin
	SET pin.IsSKU = 1
	FROM #PayableInvoiceInfo pin
    INNER JOIN PayableInvoiceAssets pia ON pia.PayableInvoiceId = pin.Id
    INNER JOIN Assets ea ON pia.AssetId = ea.Id AND ea.IsSKU = 1'
	INSERT INTO #PayableInvoiceInfo
	EXEC (@Sql)
	END;

	UPDATE pin SET 
            pin.AssetStatus = 'Inventory'
	FROM #PayableInvoiceInfo pin
	LEFT JOIN (
		SELECT DISTINCT 
				pin.AssetId
		FROM #PayableInvoiceInfo pin
				INNER JOIN LeaseAssets la ON pin.AssetId = la.AssetId
				INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId
		WHERE lf.IsCurrent = 1
				AND la.IsActive = 1
				AND pin.AssetStatus = 'Leased'
		) t ON t.AssetId = pin.AssetId
	WHERE pin.AssetStatus = 'Leased'
		AND t.AssetId IS NULL
		AND pin.IsSystemCreated = 0;

    BEGIN
        SET @Sql = 
		'SELECT 
			pin.id AS PayableInvoiceId
			,SUM(CASE
				WHEN pin.IsLeaseComponent = 1 
				THEN pin.AcquisitionCost_Amount
				ELSE 0.00
			END) [AcquisitionCost_LC_Table]
			,SUM(CASE
				WHEN pin.IsLeaseComponent = 0 
				THEN pin.AcquisitionCost_Amount
				ELSE 0.00
			END) [AcquisitionCost_FC_Table]
			,SUM(CASE
				WHEN pin.IsLeaseComponent = 1 
				THEN pin.OtherCost_Amount
				ELSE 0.00
			END) [OtherCost_LC_Table]
			,SUM(CASE
				WHEN pin.IsLeaseComponent = 0 
				THEN pin.OtherCost_Amount
				ELSE 0.00
			END) [OtherCost_FC_Table]
			,CAST(0.00 AS DECIMAL(16, 2)) [TotalAcquisitionCost_Table]
		FROM #PayableInvoiceInfo pin
		WHERE pin.AssetStatus NOT IN (''Leased'',''InvestorLeased'')
		GROUP BY pin.id';
        INSERT INTO #CostTable_HC
        EXEC (@Sql);
    END;

    BEGIN
        SET @Sql = 
		'SELECT 
			pin.id AS PayableInvoiceId
			,SUM(CASE
				WHEN la.IsLeaseAsset = 1
				THEN pin.AcquisitionCost_Amount
				ELSE 0.00
			END) [AcquisitionCost_LC_Table]
			,SUM(CASE
				WHEN la.IsLeaseAsset = 0
				THEN pin.AcquisitionCost_Amount
				ELSE 0.00
			END) [AcquisitionCost_FC_Table]
			,SUM(CASE
				WHEN la.IsLeaseAsset = 1
				THEN pin.OtherCost_Amount
				ELSE 0.00
			END) [OtherCost_LC_Table]
			,SUM(CASE
				WHEN la.IsLeaseAsset = 0
				THEN pin.OtherCost_Amount
				ELSE 0.00
			END) [OtherCost_FC_Table]
			,0 [TotalAcquisitionCost_Table]
		FROM #PayableInvoiceInfo pin
		INNER JOIN LeaseAssets la ON pin.AssetId = la.AssetId
		INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
		WHERE lf.IsCurrent = 1 AND la.IsActive = 1
		AND pin.AssetStatus IN (''Leased'',''InvestorLeased'')
		GROUP BY pin.id';
        INSERT INTO #CostTable_HC
        EXEC (@Sql);
    END;

	CREATE NONCLUSTERED INDEX IX_Id ON #CostTable_HC(PayableInvoiceId);

    UPDATE ct SET 
                    ct.TotalAcquisitionCost_Table = ISNULL(ct.AcquisitionCost_LC_Table, 0.00) + ISNULL(ct.AcquisitionCost_FC_Table, 0.00)
    FROM #CostTable_HC ct;

    SELECT ct.PayableInvoiceId
            , SUM(ct.AcquisitionCost_LC_Table) AcquisitionCost_LC_Table
            , SUM(ct.AcquisitionCost_FC_Table) AcquisitionCost_FC_Table
            , SUM(ct.OtherCost_LC_Table) OtherCost_LC_Table
            , SUM(ct.OtherCost_FC_Table) OtherCost_FC_Table
            , SUM(ct.TotalAcquisitionCost_Table) TotalAcquisitionCost_Table
    INTO #TotalCost_HC
    FROM #CostTable_HC ct
    GROUP BY ct.PayableInvoiceId;

	CREATE NONCLUSTERED INDEX IX_Id ON #TotalCost_HC(PayableInvoiceId);

    BEGIN
        SET @Sql = 
		'SELECT 
			pin.id AS PayableInvoiceId
			,SUM(CASE
				WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 1
				THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
				WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 0
				THEN pin.AcquisitionCost_Amount
				ELSE 0.00
			END) [AcquisitionCost_LC_Table]
			,SUM(CASE
				WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 1
				THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
				WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 0
				THEN pin.AcquisitionCost_Amount
				ELSE 0.00
			END) [AcquisitionCost_FC_Table]
			,SUM(CASE
				WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 1
				THEN CAST (pin.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
				WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 0
				THEN pin.OtherCost_Amount
				ELSE 0.00
			END) [OtherCost_LC_Table]
			,SUM(CASE
				WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 1
				THEN CAST (pin.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
				WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 0
				THEN pin.OtherCost_Amount
				ELSE 0.00
			END) [OtherCost_FC_Table]
		FROM #PayableInvoiceInfo pin
		INNER JOIN Payables p ON p.SourceId = pin.PayableInvoiceAssetId AND p.SourceTable = ''PayableInvoiceAsset''
		WHERE p.IsGLPosted = 1 and p.Status != ''Inactive''
		GROUP BY pin.id';
        INSERT INTO #CostTable_Posted
        EXEC (@Sql);
    END;

    CREATE NONCLUSTERED INDEX IX_Id ON #CostTable_Posted(PayableInvoiceId);
		
    SELECT ea.Id [AssetId]
            , CAST (0 AS bit) [IsSKU]
            , ea.IsLeaseComponent
            , ea.Status
            , pin.Id [PayableInvoiceId]
            , pin.IsForeignCurrency
            , pin.InitialExchangeRate
            , pioc.Id [PayableInvoiceOtherCostId]
            , pioc.Amount_Amount [SpecificCost_Amount]
            , pin.ContractType
            , pin.InvoiceDate
            , pioc.AllocationMethod
            , pioc.AssociateAssets
            , pin.AssetCostPayableCodeId
    INTO #PayableInvoiceSpecificOtherCostInfo
    FROM PayableInvoiceOtherCosts pioc
            INNER JOIN Assets ea ON pioc.AssetId = ea.Id
            INNER JOIN #EligiblePayableInvoices pin ON pioc.PayableInvoiceId = pin.Id
            INNER JOIN Payables p ON p.EntityId = pin.Id
                                    AND p.EntityType = 'PI'
									AND pioc.Id = p.SourceId
    WHERE pioc.IsActive = 1
            AND pioc.AllocationMethod = 'SpecificCostAdjustment'
            AND p.SourceTable = 'PayableInvoiceOtherCost'
            AND p.isglposted = 1 and p.Status != 'Inactive';

	CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceSpecificOtherCostInfo(PayableInvoiceId);
		
	IF @IsSku = 1
	BEGIN
	SET @Sql =
	'UPDATE pioc
	SET pioc.IsSKU = 1
	FROM #PayableInvoiceSpecificOtherCostInfo pioc
            INNER JOIN Assets ea ON pioc.AssetId = ea.Id AND ea.IsSKU = 1'
	INSERT INTO #PayableInvoiceSpecificOtherCostInfo
	EXEC (@Sql)
	END;

    BEGIN
        SET @Sql = 
		'SELECT
			pioc.PayableInvoiceId
			,SUM(
				CASE 
					WHEN pioc.IsLeaseComponent = 1 AND pioc.IsForeignCurrency = 1 
					THEN CAST (pioc.SpecificCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
					WHEN pioc.IsLeaseComponent = 1 AND pioc.IsForeignCurrency = 0
					THEN pioc.SpecificCost_Amount
					ELSE 0.00
				END) AS [SpecificCostAdjustment_LC_Table]
			,SUM(
				CASE 
					WHEN pioc.IsLeaseComponent = 0 AND pioc.IsForeignCurrency = 1 
					THEN CAST (pioc.SpecificCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
					WHEN pioc.IsLeaseComponent = 0 AND pioc.IsForeignCurrency = 0
					THEN pioc.SpecificCost_Amount
					ELSE 0.00
				END) AS [SpecificCostAdjustment_FC_Table]
		FROM #PayableInvoiceSpecificOtherCostInfo pioc
		GROUP BY pioc.PayableInvoiceId';
        INSERT INTO #SpecificCostTable_Posted
        EXEC (@Sql);
    END;
		
	CREATE NONCLUSTERED INDEX IX_Id ON #SpecificCostTable_Posted(PayableInvoiceId);


	SELECT pin.id AS PayableInvoiceId
			,SUM(CASE 
				WHEN pioc.AllocationMethod = 'ProgressPaymentCredit' AND pioc.AssociateAssets = 1 AND pin.ContractType = 'Lease'
				THEN pioc.Amount_Amount
				ELSE 0.00
			END) [TotalPPCAssetCost]
		,SUM(CASE
				WHEN pioc.AllocationMethod = 'DoNotPay'
				THEN pioc.Amount_Amount
				ELSE 0.00
			END) [TotalDoNotPay]
	INTO #PPCandDNPAmounts
	FROM PayableInvoiceOtherCosts pioc
            INNER JOIN #EligiblePayableInvoices pin ON pioc.PayableInvoiceId = pin.Id
    GROUP BY pin.Id;

	CREATE NONCLUSTERED INDEX IX_Id ON #PPCandDNPAmounts(PayableInvoiceId);


    SELECT t.Id AS PayableInvoiceId
            , SUM(t.TotalPrepaidAmount) AS TotalPrepaidAmount
    INTO #TotalPrepaidAmount
    FROM
    (
        SELECT Pin.Id
                , SUM(-(pidta.TakeDownAmount_Amount)) AS TotalPrepaidAmount
        FROM #PayableInvoiceInfo pin
                INNER JOIN PayableInvoiceDepositAssets pida ON pida.PayableInvoiceId = pin.Id
                INNER JOIN PayableInvoiceDepositTakeDownAssets pidta ON pida.Id = pidta.PayableInvoiceDepositAssetId
        GROUP BY pin.Id
        UNION
		SELECT pin.Id
                , SUM(-(pioc.Amount_Amount)) AS TotalPrepaidAmount
        FROM PayableInvoiceOtherCosts pioc
                INNER JOIN #EligiblePayableInvoices pin ON pioc.PayableInvoiceId = pin.Id
        WHERE pioc.AllocationMethod = 'ProgressPaymentCredit'
        GROUP BY pin.Id
    ) AS T
    GROUP BY t.Id;

	CREATE NONCLUSTERED INDEX IX_Id ON #TotalPrepaidAmount(PayableInvoiceId);

    SELECT pin.Id AS PayableInvoiceID
            , SUM(pioc.Amount_Amount) AS Amount
    INTO #OtherCostsAmount
    FROM PayableInvoiceOtherCosts pioc
            INNER JOIN #EligiblePayableInvoices pin ON pin.id = pioc.PayableInvoiceId
    WHERE pioc.AllocationMethod IN('Specific', 'AssetCost', 'AssetCount', 'SpecificCostAdjustment', 'VendorSubsidy', 'LoanDisbursement', 'DoNotPay', 'Absorb', 'ChargeBack')
	AND pioc.IsActive = 1
    GROUP BY pin.Id;

	CREATE NONCLUSTERED INDEX IX_Id ON #OtherCostsAmount(PayableInvoiceId);

	SELECT pin.Id AS PayableInvoiceId
            , SUM(-(pioc.Amount_Amount)) AS AssociateAssetPPC
	INTO #AssociateAssetPPC
    FROM PayableInvoiceOtherCosts pioc
            INNER JOIN #EligiblePayableInvoices pin ON pioc.PayableInvoiceId = pin.Id
			INNER JOIN PayableInvoiceOtherCosts ppcpioc ON pioc.ProgressFundingId = ppcpioc.Id
    WHERE pioc.AllocationMethod = 'ProgressPaymentCredit'
	AND ppcpioc.AssociateAssets = 1
    GROUP BY pin.Id
	
	CREATE NONCLUSTERED INDEX IX_Id ON #AssociateAssetPPC(PayableInvoiceId);

    SELECT DISTINCT 
            pin.Id AS PayableInvoiceId
            , pin.InvoiceNumber
            , pin.VendorName
            , CASE
                WHEN pin.IsForeignCurrency = 1
                THEN CAST(pin.InitialExchangeRate AS NVARCHAR(40))
                WHEN pin.IsForeignCurrency = 0
                THEN 'NA'
            END AS [ExchangeRate]
            , pin.LegalEntityName
            , pin.LineOfBusinessName
            , pin.InstrumentType
            , pin.CostCenter
            , pin.BranchName
            , CustomerName
            , pin.ContractType
            , pin.InvoiceDate
            , pin.AssetCostPayableCodeId
            , pin.SequenceNumber
            , pin.PayableInvoiceCurrency
            , pin.AssetBookingCurrency
            , pin.InvoiceTotalPayableValue
            , ISNULL(tc.TotalAcquisitionCost_Table, 0.00) AS TotalOriginalAssetCost
            , ISNULL(oca.TotalPPCAssetCost, 0.00) AS TotalPPCAssetCost
            , (ISNULL(oc.Amount, 0.00)) AS TotalOtherCost
            , ISNULL(tc.TotalAcquisitionCost_Table, 0.00) + ISNULL(oc.Amount, 0.00) AS CalculatedInvoiceTotal
            , ISNULL(tpa.TotalPrepaidAmount, 0.00) AS TotalPrepaidAmount
            , ISNULL(oca.TotalDoNotPay, 0.00) AS TotalDoNotPay
            , ctp.AcquisitionCost_LC_Table AS AcquisitionCost_LC_Table_Posted
            , ctp.AcquisitionCost_FC_Table AS AcquisitionCost_FC_Table_Posted
            , ctp.OtherCost_LC_Table AS OtherCost_LC_Table_Posted
            , ctp.OtherCost_FC_Table AS OtherCost_FC_Table_Posted
            , sctp.SpecificCostAdjustment_LC_Table AS SpecificCostAdjustment_LC_Table_Posted
            , sctp.SpecificCostAdjustment_FC_Table AS SpecificCostAdjustment_FC_Table_Posted
    INTO #ResultList_Table
    FROM #EligiblePayableInvoices pin
            LEFT JOIN #CostTable_HC ct ON ct.PayableInvoiceId = pin.Id
            LEFT JOIN #TotalCost_HC tc ON tc.PayableInvoiceId = pin.Id
            LEFT JOIN #CostTable_Posted ctp ON ctp.PayableInvoiceId = pin.Id
            LEFT JOIN #SpecificCostTable_Posted sctp ON sctp.PayableInvoiceId = pin.Id
			LEFT JOIN #PPCandDNPAmounts oca ON oca.PayableInvoiceId = pin.Id
            LEFT JOIN #TotalPrepaidAmount tpa ON pin.Id = tpa.PayableInvoiceId
            LEFT JOIN #OtherCostsAmount oc ON oc.PayableInvoiceID = pin.Id;

    SELECT gld.EntityId
            , gld.EntityType
            , SUM(CASE
                    WHEN gle.Name = 'Inventory'
                        AND gld.IsDebit = 1
                    THEN Amount_Amount
                    ELSE 0.00
                END) - SUM(CASE
                                WHEN gle.Name = 'Inventory'
                                    AND gld.IsDebit = 0
                                THEN Amount_Amount
                                ELSE 0.00
                            END) AssetPurchaseAP_GL
    INTO #DRGLAmount
    FROM GLJournalDetails gld
            INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
            INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
            INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
            LEFT JOIN GLTemplateDetails mgltd ON mgltd.Id = gld.MatchingGLTemplateDetailId
            LEFT JOIN GLEntryItems mgle ON mgle.Id = mgltd.EntryItemId
            LEFT JOIN GLTransactionTypes mgltt ON mgle.GLTransactionTypeId = mgltt.Id
            LEFT JOIN (SELECT DISTINCT GLJournalId FROM AssetValueHistories WHERE SourceModule = 'PayableInovice') AS t ON t.GLJournalId = gld.GLJournalId
    WHERE gld.EntityType = 'DisbursementRequest'
            AND gltt.Name = 'AssetPurchaseAP'
            AND t.GLJournalId IS NULL
    GROUP BY gld.EntityId
            , gld.EntityType;

	CREATE NONCLUSTERED INDEX IX_Id ON #DRGLAmount(EntityId);

    /*AcquisitionCost and OtherCost with DR */
	SELECT pin.id AS PayableInvoiceId
            , SUM(CASE
                    WHEN pin.IsLeaseComponent = 1
                        AND pin.IsForeignCurrency = 1
                    THEN CAST(pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS DECIMAL(16, 2))
                    WHEN pin.IsLeaseComponent = 1
                        AND pin.IsForeignCurrency = 0
                    THEN pin.AcquisitionCost_Amount
                    ELSE 0.00
                END) + SUM(CASE
                                WHEN pin.IsLeaseComponent = 0
                                    AND pin.IsForeignCurrency = 1
                                THEN CAST(pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS DECIMAL(16, 2))
                                WHEN pin.IsLeaseComponent = 0
                                    AND pin.IsForeignCurrency = 0
                                THEN pin.AcquisitionCost_Amount
                                ELSE 0.00
                            END) + SUM(CASE
                                            WHEN pin.IsLeaseComponent = 1
                                                AND pin.IsForeignCurrency = 1
                                            THEN CAST(pin.OtherCost_Amount * pin.InitialExchangeRate AS DECIMAL(16, 2))
                                            WHEN pin.IsLeaseComponent = 1
                                                AND pin.IsForeignCurrency = 0
                                            THEN pin.OtherCost_Amount
                                            ELSE 0.00
                                        END) + SUM(CASE
                                                    WHEN pin.IsLeaseComponent = 0
                                                            AND pin.IsForeignCurrency = 1
                                                    THEN CAST(pin.OtherCost_Amount * pin.InitialExchangeRate AS DECIMAL(16, 2))
                                                    WHEN pin.IsLeaseComponent = 0
                                                            AND pin.IsForeignCurrency = 0
                                                    THEN pin.OtherCost_Amount
                                                    ELSE 0.00
                                                END) TotalAmount_Table
    INTO #TotalAssetCost
    FROM #PayableInvoiceInfo pin
            INNER JOIN Payables p ON p.SourceId = pin.PayableInvoiceAssetId
                                    AND p.SourceTable = 'PayableInvoiceAsset'
    WHERE p.IsGLPosted = 1 and p.Status != 'Inactive'
    GROUP BY pin.id;

	CREATE NONCLUSTERED INDEX IX_Id ON #TotalAssetCost(PayableInvoiceId);

    /*PayableInvoiceTable*/
    SELECT t.PayableInvoiceId
            , SUM(t.Amount) AS TotalAmount_Table
            , CAST(0 AS DECIMAL(16, 2)) [GL_Amount]
    INTO #PayableInvoiceTable
    FROM
    (
        SELECT PayableInvoiceId
                , SUM(TotalAmount_Table) AS Amount
        FROM #TotalAssetCost
        GROUP BY PayableInvoiceId
        UNION
        SELECT PayableInvoiceId
                , SUM(SpecificCostAdjustment_LC_Table) + SUM(SpecificCostAdjustment_FC_Table) AS Amount
        FROM #SpecificCostTable_Posted
        GROUP BY PayableInvoiceId
    ) AS t
    GROUP BY t.PayableInvoiceId;

	CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceTable(PayableInvoiceId);

    /*DR TABLE*/
	SELECT t.DisbursementRequestId
			, SUM(CASE
                    WHEN t.IsForeignCurrency = 1
                    THEN CAST(t.Amount_Amount * t.InitialExchangeRate AS DECIMAL(16, 2))
                    WHEN t.IsForeignCurrency = 0
                    THEN t.Amount_Amount
                END) AS Amount
	INTO #DRTableAmount
	FROM
    (SELECT DISTINCT dr.Id AS DisbursementRequestId,p.Amount_Amount,pin.IsForeignCurrency,pin.InitialExchangeRate,p.id
    FROM #EligiblePayableInvoices pin
            INNER JOIN Payables p ON p.EntityId = pin.Id
            INNER JOIN DisbursementRequestPayables drp ON drp.PayableId = p.Id
            INNER JOIN DisbursementRequests dr ON dr.id = drp.DisbursementRequestId
			LEFT JOIN #PayableInvoiceSpecificOtherCostInfo pioc ON pioc.PayableInvoiceId = pin.Id
    WHERE dr.STATUS = 'Completed'
			AND (p.SourceTable = 'PayableInvoiceAsset'
                                        OR (p.SourceId = pioc.PayableInvoiceOtherCostId
                                            AND p.Sourcetable = 'PayableInvoiceOtherCost'))
            AND (pioc.PayableInvoiceOtherCostId IS NULL OR (pioc.PayableInvoiceOtherCostId IS NOT NULL AND pioc.AllocationMethod = 'SpecificCostAdjustment'))
			AND p.IsGLPosted = 1  and p.Status != 'Inactive'
            AND p.EntityType = 'PI') AS T
    GROUP BY t.DisbursementRequestId;

	CREATE NONCLUSTERED INDEX IX_Id ON #DRTableAmount(DisbursementRequestId);

    /*DRINFOTable*/
    SELECT DISTINCT 
            pin.id AS PayableInvoiceId
            , dr.Id AS DisbursementRequestId
    INTO #DRIdTable
    FROM #EligiblePayableInvoices pin
            INNER JOIN Payables p ON p.EntityId = pin.Id
            INNER JOIN DisbursementRequestPayables drp ON drp.PayableId = p.Id
            INNER JOIN DisbursementRequests dr ON dr.id = drp.DisbursementRequestId
			LEFT JOIN #PayableInvoiceSpecificOtherCostInfo pioc ON pioc.PayableInvoiceId = pin.Id
    WHERE dr.STATUS = 'Completed'
			AND (p.SourceTable = 'PayableInvoiceAsset'
                                        OR (p.SourceId = pioc.PayableInvoiceOtherCostId
                                            AND p.Sourcetable = 'PayableInvoiceOtherCost'))
            AND (pioc.PayableInvoiceOtherCostId IS NULL OR (pioc.PayableInvoiceOtherCostId IS NOT NULL AND pioc.AllocationMethod = 'SpecificCostAdjustment'))
			AND p.IsGLPosted = 1  and p.Status != 'Inactive'
            AND p.EntityType = 'PI';

	CREATE NONCLUSTERED INDEX IX_Id ON #DRIdTable(DisbursementRequestId);

    SELECT PayableInvoiceId
            , STUFF((SELECT ', ' + CONVERT(NVARCHAR(100), ps1.DisbursementRequestId) 
					FROM #DRIdTable ps1
					WHERE ps1.PayableInvoiceId = ps.PayableInvoiceId FOR XML PATH('')), 1, 2, '') [DisbursementRequestId]
    INTO #DRINFO
    FROM #DRIdTable ps
    GROUP BY PayableInvoiceId;

	CREATE NONCLUSTERED INDEX IX_Id ON #DRINFO(PayableInvoiceId);

    UPDATE #PayableInvoiceTable SET 
                                    GL_Amount = TotalAmount_Table
    FROM #PayableInvoiceTable pin
            INNER JOIN #DRIdTable drid ON pin.PayableInvoiceId = drid.PayableInvoiceId
    WHERE drid.DisbursementRequestId IN
    (SELECT DisbursementRequestId
        FROM #DRGLAmount drgl
                INNER JOIN #DRTableAmount drt ON drt.DisbursementRequestId = drgl.EntityId
        WHERE drt.Amount = drgl.AssetPurchaseAP_GL);

    SELECT t.*
            , CASE
                WHEN t.AssetPurchaseAP_Difference != 0.00
                    OR t.InvoiceTotal_Difference != 0.00
                THEN 'Problem Record'
                ELSE 'Not Problem Record'
            END [Result]
    INTO #ResultList
    FROM
    (SELECT 
		app.PayableInvoiceId
        , app.InvoiceNumber
        , drid.DisbursementRequestId
        , app.LegalEntityName
        , app.LineOfBusinessName
        , app.InstrumentType
        , app.CostCenter
        , app.BranchName
        , app.VendorName
        , app.CustomerName
        , app.ContractType
        , app.SequenceNumber [ContractSequenceNumber]
        , app.InvoiceDate
        , glt.Name [GLTemplateName]
        , app.PayableInvoiceCurrency
        , app.AssetBookingCurrency
        , app.ExchangeRate
        , app.TotalOriginalAssetCost
        , app.TotalPPCAssetCost
        , app.TotalOtherCost
        , ISNULL(app.CalculatedInvoiceTotal,0.00) + ISNULL(appc.AssociateAssetPPC,0.00) AS CalculatedInvoiceTotal
        , app.TotalPrepaidAmount
        , app.TotalDoNotPay
        , (ISNULL(app.CalculatedInvoiceTotal, 0.00) - ISNULL(app.TotalDoNotPay, 0.00) - ISNULL(app.TotalPrepaidAmount, 0.00)) AS InvoiceTotalComputedValue
        , ISNULL(app.InvoiceTotalPayableValue, 0.00) AS InvoiceTotalPayableValue
        , (ISNULL(app.InvoiceTotalPayableValue, 0.00) - (ISNULL(app.CalculatedInvoiceTotal,0.00) + ISNULL(appc.AssociateAssetPPC,0.00))) AS InvoiceTotal_Difference
        , ISNULL(app.AcquisitionCost_LC_Table_Posted, 0.00) AS AcquisitionCost_LC_Table
        , ISNULL(app.AcquisitionCost_FC_Table_Posted, 0.00) AS AcquisitionCost_FC_Table
        , ISNULL(app.OtherCost_LC_Table_Posted, 0.00) AS OtherCost_LC_Table
        , ISNULL(app.OtherCost_FC_Table_Posted, 0.00) AS OtherCost_FC_Table
        , ISNULL(app.SpecificCostAdjustment_LC_Table_Posted, 0.00) AS SpecificCostAdjustment_LC_Table
        , ISNULL(app.SpecificCostAdjustment_FC_Table_Posted, 0.00) AS SpecificCostAdjustment_FC_Table
        , ISNULL(pin.GL_Amount, 0.00) AS AssetPurchaseAP_GL
        , (ISNULL(app.AcquisitionCost_LC_Table_Posted, 0.00) + ISNULL(app.AcquisitionCost_FC_Table_Posted, 0.00) + ISNULL(app.OtherCost_LC_Table_Posted, 0.00) + ISNULL(app.OtherCost_FC_Table_Posted, 0.00) + ISNULL(app.SpecificCostAdjustment_LC_Table_Posted, 0.00) + ISNULL(app.SpecificCostAdjustment_FC_Table_Posted, 0.00)) - (ISNULL(pin.GL_Amount, 0.00)) AssetPurchaseAP_Difference
    FROM #ResultList_Table app
            LEFT JOIN #PayableInvoiceTable pin ON pin.PayableInvoiceId = app.PayableInvoiceId
            LEFT JOIN #DRINFO drid ON drid.PayableInvoiceId = pin.PayableInvoiceId
            LEFT JOIN PayableCodes pc ON app.AssetCostPayableCodeId = pc.Id
            LEFT JOIN GLTemplates glt ON pc.GLTemplateId = glt.Id
			LEFT JOIN #AssociateAssetPPC appc ON appc.PayableInvoiceId = app.PayableInvoiceId
    WHERE app.ContractType NOT IN('ProgesssLoan', 'Loan')) t
    ORDER BY t.PayableInvoiceId;

    SELECT name AS Name, 0 AS Count, CAST(0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(MAX)) AS Label, column_Id AS ColumnId
    INTO #AssetPurchaseAPSummary
    FROM tempdb.sys.columns
    WHERE object_id = OBJECT_ID('tempdb..#ResultList')
            AND Name LIKE '%Difference';

    DECLARE @query NVARCHAR(MAX);
    DECLARE @TableName NVARCHAR(MAX);
    WHILE EXISTS (SELECT 1 FROM #AssetPurchaseAPSummary WHERE IsProcessed = 0)
    BEGIN
        SELECT TOP 1 @TableName = Name
        FROM #AssetPurchaseAPSummary
        WHERE IsProcessed = 0;

        SET @query = 'UPDATE #AssetPurchaseAPSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName + ' != 0.00), IsProcessed = 1
		WHERE Name = ''' + @TableName + ''' ;';
        EXEC (@query);
    END;

    UPDATE #AssetPurchaseAPSummary SET 
                                       Label = CASE
													WHEN Name = 'InvoiceTotal_Difference'
                                                    THEN '1_Invoice Total_Difference'
                                                    WHEN Name = 'AssetPurchaseAP_Difference'
                                                    THEN '2_Asset Purchase AP_Difference'
                                                END;

    IF @IsFromLegalEntity = 0
        BEGIN
            SELECT Label AS Name
                    , Count
            FROM #AssetPurchaseAPSummary
			ORDER BY ColumnId;

            IF(@ResultOption = 'All')
            BEGIN
                SELECT *
                FROM #ResultList
                ORDER BY PayableInvoiceId;
            END;

            IF(@ResultOption = 'Failed')
            BEGIN
                SELECT *
                FROM #ResultList
                WHERE Result = 'Problem Record'
                ORDER BY PayableInvoiceId;
            END;

            IF(@ResultOption = 'Passed')
            BEGIN
                SELECT *
                FROM #ResultList
                WHERE Result = 'Not Problem Record'
                ORDER BY PayableInvoiceId;
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
            VALUES ('TotalPayableInvoices', (SELECT 'PayableInvoices=' + CONVERT(NVARCHAR(40), @TotalCount)));
            INSERT INTO @Messages (Name, ParameterValuesCsv)
            VALUES ('PayableInvoicesSuccessful', (SELECT 'PayableInvoiceSuccessful=' + CONVERT(NVARCHAR(40), (@TotalCount - @InCorrectCount))));
            INSERT INTO @Messages (Name, ParameterValuesCsv)
            VALUES ('PayableInvoicesIncorrect', (SELECT 'PayableInvoiceIncorrect=' + CONVERT(NVARCHAR(40), @InCorrectCount)));
            INSERT INTO @Messages (Name, ParameterValuesCsv)
            VALUES ('PayableInvoicesResultOption', (SELECT 'ResultOption=' + CONVERT(NVARCHAR(40), @ResultOption)));

            SELECT * FROM @Messages;
	END;
	
	IF @IsFromLegalEntity = 1
        BEGIN

            SELECT LegalEntityName
                    , SUM(AssetPurchaseAP_GL) AS AcquisitionCost_GL
            FROM #ResultList
            GROUP BY LegalEntityName;
    END;

    DROP TABLE #PayableInvoiceInfo;
    DROP TABLE #CostTable_HC;
    DROP TABLE #CostTable_Posted;
    DROP TABLE #PayableInvoiceSpecificOtherCostInfo;
    DROP TABLE #SpecificCostTable_Posted;
    DROP TABLE #OtherCostsAmount;
	DROP TABLE #AssociateAssetPPC;
    DROP TABLE #ResultList_Table;
    DROP TABLE #DRGLAmount;
	DROP TABLE #PPCandDNPAmounts;
    DROP TABLE #TotalPrepaidAmount;
    DROP TABLE #TotalCost_HC;
    DROP TABLE #TotalAssetCost;
    DROP TABLE #PayableInvoiceTable;
    DROP TABLE #DRTableAmount;
    DROP TABLE #DRIdTable;
    DROP TABLE #DRINFO;
    DROP TABLE #ResultList;
    DROP TABLE #AssetPurchaseAPSummary;

END;

GO
