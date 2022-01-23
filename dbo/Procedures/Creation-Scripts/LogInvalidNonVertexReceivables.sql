SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LogInvalidNonVertexReceivables]
(
	@InvalidLocationErrorMessage NVARCHAR(2000),
	@TaxRateNotFoundErrorMessage NVARCHAR(2000),
	@CreatedById BIGINT,
	@JobStepInstanceId BIGINT,
	@UALCode NVARCHAR(100),
	@ErrorMessageType nvarchar(22),
	@LocationCode NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
SELECT
REPLACE(REPLACE(@InvalidLocationErrorMessage, '@recId', ReceivableId), '@AssetIds',
CAST(ReceivableDetailId AS NVARCHAR) +' : ' + CAST(ReceivableDueDate AS NVARCHAR)
+ ' : '
+  CASE WHEN SequenceNumber IS NULL THEN ''ELSE SequenceNumber END
+ ' : '
+  CAST(AssetId AS NVARCHAR)) AS Message
,'Error' AS MessageType
,@CreatedById AS CreatedById
,SYSDATETIMEOFFSET() AS CreatedTime
,@JobStepInstanceId AS JobStepInstanceId
FROM SalesTaxReceivableDetailExtract STR
LEFT JOIN Contracts C ON STR.ContractId = C.Id
WHERE InvalidErrorCode = @UALCode AND STR.IsVertexSupported = 0
AND STR.JobStepInstanceId =@JobStepInstanceId;

SELECT  @LocationCode =  COALESCE(@LocationCode + ', ' ,'') +  CAST(L.LocationCode AS NVARCHAR(MAX))
FROM (SELECT DISTINCT L.LocationCode FROM NonVertexReceivableDetailExtract RD
INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId =L.LocationId AND RD.JobStepInstanceId = L.JobStepInstanceId
LEFT JOIN NonVertexTaxRateDetailExtract TaxRates ON  RD.ReceivableDetailId = TaxRates.ReceivableDetailId  AND RD.JobStepInstanceId = TaxRates.JobStepInstanceId
WHERE  L.IsVertexSupportedLocation = 0 AND TaxRates.ReceivableDetailId IS NULL  AND RD.JobStepInstanceId = @JobStepInstanceId) L;
END

GO
