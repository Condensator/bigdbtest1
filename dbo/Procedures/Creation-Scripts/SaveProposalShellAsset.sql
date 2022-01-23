SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveProposalShellAsset]
(
 @val [dbo].[ProposalShellAsset] READONLY
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
MERGE [dbo].[ProposalShellAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EquipmentDescription]=S.[EquipmentDescription],[EquipmentLocation]=S.[EquipmentLocation],[EquipmentTypeName]=S.[EquipmentTypeName],[ManufacturerName]=S.[ManufacturerName],[ModalityName]=S.[ModalityName],[Model]=S.[Model],[ModelYear]=S.[ModelYear],[Quantity]=S.[Quantity],[SellingPrice_Amount]=S.[SellingPrice_Amount],[SellingPrice_Currency]=S.[SellingPrice_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EquipmentDescription],[EquipmentLocation],[EquipmentTypeName],[ManufacturerName],[ModalityName],[Model],[ModelYear],[ProposalId],[Quantity],[SellingPrice_Amount],[SellingPrice_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EquipmentDescription],S.[EquipmentLocation],S.[EquipmentTypeName],S.[ManufacturerName],S.[ModalityName],S.[Model],S.[ModelYear],S.[ProposalId],S.[Quantity],S.[SellingPrice_Amount],S.[SellingPrice_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
