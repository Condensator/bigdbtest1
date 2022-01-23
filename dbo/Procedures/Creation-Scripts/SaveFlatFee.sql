SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveFlatFee]
(
 @val [dbo].[FlatFee] READONLY
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
MERGE [dbo].[FlatFees] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AssetTypeId]=S.[AssetTypeId],[EnginecapacityFrom]=S.[EnginecapacityFrom],[EngineCapacityTill]=S.[EngineCapacityTill],[IsActive]=S.[IsActive],[LegalEntityId]=S.[LegalEntityId],[LoadCapacity]=S.[LoadCapacity],[PermissibleMassFrom]=S.[PermissibleMassFrom],[PermissibleMassTill]=S.[PermissibleMassTill],[SeatFrom]=S.[SeatFrom],[SeatTill]=S.[SeatTill],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AssetTypeId],[CreatedById],[CreatedTime],[EnginecapacityFrom],[EngineCapacityTill],[IsActive],[LegalEntityId],[LoadCapacity],[PermissibleMassFrom],[PermissibleMassTill],[SeatFrom],[SeatTill])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AssetTypeId],S.[CreatedById],S.[CreatedTime],S.[EnginecapacityFrom],S.[EngineCapacityTill],S.[IsActive],S.[LegalEntityId],S.[LoadCapacity],S.[PermissibleMassFrom],S.[PermissibleMassTill],S.[SeatFrom],S.[SeatTill])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
