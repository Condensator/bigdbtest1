SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePlanPayoutOptionVolumeTier]
(
 @val [dbo].[PlanPayoutOptionVolumeTier] READONLY
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
MERGE [dbo].[PlanPayoutOptionVolumeTiers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Commission]=S.[Commission],[IsActive]=S.[IsActive],[MaximumVolume_Amount]=S.[MaximumVolume_Amount],[MaximumVolume_Currency]=S.[MaximumVolume_Currency],[MinimumVolume_Amount]=S.[MinimumVolume_Amount],[MinimumVolume_Currency]=S.[MinimumVolume_Currency],[RowNumber]=S.[RowNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Commission],[CreatedById],[CreatedTime],[IsActive],[MaximumVolume_Amount],[MaximumVolume_Currency],[MinimumVolume_Amount],[MinimumVolume_Currency],[PlanBasesPayoutId],[RowNumber])
    VALUES (S.[Commission],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[MaximumVolume_Amount],S.[MaximumVolume_Currency],S.[MinimumVolume_Amount],S.[MinimumVolume_Currency],S.[PlanBasesPayoutId],S.[RowNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
