SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInvoiceGroupingParameter]
(
 @val [dbo].[InvoiceGroupingParameter] READONLY
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
MERGE [dbo].[InvoiceGroupingParameters] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllowBlending]=S.[AllowBlending],[Blending]=S.[Blending],[BlendReceivableCategoryId]=S.[BlendReceivableCategoryId],[BlendWithReceivableTypeId]=S.[BlendWithReceivableTypeId],[InvoiceGroupingCategory]=S.[InvoiceGroupingCategory],[IsActive]=S.[IsActive],[IsDefault]=S.[IsDefault],[IsParent]=S.[IsParent],[IsSystemDefined]=S.[IsSystemDefined],[ReceivableCategoryId]=S.[ReceivableCategoryId],[ReceivableTypeId]=S.[ReceivableTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AllowBlending],[Blending],[BlendReceivableCategoryId],[BlendWithReceivableTypeId],[CreatedById],[CreatedTime],[InvoiceGroupingCategory],[IsActive],[IsDefault],[IsParent],[IsSystemDefined],[ReceivableCategoryId],[ReceivableTypeId])
    VALUES (S.[AllowBlending],S.[Blending],S.[BlendReceivableCategoryId],S.[BlendWithReceivableTypeId],S.[CreatedById],S.[CreatedTime],S.[InvoiceGroupingCategory],S.[IsActive],S.[IsDefault],S.[IsParent],S.[IsSystemDefined],S.[ReceivableCategoryId],S.[ReceivableTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
