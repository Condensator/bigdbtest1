SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVendorCreditApplicationReportTemplate]
(
 @val [dbo].[VendorCreditApplicationReportTemplate] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[VendorCreditApplicationReportTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Advance]=S.[Advance],[ApplicationStatus]=S.[ApplicationStatus],[ApplicationStatusParam]=S.[ApplicationStatusParam],[ApprovedAmount]=S.[ApprovedAmount],[AvailableBalance]=S.[AvailableBalance],[ContractsBooked]=S.[ContractsBooked],[ContractsFunded]=S.[ContractsFunded],[CreditApplicationNumber]=S.[CreditApplicationNumber],[CreditApplicationNumberFrom]=S.[CreditApplicationNumberFrom],[CreditApplicationNumberTo]=S.[CreditApplicationNumberTo],[CreditApplicationStatus]=S.[CreditApplicationStatus],[CreditDecisionStatus]=S.[CreditDecisionStatus],[CustomerId]=S.[CustomerId],[CustomerName]=S.[CustomerName],[DateSubmitted]=S.[DateSubmitted],[DateSubmittedFrom]=S.[DateSubmittedFrom],[DateSubmittedTo]=S.[DateSubmittedTo],[DealerOrDistributerId]=S.[DealerOrDistributerId],[DecisionStatus]=S.[DecisionStatus],[EquipmentDescription]=S.[EquipmentDescription],[ExpirationDate]=S.[ExpirationDate],[Frequency]=S.[Frequency],[FromSequenceNumberId]=S.[FromSequenceNumberId],[FullName]=S.[FullName],[InvoicesPaid]=S.[InvoicesPaid],[IsAvailableBalance]=S.[IsAvailableBalance],[IsContractsBooked]=S.[IsContractsBooked],[IsContractsFunded]=S.[IsContractsFunded],[IsPrivateLabel]=S.[IsPrivateLabel],[PrivateLabel]=S.[PrivateLabel],[ProgramVendor]=S.[ProgramVendor],[RequestedAmount]=S.[RequestedAmount],[RequestedEOTOption]=S.[RequestedEOTOption],[RequestedPromotion]=S.[RequestedPromotion],[SubmittedBy]=S.[SubmittedBy],[Term]=S.[Term],[ToSequenceNumberId]=S.[ToSequenceNumberId],[TransactionType]=S.[TransactionType],[UDF1Value]=S.[UDF1Value],[UDF2Value]=S.[UDF2Value],[UDF3Value]=S.[UDF3Value],[UDF4Value]=S.[UDF4Value],[UDF5Value]=S.[UDF5Value],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId],[VendorId]=S.[VendorId],[VendorName]=S.[VendorName]
WHEN NOT MATCHED THEN
	INSERT ([Advance],[ApplicationStatus],[ApplicationStatusParam],[ApprovedAmount],[AvailableBalance],[ContractsBooked],[ContractsFunded],[CreatedById],[CreatedTime],[CreditApplicationNumber],[CreditApplicationNumberFrom],[CreditApplicationNumberTo],[CreditApplicationStatus],[CreditDecisionStatus],[CustomerId],[CustomerName],[DateSubmitted],[DateSubmittedFrom],[DateSubmittedTo],[DealerOrDistributerId],[DecisionStatus],[EquipmentDescription],[ExpirationDate],[Frequency],[FromSequenceNumberId],[FullName],[Id],[InvoicesPaid],[IsAvailableBalance],[IsContractsBooked],[IsContractsFunded],[IsPrivateLabel],[PrivateLabel],[ProgramVendor],[RequestedAmount],[RequestedEOTOption],[RequestedPromotion],[SubmittedBy],[Term],[ToSequenceNumberId],[TransactionType],[UDF1Value],[UDF2Value],[UDF3Value],[UDF4Value],[UDF5Value],[UserId],[VendorId],[VendorName])
    VALUES (S.[Advance],S.[ApplicationStatus],S.[ApplicationStatusParam],S.[ApprovedAmount],S.[AvailableBalance],S.[ContractsBooked],S.[ContractsFunded],S.[CreatedById],S.[CreatedTime],S.[CreditApplicationNumber],S.[CreditApplicationNumberFrom],S.[CreditApplicationNumberTo],S.[CreditApplicationStatus],S.[CreditDecisionStatus],S.[CustomerId],S.[CustomerName],S.[DateSubmitted],S.[DateSubmittedFrom],S.[DateSubmittedTo],S.[DealerOrDistributerId],S.[DecisionStatus],S.[EquipmentDescription],S.[ExpirationDate],S.[Frequency],S.[FromSequenceNumberId],S.[FullName],S.[Id],S.[InvoicesPaid],S.[IsAvailableBalance],S.[IsContractsBooked],S.[IsContractsFunded],S.[IsPrivateLabel],S.[PrivateLabel],S.[ProgramVendor],S.[RequestedAmount],S.[RequestedEOTOption],S.[RequestedPromotion],S.[SubmittedBy],S.[Term],S.[ToSequenceNumberId],S.[TransactionType],S.[UDF1Value],S.[UDF2Value],S.[UDF3Value],S.[UDF4Value],S.[UDF5Value],S.[UserId],S.[VendorId],S.[VendorName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
