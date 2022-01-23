SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetReceivableTaxAmountSummary]
(
	@IsSummary BIT = NULL,
	@IsForChildCalculation BIT = NULL
)
AS
BEGIN
--DECLARE @IsSummary BIT = 0
DECLARE @toolidentifier INT = NULL
SET @toolidentifier =
(
    SELECT StgModule.Toolidentifier
    FROM StgModule
         INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId
    WHERE StgModuleIterationStatus.Id = (SELECT IsNull(MAX(ModuleIterationStatusId),0) from stgProcessingLog)
);
	
	DROP TABLE IF EXISTS #SalesTaxReceivableTaxSubset
	CREATE TABLE [dbo].#SalesTaxReceivableTaxSubset(
		[Id] [bigint] NOT NULL,
		[SequenceNumber] [nvarchar](40) NULL,
		[CustomerPartyNumber] [nvarchar](40) NULL,
		[EntityType] [nvarchar](2) NOT NULL,
		[ReceivableType] [nvarchar](21) NOT NULL,
		[DueDate] [date] NOT NULL,
		[ReceivableUniqueIdentifier] [nvarchar](30) NULL,
		[GLTemplateName] [nvarchar](40) NULL,
		[TaxAmount_Amount] [decimal](16, 2) NOT NULL,
		[TaxAmount_Currency] [nvarchar](3) NOT NULL,
		[R_PartyId] [bigint] NULL,
		[R_ReceivableId] [bigint] NULL,
		[R_ReceivableTypeId] [bigint] NULL,
		[R_ContractId] [bigint] NULL,
		[R_GLTemplateId] [bigint] NULL
	)
	
	INSERT INTO #SalesTaxReceivableTaxSubset(Id,SequenceNumber,CustomerPartyNumber,EntityType,ReceivableType,DueDate,ReceivableUniqueIdentifier,GLTemplateName,TaxAmount_Amount,TaxAmount_Currency) 
	SELECT Id,SequenceNumber,CustomerPartyNumber,EntityType,ReceivableType,DueDate,ReceivableUniqueIdentifier,GLTemplateName,TaxAmount_Amount,TaxAmount_Currency
	FROM stgSalesTaxReceivableTax WITH(NOLOCK)
	WHERE IsMigrated = 1 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL)

		CREATE NONCLUSTERED INDEX IX_SalesTaxReceivableTaxId ON #SalesTaxReceivableTaxSubset(Id);

		UPDATE #SalesTaxReceivableTaxSubset SET R_ContractId = Contracts.Id
		FROM 
			#SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK) 
			INNER JOIN Contracts WITH (NOLOCK) ON salesTax.SequenceNumber = Contracts.SequenceNumber
		WHERE salesTax.EntityType = 'CT'

		UPDATE #SalesTaxReceivableTaxSubset SET R_PartyId = Parties.Id
		FROM 
			#SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK) 
			INNER JOIN Parties WITH (NOLOCK) ON salesTax.CustomerPartyNumber = Parties.PartyNumber
		WHERE salesTax.CustomerPartyNumber IS NOT NULL

		UPDATE #SalesTaxReceivableTaxSubset SET R_ReceivableTypeId = rt.Id
		FROM 
			#SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK) 
			INNER JOIN ReceivableTypes rt WITH (NOLOCK) ON salesTax.ReceivableType = rt.Name
		WHERE rt.IsActive = 1

		DROP TABLE IF EXISTS #MultipleReceivables
		SELECT Id
		INTO #MultipleReceivables
		FROM
		(
			SELECT salesTax.Id
			FROM #SalesTaxReceivableTaxSubset salesTax
				 INNER JOIN Receivables r ON salesTax.DueDate = r.DueDate
											 AND r.EntityId = CASE
																  WHEN salesTax.EntityType = 'CU'
																  THEN R_PartyId
																  ELSE R_ContractId
															  END
				 INNER JOIN ReceivableCodes ON ReceivableCodes.Id = r.ReceivableCodeId
				 INNER JOIN ReceivableTypes rt ON rt.Id = ReceivableCodes.ReceivableTypeId
			WHERE rt.IsRental = 0
				  AND (R_PartyId IS NOT NULL OR R_ContractID IS NOT NULL)
			GROUP BY salesTax.Id
			HAVING COUNT(*) > 1
		) AS temp;

		DROP TABLE IF EXISTS #EligibleReceivableDetails

		SELECT Id
		INTO #EligibleReceivableDetails FROM
		(SELECT r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN Receivables r ON r.EntityId = salesTax.R_ContractId 
										 AND r.EntityType = 'CT'
			 INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON r.Id = rd.ReceivableId
		WHERE r.IsActive = 1 
		UNION
		SELECT r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN Receivables r ON r.EntityId = salesTax.R_PartyId
										 AND r.EntityType = 'CU'
			 INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON r.Id = rd.ReceivableId
		WHERE r.IsActive = 1 ) as t

		UPDATE salesTax SET R_ReceivableId = r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
		INNER JOIN #MultipleReceivables on salesTax.Id = #MultipleReceivables.Id
		INNER JOIN Receivables r WITH(NOLOCK) on salesTax.ReceivableUniqueIdentifier = r.UniqueIdentifier
		INNER JOIN ReceivableCodes rc WITH(NOLOCK) on rc.Id = r.ReceivableCodeId AND salesTax.R_ReceivableTypeId = rc.ReceivableTypeId
				
		UPDATE salesTax SET R_ReceivableId = r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN Receivables r WITH(NOLOCK) ON r.EntityId = salesTax.R_ContractId
													  AND r.EntityType = 'CT'
			 INNER JOIN #EligibleReceivableDetails erd WITH(NOLOCK) ON r.Id = erd.Id
			 INNER JOIN ReceivableCodes rc WITH(NOLOCK) ON r.ReceivableCodeId = rc.Id
			 LEFT JOIN #MultipleReceivables multipleReceivables WITH(NOLOCK) ON salesTax.Id = multipleReceivables.Id
		WHERE salesTax.EntityType = 'CT'
			  AND salesTax.DueDate = r.DueDate
			  AND salesTax.R_ReceivableTypeId = rc.ReceivableTypeId
			  AND multipleReceivables.Id IS NULL

		UPDATE salesTax SET R_ReceivableId = r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
		INNER JOIN Receivables r WITH(NOLOCK) ON r.EntityId = R_PartyId
		INNER JOIN #EligibleReceivableDetails erd WITH(NOLOCK) ON r.Id = erd.Id
		INNER JOIN ReceivableCodes rc WITH(NOLOCK) ON r.ReceivableCodeId = rc.Id
		inner join ReceivableTypes rt on rt.Id =  rc.ReceivableTypeId
		LEFT JOIN #MultipleReceivables multipleReceivables WITH(NOLOCK) ON salesTax.Id = multipleReceivables.Id
		WHERE salesTax.EntityType = 'CU'
			  AND salesTax.DueDate = r.DueDate
			  AND salesTax.R_ReceivableTypeId = rc.ReceivableTypeId
			  AND rt.IsRental = 0
			  AND multipleReceivables.Id IS NULL

	IF(@IsForChildCalculation=1)
	BEGIN
		SELECT Id,SequenceNumber,CustomerPartyNumber,EntityType,DueDate,ReceivableUniqueIdentifier,GLTemplateName,R_ReceivableId 
		FROM #SalesTaxReceivableTaxSubset
	END
	ELSE
	BEGIN
		IF(@IsSummary=1)
		BEGIN
			DROP TABLE IF EXISTS #Report
			CREATE TABLE [dbo].#Report
			(
				Intermediate_TotalNumberofRecords BIGINT,
				Intermediate_TaxAmount decimal(16,2),
				[Status] nvarchar(20),
				Target_TotalNumberofRecords BIGINT,
				Target_TaxAmount decimal(16,2)
			)

			INSERT INTO #Report([Status],Target_TotalNumberofRecords,Intermediate_TotalNumberofRecords,Target_TaxAmount,Intermediate_TaxAmount) 
			select 'Success',COUNT(*), COUNT(*), SUM(rt.Amount_Amount), SUM(salesTax.TaxAmount_Amount) 
			FROM #SalesTaxReceivableTaxSubset salesTax
			LEFT JOIN ReceivableTaxes rt ON salesTax.R_ReceivableId = rt.ReceivableId

			INSERT INTO #Report([Status],Target_TotalNumberofRecords,Target_TaxAmount) 
			select 'Failed',COUNT(*), ISNULL(SUM(rt.Amount_Amount),0)
			FROM #SalesTaxReceivableTaxSubset salesTax
			LEFT JOIN ReceivableTaxes rt ON salesTax.R_ReceivableId = rt.ReceivableId
			LEFT JOIN GLTemplates GLT ON rt.GLTemplateId = GLT.Id
			WHERE (TaxAmount_Amount != Amount_Amount OR ISNULL(GLTemplateName,'') != ISNULL(GLT.Name,'')) AND rt.Id IS NOT NULL

			INSERT INTO #Report([Status],Target_TotalNumberofRecords,Target_TaxAmount) 
			select 'Unable to Reconcile',COUNT(*), ISNULL(SUM(rt.Amount_Amount),0)
			FROM #SalesTaxReceivableTaxSubset salesTax
			LEFT JOIN ReceivableTaxes rt ON salesTax.R_ReceivableId = rt.ReceivableId
			WHERE rt.Id IS NULL

			UPDATE #Report SET 
			Target_TotalNumberofRecords = Target_TotalNumberofRecords - (SELECT SUM(Target_TotalNumberofRecords) FROM #Report WHERE Status != 'Success')
			,Target_TaxAmount = Target_TaxAmount - (SELECT SUM(Target_TaxAmount) FROM #Report WHERE Status != 'Success')
			WHERE Status = 'Success'

			SELECT * FROM #Report
		END
		ELSE IF(@IsSummary=0)
		BEGIN
			SELECT top 1048570 
			CASE
				WHEN rt.Id IS NULL THEN 'Unable to Reconcile' ELSE 'Failed'
			END AS Status,
			salesTax.Id IntermediateId,rt.Id TargetId,salesTax.EntityType,CustomerPartyNumber CustomerName,SequenceNumber
			,CAST(salesTax.DueDate as nvarchar(20)) DueDate, ReceivableUniqueIdentifier,Amount_Amount Target_TaxAmount,TaxAmount_Amount Intermediate_TaxAmount
			,ISNULL(Amount_Amount,0) - TaxAmount_Amount TaxAmount_Difference
			,rt.IsActive,rt.IsGLPosted, rt.IsDummy,GLT.Name Target_GLTemplateName,GLTemplateName Intermediate_GLTemplateName
			FROM #SalesTaxReceivableTaxSubset salesTax
			LEFT JOIN ReceivableTaxes rt ON salesTax.R_ReceivableId = rt.ReceivableId
			LEFT JOIN GLTemplates GLT ON rt.GLTemplateId = GLT.Id
			WHERE TaxAmount_Amount != Amount_Amount OR ISNULL(GLTemplateName,'') != ISNULL(GLT.Name,'') OR rt.Id IS NULL
		END
	END


END

GO
