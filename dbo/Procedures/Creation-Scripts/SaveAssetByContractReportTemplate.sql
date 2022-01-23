SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetByContractReportTemplate]
(
 @val [dbo].[AssetByContractReportTemplate] READONLY
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
MERGE [dbo].[AssetByContractReportTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetAlias]=S.[AssetAlias],[AssetId]=S.[AssetId],[AssetType]=S.[AssetType],[CommencementDate]=S.[CommencementDate],[CommencementDateOptions]=S.[CommencementDateOptions],[CommencementRunDate]=S.[CommencementRunDate],[CommencementUpThrough]=S.[CommencementUpThrough],[ContractFilterOption]=S.[ContractFilterOption],[ContractStatus]=S.[ContractStatus],[Country]=S.[Country],[CustomerId]=S.[CustomerId],[CustomerName]=S.[CustomerName],[CustomerNumber]=S.[CustomerNumber],[Description]=S.[Description],[FromCommencementDate]=S.[FromCommencementDate],[FromMaturityDate]=S.[FromMaturityDate],[FromSequenceNumberId]=S.[FromSequenceNumberId],[Location]=S.[Location],[Manufacturer]=S.[Manufacturer],[MaturityDate]=S.[MaturityDate],[MaturityDateOptions]=S.[MaturityDateOptions],[MaturityTillDate]=S.[MaturityTillDate],[MaturityTillXDaysFromRunDate]=S.[MaturityTillXDaysFromRunDate],[ModelYear]=S.[ModelYear],[Name]=S.[Name],[OrderBy]=S.[OrderBy],[PartNumber]=S.[PartNumber],[SequenceNumber]=S.[SequenceNumber],[SerialNumber]=S.[SerialNumber],[State]=S.[State],[Status]=S.[Status],[Term]=S.[Term],[ToCommencementDate]=S.[ToCommencementDate],[ToMaturityDate]=S.[ToMaturityDate],[ToSequenceNumberId]=S.[ToSequenceNumberId],[UDF1Value]=S.[UDF1Value],[UDF2Value]=S.[UDF2Value],[UDF3Value]=S.[UDF3Value],[UDF4Value]=S.[UDF4Value],[UDF5Value]=S.[UDF5Value],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([AssetAlias],[AssetId],[AssetType],[CommencementDate],[CommencementDateOptions],[CommencementRunDate],[CommencementUpThrough],[ContractFilterOption],[ContractStatus],[Country],[CreatedById],[CreatedTime],[CustomerId],[CustomerName],[CustomerNumber],[Description],[FromCommencementDate],[FromMaturityDate],[FromSequenceNumberId],[Id],[Location],[Manufacturer],[MaturityDate],[MaturityDateOptions],[MaturityTillDate],[MaturityTillXDaysFromRunDate],[ModelYear],[Name],[OrderBy],[PartNumber],[SequenceNumber],[SerialNumber],[State],[Status],[Term],[ToCommencementDate],[ToMaturityDate],[ToSequenceNumberId],[UDF1Value],[UDF2Value],[UDF3Value],[UDF4Value],[UDF5Value],[UserId])
    VALUES (S.[AssetAlias],S.[AssetId],S.[AssetType],S.[CommencementDate],S.[CommencementDateOptions],S.[CommencementRunDate],S.[CommencementUpThrough],S.[ContractFilterOption],S.[ContractStatus],S.[Country],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[CustomerName],S.[CustomerNumber],S.[Description],S.[FromCommencementDate],S.[FromMaturityDate],S.[FromSequenceNumberId],S.[Id],S.[Location],S.[Manufacturer],S.[MaturityDate],S.[MaturityDateOptions],S.[MaturityTillDate],S.[MaturityTillXDaysFromRunDate],S.[ModelYear],S.[Name],S.[OrderBy],S.[PartNumber],S.[SequenceNumber],S.[SerialNumber],S.[State],S.[Status],S.[Term],S.[ToCommencementDate],S.[ToMaturityDate],S.[ToSequenceNumberId],S.[UDF1Value],S.[UDF2Value],S.[UDF3Value],S.[UDF4Value],S.[UDF5Value],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
