SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetNextSequence]
(
	@Module varchar(50),
	@IncrementBy int = 1,
	@UpdatedById bigint,
	@UpdatedTime datetimeoffset,
	@NextValue bigint output
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE 
	UPDATE SequenceGenerators 
		SET @NextValue  = [Next]=[Next]+@IncrementBy, 
			UpdatedById = @UpdatedById,
			UpdatedTime = @UpdatedTime 
	WHERE 
		Module = @Module
END

GO
