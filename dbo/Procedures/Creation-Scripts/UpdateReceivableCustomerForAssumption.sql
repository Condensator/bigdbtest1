SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateReceivableCustomerForAssumption]
(
@NotInvoicedReceivableIdsInCSV NVARCHAR(MAX)
,@AssumptionId BIGINT
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
DECLARE @NewCustomerId BIGINT
DECLARE @OldCustomerId BIGINT
DECLARE @ContractId BIGINT
DECLARE @LeaseFinanceId BIGINT
DECLARE @BillToId BIGINT
DECLARE @BillToLocationId BIGINT
DECLARE @AssumptionDate DATE
DECLARE @ContractType NVARCHAR(28)
DECLARE @IsTaxAssessed BIT
DECLARE @IsSalesTaxRequiredForLoan BIT = CAST(0 AS BIT)
SELECT  @IsSalesTaxRequiredForLoan = CASE WHEN UPPER(Value) = 'TRUE' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
FROM dbo.GlobalParameters gp WHERE gp.Name = 'IsSalesTaxRequiredForLoan' AND gp.Category = 'SalesTax'
SELECT
@NewCustomerId = NewCustomerId,
@OldCustomerId = OriginalCustomerId,
@AssumptionDate = AssumptionDate,
@BillToId=NewBillToId,
@ContractId = ContractId,
@ContractType = ContractType,
@IsTaxAssessed = CASE WHEN ContractType = 'Lease' THEN 0 ELSE 1 END
FROM Assumptions
WHERE ID = @AssumptionId
SELECT @BillToLocationId = LocationId
FROM Billtoes WHERE Id = @BillToId
UPDATE ReceivableTaxes SET IsActive = 0,UpdatedById= @CreatedById,UpdatedTime = @CreatedTime WHERE ReceivableId IN (SELECT Id FROM ConvertCSVToBigIntTable(@NotInvoicedReceivableIdsInCSV,','))
UPDATE ReceivableTaxDetails SET IsActive = 0,UpfrontTaxSundryId = NULL ,UpdatedById= @CreatedById,UpdatedTime = @CreatedTime WHERE ReceivableTaxId IN (SELECT ID FROM ReceivableTaxes WHERE ReceivableID IN (SELECT Id FROM ConvertCSVToBigIntTable(@NotInvoicedReceivableIdsInCSV,',')))
UPDATE Receivables SET CustomerId = @NewCustomerId , UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
WHERE Receivables.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@NotInvoicedReceivableIdsInCSV,','))
UPDATE ReceivableDetails SET BillToId = @BillToId,UpdatedById= @CreatedById,UpdatedTime = @CreatedTime , IsTaxAssessed = @IsTaxAssessed
WHERE ReceivableDetails.ReceivableId IN (SELECT Id FROM ConvertCSVToBigIntTable(@NotInvoicedReceivableIdsInCSV,','))
IF @IsSalesTaxRequiredForLoan = 1
BEGIN
SELECT r.Id
INTO #LoanInterestBasedReceivables
FROM dbo.Receivables r
INNER JOIN dbo.ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
INNER JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
INNER JOIN dbo.ReceivableDetails rd ON r.Id = rd.ReceivableId
WHERE rt.Name = 'LoanInterest' AND r.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@NotInvoicedReceivableIdsInCSV,','))
SELECT
AssumptionAssets.AssetId,
AssumptionAssets.BillToId,
Billtoes.LocationId INTO #AssumptionAssetsForUpdation
FROM AssumptionAssets
JOIN Billtoes ON Billtoes.Id = AssumptionAssets.BillToId
WHERE AssumptionId = @AssumptionId
AND AssumptionAssets.IsActive = 1
UPDATE ReceivableDetails SET BillToId = #AssumptionAssetsForUpdation.BillToId,UpdatedById= @CreatedById,UpdatedTime = @CreatedTime , IsTaxAssessed = @IsTaxAssessed
FROM #AssumptionAssetsForUpdation
WHERE ReceivableDetails.ReceivableId IN (SELECT Id FROM ConvertCSVToBigIntTable(@NotInvoicedReceivableIdsInCSV,','))
AND ReceivableDetails.AssetId = #AssumptionAssetsForUpdation.AssetId
UPDATE ReceivableDetails SET UpdatedById= @CreatedById,UpdatedTime = @CreatedTime , IsTaxAssessed = 0
WHERE ReceivableDetails.ReceivableId IN (SELECT Id FROM #LoanInterestBasedReceivables)
UPDATE Receivables SET LocationId = @BillToLocationId , UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
WHERE Receivables.Id IN (SELECT Id FROM #LoanInterestBasedReceivables)
UPDATE Receivables SET LocationId = #AssumptionAssetsForUpdation.LocationId , UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
FROM (SELECT * FROM
(SELECT RANK() OVER ( PARTITION BY ReceivableId ORDER BY ReceivableId DESC) rownm,
ReceivableId,
AU.LocationId
FROM ReceivableDetails RD
JOIN #AssumptionAssetsForUpdation AU ON RD.AssetId = AU.AssetId
GROUP BY ReceivableId,AU.LocationId)T
WHERE rownm=1
) #AssumptionAssetsForUpdation
WHERE Receivables.Id IN (SELECT Id FROM #LoanInterestBasedReceivables)
AND #AssumptionAssetsForUpdation.ReceivableId = Receivables.Id
END
END

GO
