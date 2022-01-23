SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[RunPostMergeActivities]
(
@CreatedTime datetimeoffset
,@UserId bigint
,@BatchSizeForConstraintCreation int
)
as
DECLARE @sql NVARCHAR(max)='';
set @sql ='declare @max bigint;'
select @sql =  @sql + 'select @max=IsNull(max([Id]),0) from ' +  tableName + '; update Mig_LWTables set MaxId=@max where tableName=''' + tableName + ''';'
from Mig_LWTables
EXEC sp_executesql @sql;
update Mig_Constraints set IsMerged = 0,UpdatedById = @UserId,UpdatedTime = @CreatedTime; 
exec ReSeedDB 1,'lw',@UserId,@BatchSizeForConstraintCreation;
exec ResetAllIdentity 1;
DECLARE @Number bigint;
IF EXISTS(SELECT Number FROM CreditProfiles)
BEGIN
SELECT @Number = ISNULL(MAX(CONVERT(bigint,Number)),0) FROM CreditProfiles
SET @Number=@Number+1
SET @sql = 'IF EXISTS (SELECT * FROM sys.sequences s WHERE s.name =''CreditProfile'') BEGIN ALTER SEQUENCE CreditProfile RESTART WITH ' + CONVERT(NVARCHAR(20),@Number) + ' INCREMENT BY 1 END'
EXEC sp_executesql @sql
END
IF EXISTS(SELECT SequenceNumber FROM CPUContracts)
BEGIN
SELECT @Number = ISNULL(MAX(CONVERT(bigint,SequenceNumber)),0) FROM CPUContracts
SET @Number=@Number+1
SET @sql = 'IF EXISTS (SELECT * FROM sys.sequences s WHERE s.name =''CPUContract'') BEGIN ALTER SEQUENCE CPUContract RESTART WITH ' + CONVERT(NVARCHAR(20),@Number) + ' INCREMENT BY 1 END'
EXEC sp_executesql @sql
END
IF EXISTS(SELECT UniqueIdentificationNumber FROM InsurancePolicies)
BEGIN
SELECT @Number = ISNULL(MAX(CONVERT(bigint,UniqueIdentificationNumber)),0) FROM InsurancePolicies
SET @Number=@Number+1
SET @sql = 'IF EXISTS (SELECT * FROM sys.sequences s WHERE s.name =''InsurancePolicy'') BEGIN ALTER SEQUENCE InsurancePolicy RESTART WITH ' + CONVERT(NVARCHAR(20),@Number) + ' INCREMENT BY 1 END'
EXEC sp_executesql @sql
END
IF EXISTS(SELECT Number FROM Receipts)
BEGIN
SELECT @Number = ISNULL(MAX(CONVERT(bigint,Number)),0) FROM Receipts
SET @Number=@Number+1
SET @sql = 'IF EXISTS (SELECT * FROM sys.sequences s WHERE s.name =''Receipt'') BEGIN ALTER SEQUENCE Receipt RESTART WITH ' + CONVERT(NVARCHAR(20),@Number) + ' INCREMENT BY 1 END'
EXEC sp_executesql @sql
END
SELECT @Number = ISNULL(MAX(CONVERT(bigint,Number)),0) FROM ReceivableInvoices
SET @Number=@Number+1
SET @sql = 'IF EXISTS (SELECT * FROM sys.sequences s WHERE s.name =''InvoiceNumberGenerator'') BEGIN ALTER SEQUENCE InvoiceNumberGenerator RESTART WITH ' + CONVERT(NVARCHAR(20),@Number) + ' INCREMENT BY 1 END'
EXEC sp_executesql @sql

EXEC UpdateAssetStausAfterMerge @UserId, @CreatedTime;
--TODO: Rebuild all indexes

GO
