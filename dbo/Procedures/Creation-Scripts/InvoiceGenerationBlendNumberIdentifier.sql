SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InvoiceGenerationBlendNumberIdentifier]
(
	@JobStepInstanceId			BIGINT,
	@ChunkNumber				BIGINT,
	@AllowBlendingValues_Yes	NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON

	DECLARE @EntityType_CT NVARCHAR(10)	= 'CT'
	DECLARE @ContractType_Lease NVARCHAR(10)	= 'Lease'
	DECLARE @ContractType_Loan NVARCHAR(10)	= 'Loan'
	DECLARE @IsDownPaymentBlendingApplicable BIT = (SELECT CASE WHEN [ApplicableForBlending] = 'Yes' THEN 1 ELSE 0 END FROM PayableTypeInvoiceConfigs WHERE PaymentType='DownPayment' )
	
	CREATE TABLE #BillToInvoiceParameters_Extract(
	     ExtractId BIGINT,
		ReceivableId BIGINT,
		VirtualReceivableId BIGINT,
		ReceivableDetailId BIGINT PRIMARY KEY,
		JobStepInstanceId BIGINT, 
		ReceivableDueDate DATE,
		BillToId BIGINT,
		AllowBlending BIT NOT NULL,
		GroupNumber INT,
		SplitNumber INT,
		ReceivableTypeId BIGINT, 
		ReceivableTypeName NVARCHAR(21),
		IsParentReceivableDetail BIT NOT NULL,
		HasParentReceivableDetail BIT NOT NULL,
		DummyInvoiceNumber INT,
		BlendNumber BIGINT,
		ContractId BIGINT,
		CustomerId BIGINT,
		BlendWithReceivableTypeId BIGINT,
		BlendOriginalReceivableDetailId BIGINT,
		TaxType NVARCHAR(10) DEFAULT NULL,
		IsDownPaymentVATReceivable BIT DEFAULT 0
	)

	CREATE NONCLUSTERED INDEX IX_Contract ON #BillToInvoiceParameters_Extract(ContractId, DummyInvoiceNumber)

	INSERT INTO #BillToInvoiceParameters_Extract
	(
	     ExtractId,
		ReceivableId ,
		VirtualReceivableId ,
		ReceivableDetailId   ,
		JobStepInstanceId , 
		ReceivableDueDate ,
		BillToId ,
		AllowBlending   ,
		GroupNumber ,
		SplitNumber ,
		ReceivableTypeId , 
		ReceivableTypeName ,
		IsParentReceivableDetail   ,
		HasParentReceivableDetail  ,
		DummyInvoiceNumber ,
		BlendNumber ,
		ContractId ,
		CustomerId ,
		BlendWithReceivableTypeId ,
		BlendOriginalReceivableDetailId, 
		TaxType,
		IsDownPaymentVATReceivable
	)
	SELECT 
	     IRDE.Id,
		IRDE.ReceivableId,
		IRDE.ReceivableId VirtualReceivableId,
		IRDE.ReceivableDetailId,
		IRDE.JobStepInstanceId,
		IRDE.ReceivableDueDate,
		IRDE.BillToId,
		CASE WHEN BTIP.AllowBlending = @AllowBlendingValues_Yes THEN 1 ELSE 0 END AllowBlending,
		IRDE.GroupNumber,
		IRDE.SplitNumber,
		RC.ReceivableTypeId,
		RT.Name ReceivableTypeName,
		IGP.IsParent IsParentReceivableDetail,
		CAST(0 AS BIT) HasParentReceivableDetail,
		DENSE_RANK () OVER (ORDER BY IRDE.GroupNumber, IRDE.SplitNumber) DummyInvoiceNumber,
		CAST(0 AS BIGINT) BlendNumber,
		IRDE.ContractId,
		IRDE.CustomerId,
		BTIP.BlendWithReceivableTypeId,
		CAST(NULL AS BIGINT) BlendOriginalReceivableDetailId,
		IRDE.ReceivableTaxType,
		IRDE.IsDownPaymentVATReceivable
	FROM InvoiceReceivableDetails_Extract IRDE
	JOIN InvoiceChunkDetails_Extract ICD ON IRDE.BillToId = ICD.BillToId 
		AND IRDE.JobStepInstanceId = ICD.JobStepInstanceId
	JOIN BillToInvoiceParameters BTIP ON IRDE.BillToId = BTIP.BillToId
		AND BTIP.IsActive = 1
	JOIN ReceivableCodes RC ON IRDE.ReceivableCodeId = RC.Id
	JOIN InvoiceGroupingParameters IGP ON BTIP.InvoiceGroupingParameterId = IGP.Id 
		AND RC.ReceivableTypeId = IGP.ReceivableTypeId
		AND IRDE.ReceivableCategoryId = IGP.ReceivableCategoryId
		AND IGP.IsActive=1
	JOIN ReceivableTypes RT ON IGP.ReceivableTypeId = RT.Id
	WHERE IRDE.JobStepInstanceId = @JobStepInstanceId AND IRDE.IsActive=1 AND ICD.ChunkNumber=@ChunkNumber
	;

	--IDENTIFY PROPER HEADER FOR MORE THAN ONE HEADER RECORD
	-- Get the BlendWithReceivableType Record

	CREATE TABLE #BillToInvoiceParameters_BlendWithReceivableExtract(
		ReceivableDetailId BIGINT,
		ReceivableDueDate DATE,
		ContractId BIGINT,
		DummyInvoiceNumber INT,
		BlendWithReceivableTypeId BIGINT,
		OriginalReceivableDetailId BIGINT,
		OriginalReceivableDueDate DATE,
		HasMoreThanOneHeader BIT NOT NULL,
	)

	CREATE INDEX BillToInvoiceParameters_BlendWithReceivableExtract_ReceivableDetailId ON #BillToInvoiceParameters_BlendWithReceivableExtract(ReceivableDetailId);

	INSERT INTO #BillToInvoiceParameters_BlendWithReceivableExtract
	(
		ReceivableDetailId,  
		ReceivableDueDate ,
		ContractId ,
		DummyInvoiceNumber ,
		BlendWithReceivableTypeId ,
		OriginalReceivableDetailId ,
		OriginalReceivableDueDate ,
		HasMoreThanOneHeader
	)
	SELECT
		BIP.ReceivableDetailId,
		BIP.ReceivableDueDate,
		BIP.ContractId,
		BIP.DummyInvoiceNumber,
		BIP.BlendWithReceivableTypeId,
		BIPSELF.ReceivableDetailId OriginalReceivableDetailId,
		BIPSELF.ReceivableDueDate OriginalReceivableDueDate,
		CAST(0 AS BIT) HasMoreThanOneHeader
	FROM #BillToInvoiceParameters_Extract BIP
	INNER JOIN #BillToInvoiceParameters_Extract BIPSELF
	ON BIP.DummyInvoiceNumber = BIPSELF.DummyInvoiceNumber
		AND BIP.ContractId = BIPSELF.ContractId
		AND BIP.BlendWithReceivableTypeId = BIPSELF.ReceivableTypeId
		 AND (BIPSELF.IsDownPaymentVATReceivable = 0 OR @IsDownPaymentBlendingApplicable = 1)
	WHERE BIP.BlendWithReceivableTypeId IS NOT NULL
	AND BIP.ContractId IS NOT NULL AND (BIP.IsDownPaymentVATReceivable = 0 OR @IsDownPaymentBlendingApplicable = 1)
	;

	--Find the invoice with more than one header

	UPDATE BIP
		SET HasMoreThanOneHeader = 1
	FROM #BillToInvoiceParameters_BlendWithReceivableExtract BIP
	JOIN (
		SELECT 
			BIP.ReceivableDetailId,
			BIP.ReceivableDueDate
		FROM #BillToInvoiceParameters_BlendWithReceivableExtract BIP
		GROUP BY
			BIP.ReceivableDetailId,
			BIP.ReceivableDueDate
		HAVING COUNT(*) > 1
	) AS MOH
	ON BIP.ReceivableDetailId = MOH.ReceivableDetailId AND
		BIP.ReceivableDueDate = MOH.ReceivableDueDate
	;

	--get the past nearest record to get the blend number

	SELECT
		BWR.ReceivableDetailId,
		BWR.OriginalReceivableDueDate, 
		MAX(BWR.OriginalReceivableDetailId) OriginalReceivableDetailId
	INTO #BillToInvoiceParameters_BlendWithReceivableMoreThanOneHeader_MatchingReceivableExtract 
	FROM #BillToInvoiceParameters_BlendWithReceivableExtract BWR
	JOIN ( 
		SELECT
			ReceivableDetailId,
			MAX(OriginalReceivableDueDate) OriginalReceivableDueDate
		FROM #BillToInvoiceParameters_BlendWithReceivableExtract
		WHERE HasMoreThanOneHeader = 1
			AND ReceivableDueDate >= OriginalReceivableDueDate
		GROUP BY
			ReceivableDetailId
	) AS PMR	
	ON BWR.ReceivableDetailId = PMR.ReceivableDetailId
		AND BWR.OriginalReceivableDueDate = PMR.OriginalReceivableDueDate
		AND BWR.HasMoreThanOneHeader = 1
	GROUP BY
		BWR.ReceivableDetailId,
		BWR.OriginalReceivableDueDate
	;

	--get the future nearest record to get the blend number (if past record is not avaliable)

	INSERT INTO #BillToInvoiceParameters_BlendWithReceivableMoreThanOneHeader_MatchingReceivableExtract
	SELECT
		BWR.ReceivableDetailId,
		BWR.OriginalReceivableDueDate, 
		MIN(BWR.OriginalReceivableDetailId) OriginalReceivableDetailId
	FROM #BillToInvoiceParameters_BlendWithReceivableExtract BWR
	JOIN (
		SELECT
			 BWR.ReceivableDetailId,
			 MIN(BWR.OriginalReceivableDueDate) OriginalReceivableDueDate
		FROM #BillToInvoiceParameters_BlendWithReceivableExtract BWR
		LEFT JOIN #BillToInvoiceParameters_BlendWithReceivableMoreThanOneHeader_MatchingReceivableExtract BWRPMR
		ON BWR.ReceivableDetailId = BWRPMR.ReceivableDetailId
		WHERE BWRPMR.ReceivableDetailId IS NULL
			AND BWR.ReceivableDueDate <= BWR.OriginalReceivableDueDate
		GROUP BY
			BWR.ReceivableDetailId
	) AS PMR
	ON BWR.ReceivableDetailId = PMR.ReceivableDetailId
		AND BWR.OriginalReceivableDueDate = PMR.OriginalReceivableDueDate
		AND BWR.HasMoreThanOneHeader = 1
	GROUP BY
		BWR.ReceivableDetailId,
		BWR.OriginalReceivableDueDate
	;

	UPDATE BIP
		SET OriginalReceivableDetailId = BIPMR.OriginalReceivableDetailId
	FROM #BillToInvoiceParameters_BlendWithReceivableExtract BIP
	JOIN #BillToInvoiceParameters_BlendWithReceivableMoreThanOneHeader_MatchingReceivableExtract BIPMR
	ON BIP.ReceivableDetailId = BIPMR.ReceivableDetailId AND BIP.HasMoreThanOneHeader = 1

	-- update the table with proper receivable id for updating.

	UPDATE BIP
		SET BIP.BlendOriginalReceivableDetailId = BIPSELF.OriginalReceivableDetailId
	FROM #BillToInvoiceParameters_Extract BIP
	INNER JOIN #BillToInvoiceParameters_BlendWithReceivableExtract BIPSELF
	ON BIP.ReceivableDetailId = BIPSELF.ReceivableDetailId
	;

	-- tell the group which has parent receivable.

	UPDATE #BillToInvoiceParameters_Extract
		SET HasParentReceivableDetail = 1
	FROM #BillToInvoiceParameters_Extract BTI
	JOIN (SELECT 
				DummyInvoiceNumber, ContractId
		  FROM #BillToInvoiceParameters_Extract
		  WHERE IsParentReceivableDetail = 1  AND (IsDownPaymentVATReceivable = 0 OR @IsDownPaymentBlendingApplicable = 1)
		  ) AS Invoice 
	 ON BTI.ContractId = Invoice.ContractId
	 AND BTI.DummyInvoiceNumber = Invoice.DummyInvoiceNumber
	 ;

	 -- Get invoice with parent receivable and in that invoice allowblending needs to be allowed for atleast one receivable.

	 CREATE TABLE #InvoiceWithAllowBlendingReceivable(
		DummyInvoiceNumber INT,
		ContractId BIGINT
	 )

	 CREATE NONCLUSTERED INDEX IX_DummyContract ON #InvoiceWithAllowBlendingReceivable(DummyInvoiceNumber, ContractId)

	 INSERT INTO #InvoiceWithAllowBlendingReceivable(DummyInvoiceNumber, ContractId)
	 SELECT 
		DummyInvoiceNumber, ContractId 
	 FROM #BillToInvoiceParameters_Extract
	 WHERE HasParentReceivableDetail = 1 AND AllowBlending = 1
	 AND IsParentReceivableDetail = 0  AND (IsDownPaymentVATReceivable = 0 OR @IsDownPaymentBlendingApplicable = 1)
	 GROUP BY DummyInvoiceNumber, ContractId 

	 --Identifying Virutal Id for same Duedate receivable

	UPDATE #BillToInvoiceParameters_Extract
		SET VirtualReceivableId = MinReceivable.VirtualReceivableId
	FROM #BillToInvoiceParameters_Extract BTE
	JOIN (
		SELECT 
			BTI.ContractId, ReceivableDueDate, ReceivableTypeId, MIN(ReceivableId) VirtualReceivableId 
		FROM #BillToInvoiceParameters_Extract BTI
		JOIN #InvoiceWithAllowBlendingReceivable IWAB ON BTI.ContractId = IWAB.ContractId 
			AND BTI.DummyInvoiceNumber = IWAB.DummyInvoiceNumber
		WHERE IsParentReceivableDetail = 1  AND (IsDownPaymentVATReceivable = 0 OR @IsDownPaymentBlendingApplicable = 1)
		GROUP BY BTI.ContractId, ReceivableDueDate, ReceivableTypeId
		HAVING COUNT(*) > 1
	 ) AS MinReceivable
	 ON BTE.ContractId = MinReceivable.ContractId AND BTE.ReceivableDueDate = MinReceivable.ReceivableDueDate
	 AND BTE.ReceivableTypeId = MinReceivable.ReceivableTypeId 
	 AND (BTE.IsDownPaymentVATReceivable = 0 OR 0 = 1)
	 ;

	 --Identifying blend number for parent group with allowblending false and for group without parent and customer receivable

	 UPDATE #BillToInvoiceParameters_Extract
		SET BlendNumber = BN.BlendNumber
	 FROM #BillToInvoiceParameters_Extract
	 JOIN (
		SELECT
			ReceivableId,
			ReceivableDetailId,
			DENSE_RANK () OVER (PARTITION BY GroupNumber, SplitNumber ORDER BY ReceivableDueDate, VirtualReceivableId) AS BlendNumber
		FROM #BillToInvoiceParameters_Extract
		 WHERE ((HasParentReceivableDetail = 1 AND AllowBlending = 0) 
			OR HasParentReceivableDetail = 0 OR ContractId IS NULL
			OR (BlendWithReceivableTypeId IS NOT NULL AND BlendOriginalReceivableDetailId IS NULL))
	 ) AS BN
	 ON #BillToInvoiceParameters_Extract.ReceivableDetailId = BN.ReceivableDetailId
	 ;

	 --Update blend number for group with parent and allowblending true

	 UPDATE #BillToInvoiceParameters_Extract
		SET BlendNumber = MinBlend.BlendNumber
	 FROM #BillToInvoiceParameters_Extract BTI 
	 JOIN (
		 SELECT
			DISTINCT DummyInvoiceNumber, MIN(BlendNumber) BlendNumber, ContractId
		 FROM #BillToInvoiceParameters_Extract
		 WHERE IsParentReceivableDetail = 1 AND (IsDownPaymentVATReceivable = 0 OR @IsDownPaymentBlendingApplicable = 1)
		 GROUP BY DummyInvoiceNumber, IsParentReceivableDetail , ContractId
		 HAVING COUNT(*) = 1) AS MinBlend
	ON BTI.DummyInvoiceNumber = MinBlend.DummyInvoiceNumber
	AND BTI.AllowBlending = 1 AND BTI.ContractId = MinBlend.ContractId
	AND BTI.BlendWithReceivableTypeId IS NULL
	;

	--Getting group with more than one parent

	 SELECT 
		BE.DummyInvoiceNumber, BlendNumber, ReceivableDueDate, BE.ContractId 
	 INTO #BillToInvoiceParametersMoreThanOneParent_Extract
	 FROM #BillToInvoiceParameters_Extract BE
	 JOIN (
		SELECT DummyInvoiceNumber, ContractId  
		FROM #BillToInvoiceParameters_Extract
		WHERE IsParentReceivableDetail = 1 AND (IsDownPaymentVATReceivable = 0 OR @IsDownPaymentBlendingApplicable = 1)
		GROUP BY DummyInvoiceNumber, ContractId HAVING COUNT(*) > 1
	 ) AS TEMP
	 ON BE.ContractId = TEMP.ContractId AND BE.DummyInvoiceNumber = TEMP.DummyInvoiceNumber
	 AND BE.AllowBlending = 0 AND BE.IsParentReceivableDetail = 1 AND (BE.IsDownPaymentVATReceivable = 0 OR @IsDownPaymentBlendingApplicable = 1)
	 AND BE.BlendWithReceivableTypeId IS NULL
	 ;

	 --Identifying Records WithoutBlend Number

	 CREATE TABLE #InvoiceWithoutBlendNumber(
		ReceivableDetailId BIGINT PRIMARY KEY, 
		DummyInvoiceNumber INT, 
		BlendNumber INT, 
		ReceivableDueDate DATE, 
		ContractId BIGINT
	 )

	 INSERT INTO #InvoiceWithoutBlendNumber(ReceivableDetailId, DummyInvoiceNumber, BlendNumber, ReceivableDueDate, ContractId)
	 SELECT
		ReceivableDetailId, DummyInvoiceNumber, BlendNumber, ReceivableDueDate, ContractId
	 FROM #BillToInvoiceParameters_Extract
	 WHERE HasParentReceivableDetail = 1 AND BlendNumber = 0
	 AND BlendWithReceivableTypeId IS NULL
	 ;
	 
	 --updating blend number for group more than one parent (checking with past)

	 CREATE TABLE #BillToInvoiceParametersMoreThanOneParent_NearestDate(
		ReceivableDetailId BIGINT PRIMARY KEY,
		BlendNumber INT,
		ReceivableDueDate DATE
	 )

	 INSERT INTO #BillToInvoiceParametersMoreThanOneParent_NearestDate(ReceivableDetailId, BlendNumber, ReceivableDueDate)
	 SELECT
		IWB.ReceivableDetailId,
		MAX(BTIP.BlendNumber) BlendNumber, 
		IWB.ReceivableDueDate
	 FROM #InvoiceWithoutBlendNumber IWB
	 JOIN #BillToInvoiceParametersMoreThanOneParent_Extract BTIP
	 ON IWB.ContractId = BTIP.ContractId AND IWB.DummyInvoiceNumber = BTIP.DummyInvoiceNumber
	 WHERE BTIP.ReceivableDueDate <= IWB.ReceivableDueDate
	 GROUP BY
		IWB.ReceivableDetailId,
		IWB.ReceivableDueDate
	 ;

	 UPDATE #BillToInvoiceParameters_Extract
		SET BlendNumber = BTIPND.BlendNumber
	 FROM #BillToInvoiceParameters_Extract BTIP
	 JOIN #BillToInvoiceParametersMoreThanOneParent_NearestDate BTIPND
	 ON BTIPND.ReceivableDetailId = BTIP.ReceivableDetailId
	 ;

	 --updating blend number for group more than one parent (checking with future)

	 UPDATE #BillToInvoiceParameters_Extract
		SET BlendNumber = BTIPND.BlendNumber
	 FROM #BillToInvoiceParameters_Extract BTIP
	 JOIN (
		 SELECT
			IWB.ReceivableDetailId,
			IWB.ReceivableDueDate,
			MIN(BTIP.BlendNumber) BlendNumber
		 FROM #InvoiceWithoutBlendNumber IWB
		 INNER JOIN #BillToInvoiceParametersMoreThanOneParent_Extract BTIP 
			ON BTIP.DummyInvoiceNumber = BTIP.DummyInvoiceNumber AND IWB.ContractId = BTIP.ContractId	
		 LEFT JOIN #BillToInvoiceParametersMoreThanOneParent_NearestDate BTIPND
			ON IWB.ReceivableDetailId = BTIPND.ReceivableDetailId
		 WHERE BTIP.ReceivableDueDate > IWB.ReceivableDueDate
			AND BTIPND.ReceivableDetailId IS NULL
		 GROUP BY
			IWB.ReceivableDetailId,
			IWB.ReceivableDueDate
	 ) BTIPND
	 ON BTIP.ReceivableDetailId = BTIPND.ReceivableDetailId
	 ;

	UPDATE BTI
		SET BlendNumber = BTISELF.BlendNumber 
	FROM #BillToInvoiceParameters_Extract BTI
	JOIN #BillToInvoiceParameters_Extract BTISELF
	ON BTI.BlendOriginalReceivableDetailId = BTISELF.ReceivableDetailId
	WHERE BTI.BlendOriginalReceivableDetailId IS NOT NULL
	;

	CREATE TABLE #ExtractUpdates(
	   ExtractId BIGINT PRIMARY KEY,
	   BlendNumber BIGINT
	)

	INSERT INTO #ExtractUpdates(ExtractId, BlendNumber)
	SELECT ExtractId, BlendNumber FROM #BillToInvoiceParameters_Extract

	UPDATE InvoiceReceivableDetails_Extract
		SET BlendNumber = BTI.BlendNumber
	FROM InvoiceReceivableDetails_Extract IRD
	JOIN #ExtractUpdates BTI ON IRD.Id = BTI.ExtractId

	DROP TABLE #BillToInvoiceParameters_Extract
	DROP TABLE #InvoiceWithAllowBlendingReceivable
	DROP TABLE #BillToInvoiceParametersMoreThanOneParent_Extract
	DROP TABLE #InvoiceWithoutBlendNumber
	DROP TABLE #BillToInvoiceParametersMoreThanOneParent_NearestDate
	DROP TABLE #ExtractUpdates
END

GO
