SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StaticHistoryLocations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LocationCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
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
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
