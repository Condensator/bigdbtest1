CREATE TYPE [dbo].[DriverHistory] AS TABLE(
	[LicenseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LicenseIssueDate] [date] NULL,
	[LicenseExpiryDate] [date] NULL,
	[AssignedDate] [date] NULL,
	[UnassignedDate] [date] NULL,
	[ReasonDescription] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[SourceModule] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[RelatedDriverId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[DriverId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
