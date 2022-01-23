SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LogInvalidSalesTaxReversalReceivables]
(
@CashPostedOrInvoicedErrorMessage			NVARCHAR(MAX),
@LEWithoutGLPeriodErrorMessage				NVARCHAR(MAX),
@GLOpenPeriodErrorMessage					NVARCHAR(MAX),
@InvoicedOrCashPosted						NVARCHAR(40),
@LEWithoutGLPeriod							NVARCHAR(40),
@LEWithInvalidGLPeriod						NVARCHAR(40),
@CreatedById								BIGINT,
@JobStepInstanceId							BIGINT,
@ErrorMessageType							NVARCHAR(10),
@ReceivableWithApprovedTPErrorMessage		NVARCHAR(MAX),
@ReceivableWithApprovedTP					NVARCHAR(40),
@DownPaymentHirePurchaseContractErrorCode	NVARCHAR(100),
@IsTaxIncludedForDownPaymentNonHirePurchaseContractErrorCode	NVARCHAR(500),
@DownPaymentHirePurchaseContractErrorMessage					NVARCHAR(500),
@IsTaxIncludedForDownPaymentNonHirePurchaseContractErrorMessage	NVARCHAR(500)
)
AS
BEGIN

DECLARE @ReceivableId NVARCHAR(MAX);
WITH CTE_DistinctReceivableIds AS
(
	SELECT DISTINCT ReceivableId
	FROM ReversalReceivableDetail_Extract
	WHERE JobStepInstanceId = @JobStepInstanceId AND ErrorCode = @InvoicedOrCashPosted
)

SELECT @ReceivableId = stuff((
        SELECT ','+convert(VARCHAR(20),ReceivableId)
        FROM CTE_DistinctReceivableIds
        FOR XML PATH (''), TYPE).value('.','nvarchar(max)')
      ,1,1,'')

IF(@ReceivableId IS NOT NULL)
	INSERT INTO JobStepInstanceLogs
		(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
	VALUES(
		REPLACE(@CashPostedOrInvoicedErrorMessage,'@ReceivableIds', @ReceivableId)
		,@ErrorMessageType
		,@CreatedById
		,SYSDATETIMEOFFSET()
		,@JobStepInstanceId)

DECLARE @LegalEntityNames NVARCHAR(MAX);
WITH CTE_DistinctLegalEntityNames AS
(
	SELECT DISTINCT LegalEntityName
	FROM ReversalReceivableDetail_Extract
	WHERE JobStepInstanceId = @JobStepInstanceId AND ErrorCode = @LEWithoutGLPeriod
)

SELECT @LegalEntityNames = stuff((
        SELECT ','+convert(VARCHAR(20),LegalEntityName)
        FROM CTE_DistinctLegalEntityNames
        FOR XML PATH (''), TYPE).value('.','nvarchar(max)')
      ,1,1,'')

IF(@LegalEntityNames IS NOT NULL)
	INSERT INTO JobStepInstanceLogs
		(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
	VALUES(
		REPLACE(@LEWithoutGLPeriodErrorMessage,'@LegalEntityNames', @LegalEntityNames)
		,@ErrorMessageType
		,@CreatedById
		,SYSDATETIMEOFFSET()
		,@JobStepInstanceId);

DECLARE @VoucherNumbers NVARCHAR(MAX);
WITH CTE_ReceivableWithApprovedTP AS
(
	SELECT DISTINCT VoucherNumbers
	FROM ReversalReceivableDetail_Extract
	WHERE JobStepInstanceId = @JobStepInstanceId AND ErrorCode = @ReceivableWithApprovedTP
)

SELECT @VoucherNumbers = stuff((
        SELECT ','+convert(VARCHAR(20),VoucherNumbers)
        FROM CTE_ReceivableWithApprovedTP
        FOR XML PATH (''), TYPE).value('.','nvarchar(max)')
      ,1,1,'')

IF(@VoucherNumbers IS NOT NULL)
	INSERT INTO JobStepInstanceLogs
		(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
	VALUES(
		REPLACE(@ReceivableWithApprovedTPErrorMessage,'@VoucherNumbers', @VoucherNumbers)
		,@ErrorMessageType
		,@CreatedById
		,SYSDATETIMEOFFSET()
		,@JobStepInstanceId);

SELECT DISTINCT LegalEntityName, GLFinancialOpenPeriodFromDate, GLFinancialOpenPeriodToDate
INTO #DistinctLegalEntities
FROM ReversalReceivableDetail_Extract
WHERE JobStepInstanceId = @JobStepInstanceId AND ErrorCode = @LEWithInvalidGLPeriod 

IF EXISTS(SELECT 1 FROM #DistinctLegalEntities)
BEGIN
	INSERT INTO JobStepInstanceLogs
		(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
	SELECT
		REPLACE
		(REPLACE
		(REPLACE(@GLOpenPeriodErrorMessage,'@FromDate', GLFinancialOpenPeriodFromDate),
		'@ToDate',GLFinancialOpenPeriodToDate),
		'@LegalEntityName',LegalEntityName)
		,@ErrorMessageType
		,@CreatedById
		,SYSDATETIMEOFFSET()
		,@JobStepInstanceId
	FROM #DistinctLegalEntities
END




DECLARE @DownPaymentReceivables NVARCHAR(MAX);
WITH CTE_DistinctReceivableIds AS
(
SELECT 
	DISTINCT ReceivableId
FROM ReversalReceivableDetail_Extract
WHERE ErrorCode = @DownPaymentHirePurchaseContractErrorCode AND JobStepInstanceId = @JobStepInstanceId
)
SELECT @DownPaymentReceivables =COALESCE(@DownPaymentReceivables+', ' ,'') +  CAST(ReceivableId AS NVARCHAR(MAX))
FROM CTE_DistinctReceivableIds;

IF(@DownPaymentReceivables IS NOT NULL)
BEGIN
	INSERT INTO JobStepInstanceLogs
	(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
	VALUES(
	REPLACE(@DownPaymentHirePurchaseContractErrorMessage,'@ReceivableIds', @DownPaymentReceivables)
	,@ErrorMessageType
	,@CreatedById
	,SYSDATETIMEOFFSET()
	,@JobStepInstanceId)
END

DECLARE @NonHirePurchaseDownPaymentReceivables NVARCHAR(MAX);
WITH CTE_DistinctReceivableIds AS
(
SELECT 
	DISTINCT ReceivableId
FROM ReversalReceivableDetail_Extract
WHERE ErrorCode = @IsTaxIncludedForDownPaymentNonHirePurchaseContractErrorCode 
	AND JobStepInstanceId = @JobStepInstanceId
)
SELECT @NonHirePurchaseDownPaymentReceivables = COALESCE(@NonHirePurchaseDownPaymentReceivables+', ' ,'') +  CAST(ReceivableId AS NVARCHAR(MAX))
FROM CTE_DistinctReceivableIds;

IF(@NonHirePurchaseDownPaymentReceivables IS NOT NULL)
BEGIN
	INSERT INTO JobStepInstanceLogs
	(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
	VALUES(
	REPLACE(@IsTaxIncludedForDownPaymentNonHirePurchaseContractErrorMessage,'@ReceivableIds', @NonHirePurchaseDownPaymentReceivables)
	,@ErrorMessageType
	,@CreatedById
	,SYSDATETIMEOFFSET()
	,@JobStepInstanceId)
END


END

GO
