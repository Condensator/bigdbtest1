SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateIsMigratedForApprovedChargedOff]
(
@ChargeOffId NVARCHAR(MAX)
,@ApprovedChargeOffId NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON;
Select CC.R_ChargeoffId As ChargeOffId
Into #ChargeOffIds
From stgChargeoffContract CC
Inner Join (SELECT ID FROM ConvertCSVToBigIntTable(@ChargeOffId,',')) As MigratedChargeOff ON MigratedChargeOff.ID = CC.R_ChargeoffId
WHERE CC.IsMigrated = 0
AND CC.IsFailed = 0
AND Not Exists (SELECT ID FROM ConvertCSVToBigIntTable(@ApprovedChargeOffId,',') where ID = CC.R_ChargeoffId);
UPDATE stgChargeoffContract SET IsMigrated = 1
WHERE IsMigrated = 0 AND IsFailed = 0 AND R_ChargeoffId IN (SELECT ID FROM ConvertCSVToBigIntTable(@ApprovedChargeOffId,','));
Delete From ChargeOffAssetDetails where ChargeOffId In (Select ChargeOffId from #ChargeOffIds);
Delete From ChargeOffs where Id In (Select ChargeOffId from  #ChargeOffIds);
UPDATE stgChargeoffContract SET R_ChargeOffId = Null,IsFailed = 1
WHERE IsMigrated = 0 AND IsFailed = 0 AND R_ChargeoffId IN (Select ChargeOffId from #ChargeOffIds);
Drop Table #ChargeOffIds;
END

GO
