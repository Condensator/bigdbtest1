SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReversalContractDetail_Extract]
(
 @val [dbo].[ReversalContractDetail_Extract] READONLY
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
MERGE [dbo].[ReversalContractDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CommencementDate]=S.[CommencementDate],[ContractId]=S.[ContractId],[ContractTypeValue]=S.[ContractTypeValue],[IsSyndicated]=S.[IsSyndicated],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseUniqueId]=S.[LeaseUniqueId],[MaturityDate]=S.[MaturityDate],[TaxRemittanceType]=S.[TaxRemittanceType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CommencementDate],[ContractId],[ContractTypeValue],[CreatedById],[CreatedTime],[IsSyndicated],[JobStepInstanceId],[LeaseUniqueId],[MaturityDate],[TaxRemittanceType])
    VALUES (S.[CommencementDate],S.[ContractId],S.[ContractTypeValue],S.[CreatedById],S.[CreatedTime],S.[IsSyndicated],S.[JobStepInstanceId],S.[LeaseUniqueId],S.[MaturityDate],S.[TaxRemittanceType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
