SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateCreditBureauDirectBusinessRequest]
(
@NewlyAddedCreditBureauusinessDetailInfo NewlyAddedCreditBureauusinessDetailInfo ReadOnly,
@CreditProfileId bigint,
@CreatedById bigint,
@CreatedTime DATETIMEOFFSET
)
As

SELECT * INTO #NewCBs FROM @NewlyAddedCreditBureauusinessDetailInfo
IF  (SELECT COUNT(*) FROM #NewCBs) > 0
BEGIN
INSERT INTO CreditBureauDirectBusinessRequests(CreatedById,CreatedTime,CreditProfileId,Isvalid,RelationshipType,CreditBureauBusinessDetailId)
SELECT
@CreatedById AS CreatedById,
@CreatedTime AS CreatedTime,
Id AS CreditProfileId,
1,
'PrimaryCustomer',
#NewCBs.CreditBureauBusinessDetailId
FROM
CreditProfiles
JOIN #NewCBs ON CreditProfiles.CustomerId = #NewCBs.CustomerId
WHERE  Id != @CreditProfileId 


SELECT #NewCBs.CustomerId,CTP.CreditProfileId,MIN(CTPR.RelationshipType) AS RealationshipType,#NewCBs.CreditBureauBusinessDetailId
INTO #ThirdPartyRequestToInsert
FROM CreditProfileThirdPartyRelationships CTP
JOIN CustomerThirdPartyRelationships CTPR ON CTP.ThirdPartyRelationshipId = CTPR.Id
JOIN #NewCBs ON CTPR.ThirdPartyId = #NewCBs.CustomerId
WHERE CTP.CreditProfileId != @CreditProfileId
GROUP BY  #NewCBs.CustomerId,CTP.CreditProfileId,#NewCBs.CreditBureauBusinessDetailId

INSERT INTO CreditBureauDirectBusinessRequests(CreatedById,CreatedTime,CreditProfileId,Isvalid,RelationshipType,CreditBureauBusinessDetailId)
SELECT
@CreatedById AS CreatedById,
@CreatedTime AS CreatedTime,
#ThirdPartyRequestToInsert.CreditProfileId AS CreditProfileId,
1,
#ThirdPartyRequestToInsert.RealationshipType,
#ThirdPartyRequestToInsert.CreditBureauBusinessDetailId
FROM #ThirdPartyRequestToInsert

DROP TABLE #ThirdPartyRequestToInsert
END

DROP TABLE #NewCBs

GO
