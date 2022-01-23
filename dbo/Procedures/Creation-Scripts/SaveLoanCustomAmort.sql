SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanCustomAmort]
(
 @val [dbo].[LoanCustomAmort] READONLY
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
MERGE [dbo].[LoanCustomAmorts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CustomAmortDocument_Content]=S.[CustomAmortDocument_Content],[CustomAmortDocument_Source]=S.[CustomAmortDocument_Source],[CustomAmortDocument_Type]=S.[CustomAmortDocument_Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UploadCustomAmort]=S.[UploadCustomAmort]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CustomAmortDocument_Content],[CustomAmortDocument_Source],[CustomAmortDocument_Type],[Id],[UploadCustomAmort])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CustomAmortDocument_Content],S.[CustomAmortDocument_Source],S.[CustomAmortDocument_Type],S.[Id],S.[UploadCustomAmort])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
