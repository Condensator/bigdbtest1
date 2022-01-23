SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayOffTemplateTerminationType]
(
 @val [dbo].[PayOffTemplateTerminationType] READONLY
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
MERGE [dbo].[PayOffTemplateTerminationTypes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ConditionalCalculation]=S.[ConditionalCalculation],[IsActive]=S.[IsActive],[PayoffTemplateTerminationTypeConfigId]=S.[PayoffTemplateTerminationTypeConfigId],[PayoffTerminationExpressionId]=S.[PayoffTerminationExpressionId],[PortfolioId]=S.[PortfolioId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ConditionalCalculation],[CreatedById],[CreatedTime],[IsActive],[PayOffTemplateId],[PayoffTemplateTerminationTypeConfigId],[PayoffTerminationExpressionId],[PortfolioId])
    VALUES (S.[ConditionalCalculation],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[PayOffTemplateId],S.[PayoffTemplateTerminationTypeConfigId],S.[PayoffTerminationExpressionId],S.[PortfolioId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
