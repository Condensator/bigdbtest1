SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxImpositionType]
(
 @val [dbo].[TaxImpositionType] READONLY
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
MERGE [dbo].[TaxImpositionTypes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CountryId]=S.[CountryId],[IsActive]=S.[IsActive],[IsSystemDefined]=S.[IsSystemDefined],[Name]=S.[Name],[TaxJurisdictionLevel]=S.[TaxJurisdictionLevel],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CountryId],[CreatedById],[CreatedTime],[IsActive],[IsSystemDefined],[Name],[TaxJurisdictionLevel],[TaxTypeId])
    VALUES (S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsSystemDefined],S.[Name],S.[TaxJurisdictionLevel],S.[TaxTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
