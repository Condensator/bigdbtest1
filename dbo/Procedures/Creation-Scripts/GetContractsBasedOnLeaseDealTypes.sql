SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetContractsBasedOnLeaseDealTypes]
(
@InputContractIds ContractIdsForAutoPayoff READONLY,
@ParameterDetailId BIGINT NULL
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
[Values] = CPD.[Value]
INTO #ParameterValues
FROM
AutoPayoffTemplateCollectionParameterDetails CPD
JOIN AutoPayoffTemplateParameterDetails PD ON PD.Id = CPD.AutoPayoffTemplateParameterDetailId
WHERE PD.ID = @ParameterDetailId
AND CPD.IsActive = 1
AND PD.IsActive = 1
SELECT
ContractId = C.Id
FROM
Contracts C
JOIN DealProductTypes DPT ON DPT.Id = C.DealProductTypeId
JOIN @InputContractIds IC ON C.Id = IC.Id
WHERE DPT.[Name] IN (SELECT
[Values]
FROM
#ParameterValues)
SET NOCOUNT OFF;
END

GO
