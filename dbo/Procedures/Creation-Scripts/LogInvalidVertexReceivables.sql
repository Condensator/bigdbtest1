SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[LogInvalidVertexReceivables]
(
@ExtractedSalesTaxReceivableDetail ExtractedSalesTaxReceivableDetail READONLY,
@ExtractedVertexWSTransaction ExtractedVertexWSTransaction READONLY,
@InvalidLocationErrorMessage NVARCHAR(2000),
@InvalidTaxBasisErrorMessage NVARCHAR(2000),
@InvalidTaxPayerErrorMessage NVARCHAR(2000),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT,
@UALCode NVARCHAR(100),
@TPNFCode NVARCHAR(100)
)
AS
BEGIN

INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
SELECT
REPLACE(REPLACE(@InvalidLocationErrorMessage, '@recId', ReceivableId), '@AssetIds',
CAST(ReceivableDetailId AS NVARCHAR) +' : ' + CAST(ReceivableDueDate AS NVARCHAR)
+ ' : '
+  CASE WHEN SequenceNumber IS NULL THEN ''ELSE SequenceNumber END
+ ISNULL(( ' : ' +  CAST(AssetId AS NVARCHAR)), '')) As Message
,'Error'
,@CreatedById
,@CreatedTime
,@JobStepInstanceId
FROM @ExtractedSalesTaxReceivableDetail STR
LEFT JOIN Contracts C on C.Id = STR.ContractId
WHERE InvalidErrorCode = @UALCode

INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
SELECT
REPLACE(REPLACE(@InvalidTaxBasisErrorMessage, '@recId', ReceivableId), '@AssetIds',
CAST(ReceivableDetailId AS NVARCHAR) +' : ' + CAST(DueDate AS NVARCHAR)
+ ' : '
+ CASE WHEN LeaseUniqueID IS NULL THEN '' ELSE LeaseUniqueID END
+ ' : '
+  CAST(AssetId AS NVARCHAR))
,'Error'
,@CreatedById
,@CreatedTime
,@JobStepInstanceId
FROM @ExtractedVertexWSTransaction

DECLARE @TaxPayerNotFoundLegalEntity NVARCHAR(MAX);
SELECT  @TaxPayerNotFoundLegalEntity =  COALESCE(@TaxPayerNotFoundLegalEntity + ', ' ,'') +  CAST(L.LegalEntityName AS NVARCHAR(MAX))
FROM (SELECT DISTINCT LegalEntityName FROM @ExtractedSalesTaxReceivableDetail
WHERE InvalidErrorCode = @TPNFCode) L;

IF @TaxPayerNotFoundLegalEntity IS NOT NULL
BEGIN
INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
VALUES
(REPLACE(@InvalidTaxPayerErrorMessage,'@LegalEntityName',@TaxPayerNotFoundLegalEntity)
,'Error'
,@CreatedById
,@CreatedTime
,@JobStepInstanceId)
END;
END

GO
