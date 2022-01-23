SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCountry]
(
 @val [dbo].[Country] READONLY
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
MERGE [dbo].[Countries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CorporateTaxIDMask]=S.[CorporateTaxIDMask],[CorporateTaxIDName]=S.[CorporateTaxIDName],[IndividualTaxIDMask]=S.[IndividualTaxIDMask],[IndividualTaxIDName]=S.[IndividualTaxIDName],[IsActive]=S.[IsActive],[IsDefault]=S.[IsDefault],[ISO_CountryCode]=S.[ISO_CountryCode],[ISO_CountryCodeAlpha2]=S.[ISO_CountryCodeAlpha2],[IsPostalCodeMandatory]=S.[IsPostalCodeMandatory],[IsVATApplicable]=S.[IsVATApplicable],[LongName]=S.[LongName],[PostalCodeFormat]=S.[PostalCodeFormat],[PostalCodeMask]=S.[PostalCodeMask],[ShortName]=S.[ShortName],[TaxSourceType]=S.[TaxSourceType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CorporateTaxIDMask],[CorporateTaxIDName],[CreatedById],[CreatedTime],[IndividualTaxIDMask],[IndividualTaxIDName],[IsActive],[IsDefault],[ISO_CountryCode],[ISO_CountryCodeAlpha2],[IsPostalCodeMandatory],[IsVATApplicable],[LongName],[PostalCodeFormat],[PostalCodeMask],[ShortName],[TaxSourceType])
    VALUES (S.[CorporateTaxIDMask],S.[CorporateTaxIDName],S.[CreatedById],S.[CreatedTime],S.[IndividualTaxIDMask],S.[IndividualTaxIDName],S.[IsActive],S.[IsDefault],S.[ISO_CountryCode],S.[ISO_CountryCodeAlpha2],S.[IsPostalCodeMandatory],S.[IsVATApplicable],S.[LongName],S.[PostalCodeFormat],S.[PostalCodeMask],S.[ShortName],S.[TaxSourceType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
