SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SPOC_InvoiceNumber_GetNextInvoiceNumber]
(
    @CountryId		BIGINT NULL,
    @SequencePrefix NVARCHAR(40),
    @IncrementBy	INT = 1
)
AS
BEGIN 
	SET NOCOUNT ON;
	
	DECLARE @CountryShortName NVARCHAR(5), 
			@SequenceName NVARCHAR(30)
	
	SELECT @CountryShortName = ShortName 
	FROM Countries WHERE Id = @CountryId AND IsVATApplicable = 1

	SET @SequenceName = ISNULL(@SequencePrefix + '_' + @CountryShortName, @SequencePrefix)
	
	DECLARE @NextVal BIGINT
	DECLARE @FirstVal BIGINT       
	EXEC GetNextSqlSequence @SequenceName, @IncrementBy, @NextValue = @NextVal OUTPUT, @FirstValue = @FirstVal OUTPUT

	SELECT @NextVal AS SequenceNumber, @CountryShortName AS CountryShortName
		   
END

GO
