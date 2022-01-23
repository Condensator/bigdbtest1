SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivatePayablesAndTreasuryPayables]
(
@PayablesToBeInactivated PayableId READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET(7)
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE Payables
SET [Status] = 'Inactive'
FROM Payables join @PayablesToBeInactivated PI on Payables.Id = PI.Id
UPDATE TreasuryPayables
SET [Status] = 'Inactive'
FROM TreasuryPayables JOIN TreasuryPayableDetails ON TreasuryPayables.Id = TreasuryPayableDetails.TreasuryPayableId JOIN @PayablesToBeInactivated PI on TreasuryPayableDetails.PayableId = PI.Id
UPDATE TreasuryPayableDetails
SET [IsActive] = 0
FROM TreasuryPayableDetails JOIN @PayablesToBeInactivated PI on TreasuryPayableDetails.PayableId = PI.Id
END

GO
