SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePlanBasisAdministrativeCharge]
(
 @val [dbo].[PlanBasisAdministrativeCharge] READONLY
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
MERGE [dbo].[PlanBasisAdministrativeCharges] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdministrativeCost_Amount]=S.[AdministrativeCost_Amount],[AdministrativeCost_Currency]=S.[AdministrativeCost_Currency],[COFAdjustment]=S.[COFAdjustment],[IsActive]=S.[IsActive],[MaximumTransaction_Amount]=S.[MaximumTransaction_Amount],[MaximumTransaction_Currency]=S.[MaximumTransaction_Currency],[MinimumTransaction_Amount]=S.[MinimumTransaction_Amount],[MinimumTransaction_Currency]=S.[MinimumTransaction_Currency],[RowNumber]=S.[RowNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdministrativeCost_Amount],[AdministrativeCost_Currency],[COFAdjustment],[CreatedById],[CreatedTime],[IsActive],[MaximumTransaction_Amount],[MaximumTransaction_Currency],[MinimumTransaction_Amount],[MinimumTransaction_Currency],[PlanBaseId],[RowNumber])
    VALUES (S.[AdministrativeCost_Amount],S.[AdministrativeCost_Currency],S.[COFAdjustment],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[MaximumTransaction_Amount],S.[MaximumTransaction_Currency],S.[MinimumTransaction_Amount],S.[MinimumTransaction_Currency],S.[PlanBaseId],S.[RowNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
