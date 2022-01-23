CREATE TYPE [dbo].[RentSharingDetail] AS TABLE(
	[Percentage] [decimal](18, 8) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SourceType] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[PayableCodeId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
