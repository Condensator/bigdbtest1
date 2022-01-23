SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveQuoteLeaseType]
(
 @val [dbo].[QuoteLeaseType] READONLY
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
MERGE [dbo].[QuoteLeaseTypes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Code]=S.[Code],[DealProductTypeId]=S.[DealProductTypeId],[DealTypeId]=S.[DealTypeId],[Description]=S.[Description],[IsActive]=S.[IsActive],[IsCloseEndLease]=S.[IsCloseEndLease],[IsFloatRate]=S.[IsFloatRate],[LegalEntityId]=S.[LegalEntityId],[MinimumResidualValuePercentage]=S.[MinimumResidualValuePercentage],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATBasis]=S.[VATBasis]
WHEN NOT MATCHED THEN
	INSERT ([Code],[CreatedById],[CreatedTime],[DealProductTypeId],[DealTypeId],[Description],[IsActive],[IsCloseEndLease],[IsFloatRate],[LegalEntityId],[MinimumResidualValuePercentage],[VATBasis])
    VALUES (S.[Code],S.[CreatedById],S.[CreatedTime],S.[DealProductTypeId],S.[DealTypeId],S.[Description],S.[IsActive],S.[IsCloseEndLease],S.[IsFloatRate],S.[LegalEntityId],S.[MinimumResidualValuePercentage],S.[VATBasis])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
