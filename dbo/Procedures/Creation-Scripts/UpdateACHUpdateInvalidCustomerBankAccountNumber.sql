SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[UpdateACHUpdateInvalidCustomerBankAccountNumber]
(
	@ACHUpdateBankAccountInfo	ACHUpdateBankAccountInfo READONLY,
	@ErrorCode					NVARCHAR(10)
)
AS
BEGIN

	UPDATE AE
		SET ErrorCode = @ErrorCode,
			ErrorMessage = AEInfo.ErrorMessage
	FROM ACHSchedule_Extract AE
	JOIN @ACHUpdateBankAccountInfo AEInfo
	ON AE.Id = AEInfo.ACHScheduleExtractId

END

GO
