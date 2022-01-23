CREATE TYPE [dbo].[DriversAssignedToAsset] AS TABLE(
	[Assign] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssignedDate] [date] NULL,
	[UnassignedDate] [date] NULL,
	[IsPrimary] [bit] NOT NULL,
	[AssetId] [bigint] NULL,
	[DriverId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
