SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UnAssignThirdPartyAssignmentForInactiveCustomer]
(
@PartyId BIGINT
,@UpdatedById bigint
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
DECLARE @DeactivationDate DATETIME = CAST(GETDATE() AS DATE)
UPDATE CustomerThirdPartyRelationships
SET  IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM CustomerThirdPartyRelationships CTPR
WHERE CTPR.IsActive = 1
AND CTPR.ThirdPartyId = @PartyId
END

GO
