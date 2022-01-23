SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateCreditPaynets]
(
@Customer bigint,
@PaynetDirectDetailId bigint,
@CreditProfileId bigint,
@CreatedById bigint,
@CommaSeperatedPaynetIDs nvarchar(max),
@CreatedTime DATETIMEOFFSET
)
As
IF  @PaynetDirectDetailId > 0
BEGIN
INSERT INTO CreditPaynets (CreatedById,CreatedTime,UpdatedById,UpdatedTime,PaynetDirectDetailId,CreditProfileId)
SELECT
@CreatedById AS CreatedById,
@CreatedTime AS CreatedTime,
NULL,
NULL,
@PaynetDirectDetailId AS PaynetDirectDetailId,
Id AS CreditProfileId
FROM
CreditProfiles
WHERE CustomerId = @Customer and Id != @CreditProfileId
END
SELECT DISTINCT PaynetDirectDetailId,@CreditProfileId AS CreditProfileId INTO #PaynetDetail
FROM CreditPaynets
JOIN CreditProfiles ON CreditPaynets.CreditProfileId=CreditProfiles.Id
WHERE CustomerId=@Customer AND PaynetDirectDetailId NOT IN (SELECT PaynetDirectDetailId FROM CreditPaynets WHERE CreditProfileId = @CreditProfileId)  AND PaynetDirectDetailId NOT IN   (SELECT Id FROM ConvertCSVToBigIntTable(@CommaSeperatedPaynetIDs,','))
INSERT INTO CreditPaynets (CreatedById,CreatedTime,UpdatedById,UpdatedTime,PaynetDirectDetailId,CreditProfileId)
SELECT
@CreatedById AS CreatedById,
@CreatedTime AS CreatedTime,
NULL,
NULL,
PaynetDirectDetailId,
CreditProfileId
FROM
#PaynetDetail
DROP TABLE #PaynetDetail
DELETE FROM PaynetDirectLOS WHERE Id IN (SELECT PaynetDirectLOS.Id FROM PaynetDirectLOS
INNER JOIN PaynetDirectDetails
ON PaynetDirectDetails.Id = PaynetDirectLOS.PaynetDirectDetailId
WHERE
PaynetDirectLOS.IsActive = 0)

GO
