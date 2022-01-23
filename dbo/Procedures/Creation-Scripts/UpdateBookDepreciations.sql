SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateBookDepreciations]
(
	@BookDepreciationDetailInputs BookDepreciationDetails READONLY,
	@UserId	BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
	
	UPDATE BookDepreciations
	SET
		IsActive = BDDI.IsActive,
		TerminatedDate = BDDI.TerminatedDate,
		UpdatedTime = @UpdatedTime,
		UpdatedById = @UserId
	FROM BookDepreciations
	JOIN @BookDepreciationDetailInputs BDDI ON BDDI.BookDepreciationId = BookDepreciations.Id

END

GO
