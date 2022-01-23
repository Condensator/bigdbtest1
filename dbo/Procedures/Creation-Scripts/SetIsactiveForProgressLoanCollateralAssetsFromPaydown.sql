SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SetIsactiveForProgressLoanCollateralAssetsFromPaydown]
(
@AssetIds NVARCHAR(MAX),
@LoanFinanceId BIGINT,
@UpdateStatus BIT,
@PaydownDate DATETIME,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
If(@UpdateStatus = 1)
BEGIN
UPDATE CollateralAssets SET IsActive = 0, TerminationDate = @PaydownDate, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime WHERE Id IN (SELECT CA.Id FROM CollateralAssets CA
WHERE CA.LoanFinanceId = @LoanFinanceId
AND CA.IsFromProgressFunding = 0
AND CA.AssetId in (SELECT Id FROM ConvertCSVToBigIntTable(@AssetIds,',')))
END
ELSE
BEGIN
UPDATE CollateralAssets SET IsActive = 1, TerminationDate = null, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime WHERE Id in (SELECT CA.Id FROM CollateralAssets CA
WHERE CA.LoanFinanceId = @LoanFinanceId
AND CA.IsFromProgressFunding = 0
AND CA.AssetId IN (SELECT Id FROM ConvertCSVToBigIntTable(@AssetIds,',')))
END
END

GO
