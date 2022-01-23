SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditApplicationInsuranceDetail]
(
 @val [dbo].[CreditApplicationInsuranceDetail] READONLY
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
MERGE [dbo].[CreditApplicationInsuranceDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CreditApplicationEquipmentDetailId]=S.[CreditApplicationEquipmentDetailId],[EngineCapacity]=S.[EngineCapacity],[Frequency]=S.[Frequency],[InsuranceAgencyId]=S.[InsuranceAgencyId],[InsuranceCompanyId]=S.[InsuranceCompanyId],[InsurancePremium_Amount]=S.[InsurancePremium_Amount],[InsurancePremium_Currency]=S.[InsurancePremium_Currency],[InsuranceType]=S.[InsuranceType],[Internal]=S.[Internal],[IsActive]=S.[IsActive],[Number]=S.[Number],[ProgramAssetTypeId]=S.[ProgramAssetTypeId],[ReceivableCodeId]=S.[ReceivableCodeId],[RegionConfigId]=S.[RegionConfigId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VehicleAge]=S.[VehicleAge]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CreditApplicationEquipmentDetailId],[CreditApplicationId],[EngineCapacity],[Frequency],[InsuranceAgencyId],[InsuranceCompanyId],[InsurancePremium_Amount],[InsurancePremium_Currency],[InsuranceType],[Internal],[IsActive],[Number],[ProgramAssetTypeId],[ReceivableCodeId],[RegionConfigId],[VehicleAge])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CreditApplicationEquipmentDetailId],S.[CreditApplicationId],S.[EngineCapacity],S.[Frequency],S.[InsuranceAgencyId],S.[InsuranceCompanyId],S.[InsurancePremium_Amount],S.[InsurancePremium_Currency],S.[InsuranceType],S.[Internal],S.[IsActive],S.[Number],S.[ProgramAssetTypeId],S.[ReceivableCodeId],S.[RegionConfigId],S.[VehicleAge])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
