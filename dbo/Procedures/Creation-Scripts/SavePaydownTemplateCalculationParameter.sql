SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePaydownTemplateCalculationParameter]
(
 @val [dbo].[PaydownTemplateCalculationParameter] READONLY
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
MERGE [dbo].[PaydownTemplateCalculationParameters] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DiscountRate]=S.[DiscountRate],[Factor]=S.[Factor],[IsActive]=S.[IsActive],[NumberofTerms]=S.[NumberofTerms],[TerminationTypeParameterConfigId]=S.[TerminationTypeParameterConfigId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DiscountRate],[Factor],[IsActive],[NumberofTerms],[PaydownCalculationId],[TerminationTypeParameterConfigId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DiscountRate],S.[Factor],S.[IsActive],S.[NumberofTerms],S.[PaydownCalculationId],S.[TerminationTypeParameterConfigId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
