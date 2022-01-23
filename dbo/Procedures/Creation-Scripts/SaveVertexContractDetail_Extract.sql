SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVertexContractDetail_Extract]
(
 @val [dbo].[VertexContractDetail_Extract] READONLY
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
MERGE [dbo].[VertexContractDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BusCode]=S.[BusCode],[ClassificationContractType]=S.[ClassificationContractType],[CommencementDate]=S.[CommencementDate],[ContractId]=S.[ContractId],[DealProductTypeId]=S.[DealProductTypeId],[IsContractCapitalizeUpfront]=S.[IsContractCapitalizeUpfront],[IsLease]=S.[IsLease],[IsSyndicated]=S.[IsSyndicated],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseFinanceId]=S.[LeaseFinanceId],[LineofBusinessId]=S.[LineofBusinessId],[MaturityDate]=S.[MaturityDate],[NumberOfInceptionPayments]=S.[NumberOfInceptionPayments],[SequenceNumber]=S.[SequenceNumber],[ShortLeaseType]=S.[ShortLeaseType],[TaxAssessmentLevel]=S.[TaxAssessmentLevel],[TaxRemittanceType]=S.[TaxRemittanceType],[Term]=S.[Term],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BusCode],[ClassificationContractType],[CommencementDate],[ContractId],[CreatedById],[CreatedTime],[DealProductTypeId],[IsContractCapitalizeUpfront],[IsLease],[IsSyndicated],[JobStepInstanceId],[LeaseFinanceId],[LineofBusinessId],[MaturityDate],[NumberOfInceptionPayments],[SequenceNumber],[ShortLeaseType],[TaxAssessmentLevel],[TaxRemittanceType],[Term])
    VALUES (S.[BusCode],S.[ClassificationContractType],S.[CommencementDate],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DealProductTypeId],S.[IsContractCapitalizeUpfront],S.[IsLease],S.[IsSyndicated],S.[JobStepInstanceId],S.[LeaseFinanceId],S.[LineofBusinessId],S.[MaturityDate],S.[NumberOfInceptionPayments],S.[SequenceNumber],S.[ShortLeaseType],S.[TaxAssessmentLevel],S.[TaxRemittanceType],S.[Term])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
