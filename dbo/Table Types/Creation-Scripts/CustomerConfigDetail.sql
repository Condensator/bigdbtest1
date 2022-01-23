CREATE TYPE [dbo].[CustomerConfigDetail] AS TABLE(
	[PaidOffViewDays] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomDashboardApplicable] [bit] NOT NULL,
	[IsDisplaySoftAsset] [bit] NOT NULL,
	[DashboardProfileId] [bigint] NULL,
	[PartyId] [bigint] NOT NULL,
	[CustomerConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
