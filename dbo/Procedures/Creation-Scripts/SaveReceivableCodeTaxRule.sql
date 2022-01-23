SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableCodeTaxRule]
(
 @val [dbo].[ReceivableCodeTaxRule] READONLY
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
MERGE [dbo].[ReceivableCodeTaxRules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AppliesToLowerJurisdictions]=S.[AppliesToLowerJurisdictions],[CountryId]=S.[CountryId],[ExemptionRate]=S.[ExemptionRate],[IsActive]=S.[IsActive],[IsTaxable]=S.[IsTaxable],[JurisdictionLevel]=S.[JurisdictionLevel],[StateId]=S.[StateId],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UseCorporateRate]=S.[UseCorporateRate]
WHEN NOT MATCHED THEN
	INSERT ([AppliesToLowerJurisdictions],[CountryId],[CreatedById],[CreatedTime],[ExemptionRate],[IsActive],[IsTaxable],[JurisdictionLevel],[ReceivableCodeId],[StateId],[TaxTypeId],[UseCorporateRate])
    VALUES (S.[AppliesToLowerJurisdictions],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[ExemptionRate],S.[IsActive],S.[IsTaxable],S.[JurisdictionLevel],S.[ReceivableCodeId],S.[StateId],S.[TaxTypeId],S.[UseCorporateRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
