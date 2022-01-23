SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePaydownTemplate]
(
 @val [dbo].[PaydownTemplate] READONLY
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
MERGE [dbo].[PaydownTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApplicableforFloatRateContract]=S.[ApplicableforFloatRateContract],[Description]=S.[Description],[IsActive]=S.[IsActive],[IsAvailableInCustomerPortal]=S.[IsAvailableInCustomerPortal],[IsAvailableInVendorPortal]=S.[IsAvailableInVendorPortal],[PortfolioId]=S.[PortfolioId],[TemplateName]=S.[TemplateName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ApplicableforFloatRateContract],[CreatedById],[CreatedTime],[Description],[IsActive],[IsAvailableInCustomerPortal],[IsAvailableInVendorPortal],[PortfolioId],[TemplateName])
    VALUES (S.[ApplicableforFloatRateContract],S.[CreatedById],S.[CreatedTime],S.[Description],S.[IsActive],S.[IsAvailableInCustomerPortal],S.[IsAvailableInVendorPortal],S.[PortfolioId],S.[TemplateName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
