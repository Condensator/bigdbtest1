SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InvoiceGenerationGrouping] 
(
	@JobStepInstanceId BIGINT,
	@ChunkNumber INT,
	@OriginationChannel_Direct NVARCHAR(100),
	@InvoiceReceivableGroupingOption_Separate NVARCHAR(100),
	@InvoiceReceivableGroupingOption_Category NVARCHAR(100),
	@InvoiceReceivableGroupingOption_Other NVARCHAR(100)
)
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #GroupingLogic(
		Id BIGINT PRIMARY KEY,
		GroupNumber INT,
		InvoiceOutputFormat NVARCHAR(5),
		InvoiceFormatId BIGINT,
		IsGroupingOptionOther BIT,
		IsActive BIT NOT NULL
	)

	CREATE NONCLUSTERED INDEX IX_GroupNumber ON #GroupingLogic(GroupNumber)

	INSERT INTO #GroupingLogic(Id, InvoiceOutputFormat, InvoiceFormatId, IsGroupingOptionOther, GroupNumber, IsActive)
	SELECT IRD.Id, InvoiceOutputFormat, InvoiceFormatId, 
		CASE 
			WHEN DefaultInvoiceReceivableGroupingOption=@InvoiceReceivableGroupingOption_Other THEN 1 
			ELSE 0 
		END,  
		DENSE_RANK() OVER (
				ORDER BY CustomerId,
					IRD.InvoiceDueDate,
					IRD.RemitToId,
					IRD.BillToId,
					CASE 
						WHEN IRD.DefaultInvoiceReceivableGroupingOption = @InvoiceReceivableGroupingOption_Category THEN IRD.ReceivableCategoryName
						WHEN IRD.DefaultInvoiceReceivableGroupingOption = @InvoiceReceivableGroupingOption_Separate THEN CAST(IRD.ReceivableId AS NVARCHAR(10)) 
						ELSE IRD.DefaultInvoiceReceivableGroupingOption END,
					IRD.CurrencyId,
					IRD.AlternateBillingCurrencyId,
					IRD.LegalEntityId,
					IRD.IsDSL,
					IRD.IsACH,
					IRD.IsPrivateLabel,
					ISNULL(IOS.OriginationSource, @OriginationChannel_Direct),
					ISNULL(IOS.OriginationSourceId, IRD.LegalEntityId),
					IRD.InvoicePreference,
					CASE WHEN IRD.ReceivableTaxType = 'VAT' AND IRD.TaxAmount = 0 THEN 0 ELSE 1 END,
					ISNULL(IRD.DealCountryId, 0)
				) AS GroupNumber,
				1
	FROM InvoiceReceivableDetails_Extract IRD
	INNER JOIN InvoiceChunkDetails_Extract ICD ON ICD.JobStepInstanceId = @JobStepInstanceId
		AND IRD.BillToId = ICD.BillToId 
	LEFT JOIN InvoiceOriginationSource_Extract IOS ON IOS.JobStepInstanceId = @JobStepInstanceId
		AND IRD.ContractId = IOS.ContractId 
	WHERE IRD.JobStepInstanceId = @JobStepInstanceId AND IRD.IsActive=1
		AND ICD.ChunkNumber = @ChunkNumber

	;WITH GroupCount AS 
	(
		SELECT GroupNumber
		FROM #GroupingLogic WHERE IsGroupingOptionOther=1
		GROUP BY GroupNumber, InvoiceFormatId, InvoiceOutputFormat
	)
	, GroupWithDuplicateInvoiceFormat AS 
	(
		SELECT GroupNumber
		FROM GroupCount 
		GROUP BY GroupNumber
		HAVING COUNT(1) > 1
	)
	UPDATE #GroupingLogic
	SET IsActive=0
	FROM #GroupingLogic INNER JOIN GroupWithDuplicateInvoiceFormat ON #GroupingLogic.GroupNumber=GroupWithDuplicateInvoiceFormat.GroupNumber

	UPDATE IRD 
	SET IsActive = G.IsActive, GroupNumber=G.GroupNumber
	FROM InvoiceReceivableDetails_Extract IRD 
	INNER JOIN #GroupingLogic G ON IRD.Id = G.Id
END

GO
