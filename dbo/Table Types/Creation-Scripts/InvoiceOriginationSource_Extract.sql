CREATE TYPE [dbo].[InvoiceOriginationSource_Extract] AS TABLE(
	[JobStepInstanceId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[OriginationSource] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[OriginationSourceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
