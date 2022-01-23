SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCustomerLocationTaxBasisProcessingDetail_Extract]
(
 @val [dbo].[CustomerLocationTaxBasisProcessingDetail_Extract] READONLY
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
MERGE [dbo].[CustomerLocationTaxBasisProcessingDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BatchId]=S.[BatchId],[City]=S.[City],[Company]=S.[Company],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[Country]=S.[Country],[Currency]=S.[Currency],[CustomerLocationId]=S.[CustomerLocationId],[CustomerNumber]=S.[CustomerNumber],[DueDate]=S.[DueDate],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseType]=S.[LeaseType],[LeaseUniqueID]=S.[LeaseUniqueID],[LegalEntityName]=S.[LegalEntityName],[LineItemId]=S.[LineItemId],[LocationCode]=S.[LocationCode],[LocationId]=S.[LocationId],[TaxAreaId]=S.[TaxAreaId],[ToState]=S.[ToState],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[BatchId],[City],[Company],[ContractId],[ContractType],[Country],[CreatedById],[CreatedTime],[Currency],[CustomerLocationId],[CustomerNumber],[DueDate],[JobStepInstanceId],[LeaseType],[LeaseUniqueID],[LegalEntityName],[LineItemId],[LocationCode],[LocationId],[TaxAreaId],[ToState])
    VALUES (S.[AssetId],S.[BatchId],S.[City],S.[Company],S.[ContractId],S.[ContractType],S.[Country],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[CustomerLocationId],S.[CustomerNumber],S.[DueDate],S.[JobStepInstanceId],S.[LeaseType],S.[LeaseUniqueID],S.[LegalEntityName],S.[LineItemId],S.[LocationCode],S.[LocationId],S.[TaxAreaId],S.[ToState])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
