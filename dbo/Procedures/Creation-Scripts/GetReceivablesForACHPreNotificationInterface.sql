SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceivablesForACHPreNotificationInterface] (@FromDate int, @ToDate int, @UserId BigInt, @UpdatedTime DateTimeOffset)
AS
IF OBJECT_ID('tempdb..#ReceivableDetailIds') IS NOT NULL DROP Table #ReceivableDetailIds;
IF OBJECT_ID('tempdb..#PreAchScheduleDetails') IS NOT NULL DROP Table #PreAchScheduleDetails;
IF OBJECT_ID('tempdb..#ACHPreNotificationDetails') IS NOT NULL DROP Table ACHPreNotificationDetails;
--IF OBJECT_ID('tempdb..#ReceivableDetailIds') IS NOT NULL DROP Table ReceivableDetailIds;
--IF OBJECT_ID('tempdb..#BillToLevelACHPreNotificationDetails') IS NOT NULL DROP Table #BillToLevelACHPreNotificationDetails;
--IF OBJECT_ID('tempdb..#ContractLevelACHPreNotificationDetails') IS NOT NULL DROP Table #ContractLevelACHPreNotificationDetails;
BEGIN
SET NOCOUNT ON;
--DECLARE @UpdatedTime DateTimeOffset;
--DECLARE @FromDate Int, @ToDate Int;
--DECLARE @UserId BIGINT;
--Set @UpdatedTime = SYSDATETIMEOFFSET();
--set @FromDate=2
--Set @ToDate=50
--Set @UserId = 40419
SELECT
ContractId= Contract.Id
,BankAccountId=BankAccounts.Id
,SequenceNumber=Contract.SequenceNumber
,ACHAmount=Receivable.TotalEffectiveBalance_Amount
,SettlementDate =CONVERT(nvarchar(10),ACHSchedule.SettlementDate,101)
,AccountNumber = '' --Encryption change
,FromEmailAddress=RemitToes.DefaultFromEmail
,IsPrivateLabel=Receivable.IsPrivateLabel
,ReceivableId=Receivable.Id
--,ACHScheduleId = ACHSchedule.Id
INTO #ReceivableDetailIds
FROM Contracts Contract
INNER JOIN ACHSchedules ACHSchedule ON ACHSchedule.ContractBillingId=Contract.Id
AND ACHSchedule.IsActive=1
INNER JOIN Receivables Receivable ON ACHSchedule.ReceivableId=Receivable.Id
AND Contract.Id=Receivable.EntityId
AND Receivable.IsActive=1
INNER JOIN BankAccounts ON ACHSchedule.ACHAccountId = BankAccounts.Id
LEFT JOIN RemitToes ON RemitToes.Id=Receivable.RemitToId
WHERE
Receivable.DueDate >= Convert(DATE,DATEADD(dd,@FromDate,GetDate()))
AND Receivable.DueDate <= Convert(DATE,DATEADD(dd,@ToDate,GetDate()))
AND ( ACHSchedule.Status = 'Pending')
AND ACHSchedule.IsPreACHNotificationCreated = 0
AND Receivable.TotalEffectiveBalance_Amount >0
;
WITH CTE_ReceivableDetails AS(
SELECT
ContractId
,SequenceNumber
,BankAccountId
,ACHAmount=SUM(ACHAmount)
,SettlementDate
--,AccountNumber = '' --Encryption change
,FromEmailAddress
,IsPrivateLabel
--,ACHScheduleId
FROM #ReceivableDetailIds
GROUP BY
#ReceivableDetailIds.ContractId
,#ReceivableDetailIds.SequenceNumber
,#ReceivableDetailIds.SettlementDate
--,BankAccounts.AccountNumber  (Encryption changes)
,#ReceivableDetailIds.FromEmailAddress
,#ReceivableDetailIds.IsPrivateLabel
,#ReceivableDetailIds.BankAccountId
--,#ReceivableDetailIds.ACHScheduleId
),
CTE_LegalEntity AS
(
SELECT
LegalEntityId,
FromEmailAddress,
PhoneNumber
FROM
(
SELECT
LegalEntityId=LegalEntities.Id,
FromEmailAddress = LegalEntityContacts.EMailId,
PhoneNumber=LegalEntityContacts.PhoneNumber1,
RANK=ROW_NUMBER() OVER(PARTITION BY LegalEntities.Id ORDER BY LegalEntityContacts.Id desc)
FROM LegalEntities
INNER JOIN LegalEntityContacts ON LegalEntities.Id = LegalEntityContacts.LegalEntityId
AND  LegalEntityContacts.IsActive = 1
AND  LegalEntities.Status='Active'
)
AS TEMP WHERE TEMP.RANK=1
),
CTE_Contracts AS
(
SELECT
ContractId=Contracts.Id,
SequenceNumber=Contracts.SequenceNumber,
CustomerId=LeaseFinances.CustomerId,
BillToId=Contracts.BillToId,
SyndicationType=Contracts.SyndicationType,
LegalEntityId=LeaseFinances.LegalEntityId,
ContractOriginationId=LeaseFinances.ContractOriginationId
FROM Contracts
INNER JOIN LeaseFinances LeaseFinances ON LeaseFinances.ContractId=Contracts.Id AND LeaseFinances.IsCurrent=1
UNION ALL
SELECT
ContractId=Contracts.Id,
SequenceNumber=Contracts.SequenceNumber,
CustomerId=LoanFinances.CustomerId,
BillToId=Contracts.BillToId,
SyndicationType=Contracts.SyndicationType,
LegalEntityId=LoanFinances.LegalEntityId,
ContractOriginationId=LoanFinances.ContractOriginationId
FROM Contracts
INNER JOIN LoanFinances ON LoanFinances.ContractId=Contracts.Id AND LoanFinances.IsCurrent=1
),
CTE_ContractsWithACH AS
(
--SELECT
--  ContractId
--  ,Contract_PreNotificationFlag
--  ,Contract_PreACHNotificationEmailAddress
--  ,Contract_EmailTemplateId
--  ,CustomerId
--  ,Customer_PreNotificationFlag
--  ,Customer_PreACHNotificationEmailAddress
--  ,Customer_EmailTemplateId
--  ,BillToId
--  ,BillTo_PreNotificationFlag
--  ,BillTo_PreACHNotificationEmailAddress
--  ,BillTo_EmailTemplateId
--FROM
--(
SELECT
ContractId=CTE_Contracts.ContractId,
Contract_PreNotificationFlag = ContractBilling.IsPreACHNotification,
Contract_PreACHNotificationEmailAddress=ISNULL(ContractBilling.PreACHNotificationEmail,''),
Contract_EmailTemplateId=ISNULL(ContractBilling.PreACHNotificationEmailTemplateId,''),
CustomerId =  Customers.Id,
Customer_PreNotificationFlag = Customers.IsPreACHNotification,
Customer_PreACHNotificationEmailAddress = IsNull (Customers.PreACHNotificationEmailTo,''),
Customer_EmailTemplateId = Customers.PreACHNotificationEmailTemplateId,
BillToId = BillToes.Id,
BillTo_PreNotificationFlag = BillToes.IsPreACHNotification,
BillTo_PreACHNotificationEmailAddress = IsNull (BillToes.PreACHNotificationEmailTo,''),
BillTo_EmailTemplateId = IsNull (BillToes.PreACHNotificationEmailTemplateId,'')
FROM CTE_Contracts
INNER JOIN Parties Party ON Party.Id=CTE_Contracts.CustomerId
INNER JOIN Customers ON Party.Id=Customers.Id
INNER JOIN ContractBillings ContractBilling ON CTE_Contracts.ContractId =ContractBilling.Id AND ContractBilling.IsActive = 1
INNER JOIN BillToes ON BillToes.Id=CTE_Contracts.BillToId AND BillToes.IsActive=1
WHERE ContractBilling.IsPreACHNotification=1  OR Customers.IsPreACHNotification=1 OR BillToes.IsPreACHNotification=1
--) AS Temp
--WHERE Temp.Contract_PreNotificationFlag=1  OR Temp.Customer_PreNotificationFlag=1 OR Temp.BillTo_PreNotificationFlag =1
)
SELECT
CustomerId = CTE_ContractsWithACH.CustomerId,
BillToId = CTE_ContractsWithACH.BillToId,
ContractId = CTE_ContractsWithACH.ContractId,
--AchScheduleId = ReceivableDetail.AchScheduleId,
SequenceNumber=ReceivableDetail.SequenceNumber
,BankAccountId=ReceivableDetail.BankAccountId
,ACHAmount=ReceivableDetail.ACHAmount
,SettlementDate=CONVERT(nvarchar(10),ReceivableDetail.SettlementDate,101)
,PhoneNumber=CTE_LegalEntity.PhoneNumber
,LegalEntityId=CTE_LegalEntity.LegalEntityId
,CustomerNumber=Party.PartyNumber
,CTE_ContractsWithACH.Contract_PreNotificationFlag
,CTE_ContractsWithACH.Contract_PreACHNotificationEmailAddress
,CTE_ContractsWithACH.Contract_EmailTemplateId
,CTE_ContractsWithACH.Customer_PreNotificationFlag
,CTE_ContractsWithACH.Customer_PreACHNotificationEmailAddress
,CTE_ContractsWithACH.Customer_EmailTemplateId
,CTE_ContractsWithACH.BillTo_PreNotificationFlag
,CTE_ContractsWithACH.BillTo_PreACHNotificationEmailAddress
,CTE_ContractsWithACH.BillTo_EmailTemplateId
,CustomerName=CAST(
CASE
WHEN Party.IsCorporate =1
THEN Party.CompanyName
ELSE
Party.PartyName
END AS NVARCHAR
)
--,CustomerEmailAddress=CTE_ContractsWithACH.CustomerEmailAddress
,FromEmailAddress=ReceivableDetail.FromEmailAddress
,PrivateLabelFlag=CAST(
CASE
WHEN ReceivableDetail.IsPrivateLabel =1
THEN '1'
ELSE '0'
END AS nvarchar
)
,Contract_EmailTemplateName=EmailTemplates.Name
,Customer_EmailTemplateName = ETFC.Name
,BillTo_EmailTemplateName = ETFB.Name
,IsPreACHNotificationSent = 0
INTO #PreAchScheduleDetails
FROM CTE_ReceivableDetails ReceivableDetail
INNER JOIN CTE_ContractsWithACH ON CTE_ContractsWithACH.ContractId=ReceivableDetail.ContractId
LEFT JOIN CTE_Contracts ON CTE_Contracts.ContractId=CTE_ContractsWithACH.ContractId
LEFT JOIN Parties Party ON Party.Id=CTE_Contracts.CustomerId
LEFT JOIN Customers ON Party.Id=Customers.Id
LEFT JOIN CTE_LegalEntity ON CTE_Contracts.LegalEntityId=CTE_LegalEntity.LegalEntityId
LEFT JOIN EmailTemplates ON CTE_ContractsWithACH.Contract_EmailTemplateId=EmailTemplates.Id
LEFT JOIN EmailTemplates ETFC ON CTE_ContractsWithACH.Customer_EmailTemplateId=ETFC.Id
LEFT JOIN EmailTemplates ETFB ON CTE_ContractsWithACH.BillTo_EmailTemplateId=ETFB.Id
CREATE TABLE #ACHPreNotificationDetails
(
GroupId BIGINT,
CustomerId    BIGINT,
ContractId   BIGINT NULL,
BillToId  BIGINT NULL,
GroupingLevel NVARCHAR(2),
BankAccountId BIGINT,
LegalEntityId BIGINT,
CustomerNumber NVARCHAR(40),
SequenceNumber NVARCHAR(80),
--,AchScheduleId
ACHAmount DECIMAL(16,2),
--AccountNumber  NVARCHAR(100),
SettlementDate DATE,
PhoneNumber NVARCHAR(30),
ToEmailAddress NVARCHAR(500),
EmailTemplateName NVARCHAR(200),
IsPrivateLabel BIT,
)
-- select * from #PreAchScheduleDetails
INSERT INTO #ACHPreNotificationDetails
SELECT DENSE_RANK() OVER (ORDER BY CustomerId) AS
GroupId,
CustomerId,
ContractId =null,
BillToId=null,
GroupingLevel='CU',
BankAccountId,
LegalEntityId,
CustomerNumber,
SequenceNumber,
--,AchScheduleId
ACHAmount,
--AccountNumber,
SettlementDate,
PhoneNumber,
Customer_PreACHNotificationEmailAddress AS ToEmailAddress,
Customer_EmailTemplateName AS EmailTemplateName,
PrivateLabelFlag AS IsPrivateLabel
-- Into  #CustomerLevelACHPreNotificationDetails
FROM #PreAchScheduleDetails  WHERE Customer_PreNotificationFlag =1 AND IsPreACHNotificationSent = 0 ORDER BY CustomerId
UPDATE #PreAchScheduleDetails SET IsPreACHNotificationSent = 1 where CustomerId IN (select CustomerId FROM #PreAchScheduleDetails WHERE Customer_PreNotificationFlag = 1 )
INSERT INTO #ACHPreNotificationDetails
SELECT DENSE_RANK() OVER (ORDER BY BillToId) AS
GroupId,
CustomerId,
ContractId=null,
BillToId,
GroupingLevel='BT',
BankAccountId,
LegalEntityId,
CustomerNumber,
SequenceNumber,
--,AchScheduleId
ACHAmount,
--AccountNumber,
SettlementDate,
PhoneNumber,
BillTo_PreACHNotificationEmailAddress AS ToEmailAddress,
BillTo_EmailTemplateName AS EmailTemplateName,
PrivateLabelFlag  AS IsPrivateLabel
FROM #PreAchScheduleDetails  WHERE BillTo_PreNotificationFlag =1  AND IsPreACHNotificationSent = 0 ORDER BY BillToId
UPDATE #PreAchScheduleDetails SET IsPreACHNotificationSent = 1 WHERE BillToId IN (SELECT BillToId FROM #PreAchScheduleDetails WHERE BillTo_PreNotificationFlag = 1 )
INSERT INTO #ACHPreNotificationDetails
SELECT DENSE_RANK() OVER (ORDER BY ContractId) AS
GroupId,
CustomerId,
ContractId,
BillToId,
GroupingLevel='CT',
BankAccountId,
LegalEntityId,
CustomerNumber,
SequenceNumber,
--,AchScheduleId
ACHAmount,
--AccountNumber,
SettlementDate,
PhoneNumber,
Contract_PreACHNotificationEmailAddress AS ToEmailAddress,
Contract_EmailTemplateName AS EmailTemplateName,
PrivateLabelFlag AS IsPrivateLabel
-- into #ACHPreNotificationDetails
FROM #PreAchScheduleDetails  WHERE Contract_PreNotificationFlag =1  AND IsPreACHNotificationSent = 0 ORDER BY ContractId
SELECT * FROM  #ACHPreNotificationDetails
--UPDATE #PreAchScheduleDetails set IsPreACHNotificationSent = 1 where ContractId in (select ContractId from #PreAchScheduleDetails where Contract_PreNotificationFlag = 1 )
--SELECT * FROM #CustomerLevelACHPreNotificationDetails
--SELECT * FROM #BillToLevelACHPreNotificationDetails
--SELECT * FROM #ContractLevelACHPreNotificationDetails
SELECT ReceivableId FROM #ReceivableDetailIds
END

GO
