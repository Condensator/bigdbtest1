CREATE TYPE [dbo].[UDFLabelForPartyDetail] AS TABLE(
	[EntityType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UDF1Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF2Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF3Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF4Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF5Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDFLabelForPartyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
