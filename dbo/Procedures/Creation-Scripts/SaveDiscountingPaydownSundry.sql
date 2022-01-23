SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingPaydownSundry]
(
 @val [dbo].[DiscountingPaydownSundry] READONLY
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
MERGE [dbo].[DiscountingPaydownSundries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BillToId]=S.[BillToId],[Description]=S.[Description],[DueDate]=S.[DueDate],[IsActive]=S.[IsActive],[LocationId]=S.[LocationId],[PartyId]=S.[PartyId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[RemitToId]=S.[RemitToId],[SundryId]=S.[SundryId],[SundryPayableCodeId]=S.[SundryPayableCodeId],[SundryReceivableCodeId]=S.[SundryReceivableCodeId],[SundryType]=S.[SundryType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[BillToId],[CreatedById],[CreatedTime],[Description],[DiscountingPaydownId],[DueDate],[IsActive],[LocationId],[PartyId],[PayableWithholdingTaxRate],[RemitToId],[SundryId],[SundryPayableCodeId],[SundryReceivableCodeId],[SundryType])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[BillToId],S.[CreatedById],S.[CreatedTime],S.[Description],S.[DiscountingPaydownId],S.[DueDate],S.[IsActive],S.[LocationId],S.[PartyId],S.[PayableWithholdingTaxRate],S.[RemitToId],S.[SundryId],S.[SundryPayableCodeId],S.[SundryReceivableCodeId],S.[SundryType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
