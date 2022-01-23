CREATE TYPE [dbo].[CommissionPackageSalesOfficer] AS TABLE(
	[IsPrimary] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[FreeCashSplit] [decimal](10, 2) NOT NULL,
	[VolumeSplit] [decimal](10, 2) NOT NULL,
	[FeeSplit] [decimal](10, 2) NOT NULL,
	[SalesOfficerId] [bigint] NOT NULL,
	[PlanBasisPayoutId] [bigint] NOT NULL,
	[CommissionPackageId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
