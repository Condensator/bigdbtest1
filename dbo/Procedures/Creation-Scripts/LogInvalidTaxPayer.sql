SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LogInvalidTaxPayer]
(
@ErrorMessage NVARCHAR(2000),
@CreatedById BIGINT,
@JobStepInstanceId BIGINT,
@ErrorMessageType nvarchar(22)
)
AS
BEGIN
DECLARE @LegalEntityName NVARCHAR(MAX);
SELECT @LegalEntityName =  COALESCE(@LegalEntityName + ', ' ,'') +  CAST(L.LegalEntityName AS NVARCHAR(MAX))
FROM (SELECT DISTINCT LegalEntityName
FROM CustomerLocationTaxBasisProcessingDetail_Extract WHERE Company IS NULL AND JobStepInstanceId = @JobStepInstanceId
UNION
SELECT DISTINCT LegalEntityName
FROM AssetLocationTaxBasisProcessingDetail_Extract WHERE Company IS NULL AND JobStepInstanceId = @JobStepInstanceId) AS L
IF(@LegalEntityName IS NOT NULL)
BEGIN
INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
VALUES
(REPLACE(@ErrorMessage,'@LegalEntityName', @LegalEntityName)
,@ErrorMessageType
,@CreatedById
,SYSDATETIMEOFFSET()
,@JobStepInstanceId)
END;
END

GO
