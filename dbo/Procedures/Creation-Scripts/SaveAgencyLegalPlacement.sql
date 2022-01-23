SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAgencyLegalPlacement]
(
 @val [dbo].[AgencyLegalPlacement] READONLY
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
MERGE [dbo].[AgencyLegalPlacements] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AgencyFileNumber]=S.[AgencyFileNumber],[BusinessUnitId]=S.[BusinessUnitId],[ContingencyPercentage]=S.[ContingencyPercentage],[CustomerId]=S.[CustomerId],[DateOfPlacement]=S.[DateOfPlacement],[Fee_Amount]=S.[Fee_Amount],[Fee_Currency]=S.[Fee_Currency],[FeeStructure]=S.[FeeStructure],[IsActive]=S.[IsActive],[LegalReliefId]=S.[LegalReliefId],[Outcome]=S.[Outcome],[PlacementNumber]=S.[PlacementNumber],[PlacementPurpose]=S.[PlacementPurpose],[PlacementType]=S.[PlacementType],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([AgencyFileNumber],[BusinessUnitId],[ContingencyPercentage],[CreatedById],[CreatedTime],[CustomerId],[DateOfPlacement],[Fee_Amount],[Fee_Currency],[FeeStructure],[IsActive],[LegalReliefId],[Outcome],[PlacementNumber],[PlacementPurpose],[PlacementType],[Status],[VendorId])
    VALUES (S.[AgencyFileNumber],S.[BusinessUnitId],S.[ContingencyPercentage],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DateOfPlacement],S.[Fee_Amount],S.[Fee_Currency],S.[FeeStructure],S.[IsActive],S.[LegalReliefId],S.[Outcome],S.[PlacementNumber],S.[PlacementPurpose],S.[PlacementType],S.[Status],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
