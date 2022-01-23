SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMasterAgreement]
(
 @val [dbo].[MasterAgreement] READONLY
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
MERGE [dbo].[MasterAgreements] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[AgreementAlias]=S.[AgreementAlias],[AgreementDate]=S.[AgreementDate],[AgreementTypeId]=S.[AgreementTypeId],[CustomerId]=S.[CustomerId],[DeactivationDate]=S.[DeactivationDate],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[Number]=S.[Number],[ReceivedDate]=S.[ReceivedDate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[AgreementAlias],[AgreementDate],[AgreementTypeId],[CreatedById],[CreatedTime],[CustomerId],[DeactivationDate],[LegalEntityId],[LineofBusinessId],[Number],[ReceivedDate],[Status])
    VALUES (S.[ActivationDate],S.[AgreementAlias],S.[AgreementDate],S.[AgreementTypeId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DeactivationDate],S.[LegalEntityId],S.[LineofBusinessId],S.[Number],S.[ReceivedDate],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
