SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateReplacementAmountsInPartiesFromTerminations]
(
@ContractId BIGINT,
@CustomerId BIGINT,
@CoBorrowerThirdPartyType NVARCHAR(30),
@CoLesseeThirdPartyType NVARCHAR(30),
@CorporateGuarantorThirdPartyType NVARCHAR(30),
@CustomerStatusActive NVARCHAR(30),
@ApprovedCreditProfileStatus NVARCHAR(30),
@IsReversal TINYINT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @ReplacementAmountToReduce DECIMAL(16,2) = (SELECT SUM(CPCR.ReplacementAmount_Amount)
FROM CreditProfileContractReplacements CPCR
JOIN CreditProfiles CP ON CPCR.CreditProfileId = CP.Id
WHERE CPCR.ContractId = @ContractId
AND CPCR.IsActive = 1
AND CP.Status = @ApprovedCreditProfileStatus
AND CP.ReplacementSchedule = 1);
IF @ReplacementAmountToReduce != 0
BEGIN
CREATE TABLE #CustomersToUpdate
(
CustomerId BIGINT,
AmountToReduce DECIMAL(16,2)
);
INSERT INTO #CustomersToUpdate VALUES ( @CustomerId, @ReplacementAmountToReduce )
DECLARE @ParentPartyId BIGINT = (SELECT TOP 1 P.ParentPartyId FROM Customers C
JOIN Parties P ON C.Id = P.Id
WHERE C.Id = @CustomerId);
IF @ParentPartyId IS NOT NULL
INSERT INTO #CustomersToUpdate VALUES ( @ParentPartyId, @ReplacementAmountToReduce );
INSERT INTO #CustomersToUpdate
SELECT C.Id, @ReplacementAmountToReduce FROM Customers C
JOIN Parties P ON C.Id = P.Id
WHERE C.Status = @CustomerStatusActive AND (P.ParentPartyId IS NOT NULL) AND P.ParentPartyId IN (@ParentPartyId,@CustomerId) AND C.Id != @CustomerId;
INSERT INTO #CustomersToUpdate
SELECT C.Id, CASE WHEN TP.RelationshipType = @CorporateGuarantorThirdPartyType THEN ROUND((CTT.RelationshipPercentage/100) * @ReplacementAmountToReduce, 2)
ELSE @ReplacementAmountToReduce END
FROM ContractThirdPartyRelationships CTT
JOIN  CustomerThirdPartyRelationships TP ON CTT.ThirdPartyRelationshipId = TP.Id
JOIN Customers C ON TP.ThirdPartyId = C.Id
LEFT JOIN #CustomersToUpdate ExC ON Exc.CustomerId = C.Id
WHERE CTT.ContractId=@ContractId
AND CTT.IsActive = 1 AND TP.RelationshipType IN (@CoBorrowerThirdPartyType,@CoLesseeThirdPartyType,@CorporateGuarantorThirdPartyType)
AND C.Status = @CustomerStatusActive
AND ExC.CustomerId IS NULL;
IF @IsReversal = 0
BEGIN
UPDATE C SET C.ReplacementAmount_Amount = ROUND(C.ReplacementAmount_Amount - CU.AmountToReduce, 2)
FROM Customers C
JOIN #CustomersToUpdate CU ON C.Id = CU.CustomerId;
END
ELSE
BEGIN
UPDATE C SET C.ReplacementAmount_Amount = ROUND(C.ReplacementAmount_Amount + CU.AmountToReduce, 2)
FROM Customers C
JOIN #CustomersToUpdate CU ON C.Id = CU.CustomerId;
END
END
END

GO
