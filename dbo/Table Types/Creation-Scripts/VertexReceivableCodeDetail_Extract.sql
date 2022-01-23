CREATE TYPE [dbo].[VertexReceivableCodeDetail_Extract] AS TABLE(
	[ReceivableCodeId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsExemptAtReceivableCode] [bit] NOT NULL,
	[SundryReceivableCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxReceivableName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsRental] [bit] NOT NULL,
	[TransactionType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
