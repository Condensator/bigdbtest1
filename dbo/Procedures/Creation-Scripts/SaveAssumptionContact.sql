SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssumptionContact]
(
 @val [dbo].[AssumptionContact] READONLY
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
MERGE [dbo].[AssumptionContacts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[CustomerId]=S.[CustomerId],[DeactivationDate]=S.[DeactivationDate],[IsActive]=S.[IsActive],[IsNewAddress]=S.[IsNewAddress],[IsNewlyAdded]=S.[IsNewlyAdded],[PartyAddressId]=S.[PartyAddressId],[PartyContactId]=S.[PartyContactId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[AssumptionId],[CreatedById],[CreatedTime],[CustomerId],[DeactivationDate],[IsActive],[IsNewAddress],[IsNewlyAdded],[PartyAddressId],[PartyContactId])
    VALUES (S.[ActivationDate],S.[AssumptionId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DeactivationDate],S.[IsActive],S.[IsNewAddress],S.[IsNewlyAdded],S.[PartyAddressId],S.[PartyContactId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
