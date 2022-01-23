SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SP to fetch customer details
CREATE PROCEDURE [dbo].[InsertVertexCustomerDetail]
(
@JobStepInstanceId BIGINT
)
AS
BEGIN

;WITH CTE_DistinctCustomerIds AS
(
SELECT
DISTINCT CustomerId
FROM
SalesTaxReceivableDetailExtract
WHERE IsVertexSupported = 1 AND InvalidErrorCode IS NULL AND JobStepInstanceId =  @JobStepInstanceId
)
INSERT INTO VertexCustomerDetailExtract
(CustomerId, CustomerName, CustomerNumber, ISOCountryCode, ClassCode, TaxRegistrationNumber, JobStepInstanceId)
SELECT
CustomerId = C.Id,
CustomerName = P.PartyName,
CustomerNumber = P.PartyNumber,
ISOCountryCode =  Ct.ShortName,
ClassCode = CC.Class,
TaxRegistrationNumber = P.VATRegistrationNumber,
JobStepInstanceId = @JobStepInstanceId
FROM CTE_DistinctCustomerIds Cust
JOIN Customers C ON Cust.CustomerId = C.Id
JOIN Parties P ON Cust.CustomerId = P.Id
LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id
LEFT JOIN States S ON P.StateOfIncorporationId = S.Id
LEFT JOIN Countries Ct ON S.CountryId = Ct.Id
END

GO
