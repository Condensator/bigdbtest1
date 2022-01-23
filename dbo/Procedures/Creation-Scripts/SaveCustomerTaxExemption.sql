SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCustomerTaxExemption]
(
 @val [dbo].[CustomerTaxExemption] READONLY
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
MERGE [dbo].[CustomerTaxExemptions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AppliesToLowerJurisdictions]=S.[AppliesToLowerJurisdictions],[CountryId]=S.[CountryId],[ExemptionRate]=S.[ExemptionRate],[IsActive]=S.[IsActive],[JurisdictionLevel]=S.[JurisdictionLevel],[StateId]=S.[StateId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AppliesToLowerJurisdictions],[CountryId],[CreatedById],[CreatedTime],[CustomerId],[ExemptionRate],[IsActive],[JurisdictionLevel],[StateId])
    VALUES (S.[AppliesToLowerJurisdictions],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[ExemptionRate],S.[IsActive],S.[JurisdictionLevel],S.[StateId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
