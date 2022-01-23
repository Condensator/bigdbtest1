SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveFloatRateIndexDetail]
(
 @val [dbo].[FloatRateIndexDetail] READONLY
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
MERGE [dbo].[FloatRateIndexDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BaseRate]=S.[BaseRate],[EffectiveDate]=S.[EffectiveDate],[IsActive]=S.[IsActive],[IsModified]=S.[IsModified],[IsRateUsed]=S.[IsRateUsed],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BaseRate],[CreatedById],[CreatedTime],[EffectiveDate],[FloatRateIndexId],[IsActive],[IsModified],[IsRateUsed])
    VALUES (S.[BaseRate],S.[CreatedById],S.[CreatedTime],S.[EffectiveDate],S.[FloatRateIndexId],S.[IsActive],S.[IsModified],S.[IsRateUsed])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
