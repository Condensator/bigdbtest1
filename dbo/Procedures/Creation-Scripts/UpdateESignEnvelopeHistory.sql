SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create PROCEDURE [dbo].[UpdateESignEnvelopeHistory]
(
@HistoryDetails EnvelopeHistoryDetails READONLY,
@CreatedById BigInt,
@IsDociSign bit,
@ESignEnvelopeId BigInt
)
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF(@IsDociSign = 1)
	Begin
		Update [dbo].[ESignEnvelopeHistories] SET IsActive = 0 WHERE ESignEnvelopeId = @ESignEnvelopeId
	End
	
	INSERT INTO [dbo].ESignEnvelopeHistories(Name, Status,Activity, ExternalId, ESignEnvelopeId, [Date], IsActive, CreatedById, CreatedTime)
	SELECT
	     [Name], [Status],Activity, ExternalId, @ESignEnvelopeId, CONVERT(date, Date), 1, @CreatedById, SYSDATETIMEOFFSET()
	FROM
     @HistoryDetails
END

GO
