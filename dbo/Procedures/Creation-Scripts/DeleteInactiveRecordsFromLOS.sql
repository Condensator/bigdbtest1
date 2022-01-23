SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create  PROCEDURE [dbo].[DeleteInactiveRecordsFromLOS]
(
@CreditBureauRqstBusinessId BIGINT
)
AS
BEGIN
SET NOCOUNT ON
Delete from CreditBureauRqstBusinessLOS where IsActive=0 and CreditBureauRqstBusinessId=@CreditBureauRqstBusinessId
END

GO
