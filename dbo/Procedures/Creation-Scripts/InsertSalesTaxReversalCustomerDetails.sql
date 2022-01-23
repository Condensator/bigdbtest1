SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InsertSalesTaxReversalCustomerDetails]
(
@JobStepInstanceId BIGINT
)
AS
BEGIN
WITH CTE_DistinctCustomerIds AS
(
SELECT DISTINCT	CustomerId FROM ReversalReceivableDetail_Extract WHERE ErrorCode IS NULL AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO ReversalCustomerDetail_Extract
(CustomerId, PartyName, CustomerNumber, ISOCountryCode, ClassCode, TaxRegistrationNumber, CreatedById, CreatedTime, JobStepInstanceId)
SELECT
CustomerId = C.Id,
PartyName = P.PartyName,
CustomerNumber = P.PartyNumber,
ISOCountryCode =  Ct.ShortName,
ClassCode = CC.Class,
TaxRegistrationNumber = P.VATRegistrationNumber,
CreatedById = 1,
CreatedTime = SYSDATETIMEOFFSET(),
@JobStepInstanceId
FROM CTE_DistinctCustomerIds Cust
INNER JOIN Customers C ON Cust.CustomerId = C.Id
INNER JOIN Parties P ON Cust.CustomerId = P.Id
LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id
LEFT JOIN States S ON P.StateOfIncorporationId = S.Id
LEFT JOIN Countries Ct ON S.CountryId = Ct.Id;
UPDATE ReversalReceivableDetail_Extract
SET CustomerName = PartyName
FROM ReversalReceivableDetail_Extract RD
INNER JOIN ReversalCustomerDetail_Extract CD ON RD.CustomerId = CD.CustomerId AND RD.JobStepInstanceId = CD.JobStepInstanceId
WHERE RD.ErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId
END

GO
