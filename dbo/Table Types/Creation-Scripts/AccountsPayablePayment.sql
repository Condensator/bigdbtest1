CREATE TYPE [dbo].[AccountsPayablePayment] AS TABLE(
	[Status] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentDate] [date] NULL,
	[PostDate] [date] NOT NULL,
	[IsIntercompany] [bit] NOT NULL,
	[GLTemplateId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
