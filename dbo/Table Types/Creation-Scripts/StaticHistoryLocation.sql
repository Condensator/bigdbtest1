CREATE TYPE [dbo].[StaticHistoryLocation] AS TABLE(
	[LocationCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Address] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[County] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[State] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Country] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
