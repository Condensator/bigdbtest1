SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateACHScheduleStatusAfterMigration]
(
@UserId BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
SET NOCOUNT ON;
BEGIN
DECLARE @u_ConversionSource nvarchar(50); 
SELECT @u_ConversionSource = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource'
UPDATE ACHSchedules set Status = 'Completed',UpdatedById = @UserId,UpdatedTime =@CreatedTime FROM ACHSchedules 
JOIN Contracts ON Contracts.Id = ACHSchedules.ContractBillingId 
JOIN Receivables ON ACHSchedules.ReceivableId = Receivables.Id 
WHERE Receivables.TotalEffectiveBalance_Amount = 0 
	AND Contracts.u_ConversionSource=@u_ConversionSource
	AND ACHSchedules.StopPayment = 0 
	AND ACHSchedules.IsActive = 1 
	AND Receivables.IsActive = 1 
	and ACHSchedules.Status = 'Pending'
END

GO
