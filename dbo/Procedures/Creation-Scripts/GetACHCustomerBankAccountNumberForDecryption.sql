SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetACHCustomerBankAccountNumberForDecryption]
(
	@JobStepInstanceId BIGINT
)
AS
BEGIN

	SELECT 
		Id AS ACHScheduleExtractId, CustomerBankAccountNumber_CT CustomerBankAccountNumber, CustomerNumber FROM ACHSchedule_Extract ACHS
	WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
	AND ACHS.ErrorCode = '_'


END

GO
