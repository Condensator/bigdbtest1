SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetContractsNotAssignedToRecoveryGroup]
(
@InputContractIds ContractIdsForAutoPayoff READONLY,
@ParameterDetailId BIGINT NULL
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
ContractId = C.Id
INTO #FilteredContracts
FROM
Contracts C
JOIN @InputContractIds IC ON C.Id = IC.Id
WHERE
C.IsAssignToRecovery = 0
GROUP BY
C.Id
SELECT
ContractId
FROM
#FilteredContracts
SET NOCOUNT OFF;
END

GO
