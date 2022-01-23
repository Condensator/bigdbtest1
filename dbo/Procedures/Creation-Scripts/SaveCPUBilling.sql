SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUBilling]
(
 @val [dbo].[CPUBilling] READONLY
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
MERGE [dbo].[CPUBillings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BasePassThroughPercent]=S.[BasePassThroughPercent],[BillToId]=S.[BillToId],[InvoiceComment]=S.[InvoiceComment],[InvoiceLeadDays]=S.[InvoiceLeadDays],[InvoiceTransitDays]=S.[InvoiceTransitDays],[IsPerfectPay]=S.[IsPerfectPay],[OveragePassThroughPercent]=S.[OveragePassThroughPercent],[PassThroughRemitToId]=S.[PassThroughRemitToId],[PerfectPayModeAssigned]=S.[PerfectPayModeAssigned],[RemitToId]=S.[RemitToId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([BasePassThroughPercent],[BillToId],[CreatedById],[CreatedTime],[Id],[InvoiceComment],[InvoiceLeadDays],[InvoiceTransitDays],[IsPerfectPay],[OveragePassThroughPercent],[PassThroughRemitToId],[PerfectPayModeAssigned],[RemitToId],[VendorId])
    VALUES (S.[BasePassThroughPercent],S.[BillToId],S.[CreatedById],S.[CreatedTime],S.[Id],S.[InvoiceComment],S.[InvoiceLeadDays],S.[InvoiceTransitDays],S.[IsPerfectPay],S.[OveragePassThroughPercent],S.[PassThroughRemitToId],S.[PerfectPayModeAssigned],S.[RemitToId],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
