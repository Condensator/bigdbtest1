CREATE TYPE [dbo].[PropertyTaxExportFileDetail] AS TABLE(
	[ExportFile] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsPreview] [bit] NOT NULL,
	[IsExported] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
