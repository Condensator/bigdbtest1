SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[OpenWorkListsInHibernation]
(
	@BusinessUnitId BIGINT,
	@CustomerId BIGINT,
	@NextBusinessDate DATETIME,
	@WorkListStatusOpen NVARCHAR(11),	
	@WorkListStatusHibernation NVARCHAR(11),
	@UserId BIGINT,
	@ServerTimeStamp DATETIMEOFFSET	
)
AS
BEGIN

	UPDATE CollectionWorkLists
			SET Status = @WorkListStatusOpen
				,FlagAsWorked = 0
				,NextWorkDate = NULL
				,FlagAsWorkedOn = NULL
				,UpdatedById = @UserId
				,UpdatedTime = @ServerTimeStamp
		WHERE BusinessUnitId = @BusinessUnitId AND  
			(@CustomerId = 0 OR CustomerId = @CustomerId) AND
			Status = @WorkListStatusHibernation AND
		    (DATEDIFF(DD, NextWorkDate, @NextBusinessDate) >= 0)

END

GO
