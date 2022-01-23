SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePlanBase]
(
 @val [dbo].[PlanBase] READONLY
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
MERGE [dbo].[PlanBases] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [PlanBasisAbbreviation]=S.[PlanBasisAbbreviation],[PlanBasisDescription]=S.[PlanBasisDescription],[PlanBasisNumber]=S.[PlanBasisNumber],[PlanBasisQuoteDocument_Content]=S.[PlanBasisQuoteDocument_Content],[PlanBasisQuoteDocument_Source]=S.[PlanBasisQuoteDocument_Source],[PlanBasisQuoteDocument_Type]=S.[PlanBasisQuoteDocument_Type],[PlanFamilyId]=S.[PlanFamilyId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[PlanBasisAbbreviation],[PlanBasisDescription],[PlanBasisNumber],[PlanBasisQuoteDocument_Content],[PlanBasisQuoteDocument_Source],[PlanBasisQuoteDocument_Type],[PlanFamilyId],[Status])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[PlanBasisAbbreviation],S.[PlanBasisDescription],S.[PlanBasisNumber],S.[PlanBasisQuoteDocument_Content],S.[PlanBasisQuoteDocument_Source],S.[PlanBasisQuoteDocument_Type],S.[PlanFamilyId],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
