SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePersonalGuarantorCIPHistory]
(
 @val [dbo].[PersonalGuarantorCIPHistory] READONLY
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
MERGE [dbo].[PersonalGuarantorCIPHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[CIPDocumentSourceForAddress]=S.[CIPDocumentSourceForAddress],[CIPDocumentSourceForName]=S.[CIPDocumentSourceForName],[CIPDocumentSourceForTaxIdOrSSN]=S.[CIPDocumentSourceForTaxIdOrSSN],[CIPDocumentSourceNameId]=S.[CIPDocumentSourceNameId],[City]=S.[City],[FirstName]=S.[FirstName],[LastName]=S.[LastName],[PostalCode]=S.[PostalCode],[SocialSecurityNumber]=S.[SocialSecurityNumber],[StateId]=S.[StateId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[CIPDocumentSourceForAddress],[CIPDocumentSourceForName],[CIPDocumentSourceForTaxIdOrSSN],[CIPDocumentSourceNameId],[City],[CreatedById],[CreatedTime],[FirstName],[LastName],[PartyContactId],[PostalCode],[SocialSecurityNumber],[StateId])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[CIPDocumentSourceForAddress],S.[CIPDocumentSourceForName],S.[CIPDocumentSourceForTaxIdOrSSN],S.[CIPDocumentSourceNameId],S.[City],S.[CreatedById],S.[CreatedTime],S.[FirstName],S.[LastName],S.[PartyContactId],S.[PostalCode],S.[SocialSecurityNumber],S.[StateId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
