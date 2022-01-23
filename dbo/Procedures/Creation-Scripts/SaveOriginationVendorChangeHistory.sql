SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOriginationVendorChangeHistory]
(
 @val [dbo].[OriginationVendorChangeHistory] READONLY
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
MERGE [dbo].[OriginationVendorChangeHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[CreditProfileId]=S.[CreditProfileId],[EffectiveFromDate]=S.[EffectiveFromDate],[IsCurrent]=S.[IsCurrent],[NewOriginationVendorId]=S.[NewOriginationVendorId],[NewProgramId]=S.[NewProgramId],[NewProgramVendorId]=S.[NewProgramVendorId],[NewRemitToId]=S.[NewRemitToId],[OldOriginationVendorId]=S.[OldOriginationVendorId],[OldProgramId]=S.[OldProgramId],[OldProgramVendorId]=S.[OldProgramVendorId],[OldRemitToId]=S.[OldRemitToId],[OpportunityId]=S.[OpportunityId],[TransferDate]=S.[TransferDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[CreditProfileId],[EffectiveFromDate],[IsCurrent],[NewOriginationVendorId],[NewProgramId],[NewProgramVendorId],[NewRemitToId],[OldOriginationVendorId],[OldProgramId],[OldProgramVendorId],[OldRemitToId],[OpportunityId],[TransferDate])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CreditProfileId],S.[EffectiveFromDate],S.[IsCurrent],S.[NewOriginationVendorId],S.[NewProgramId],S.[NewProgramVendorId],S.[NewRemitToId],S.[OldOriginationVendorId],S.[OldProgramId],S.[OldProgramVendorId],S.[OldRemitToId],S.[OpportunityId],S.[TransferDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
