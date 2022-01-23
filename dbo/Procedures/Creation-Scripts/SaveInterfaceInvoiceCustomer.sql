SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInterfaceInvoiceCustomer]
(
 @val [dbo].[InterfaceInvoiceCustomer] READONLY
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
MERGE [dbo].[InterfaceInvoiceCustomers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CustomerNumber]=S.[CustomerNumber],[DueDate]=S.[DueDate],[IsWilliamsCustomer]=S.[IsWilliamsCustomer],[MaxInvoiceNumber]=S.[MaxInvoiceNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CustomerNumber],[DueDate],[IsWilliamsCustomer],[MaxInvoiceNumber])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CustomerNumber],S.[DueDate],S.[IsWilliamsCustomer],S.[MaxInvoiceNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
