SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLegalEntityNamesForValidReceivables]
(
@GLNFCode NVARCHAR(100),
@JobStepInstanceId BIGINT
)
AS
BEGIN
DECLARE @LegalEntityName NVARCHAR(MAX);
SELECT @LegalEntityName =  COALESCE(@LegalEntityName + ', ' ,'') +  CAST(L.LegalEntityName AS NVARCHAR(MAX))
FROM(SELECT DISTINCT LegalEntityName FROM SalesTaxReceivableDetailExtract RD
WHERE RD.JobStepInstanceId = @JobStepInstanceId AND RD.InvalidErrorCode = @GLNFCode) L;
IF @LegalEntityName IS NOT NULL
BEGIN
SELECT @LegalEntityName AS 'Name'
END
END

GO
