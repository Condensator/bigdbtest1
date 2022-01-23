CREATE TYPE [dbo].[AssetLifeCycleDataType] AS TABLE(
	[LegalEntityName] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[AcquisitionCost_Table] [decimal](16, 2) NOT NULL,
	[AcquisitionCostTable_GL] [decimal](16, 2) NOT NULL,
	[ETC_Table] [decimal](16, 2) NOT NULL,
	[CapitalizedCost_Table] [decimal](16, 2) NOT NULL,
	[AssetBookValueAdjustment_Table] [decimal](16, 2) NOT NULL,
	[ReturnedToInventory_Paydown_Table] [decimal](16, 2) NOT NULL,
	[LeasedAssetCost_Table] [decimal](16, 2) NOT NULL,
	[AssetAmortizedValue_Table] [decimal](16, 2) NOT NULL,
	[ClearedDepreciation_Table] [decimal](16, 2) NOT NULL,
	[ClearedImpairment_Table] [decimal](16, 2) NOT NULL,
	[AccumulatedFixedTermDepreciation_Table] [decimal](16, 2) NOT NULL,
	[AccumulatedOTPDepreciation_Table] [decimal](16, 2) NOT NULL,
	[AccumulatedAssetDepreciation_Table] [decimal](16, 2) NOT NULL,
	[AccumulatedNBVImpairment_Table] [decimal](16, 2) NOT NULL,
	[AccumulatedAssetImpairment_Table] [decimal](16, 2) NOT NULL,
	[CostOfGoodsSold_Table] [decimal](16, 2) NOT NULL,
	[ReturnToInventory_Lease_Table] [decimal](16, 2) NOT NULL,
	[ChargeOff_Table] [decimal](16, 2) NOT NULL,
	[RenewalAmortizedValue_Table] [decimal](16, 2) NOT NULL,
	[LeasedChargedOff_Table] [decimal](16, 2) NOT NULL
)
GO
