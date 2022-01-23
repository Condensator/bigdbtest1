SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[UpdateAuthorityLimitForApproveOnBehalfOf]
(
@LimitAmount decimal(24,2),
@UserId BigInt
)
AS
--Declare @UserId int ;
--set @UserId = 5
--Declare @LimitAmount decimal(24,2);
--set @LimitAmount = 99999999999999999900
Begin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN
Update ApproveOnBehalfOfs set Limit_Amount = @LimitAmount where ApproveOnBehalfOfUserId = @UserId
END
END

GO
