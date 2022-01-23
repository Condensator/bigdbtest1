SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayoffReversalInvoice]
(
 @val [dbo].[PayoffReversalInvoice] READONLY
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
MERGE [dbo].[PayoffReversalInvoices] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [InvoiceFile_Content]=S.[InvoiceFile_Content],[InvoiceFile_Source]=S.[InvoiceFile_Source],[InvoiceFile_Type]=S.[InvoiceFile_Type],[InvoiceId]=S.[InvoiceId],[IsActive]=S.[IsActive],[ReferenceNumber]=S.[ReferenceNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[InvoiceFile_Content],[InvoiceFile_Source],[InvoiceFile_Type],[InvoiceId],[IsActive],[PayoffReversalId],[ReferenceNumber])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[InvoiceFile_Content],S.[InvoiceFile_Source],S.[InvoiceFile_Type],S.[InvoiceId],S.[IsActive],S.[PayoffReversalId],S.[ReferenceNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
