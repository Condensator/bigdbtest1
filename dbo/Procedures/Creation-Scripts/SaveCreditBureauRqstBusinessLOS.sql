SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditBureauRqstBusinessLOS]
(
 @val [dbo].[CreditBureauRqstBusinessLOS] READONLY
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
MERGE [dbo].[CreditBureauRqstBusinessLOS] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Address]=S.[Address],[BureauCustomerName]=S.[BureauCustomerName],[BureauCustomerNumber]=S.[BureauCustomerNumber],[City]=S.[City],[ConfidenceIndicator]=S.[ConfidenceIndicator],[IsActive]=S.[IsActive],[LosTransactionNumber]=S.[LosTransactionNumber],[MainAddress]=S.[MainAddress],[ResponseUniqueNumber]=S.[ResponseUniqueNumber],[SSN]=S.[SSN],[StateName]=S.[StateName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Zip]=S.[Zip]
WHEN NOT MATCHED THEN
	INSERT ([Address],[BureauCustomerName],[BureauCustomerNumber],[City],[ConfidenceIndicator],[CreatedById],[CreatedTime],[CreditBureauRqstBusinessId],[IsActive],[LosTransactionNumber],[MainAddress],[ResponseUniqueNumber],[SSN],[StateName],[Zip])
    VALUES (S.[Address],S.[BureauCustomerName],S.[BureauCustomerNumber],S.[City],S.[ConfidenceIndicator],S.[CreatedById],S.[CreatedTime],S.[CreditBureauRqstBusinessId],S.[IsActive],S.[LosTransactionNumber],S.[MainAddress],S.[ResponseUniqueNumber],S.[SSN],S.[StateName],S.[Zip])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
