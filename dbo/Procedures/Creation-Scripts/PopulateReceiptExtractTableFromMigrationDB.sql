SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PopulateReceiptExtractTableFromMigrationDB]
(  
 @CreatedById BIGINT,
 @CreatedTime DATETIMEOFFSET , 
 @JobStepInstanceId BIGINT ,
 @ToolIdentifier BIGINT
)
AS  

BEGIN

DECLARE @TotalRecordsCount BIGINT;  
SELECT @TotalRecordsCount= IsNull(COUNT(Id), 0) from stgReceipt where IsMigrated=0  AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) 
PRINT CAST(@TotalRecordsCount AS NVARCHAR(10)) + ' records will be migrated'

IF(@TotalRecordsCount>0)
BEGIN
INSERT INTO [ReceiptMigration_Extract] 
(
ReceiptMigrationId
,ContractSequenceNumber
,LegalEntityNumber
,CheckNumber
,ReceiptAmount_Amount
,ReceiptAmount_Currency
,PostDate
,IsPureUnallocatedCash
,TotalAmountToApply_Amount
,TotalAmountToApply_Currency
,TotalTaxAmountToApply_Amount
,TotalTaxAmountToApply_Currency
,CashTypeName
,CurrencyCode
,BankAccountNumber
,BankAccountBranchName
,BankAccountBankName
,BankName
,ReceiptGLTemplateName
,ReceiptTypeName
,ReceivedDate
,IsValid
,IsProcessed
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,[UniqueIdentifier]
,JobStepInstanceId
,Comment)
SELECT 
Id
,ContractSequenceNumber
,LegalEntityNumber
,CheckNumber
,ReceiptAmount_Amount
,ReceiptAmount_Currency
,PostDate
,IsPureUnallocatedCash
,TotalAmountToApply_Amount
,TotalAmountToApply_Currency
,TotalTaxAmountToApply_Amount
,TotalTaxAmountToApply_Currency
,CashTypeName
,CurrencyCode
,BankAccountNumber
,BankAccountBranchName
,BankAccountBankName
,BankName
,ReceiptGLTemplateName
,ReceiptTypeName
,ReceivedDate
,1
,0
,@CreatedById
,@CreatedTime
,NULL
,NULL
,[UniqueIdentifier]
,@JobStepInstanceId
,Comment
FROM stgReceipt
WHERE IsMigrated=0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) 

INSERT INTO [dbo].[ReceiptReceivableDetailMigration_Extract] 
(
ReceiptReceivableMigrationId
,PaymentNumber
,ReceivableType
,FunderPartyNumber
,PaymentType
,DueDate
,AmountToApply_Amount
,AmountToApply_Currency
,TaxAmountToApply_Amount
,TaxAmountToApply_Currency
,ReceiptMigrationId
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,JobStepInstanceId)
SELECT
sRR.Id
,PaymentNumber
,ReceivableType
,FunderPartyNumber
,PaymentType
,DueDate
,AmountToApply_Amount
,AmountToApply_Currency
,TaxAmountToApply_Amount
,TaxAmountToApply_Currency
,ReceiptId
,@CreatedById
,@CreatedTime
,NULL
,NULL
,@JobStepInstanceId
FROM stgReceiptReceivable sRR
INNER JOIN stgReceipt sR ON sRR.ReceiptId=sR.Id
WHERE sR.IsMigrated=0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) 

END
END

GO
