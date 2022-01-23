SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ImportNonDSLReceivablesForReceiptApplication]
@LegalEntityId BIGINT
,@ReceiptContractId BIGINT
,@CurrentUserId BIGINT
,@CurrencyISO NVARCHAR(6)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #AccesibleLegalEntity
(
LegalEntityId BIGINT NOT NULL
);
INSERT INTO #AccesibleLegalEntity
SELECT LegalEntities.Id AS LegalEntityId
FROM LegalEntities
JOIN LegalEntitiesForUsers
ON LegalEntities.Id = LegalEntitiesForUsers.LegalEntityId
AND LegalEntitiesForUsers.IsActive = 1
AND LegalEntitiesForUsers.UserId = @CurrentUserId
WHERE ( @LegalEntityId = LegalEntities.Id)
SELECT  Receivables.Id AS Id
,ReceivableDetails.Id AS ReceivableDetailId
,ISNULL(ReceivableDetails.Amount_Amount,0.0) AS ReceivableAmount_Amount
,ISNULL(ReceivableDetails.EffectiveBalance_Amount,0.0) AS EffectiveReceivableBalance_Amount
,ISNULL(ReceivableDetails.EffectiveBookBalance_Amount,0.0) AS EffectiveBookBalance_Amount
,ISNULL(ReceivableDetails.Balance_Amount,0.0) AS ReceivableBalance_Amount
,ReceivableTypes.Name AS  ReceivableType
,Receivables.DueDate AS DueDate
,Receivables.PaymentScheduleID
FROM Receivables
JOIN #AccesibleLegalEntity ON Receivables.LegalEntityId = #AccesibleLegalEntity.LegalEntityId
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN ReceivableDetails ON Receivables.Id=ReceivableDetails.ReceivableId
LEFT JOIN Contracts ON Contracts.Id = Receivables.EntityId AND Receivables.EntityType = 'CT'
WHERE Receivables.IsActive = 1
AND ReceivableDetails.IsActive=1
AND Receivables.IsDummy = 0
AND Receivables.IsCollected = 1
AND (ISNULL(ReceivableDetails.EffectiveBookBalance_Amount,0.0)+ISNULL(ReceivableDetails.EffectiveBalance_Amount,0.0)<>0)
AND (@ReceiptContractId IS NULL OR Contracts.Id = @ReceiptContractId)
AND ( ReceivableTypes.Name='LoanInterest' or ReceivableTypes.Name='LoanPrincipal')
AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
AND ReceivableDetails.Amount_Currency = @CurrencyISO
ORDER BY Receivables.DueDate,Receivables.ID
DROP TABLE #AccesibleLegalEntity;
END

GO
