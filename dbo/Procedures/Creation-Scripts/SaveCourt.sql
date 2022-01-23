SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCourt]
(
 @val [dbo].[Court] READONLY
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
MERGE [dbo].[Courts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[AddressLine3]=S.[AddressLine3],[City]=S.[City],[ClerkOfCourtPhoneNumber]=S.[ClerkOfCourtPhoneNumber],[Comments]=S.[Comments],[CourtName]=S.[CourtName],[CourtType]=S.[CourtType],[DeactivationDate]=S.[DeactivationDate],[ECMPassword]=S.[ECMPassword],[ECMTrainingLink]=S.[ECMTrainingLink],[ECMUserName]=S.[ECMUserName],[ECMWebPOCFilingLink]=S.[ECMWebPOCFilingLink],[IsActive]=S.[IsActive],[Neighborhood]=S.[Neighborhood],[PortfolioId]=S.[PortfolioId],[PostalCode]=S.[PostalCode],[ReactivationDate]=S.[ReactivationDate],[Region]=S.[Region],[StateId]=S.[StateId],[SubdivisionOrMunicipality]=S.[SubdivisionOrMunicipality],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[AddressLine3],[City],[ClerkOfCourtPhoneNumber],[Comments],[CourtName],[CourtType],[CreatedById],[CreatedTime],[DeactivationDate],[ECMPassword],[ECMTrainingLink],[ECMUserName],[ECMWebPOCFilingLink],[IsActive],[Neighborhood],[PortfolioId],[PostalCode],[ReactivationDate],[Region],[StateId],[SubdivisionOrMunicipality])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[AddressLine3],S.[City],S.[ClerkOfCourtPhoneNumber],S.[Comments],S.[CourtName],S.[CourtType],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[ECMPassword],S.[ECMTrainingLink],S.[ECMUserName],S.[ECMWebPOCFilingLink],S.[IsActive],S.[Neighborhood],S.[PortfolioId],S.[PostalCode],S.[ReactivationDate],S.[Region],S.[StateId],S.[SubdivisionOrMunicipality])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
