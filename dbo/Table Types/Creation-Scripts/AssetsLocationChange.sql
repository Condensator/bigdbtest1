CREATE TYPE [dbo].[AssetsLocationChange] AS TABLE(
	[MoveChildAssets] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveFromDate] [date] NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[LocationChangeSourceType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[VendorComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CustomerComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[MigrationId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[NewLocationId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
