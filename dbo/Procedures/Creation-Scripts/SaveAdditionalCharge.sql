SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAdditionalCharge]
(
 @val [dbo].[AdditionalCharge] READONLY
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
MERGE [dbo].[AdditionalCharges] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AssetLocationId]=S.[AssetLocationId],[AssetTypeId]=S.[AssetTypeId],[Capitalize]=S.[Capitalize],[ChargeApplicable]=S.[ChargeApplicable],[CreateSoftAsset]=S.[CreateSoftAsset],[DueDay]=S.[DueDay],[FeeId]=S.[FeeId],[FeePercent]=S.[FeePercent],[FirstDueDate]=S.[FirstDueDate],[Frequency]=S.[Frequency],[GLTemplateId]=S.[GLTemplateId],[IsActive]=S.[IsActive],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableDueDate]=S.[ReceivableDueDate],[Recurring]=S.[Recurring],[RecurringNumber]=S.[RecurringNumber],[RowNumber]=S.[RowNumber],[SourceType]=S.[SourceType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AssetLocationId],[AssetTypeId],[Capitalize],[ChargeApplicable],[CreatedById],[CreatedTime],[CreateSoftAsset],[DueDay],[FeeId],[FeePercent],[FirstDueDate],[Frequency],[GLTemplateId],[IsActive],[ReceivableCodeId],[ReceivableDueDate],[Recurring],[RecurringNumber],[RowNumber],[SourceType],[VATAmount_Amount],[VATAmount_Currency])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AssetLocationId],S.[AssetTypeId],S.[Capitalize],S.[ChargeApplicable],S.[CreatedById],S.[CreatedTime],S.[CreateSoftAsset],S.[DueDay],S.[FeeId],S.[FeePercent],S.[FirstDueDate],S.[Frequency],S.[GLTemplateId],S.[IsActive],S.[ReceivableCodeId],S.[ReceivableDueDate],S.[Recurring],S.[RecurringNumber],S.[RowNumber],S.[SourceType],S.[VATAmount_Amount],S.[VATAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
