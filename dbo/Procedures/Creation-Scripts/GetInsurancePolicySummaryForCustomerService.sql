SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetInsurancePolicySummaryForCustomerService]
(
@CustomerNumber nvarchar(50),
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
INNER JOIN Customers ON
InsurancePolicies.CustomerId = Customers.Id
INNER JOIN Parties ON
Customers.Id = Parties.Id
AND Parties.PartyNumber = @CustomerNumber
INNER JOIN InsurancePolicyCoverageDetails ON
InsurancePolicyCoverageDetails.InsurancePolicyId = InsurancePolicies.Id
AND InsurancePolicyCoverageDetails .IsActive = 1
where Parties.PortFolioId= @CurrentPortfolioId
) as s
pivot
(
SUM(CoverageAmount)
FOR [PolicyType] in (Blanket,Specific)
)AS pivotingType
SELECT
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
,Insurancepolicies.IsActive
FROM
Insurancepolicies
INNER JOIN InsuranceCompanies ON
InsurancePolicies.InsuranceCompanyId = InsuranceCompanies.Id
INNER JOIN Customers ON
InsurancePolicies.CustomerId = Customers.Id
INNER JOIN Parties ON
Customers.Id = Parties.Id
AND Parties.PartyNumber = @CustomerNumber
INNER JOIN Currencies Curr on
Insurancepolicies.CurrencyId = Curr.Id
INNER JOIN CurrencyCodes CurrCode on
Curr.CurrencyCodeId = CurrCode.Id
INNER JOIN @CoverageAmountOnType as InsConverageAmount on
Insurancepolicies.Id = InsConverageAmount.InsurancePolicyId
LEFT JOIN PartyContacts [InsuranceAgent] on
InsurancePolicies.InsuranceAgentId = InsuranceAgent.Id
where Parties.PortFolioId= @CurrentPortfolioId
END

GO
