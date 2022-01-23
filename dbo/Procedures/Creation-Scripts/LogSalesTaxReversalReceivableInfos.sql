SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LogSalesTaxReversalReceivableInfos]
(
@ReceivableTaxIds ReceivableTaxIdCollection Readonly,
@CustomerInfoMessage NVARCHAR(MAX),
@LeaseInfoMessage NVARCHAR(MAX),
@LoanInfoMessage NVARCHAR(MAX),
@DiscountingInfoMessage NVARCHAR(MAX),
@NoReceivablesFoundMessage NVARCHAR(MAX),
@FromDate DATETIME,
@ToDate NVARCHAR(100),
@CUEntityType NVARCHAR(5),
@CTEntityType NVARCHAR(5),
@DTEntityType NVARCHAR(5),
@LeaseContractType NVARCHAR(20),
@LoanContractType NVARCHAR(20),
@CreatedById BIGINT,
@JobStepInstanceId BIGINT,
@InformationMessageType NVARCHAR(20)
)
AS
BEGIN
DECLARE @CustomerNumbers NVARCHAR(MAX);
WITH CTE_DistinctCustomerNames AS
(
SELECT DISTINCT CustomerName
FROM ReversalReceivableDetail_Extract  R
INNER JOIN @ReceivableTaxIds RT ON R.ReceivableTaxId = RT.ReceivableTaxId
WHERE EntityType = @CUEntityType AND ErrorCode IS NULL AND R.JobStepInstanceId = @JobStepInstanceId
)
SELECT @CustomerNumbers = COALESCE(@CustomerNumbers + ', ' ,'') +  CAST(CustomerName AS NVARCHAR(MAX))
FROM CTE_DistinctCustomerNames;
IF(@CustomerNumbers IS NOT NULL)
INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
VALUES(
REPLACE
(REPLACE
(REPLACE(@CustomerInfoMessage,'@FromDate', CAST(@FromDate AS DATE)),
'@ToDate',@ToDate),
'@CustomerNumbers',@CustomerNumbers)
,@InformationMessageType
,@CreatedById
,SYSDATETIMEOFFSET()
,@JobStepInstanceId);
DECLARE @LeaseUniqueIds NVARCHAR(MAX);
WITH CTE_DistinctLeaseUniqueIds AS
(
SELECT DISTINCT LeaseUniqueId
FROM ReversalReceivableDetail_Extract R
INNER JOIN @ReceivableTaxIds RT ON R.ReceivableTaxId = RT.ReceivableTaxId
WHERE EntityType = @CTEntityType AND ContractTypeValue = @LeaseContractType AND ErrorCode IS NULL AND R.JobStepInstanceId = @JobStepInstanceId
)
SELECT @LeaseUniqueIds = COALESCE(@LeaseUniqueIds + ', ' ,'') +  CAST(LeaseUniqueId AS NVARCHAR(MAX))
FROM CTE_DistinctLeaseUniqueIds;
IF(@LeaseUniqueIds IS NOT NULL)
INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
VALUES(
REPLACE
(REPLACE
(REPLACE(@LeaseInfoMessage,'@FromDate', CAST(@FromDate AS DATE)),
'@ToDate',@ToDate),
'@Leases',@LeaseUniqueIds)
,@InformationMessageType
,@CreatedById
,SYSDATETIMEOFFSET()
,@JobStepInstanceId);
DECLARE @LoanUniqueId NVARCHAR(MAX);
WITH CTE_DistinctLoanUniqueIds AS
(
SELECT DISTINCT LeaseUniqueId AS LoanUniqueId
FROM ReversalReceivableDetail_Extract R
INNER JOIN @ReceivableTaxIds RT ON R.ReceivableTaxId = RT.ReceivableTaxId
WHERE EntityType = @CTEntityType AND ContractTypeValue = @LoanContractType AND ErrorCode IS NULL AND R.JobStepInstanceId = @JobStepInstanceId
)
SELECT @LoanUniqueId = COALESCE(@LoanUniqueId + ', ' ,'') +  CAST(LoanUniqueId AS NVARCHAR(MAX))
FROM CTE_DistinctLoanUniqueIds;
IF(@LoanUniqueId IS NOT NULL)
INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
VALUES(
REPLACE
(REPLACE
(REPLACE(@LoanInfoMessage,'@FromDate', CAST(@FromDate AS DATE)),
'@ToDate',@ToDate),
'@Loans',@LoanUniqueId)
,@InformationMessageType
,@CreatedById
,SYSDATETIMEOFFSET()
,@JobStepInstanceId)
DECLARE @DiscountingSequenceNumbers NVARCHAR(MAX);
WITH CTE_DistinctDiscountingSequenceNumbers AS
(
SELECT DISTINCT SequenceNumber
FROM ReversalReceivableDetail_Extract R
INNER JOIN @ReceivableTaxIds RT ON R.ReceivableTaxId = RT.ReceivableTaxId
INNER JOIN Discountings D ON R.DiscountingId = D.Id
WHERE EntityType = @DTEntityType AND ErrorCode IS NULL AND  R.JobStepInstanceId = @JobStepInstanceId
)
SELECT @DiscountingSequenceNumbers = COALESCE(@DiscountingSequenceNumbers + ', ' ,'') +  CAST(SequenceNumber AS NVARCHAR(MAX))
FROM CTE_DistinctDiscountingSequenceNumbers;
IF(@DiscountingSequenceNumbers IS NOT NULL)
INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
VALUES(
REPLACE
(REPLACE
(REPLACE(@DiscountingInfoMessage,'@FromDate', CAST(@FromDate AS DATE)),
'@ToDate',@ToDate),
'@Discountings',@DiscountingSequenceNumbers)
,@InformationMessageType
,@CreatedById
,SYSDATETIMEOFFSET()
,@JobStepInstanceId);
IF EXISTS(
SELECT 1
FROM ReversalReceivableDetail_Extract R
INNER JOIN @ReceivableTaxIds RT ON R.ReceivableTaxId = RT.ReceivableTaxId
WHERE EntityType != @CTEntityType AND EntityType != @CUEntityType AND EntityType != @DTEntityType AND ErrorCode IS NULL AND R.JobStepInstanceId = @JobStepInstanceId
)
BEGIN
INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
SELECT
@NoReceivablesFoundMessage
,@InformationMessageType
,@CreatedById
,SYSDATETIMEOFFSET()
,@JobStepInstanceId
FROM ReversalReceivableDetail_Extract R
INNER JOIN @ReceivableTaxIds RT ON R.ReceivableTaxId = RT.ReceivableTaxId
WHERE EntityType != @CTEntityType AND EntityType != @CUEntityType AND EntityType != @DTEntityType AND ErrorCode IS NULL AND R.JobStepInstanceId = @JobStepInstanceId ;
END
END

GO
