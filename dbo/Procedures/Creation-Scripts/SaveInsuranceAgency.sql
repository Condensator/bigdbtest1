SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInsuranceAgency]
(
 @val [dbo].[InsuranceAgency] READONLY
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
MERGE [dbo].[InsuranceAgencies] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[Alias]=S.[Alias],[FaxNumber]=S.[FaxNumber],[InactivationDate]=S.[InactivationDate],[InactivationReason]=S.[InactivationReason],[Name]=S.[Name],[PhoneNumber]=S.[PhoneNumber],[PortfolioId]=S.[PortfolioId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[Alias],[CreatedById],[CreatedTime],[FaxNumber],[Id],[InactivationDate],[InactivationReason],[Name],[PhoneNumber],[PortfolioId],[Status])
    VALUES (S.[ActivationDate],S.[Alias],S.[CreatedById],S.[CreatedTime],S.[FaxNumber],S.[Id],S.[InactivationDate],S.[InactivationReason],S.[Name],S.[PhoneNumber],S.[PortfolioId],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
