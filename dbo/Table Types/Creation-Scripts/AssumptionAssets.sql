CREATE TYPE [dbo].[AssumptionAssets] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UpdateDriverAssignment] [bit] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[BillToId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[NewDriverId] [bigint] NULL,
	[OriginalLocationId] [bigint] NULL,
	[AssumptionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
