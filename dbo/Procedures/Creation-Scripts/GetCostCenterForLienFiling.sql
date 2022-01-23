SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetCostCenterForLienFiling]
(
@EntityId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
;WITH CTE_LegalEntity
AS(
SELECT
Contracts.Id
,Contracts.LineofBusinessId
,COALESCE(LeaseFinances.LegalEntityId,LoanFinances.LegalEntityId) AS LegalEntityId
FROM
Contracts
LEFT JOIN LeaseFinances
ON LeaseFinances.ContractId = Contracts.Id
LEFT JOIN LoanFinances
ON LoanFinances.ContractId = Contracts.Id
WHERE
Contracts.Id = @EntityId
)
SELECT
TOP 1
CostCenterConfigs.CostCenter AS [FieldValue]
FROM
CTE_LegalEntity
INNER JOIN GLOrgStructureConfigs
ON GLOrgStructureConfigs.LegalEntityId = CTE_LegalEntity.LegalEntityId
AND GLOrgStructureConfigs.LineofBusinessId = CTE_LegalEntity.LineofBusinessId
INNER JOIN CostCenterConfigs
ON CostCenterConfigs.Id = GLOrgStructureConfigs.CostCenterId
WHERE
GLOrgStructureConfigs.IsActive = 1
END

GO
