SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMetaEntityExtensionField]
(
 @val [dbo].[MetaEntityExtensionField] READONLY
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
MERGE [dbo].[MetaEntityExtensionFields] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DataType]=S.[DataType],[DefaultValue]=S.[DefaultValue],[Description]=S.[Description],[Enabled]=S.[Enabled],[IsAlteration]=S.[IsAlteration],[Label]=S.[Label],[Name]=S.[Name],[Nullable]=S.[Nullable],[ShowOnBrowseForm]=S.[ShowOnBrowseForm],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Visible]=S.[Visible]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DataType],[DefaultValue],[Description],[Enabled],[IsAlteration],[Label],[MetaEntityExtensionId],[Name],[Nullable],[ShowOnBrowseForm],[Visible])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DataType],S.[DefaultValue],S.[Description],S.[Enabled],S.[IsAlteration],S.[Label],S.[MetaEntityExtensionId],S.[Name],S.[Nullable],S.[ShowOnBrowseForm],S.[Visible])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
