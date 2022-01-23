SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateCreditBureauDirectConsumerRequest]
(
@NewlyAddedCreditBureauConsumerDetailInfo NewlyAddedCreditBureauConsumerDetailInfo ReadOnly,
@CreditProfileId bigint,
@CreatedById bigint,
@CreatedTime DATETIMEOFFSET
)
As

SELECT * INTO #NewCBs FROM @NewlyAddedCreditBureauConsumerDetailInfo
IF  (SELECT COUNT(*) FROM #NewCBs) > 0
BEGIN
INSERT INTO CreditBureauDirectConsumerRequests(CreatedById,CreatedTime,CreditProfileId,Isvalid,RelationshipType,CreditBureauConsumerDetailId)
SELECT
@CreatedById AS CreatedById,
@CreatedTime AS CreatedTime,
Id AS CreditProfileId,
1,
'PrimaryCustomer',
#NewCBs.CreditBureauConsumerDetailId
FROM
CreditProfiles
JOIN #NewCBs ON CreditProfiles.CustomerId = #NewCBs.CustomerId
WHERE  Id != @CreditProfileId 


SELECT #NewCBs.CustomerId,CTP.CreditProfileId,MIN(CTPR.RelationshipType) AS RealationshipType,#NewCBs.CreditBureauConsumerDetailId
INTO #ThirdPartyRequestToInsert
FROM CreditProfileThirdPartyRelationships CTP
JOIN CustomerThirdPartyRelationships CTPR ON CTP.ThirdPartyRelationshipId = CTPR.Id
JOIN #NewCBs ON CTPR.ThirdPartyId = #NewCBs.CustomerId
WHERE CTP.CreditProfileId != @CreditProfileId
GROUP BY  #NewCBs.CustomerId,CTP.CreditProfileId,#NewCBs.CreditBureauConsumerDetailId

INSERT INTO CreditBureauDirectConsumerRequests(CreatedById,CreatedTime,CreditProfileId,Isvalid,RelationshipType,CreditBureauConsumerDetailId)
SELECT
@CreatedById AS CreatedById,
@CreatedTime AS CreatedTime,
#ThirdPartyRequestToInsert.CreditProfileId AS CreditProfileId,
1,
#ThirdPartyRequestToInsert.RealationshipType,
#ThirdPartyRequestToInsert.CreditBureauConsumerDetailId
FROM #ThirdPartyRequestToInsert

DROP TABLE #ThirdPartyRequestToInsert
END

DROP TABLE #NewCBs

GO
