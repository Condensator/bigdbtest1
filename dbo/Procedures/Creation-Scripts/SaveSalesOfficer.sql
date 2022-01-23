SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSalesOfficer]
(
 @val [dbo].[SalesOfficer] READONLY
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
MERGE [dbo].[SalesOfficers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CurrencyId]=S.[CurrencyId],[DealCommissionCap_Amount]=S.[DealCommissionCap_Amount],[DealCommissionCap_Currency]=S.[DealCommissionCap_Currency],[EmployeeCode]=S.[EmployeeCode],[IsActive]=S.[IsActive],[IsCommissionable]=S.[IsCommissionable],[JobTittle]=S.[JobTittle],[OperatingTierVolume_Amount]=S.[OperatingTierVolume_Amount],[OperatingTierVolume_Currency]=S.[OperatingTierVolume_Currency],[OperatingTierVolumeFloorExpirationDate]=S.[OperatingTierVolumeFloorExpirationDate],[OperatingTierVolumeFloorStartDate]=S.[OperatingTierVolumeFloorStartDate],[PrimaryLineOfBussinessId]=S.[PrimaryLineOfBussinessId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserNameId]=S.[UserNameId]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CurrencyId],[DealCommissionCap_Amount],[DealCommissionCap_Currency],[EmployeeCode],[IsActive],[IsCommissionable],[JobTittle],[OperatingTierVolume_Amount],[OperatingTierVolume_Currency],[OperatingTierVolumeFloorExpirationDate],[OperatingTierVolumeFloorStartDate],[PrimaryLineOfBussinessId],[UserNameId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[DealCommissionCap_Amount],S.[DealCommissionCap_Currency],S.[EmployeeCode],S.[IsActive],S.[IsCommissionable],S.[JobTittle],S.[OperatingTierVolume_Amount],S.[OperatingTierVolume_Currency],S.[OperatingTierVolumeFloorExpirationDate],S.[OperatingTierVolumeFloorStartDate],S.[PrimaryLineOfBussinessId],S.[UserNameId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
