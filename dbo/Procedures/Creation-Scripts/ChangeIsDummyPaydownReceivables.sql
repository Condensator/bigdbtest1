SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ChangeIsDummyPaydownReceivables]
(
@ContractId BIGINT,
@PaydownId BIGINT,
@SourceModule NVARCHAR(50),
@CanUpdateBalance BIT,
@CreatedById BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @ContractId BIGINT = 598783
--DECLARE @LoanPaydownId BIGINT = 598783
--DECLARE @SourceModule NVARCHAR(50) = 'LoanPaydown'
CREATE TABLE #ReceivablesToUpdateReal
(
Id BIGINT
)
INSERT INTO #ReceivablesToUpdateReal
SELECT R.Id FROM Receivables R
WHERE R.IsActive = 1 AND R.SourceTable = @SourceModule
AND R.EntityId = @ContractId AND R.IsDummy = 1 AND R.SourceId = @PaydownId
INSERT INTO #ReceivablesToUpdateReal
SELECT S.ReceivableId FROM LoanPaydowns LP
JOIN LoanPaydownSundries LPS ON LP.Id = LPs.LoanPaydownId AND LPS.IsActive = 1
JOIN Sundries S ON S.Id = LPS.SundryId AND S.IsActive = 1
JOIN Receivables R ON R.Id = S.ReceivableId AND R.IsActive = 1
WHERE S.SundryType = 'ReceivableOnly' AND R.IsDummy = 1
AND R.EntityId = @ContractId AND LP.Id = @PaydownId
IF @CanUpdateBalance = 0 --!(e.PaydownReason.IsFullPaydown && e.IsDailySensitiveLoan)
BEGIN
UPDATE Receivables SET IsDummy = 0 , UpdatedById = @CreatedById , UpdatedTime = @CurrentTime  FROM Receivables R
JOIN #ReceivablesToUpdateReal RR ON R.Id = RR.Id
WHERE R.SourceTable != @SourceModule
END
IF @CanUpdateBalance = 1 --!(e.PaydownReason.IsFullPaydown && e.IsDailySensitiveLoan)
BEGIN
UPDATE Receivables SET IsDummy = 0 , UpdatedById = @CreatedById , UpdatedTime = @CurrentTime FROM Receivables R
JOIN #ReceivablesToUpdateReal RR ON R.Id = RR.Id
END
UPDATE ReceivableTaxes SET IsDummy = 0 , UpdatedById = @CreatedById , UpdatedTime = @CurrentTime FROM ReceivableTaxes RT
JOIN #ReceivablesToUpdateReal RR ON RT.ReceivableId = RR.Id
WHERE RT.IsDummy = 1
IF @CanUpdateBalance = 1 --!(e.PaydownReason.IsFullPaydown && e.IsDailySensitiveLoan)
BEGIN
UPDATE RD SET RD.Balance_Amount = 0,RD.EffectiveBalance_Amount = 0,RD.EffectiveBookBalance_Amount = 0 , UpdatedById = @CreatedById , UpdatedTime = @CurrentTime, LeaseComponentBalance_Amount = 0
FROM ReceivableDetails RD
JOIN Receivables R ON RD.ReceivableId = R.Id
JOIN #ReceivablesToUpdateReal RR ON RD.ReceivableId = RR.Id AND R.Id = RR.Id
WHERE R.IsCollected = 0
UPDATE R SET TotalBalance_Amount= 0,TotalEffectiveBalance_Amount = 0 , UpdatedById = @CreatedById , UpdatedTime = @CurrentTime
FROM Receivables R
JOIN #ReceivablesToUpdateReal RR ON R.Id = RR.Id
WHERE R.IsCollected = 0
END
SET NOCOUNT OFF
END

GO
