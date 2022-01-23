CREATE TYPE [dbo].[GLAccountDetail] AS TABLE(
	[SegmentNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsDynamic] [bit] NOT NULL,
	[SegmentValue] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[DynamicSegmentTypeId] [bigint] NULL,
	[GLAccountId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
