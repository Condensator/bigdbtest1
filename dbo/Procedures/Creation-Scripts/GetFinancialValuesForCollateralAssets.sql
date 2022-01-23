SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetFinancialValuesForCollateralAssets]
(
@ContractId BIGINT
)
AS
BEGIN
SET NOCOUNT ON
SELECT
EffectiveBalance = CASE WHEN R.FunderId IS NULL THEN RD.EffectiveBalance_Amount ELSE 0.0 END
INTO #LeaseAssetRentalsInfo
FROM ReceivableDetails RD
JOIN Receivables R ON RD.ReceivableId = R.Id
JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = 'CT'
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE RD.IsActive = 1 AND R.IsActive = 1 AND C.Id = @ContractId
AND RT.Name IN ('LoanInterest','LoanPrincipal')
AND R.IsDummy = 0
AND R.FunderId IS NULL;
SELECT OutstandingRental = SUM(EffectiveBalance) FROM #LeaseAssetRentalsInfo;
DROP TABLE
#LeaseAssetRentalsInfo
END

GO
