SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DealExposureReport]
(
@SequenceNumber Nvarchar(80) = NULL,
@CustomerNumber Nvarchar(80) = NULL,
@LegalEntityNumber Nvarchar(40) = NULL,
@EntityType Nvarchar(40) = NULL,
@CreditProfileId BIGINT = NULL,
@CustomerId BIGINT = NULL,
@LegalEntityId BIGINT = NULL,
@IncomeDate  Date,
@ExposureCurrency nvarchar(3)
)
AS
BEGIN
SELECT
DE.ExposureDate
,DE.EntityType
,CASE WHEN CC.Id IS NOT NULL THEN CC.SequenceNumber
WHEN CP.Id IS NOT NULL THEN CP.Number ELSE NULL END 'EntityId'
,DE.ExposureType
,PT.PartyName 'PartyName'
,DE.RelationshipPercentage
,DE.CommencedDealRNI_Amount
,DE.CommencedDealRNI_Currency
,DE.CommencedDealExposure_Amount
,DE.CommencedDealExposure_Currency
,DE.OTPLeaseRNI_Amount
,DE.OTPLeaseRNI_Currency
,DE.OTPLeaseExposure_Amount
,DE.OTPLeaseExposure_Currency
,DE.UncommencedDealRNI_Amount
,DE.UncommencedDealRNI_Currency
,DE.UncommencedDealExposure_Amount
,DE.UncommencedDealExposure_Currency
,DE.LOCBalanceRevolving_Amount
,DE.LOCBalanceRevolving_Currency
,DE.LOCBalanceNonRevolving_Amount
,DE.LOCBalanceNonRevolving_Currency
,DE.LOCBalanceExposure_Amount
,DE.LOCBalanceExposure_Currency
,DE.TotalExposure_Amount
,DE.TotalExposure_Currency
FROM
DealExposures DE
LEFT JOIN Contracts CC ON DE.EntityType IN ('Loan','ProgressLoan','Lease', 'LeveragedLease') AND DE.EntityId = CC.Id
LEFT JOIN LeaseFinances LEF ON DE.EntityType = 'Lease' AND DE.EntityId = LEF.ContractId AND LEF.IsCurrent = 1
LEFT JOIN LegalEntities LELE ON LEF.LegalEntityId =  LELE.Id
LEFT JOIN LoanFinances LOF ON DE.EntityType IN ('Loan','ProgressLoan') AND DE.EntityId = LOF.ContractId AND LOF.IsCurrent = 1
LEFT JOIN LegalEntities LOLE ON LOF.LegalEntityId =  LOLE.Id
LEFT JOIN LeveragedLeases LEV ON DE.EntityType = 'LeveragedLease' AND DE.EntityId = LEV.ContractId AND LEV.IsCurrent = 1
LEFT JOIN LegalEntities LEVLE ON LEV.LegalEntityId =  LEVLE.Id
LEFT JOIN CreditProfiles CP ON DE.EntityType = 'LOC' AND DE.EntityId = CP.Id
LEFT JOIN LegalEntities CPLE ON CP.LegalEntityId =  CPLE.Id
LEFT JOIN Parties PT ON DE.ExposureCustomerId = PT.Id
WHERE IsActive = 1
AND (@SequenceNumber IS NULL OR (DE.EntityType IN ('Loan','ProgressLoan','Lease', 'LeveragedLease') AND DE.EntityId = (SELECT ID FROM Contracts WHERE SequenceNumber = @SequenceNumber)))
AND (@CreditProfileId IS NULL OR (DE.EntityType = 'LOC' AND DE.EntityId = @CreditProfileId))
AND (@CustomerId IS NULL OR DE.ExposureCustomerId = @CustomerId)
AND ExposureDate = @IncomeDate
AND (@LegalEntityId IS NULL OR ((LELE.Id IS NOT NULL AND LELE.Id = @LegalEntityId)
OR (LOLE.Id IS NOT NULL AND LOLE.Id = @LegalEntityId) OR (LEV.Id IS NOT NULL AND LEVLE.Id = @LegalEntityId) OR (CPLE.Id IS NOT NULL AND CPLE.Id = @LegalEntityId)))
END

GO
