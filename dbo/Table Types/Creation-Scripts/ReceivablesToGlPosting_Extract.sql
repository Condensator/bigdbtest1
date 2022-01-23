CREATE TYPE [dbo].[ReceivablesToGlPosting_Extract] AS TABLE(
	[ReceivableId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsReceivableGLPosted] [bit] NOT NULL,
	[ReceivableTaxId] [bigint] NOT NULL,
	[IsTaxGLPosted] [bit] NOT NULL,
	[InvoiceRunDate] [date] NOT NULL,
	[ReceivableTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[IsGLProcessed] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
