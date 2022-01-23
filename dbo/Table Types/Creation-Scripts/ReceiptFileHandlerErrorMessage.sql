CREATE TYPE [dbo].[ReceiptFileHandlerErrorMessage] AS TABLE(
	[RowId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ErrorMessage] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[SourceTable] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
