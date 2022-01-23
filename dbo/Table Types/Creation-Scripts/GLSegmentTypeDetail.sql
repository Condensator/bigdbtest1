CREATE TYPE [dbo].[GLSegmentTypeDetail] AS TABLE(
	[GLEntityType] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Expression] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[StaticSegmentValue] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[GLSegmentTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
