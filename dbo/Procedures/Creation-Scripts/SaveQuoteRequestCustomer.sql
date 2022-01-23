SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveQuoteRequestCustomer]
(
 @val [dbo].[QuoteRequestCustomer] READONLY
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
MERGE [dbo].[QuoteRequestCustomers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comments]=S.[Comments],[CompanyName]=S.[CompanyName],[CustomerId]=S.[CustomerId],[EGNNumber]=S.[EGNNumber],[EIKNumber]=S.[EIKNumber],[Email]=S.[Email],[FirstName]=S.[FirstName],[IsCorporate]=S.[IsCorporate],[IsCreateCustomer]=S.[IsCreateCustomer],[IsSoleProprietor]=S.[IsSoleProprietor],[LastName]=S.[LastName],[PhoneNumber]=S.[PhoneNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Comments],[CompanyName],[CreatedById],[CreatedTime],[CustomerId],[EGNNumber],[EIKNumber],[Email],[FirstName],[Id],[IsCorporate],[IsCreateCustomer],[IsSoleProprietor],[LastName],[PhoneNumber])
    VALUES (S.[Comments],S.[CompanyName],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[EGNNumber],S.[EIKNumber],S.[Email],S.[FirstName],S.[Id],S.[IsCorporate],S.[IsCreateCustomer],S.[IsSoleProprietor],S.[LastName],S.[PhoneNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
