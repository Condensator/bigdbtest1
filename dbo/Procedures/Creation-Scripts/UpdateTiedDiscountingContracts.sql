SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTiedDiscountingContracts]
(
@DiscountingContractId NVARCHAR(MAX),
@PayOffDate DATETIME,
@PayOffId BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE DC
SET DC.PaidOffDate = @PayOffDate,
DC.PaidOffId = @PayOffId,
DC.UpdatedById = @UpdatedById,
DC.UpdatedTime = @UpdatedTime
FROM DiscountingContracts DC
JOIN ConvertCSVToBigIntTable(@DiscountingContractId,',') csv ON DC.Id = csv.Id
;
UPDATE DF
SET DF.IsOnHold = 1,
DF.UpdatedById = @UpdatedById,
DF.UpdatedTime = @UpdatedTime
FROM DiscountingContracts DC
JOIN ConvertCSVToBigIntTable(@DiscountingContractId,',') csv ON DC.Id = csv.Id
JOIN DiscountingFinances DF ON DC.DiscountingFinanceId = DF.Id
WHERE DF.IsOnHold = 0
;
SET NOCOUNT OFF;
END

GO
