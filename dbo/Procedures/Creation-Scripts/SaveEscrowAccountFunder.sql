SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEscrowAccountFunder]
(
 @val [dbo].[EscrowAccountFunder] READONLY
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
MERGE [dbo].[EscrowAccountFunders] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comments]=S.[Comments],[DisbursementNumber]=S.[DisbursementNumber],[DisbursementType]=S.[DisbursementType],[FederalReferenceNumber]=S.[FederalReferenceNumber],[FinalFunding]=S.[FinalFunding],[FundingAmount_Amount]=S.[FundingAmount_Amount],[FundingAmount_Currency]=S.[FundingAmount_Currency],[FundingFor]=S.[FundingFor],[InvoiceNumber]=S.[InvoiceNumber],[PayeeName]=S.[PayeeName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Comments],[CreatedById],[CreatedTime],[DisbursementNumber],[DisbursementType],[EscrowAccountId],[FederalReferenceNumber],[FinalFunding],[FundingAmount_Amount],[FundingAmount_Currency],[FundingFor],[InvoiceNumber],[PayeeName])
    VALUES (S.[Comments],S.[CreatedById],S.[CreatedTime],S.[DisbursementNumber],S.[DisbursementType],S.[EscrowAccountId],S.[FederalReferenceNumber],S.[FinalFunding],S.[FundingAmount_Amount],S.[FundingAmount_Currency],S.[FundingFor],S.[InvoiceNumber],S.[PayeeName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
