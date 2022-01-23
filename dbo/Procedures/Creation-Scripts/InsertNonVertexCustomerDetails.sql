SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexCustomerDetails]
(
@JobStepInstanceId BIGINT
)
AS
BEGIN
WITH CTE_DistinctCustomerIds AS
(
SELECT DISTINCT	CustomerId
FROM SalesTaxReceivableDetailExtract WHERE IsVertexSupported =0 AND InvalidErrorCode IS NULL  AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO NonVertexCustomerDetailExtract
([CustomerId],[ClassCode],[JobStepInstanceId])
SELECT
C.Id
,CC.Class
,@JobStepInstanceId
FROM CTE_DistinctCustomerIds Cust
INNER JOIN Customers C ON Cust.CustomerId = C.Id
LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id
END

GO
