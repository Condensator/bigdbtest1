SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonVertexReceivableCodeDetail_Extract]
(
 @val [dbo].[NonVertexReceivableCodeDetail_Extract] READONLY
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
MERGE [dbo].[NonVertexReceivableCodeDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsCityTaxExempt]=S.[IsCityTaxExempt],[IsCountryTaxExempt]=S.[IsCountryTaxExempt],[IsCountyTaxExempt]=S.[IsCountyTaxExempt],[IsExemptAtReceivableCode]=S.[IsExemptAtReceivableCode],[IsRental]=S.[IsRental],[IsStateTaxExempt]=S.[IsStateTaxExempt],[JobStepInstanceId]=S.[JobStepInstanceId],[ReceivableCodeId]=S.[ReceivableCodeId],[StateId]=S.[StateId],[TaxReceivableName]=S.[TaxReceivableName],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[IsCityTaxExempt],[IsCountryTaxExempt],[IsCountyTaxExempt],[IsExemptAtReceivableCode],[IsRental],[IsStateTaxExempt],[JobStepInstanceId],[ReceivableCodeId],[StateId],[TaxReceivableName],[TaxTypeId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[IsCityTaxExempt],S.[IsCountryTaxExempt],S.[IsCountyTaxExempt],S.[IsExemptAtReceivableCode],S.[IsRental],S.[IsStateTaxExempt],S.[JobStepInstanceId],S.[ReceivableCodeId],S.[StateId],S.[TaxReceivableName],S.[TaxTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
