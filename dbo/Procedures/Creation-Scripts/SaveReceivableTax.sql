SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableTax]
(
 @val [dbo].[ReceivableTax] READONLY
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
MERGE [dbo].[ReceivableTaxes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[EffectiveBalance_Amount]=S.[EffectiveBalance_Amount],[EffectiveBalance_Currency]=S.[EffectiveBalance_Currency],[GLTemplateId]=S.[GLTemplateId],[IsActive]=S.[IsActive],[IsCashBased]=S.[IsCashBased],[IsDummy]=S.[IsDummy],[IsGLPosted]=S.[IsGLPosted],[ReceivableId]=S.[ReceivableId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[Balance_Amount],[Balance_Currency],[CreatedById],[CreatedTime],[EffectiveBalance_Amount],[EffectiveBalance_Currency],[GLTemplateId],[IsActive],[IsCashBased],[IsDummy],[IsGLPosted],[ReceivableId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[Balance_Amount],S.[Balance_Currency],S.[CreatedById],S.[CreatedTime],S.[EffectiveBalance_Amount],S.[EffectiveBalance_Currency],S.[GLTemplateId],S.[IsActive],S.[IsCashBased],S.[IsDummy],S.[IsGLPosted],S.[ReceivableId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
