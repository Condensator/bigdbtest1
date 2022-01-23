SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPOC_InvoiceNumber_CreateInvoiceNumberSequenceForCountry]
(
    @CountryId		BIGINT,
    @SequencePrefix NVARCHAR(40),
    @StartWith		BIGINT = 1
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SequenceName NVARCHAR(30),
			@Sql NVARCHAR(100) = ''

	SELECT @SequenceName = @SequencePrefix + '_' + ShortName 
	FROM Countries WHERE Id = @CountryId AND IsVATApplicable = 1

	IF @SequenceName IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.sequences WHERE name = @SequenceName)
	BEGIN
		SET @Sql = 'CREATE SEQUENCE [' + @SequenceName + '] START WITH ' + CAST((@StartWith) AS VARCHAR(100)) + ' INCREMENT BY 1 '
		EXEC sp_executesql @Sql
	END;
END

GO
