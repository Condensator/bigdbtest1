SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBranch]
(
 @val [dbo].[Branch] READONLY
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
MERGE [dbo].[Branches] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[BranchCode]=S.[BranchCode],[BranchName]=S.[BranchName],[BranchNumber]=S.[BranchNumber],[CostCenter]=S.[CostCenter],[CreationDate]=S.[CreationDate],[EIKNumber_CT]=S.[EIKNumber_CT],[InActivationDate]=S.[InActivationDate],[IsHeadquarter]=S.[IsHeadquarter],[LegalEntityId]=S.[LegalEntityId],[PortfolioId]=S.[PortfolioId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATRegistrationNumber]=S.[VATRegistrationNumber]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[BranchCode],[BranchName],[BranchNumber],[CostCenter],[CreatedById],[CreatedTime],[CreationDate],[EIKNumber_CT],[InActivationDate],[IsHeadquarter],[LegalEntityId],[PortfolioId],[Status],[VATRegistrationNumber])
    VALUES (S.[ActivationDate],S.[BranchCode],S.[BranchName],S.[BranchNumber],S.[CostCenter],S.[CreatedById],S.[CreatedTime],S.[CreationDate],S.[EIKNumber_CT],S.[InActivationDate],S.[IsHeadquarter],S.[LegalEntityId],S.[PortfolioId],S.[Status],S.[VATRegistrationNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
