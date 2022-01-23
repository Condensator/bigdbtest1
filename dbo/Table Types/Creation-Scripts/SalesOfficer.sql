CREATE TYPE [dbo].[SalesOfficer] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EmployeeCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[OperatingTierVolumeFloorStartDate] [date] NULL,
	[OperatingTierVolumeFloorExpirationDate] [date] NULL,
	[JobTittle] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[DealCommissionCap_Amount] [decimal](16, 2) NULL,
	[DealCommissionCap_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[OperatingTierVolume_Amount] [decimal](16, 2) NULL,
	[OperatingTierVolume_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsCommissionable] [bit] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[PrimaryLineOfBussinessId] [bigint] NOT NULL,
	[UserNameId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
