SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetInsurancePolicySummaryForContractService]
(
@ContractSequenceNumber nvarchar(80),
@FilterCustomerId BIGINT = NULL,
@CurrentPortfolioId BigInt
)
As
SET NOCOUNT ON
BEGIN
DECLARE @CoverageAmountOnType AS TABLE(InsurancePolicyId INT,Blanket DECIMAL(19,2),Specific DECIMAL(19,2))
INSERT INTO @CoverageAmountOnType(InsurancePolicyId,Blanket,Specific)
select
*
from
(
SELECT
Insurancepolicies.Id InsurancePolicyId
,InsurancePolicies.Type [PolicyType]
,InsurancePolicyCoverageDetails.AggregateAmount_Amount CoverageAmount
FROM
Insurancepolicies
Inner join InsurancePolicyAssignments On
InsurancePolicies.Id = InsurancePolicyAssignments.InsurancePolicyId
and InsurancePolicyAssignments.IsActive = 1
INNER JOIN Contracts on
InsurancePolicyAssignments.ContractId = Contracts.Id
and Contracts.SequenceNumber = 	@ContractSequenceNumber
INNER JOIN InsurancePolicyCoverageDetails ON
InsurancePolicyCoverageDetails.InsurancePolicyId = InsurancePolicies.Id
AND InsurancePolicyCoverageDetails .IsActive = 1
AND (@FilterCustomerId IS NULL OR Insurancepolicies.CustomerId = @FilterCustomerId )
) as s
pivot
(
SUM(CoverageAmount)
FOR [PolicyType] in (Blanket,Specific)
)AS pivotingType
SELECT DISTINCT
PolicyNumber
,InsuranceCompanies.Name [InsuranceCompany]
,Type [CoverageType]
,EffectiveDate
,ExpirationDate
,InsuranceAgent.FullName [InsuranceBrokerName]
,CurrCode.ISO as Currency
,ISNULL(InsConverageAmount.Blanket,0.00) Casualty
,ISNULL(InsConverageAmount.Specific,0.00) Liability
,'Edit' as TransactionName
,'InsurancePolicy' as EntityName
,Insurancepolicies.Id AS EntityId
,InsurancePolicies.IsActive
,Parties.PartyNumber [CustomerNumber]
FROM
Insurancepolicies
INNER JOIN InsuranceCompanies ON
InsurancePolicies.InsuranceCompanyId = InsuranceCompanies.Id
INNER JOIN Parties ON
Insurancepolicies.CustomerId = Parties.Id
AND (@FilterCustomerId IS NULL OR Insurancepolicies.CustomerId = @FilterCustomerId )
Inner join InsurancePolicyAssignments On
InsurancePolicies.Id = InsurancePolicyAssignments.InsurancePolicyId
and InsurancePolicyAssignments.IsActive = 1
INNER JOIN Contracts on
Contracts.SequenceNumber = 	@ContractSequenceNumber
INNER JOIN Currencies Curr on
Insurancepolicies.CurrencyId = Curr.Id
INNER JOIN CurrencyCodes CurrCode on
Curr.CurrencyCodeId = CurrCode.Id
INNER JOIN @CoverageAmountOnType as InsConverageAmount on
Insurancepolicies.Id = InsConverageAmount.InsurancePolicyId
LEFT JOIN PartyContacts [InsuranceAgent] on
InsurancePolicies.InsuranceAgentId = InsuranceAgent.Id
Where Parties.PortfolioId=@CurrentPortfolioId
END

GO
