SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetExtractedContractsForLeaseIncome]
(
@JobStepInstanceId BIGINT
)
AS
SET NOCOUNT ON;
BEGIN

SELECT IsSubmitted 
FROM LeaseIncomeRecognitionJob_Extracts 
WHERE JobStepInstanceId = @JobStepInstanceId

END

GO
