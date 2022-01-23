SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreditFactSheetLCReport]
(
@CreditProfileId BIGINT,
@PartyId BigInt,
@Business NVARCHAR(20),
@Principal NVARCHAR(20)
)
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON
SELECT TOP 1 CreditBureauRequests.Id
,CASe WHEN BusinessBureauScore='I' THEN NULL ELSE BusinessBureauScore END  AS CBScore
,TotalScore
,CreditProfileId
,NULL as AppScore
,CASE WHEN CreditBureauConfigs.Code='I' THEN NULL ELSE CreditBureauConfigs.Code END AS BusReport
INTO #CreditBureauRequestTable
FROM CreditBureauRqstBusinesses
join CreditBureauRequests on CreditBureauRqstBusinesses.CreditBureauRequestId=CreditBureauRequests.Id
join CreditBureauConfigs on CreditBureauRqstBusinesses.CustomerCreditBureauId=CreditBureauConfigs.Id
WHERE CreditProfileId= @CreditProfileId
And CreditBureauRqstBusinesses.IsDefault=1
And (CreditBureauRequests.DataRequestStatus = 'Failed' OR CreditBureauRequests.DataRequestStatus = 'NeedsReview' OR CreditBureauRequests.DataRequestStatus = 'Completed')
ORDER BY CreditBureauRequests.Id DESC
IF EXISTS (SELECT Id FROM  #CreditBureauRequestTable)
BEGIN
SELECT @Business AS CustomerType
,CBScore
,CASE WHEN TotalScore = (SELECT Value FROM GlobalParameters WHERE Name = 'CreditScoreUndefinedIndicator' AND Category = 'CreditRAC' AND IsActive=1) THEN NULL ELSE TotalScore END AS TotalScore
,AppScore
,BusReport
FROM #CreditBureauRequestTable
UNION
SELECT 'Principal '+Convert(nvarchar(20),ROW_NUMBER() OVER(ORDER BY CreditBureauRqstConsumers.Id ASC)) AS CustomerType
, CASE WHEN CreditBureauRqstConsumers.CBScore = 'I' THEN NULL ELSE CreditBureauRqstConsumers.CBScore END AS CBScore
,CASE WHEN CreditBureauRqstConsumers.TotalScore =  (SELECT Value FROM GlobalParameters WHERE Name = 'CreditScoreUndefinedIndicator' AND Category = 'CreditRAC' AND IsActive=1) THEN NULL ELSE CreditBureauRqstConsumers.TotalScore END AS TotalScore
,CASE WHEN CreditBureauRqstConsumers.TotalScore =  (SELECT Value FROM GlobalParameters WHERE Name = 'CreditScoreUndefinedIndicator' AND Category = 'CreditRAC' AND IsActive=1) THEN NULL ELSE CreditBureauRqstConsumers.TotalScore END AS AppScore
,CASE WHEN CreditBureauConfigs.Code ='I' THEN NULL ELSE CreditBureauConfigs.Code END AS BusReport
FROM CreditBureauRqstConsumers
INNER JOIN #CreditBureauRequestTable
ON CreditBureauRqstConsumers.CreditBureauRequestId= #CreditBureauRequestTable.Id
INNER JOIN CreditBureauConfigs on CreditBureauRqstConsumers.ConsumerCreditBureauId=CreditBureauConfigs.Id
END
ELSE
BEGIN
CREATE TABLE #ThirdPartiesTempTable
(
CustomerType NVARCHAR(50),
CBScore NVARCHAR(40),
TotalScore DECIMAL(5,2),
AppScore DECIMAL(5,2),
BusReport NVARCHAR(8)
);
INSERT INTO #ThirdPartiesTempTable VALUES(@Business,null,null,null,null)
INSERT INTO #ThirdPartiesTempTable VALUES(@Principal+'1',null,null,null,null)
INSERT INTO #ThirdPartiesTempTable VALUES(@Principal+'2',null,null,null,null)
SELECT
CustomerType
,TotalScore
,CBScore
,AppScore
,BusReport
FROM #ThirdPartiesTempTable
DROP TABLE #ThirdPartiesTempTable
END
DROP TABLE #CreditBureauRequestTable

GO
