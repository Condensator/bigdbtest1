SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBillToInvoiceParameter]
(
 @val [dbo].[BillToInvoiceParameter] READONLY
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
MERGE [dbo].[BillToInvoiceParameters] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllowBlending]=S.[AllowBlending],[BlendWithReceivableTypeId]=S.[BlendWithReceivableTypeId],[InvoiceGroupingParameterId]=S.[InvoiceGroupingParameterId],[IsActive]=S.[IsActive],[ReceivableTypeLabelId]=S.[ReceivableTypeLabelId],[ReceivableTypeLanguageLabelId]=S.[ReceivableTypeLanguageLabelId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AllowBlending],[BillToId],[BlendWithReceivableTypeId],[CreatedById],[CreatedTime],[InvoiceGroupingParameterId],[IsActive],[ReceivableTypeLabelId],[ReceivableTypeLanguageLabelId])
    VALUES (S.[AllowBlending],S.[BillToId],S.[BlendWithReceivableTypeId],S.[CreatedById],S.[CreatedTime],S.[InvoiceGroupingParameterId],S.[IsActive],S.[ReceivableTypeLabelId],S.[ReceivableTypeLanguageLabelId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
