SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveProgramDefaultSalesRepAssignmentDetail]
(
 @val [dbo].[ProgramDefaultSalesRepAssignmentDetail] READONLY
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
MERGE [dbo].[ProgramDefaultSalesRepAssignmentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsActive]=S.[IsActive],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UploadById]=S.[UploadById],[UploadDate]=S.[UploadDate],[UploadFile_Content]=S.[UploadFile_Content],[UploadFile_Source]=S.[UploadFile_Source],[UploadFile_Type]=S.[UploadFile_Type]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[IsActive],[ProgramDefaultSalesRepAssignmentId],[Type],[UploadById],[UploadDate],[UploadFile_Content],[UploadFile_Source],[UploadFile_Type])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[ProgramDefaultSalesRepAssignmentId],S.[Type],S.[UploadById],S.[UploadDate],S.[UploadFile_Content],S.[UploadFile_Source],S.[UploadFile_Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
