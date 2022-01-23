SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInvoiceAddendumBodyDynamicContent]
(
 @val [dbo].[InvoiceAddendumBodyDynamicContent] READONLY
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
MERGE [dbo].[InvoiceAddendumBodyDynamicContents] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AttributeName]=S.[AttributeName],[EntityName]=S.[EntityName],[IsActive]=S.[IsActive],[Label]=S.[Label],[SortOrder]=S.[SortOrder],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AttributeName],[CreatedById],[CreatedTime],[EntityName],[IsActive],[Label],[SortOrder])
    VALUES (S.[AttributeName],S.[CreatedById],S.[CreatedTime],S.[EntityName],S.[IsActive],S.[Label],S.[SortOrder])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
