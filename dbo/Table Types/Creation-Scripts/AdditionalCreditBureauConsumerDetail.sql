CREATE TYPE [dbo].[AdditionalCreditBureauConsumerDetail] AS TABLE(
	[FieldName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ResponseValue] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreditBureauConsumerDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
