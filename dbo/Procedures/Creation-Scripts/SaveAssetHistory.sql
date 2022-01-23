SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetHistory]
(
 @val [dbo].[AssetHistory] READONLY
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
MERGE [dbo].[AssetHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionDate]=S.[AcquisitionDate],[AsOfDate]=S.[AsOfDate],[AssetId]=S.[AssetId],[ContractId]=S.[ContractId],[CustomerId]=S.[CustomerId],[FinancialType]=S.[FinancialType],[IsReversed]=S.[IsReversed],[LegalEntityId]=S.[LegalEntityId],[ParentAssetId]=S.[ParentAssetId],[PropertyTaxReportCodeId]=S.[PropertyTaxReportCodeId],[Reason]=S.[Reason],[SourceModule]=S.[SourceModule],[SourceModuleId]=S.[SourceModuleId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionDate],[AsOfDate],[AssetId],[ContractId],[CreatedById],[CreatedTime],[CustomerId],[FinancialType],[IsReversed],[LegalEntityId],[ParentAssetId],[PropertyTaxReportCodeId],[Reason],[SourceModule],[SourceModuleId],[Status])
    VALUES (S.[AcquisitionDate],S.[AsOfDate],S.[AssetId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[FinancialType],S.[IsReversed],S.[LegalEntityId],S.[ParentAssetId],S.[PropertyTaxReportCodeId],S.[Reason],S.[SourceModule],S.[SourceModuleId],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
