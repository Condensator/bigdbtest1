SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [dbo].[CreateDomainSequences]
AS

IF NOT EXISTS (SELECT 1 FROM  sys.sequences WHERE name = 'InvoiceNumberGenerator')
BEGIN
CREATE SEQUENCE InvoiceNumberGenerator START WITH  1 INCREMENT BY 1
END;

IF NOT EXISTS (SELECT 1 FROM  sys.sequences WHERE name = 'ReceiptExtractSequenceGenerator')
BEGIN
DECLARE @MinJobStepInstanceId BIGINT;
SET @MinJobStepInstanceId = (SELECT ISNULL(MIN(JobStepInstanceId) * (-1),0) + 1 FROM Receipts_Extract WHERE JobStepInstanceId < 0)
DECLARE @CreateSequenceQuery NVARCHAR(1000) = N'
	CREATE SEQUENCE ReceiptExtractSequenceGenerator
    AS BIGINT 
    START WITH '+ CAST(@MinJobStepInstanceId AS NVARCHAR)+ '
    INCREMENT BY 1  
;'
EXEC sp_executesql  @CreateSequenceQuery
END;

declare @Modules NVARCHAR(Max),
@Module NVARCHAR(500),
@Sql NVARCHAR(MAX) = '',
@Startcount BIGINT;
--Set module names 
set @Modules = 'Location,AppraisalRequest,CreditProfile,Opportunity,CPIContract,PaymentVoucher,Receipt,Payoff,AVNotice,PPTInvoice,LeveragedLeasePayoff,JudgementDetail,AgencyLegalPlacement,LegalRelief,OutBoundCheckInterfaceParam,RMAProfile,PropertyTaxExport,CommissionPackage,PlanFamily,PlanBasis,PlanBasisAdminCharge,PlanBasisPayout,PlanBasisFreeCash,LienFiling,ShellCustomerContact,PlateUniqueNumber,Driver,Party,Branch,QuoteRequest,LegalEntityAddress,LegalEntityContact,AssetTypeTaxDepreciation,RemitToWireDetail,CorporateTaxRate,BankAccount,LoanPaydown,InsurancePolicy,DiscountingPaydown,CPUContract,CPUTransaction,DiscountingAmendment,ReceiptExtractIdentifier,SalesTaxJobStepInstanceIdentifier'

--Loop through module names
while len(@Modules) > 0
begin
  set @Module = left(@Modules, charindex(',', @Modules+',')-1)
  --Check if sequence already exists
  IF NOT EXISTS (SELECT NAME FROM sys.sequences WHERE NAME = @Module)  
	BEGIN  
    SET @StartCount = (SELECT NEXT FROM SequenceGenerators WHERE Module = @Module) 
	IF @StartCount IS NULL
	SET @StartCount = 0
    SET @Sql = CONCAT(@Sql, 'CREATE SEQUENCE [' + @Module + '] AS BIGINT START WITH ' + CAST((@StartCount+1) AS VARCHAR(MAX)) + ' INCREMENT BY 1 ') + CHAR(10)
	END  
  set @Modules = stuff(@Modules, 1, charindex(',', @Modules+','), '')
end

IF @Sql <> ''
	EXEC sp_executesql @Sql


GO
