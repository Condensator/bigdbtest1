SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateDisbursementRequestSequenceNumber]
(  
    @DisbursementRequestIds NVARCHAR(MAX),
	@SequenceNumber NVARCHAR(40),
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS

BEGIN
	SET NOCOUNT ON

	DECLARE @ContractSequenceNumberMaxLength INT;

	SELECT
		@ContractSequenceNumberMaxLength = CHARACTER_MAXIMUM_LENGTH
	FROM
  		INFORMATION_SCHEMA.COLUMNS
	WHERE
		TABLE_NAME = 'DisbursementRequests' AND COLUMN_NAME = 'ContractSequenceNumber';


	SELECT ID 
	INTO #@DisbursementRequestIds
	FROM ConvertCSVToBigIntTable(@DisbursementRequestIds, ',')

	CREATE INDEX IX_Id ON #@DisbursementRequestIds (Id);

	UPDATE DR SET 
		ContractSequenceNumber = SUBSTRING(COALESCE(ContractSequenceNumber + ',' + @SequenceNumber , @SequenceNumber),1,@ContractSequenceNumberMaxLength)
	   ,UpdatedById = @UpdatedById 
	   ,UpdatedTime = @UpdatedTime
	FROM DisbursementRequests DR
	INNER JOIN #@DisbursementRequestIds DRID ON DR.Id = DRID.ID
END

GO
