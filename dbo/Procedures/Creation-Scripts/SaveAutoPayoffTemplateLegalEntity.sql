SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAutoPayoffTemplateLegalEntity]
(
 @val [dbo].[AutoPayoffTemplateLegalEntity] READONLY
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
MERGE [dbo].[AutoPayoffTemplateLegalEntities] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BuyoutReceivableCodeId]=S.[BuyoutReceivableCodeId],[CapitalLeasePayoffGLTemplateId]=S.[CapitalLeasePayoffGLTemplateId],[InventoryBookDepGLTemplateId]=S.[InventoryBookDepGLTemplateId],[IsActive]=S.[IsActive],[LegalEntityId]=S.[LegalEntityId],[OperatingLeasePayoffGLTemplateId]=S.[OperatingLeasePayoffGLTemplateId],[PayoffReceivableCodeId]=S.[PayoffReceivableCodeId],[SundryReceivableCodeId]=S.[SundryReceivableCodeId],[TaxDepDisposalGLTemplateId]=S.[TaxDepDisposalGLTemplateId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AutoPayoffTemplateId],[BuyoutReceivableCodeId],[CapitalLeasePayoffGLTemplateId],[CreatedById],[CreatedTime],[InventoryBookDepGLTemplateId],[IsActive],[LegalEntityId],[OperatingLeasePayoffGLTemplateId],[PayoffReceivableCodeId],[SundryReceivableCodeId],[TaxDepDisposalGLTemplateId])
    VALUES (S.[AutoPayoffTemplateId],S.[BuyoutReceivableCodeId],S.[CapitalLeasePayoffGLTemplateId],S.[CreatedById],S.[CreatedTime],S.[InventoryBookDepGLTemplateId],S.[IsActive],S.[LegalEntityId],S.[OperatingLeasePayoffGLTemplateId],S.[PayoffReceivableCodeId],S.[SundryReceivableCodeId],S.[TaxDepDisposalGLTemplateId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
